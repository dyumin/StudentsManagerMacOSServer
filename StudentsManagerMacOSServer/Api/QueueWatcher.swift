//
//  QueueWatcher.swift
//  StudentsManagerMacOSServer
//
//  Created by Дюмин Алексей on 14/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

import RxSwift
import FirebaseCore
import FirebaseFirestore

import PINCache

import FirebaseStorage
import RxFirebaseStorage

fileprivate let Model = ModelApi()

class QueueWatcher
{
    let disposeBag = DisposeBag()
    
//    private let mediaObservablesCache = PINMemoryCache()
    private let mediaObservablesRetainingSubscriptionCache = PINMemoryCache()
    private let starter = PINMemoryCache()
    
    func shouldStartNewThread() -> Bool
    {
        var totalThreads = 0
        
        self.starter.enumerateObjects(
            block: { (_, _, _) in
                totalThreads += 1
        })
        
        if totalThreads > 1
        {
            print("QueueWatcher worker: performance guard, threads count limit exceeded \(totalThreads)")
            return false
        }
        
        return true
    }
    
    init()
    {
        let lostJobsTimer = Observable<Int>.interval(15, scheduler: MainScheduler.instance)
        
        let db = Firestore.firestore()
        
        Observable.combineLatest(
        db.collection("processingQueue").whereField(ProcessingQueue.active, isEqualTo: true).rx.listen(),
        lostJobsTimer).throttle(5, scheduler: MainScheduler.instance).debug("lostJobs worker").subscribe(onNext:
        { [weak self] (querySnapshot, _) in
            
            print("lostJobs worker: now active: \(querySnapshot.count)")
            
            querySnapshot.documents.forEach({ (queryDocumentSnapshot) in
            
                if let lastUpdateTime = queryDocumentSnapshot.get(ProcessingQueue.lastUpdateTime) as? Timestamp
                {
                    let timePassed = Timestamp.init().seconds - lastUpdateTime.seconds
                    
                    // processing takes too long or lost
                    if timePassed > 90 && !(self?.mediaObservablesRetainingSubscriptionCache.containsObject(forKey: queryDocumentSnapshot.documentID) ?? false)
                    {
                        // it is ok, update sequences will terminate in finite time
                        
                        let data = [ProcessingQueue.active : false,
                                    ProcessingQueue.lastUpdateTime: Timestamp.init()] as [String : Any]
                        
                        _ = queryDocumentSnapshot.reference.rx
                            .updateData(data)
                            .debug("\(queryDocumentSnapshot.reference.path): update to \(data)")
                            .subscribe()
                        
                    }
                }
                else
                {
                    let data = [ProcessingQueue.lastUpdateTime : Timestamp.init()]
                    
                    _ = queryDocumentSnapshot.reference.rx
                        .updateData(data)
                        .debug("\(queryDocumentSnapshot.reference.path): update to \(data)").subscribe(
                    onError: { error in
                        print(error)
                        assertionFailure()
                    })
                }
            })
            
        }).disposed(by: disposeBag)
        
        let workTimer = Observable<Int>.interval(15, scheduler: MainScheduler.instance)
            .startWith(0) // start immediately
        Observable.combineLatest(
        db.collection("processingQueue").whereField(ProcessingQueue.active, isEqualTo: false).rx.listen(),
        workTimer).throttle(5, scheduler: MainScheduler.instance).debug("QueueWatcher worker").subscribe(onNext:
        { [weak self] (querySnapshot, _) in
            
            guard let self = self else { return }
            
            querySnapshot.documents.forEach({ (queryDocumentSnapshot) in
                
                guard self.shouldStartNewThread() else { return }
                
                // already processing, return
                if self.mediaObservablesRetainingSubscriptionCache.object(forKey: queryDocumentSnapshot.documentID) != nil
                {
                    return
                }
                
                guard let imageServerPath = queryDocumentSnapshot.get(ProcessingQueue.imagePath) as? String
                else
                {
                    QueueWatcher.deleteIllFormedMediaRecords(processingQueueDocumentSnapshot: queryDocumentSnapshot)
                    return
                }
                
                guard let imageMeta = queryDocumentSnapshot.get(ProcessingQueue.imageMeta) as? DocumentReference
                else
                {
                    QueueWatcher.deleteIllFormedMediaRecords(processingQueueDocumentSnapshot: queryDocumentSnapshot)
                    return
                }
                
                guard let session = queryDocumentSnapshot.get(ProcessingQueue.session) as? DocumentReference
                    else
                {
                    QueueWatcher.deleteIllFormedMediaRecords(processingQueueDocumentSnapshot: queryDocumentSnapshot)
                    return
                }
                
                guard let active = queryDocumentSnapshot.get(ProcessingQueue.active) as? Bool
                else
                {
                    QueueWatcher.deleteIllFormedMediaRecords(processingQueueDocumentSnapshot: queryDocumentSnapshot)
                    return
                }
                
                // somebody already processing, return
                // timeout implemented by "lostJobs worker"
                if active
                {
                    return
                }
                
                let bag = DisposeBag()
                
                self.starter.setObject(bag, forKey: queryDocumentSnapshot.documentID)
                
                let dataSettingProcessingToTrue = [ ProcessingQueue.active : true,
                                                    ProcessingQueue.lastUpdateTime : Timestamp.init() ] as [String : Any]
                queryDocumentSnapshot.reference.rx.updateData(dataSettingProcessingToTrue)
                    .debug("\(queryDocumentSnapshot.documentID): updating to \(dataSettingProcessingToTrue)")
                    .subscribe(
                    onNext: { [weak self] event in
                            
                        self?.startImageDownloading(imageServerPath: imageServerPath, queryDocumentSnapshot: queryDocumentSnapshot, session: session, imageMeta: imageMeta)
                        
                    },
                    onError: { [weak self] error in
                        print(error)
                        assertionFailure()
                        self?.starter.removeObject(forKey: queryDocumentSnapshot.documentID)
                    }).disposed(by: bag)
            })
                
        }).disposed(by: disposeBag)
    }
    
    class func deleteIllFormedMediaRecords(processingQueueDocumentSnapshot: DocumentSnapshot)
    {
        assertionFailure();
        
        // ill formed document, delete
        let batch = Firestore.firestore().batch()
        
        if let imageMeta = processingQueueDocumentSnapshot.get(ProcessingQueue.imageMeta) as? DocumentReference
        {
            batch.deleteDocument(imageMeta)
        }
        
        batch.deleteDocument(processingQueueDocumentSnapshot.reference)
        
        _ = batch.rx.commit().debug("ill formed document, delete \(processingQueueDocumentSnapshot.documentID)")
            .subscribe(
            onError: { error in
                print(error)
                assertionFailure()
            })
    }
    
    func startImageDownloading(imageServerPath: String, queryDocumentSnapshot: QueryDocumentSnapshot, session: DocumentReference, imageMeta: DocumentReference)
    {
        let sessionImageLocalPathString = FileManager.default.applicationSupportDirectory()!.appending("/queueItems/\(queryDocumentSnapshot.documentID)/\((imageServerPath as NSString).lastPathComponent)")
        let sessionImageLocalPath = URL(fileURLWithPath: sessionImageLocalPathString)
        let sessionImageLocalDir = sessionImageLocalPath.deletingLastPathComponent()
        
        try! FileManager.default.createDirectory(at: sessionImageLocalDir, withIntermediateDirectories: true, attributes: nil)
        
        let bag = DisposeBag()
        
        let storage = Storage.storage()
        // TODO: what if it is already downloaded
        storage.reference(withPath: imageServerPath).rx
            .write(toFile: sessionImageLocalPath)
            .debug("downloading \(sessionImageLocalPath)")
            .subscribe(
            onNext: { [weak self] event in
            // call api, get results
                
                DispatchQueue.global().async
                { [weak self] in
                    self?.processDownloadedImage(sessionImageLocalPath: sessionImageLocalPath, session: session, sessionImageLocalDir: sessionImageLocalDir, queryDocumentSnapshot: queryDocumentSnapshot, imageMeta: imageMeta, imageServerPath: imageServerPath)
                }
            },
            onError: { [weak self] error in
                print(error)
                assertionFailure()
                self?.cleanup(sessionImageLocalDir: sessionImageLocalDir, queryDocumentSnapshot: queryDocumentSnapshot)
            }).disposed(by: bag)
        
        // this bag will be removed later...
        self.mediaObservablesRetainingSubscriptionCache.setObject(bag, forKey: queryDocumentSnapshot.documentID)
    }
    
    func processDownloadedImage(sessionImageLocalPath: URL, session: DocumentReference, sessionImageLocalDir: URL, queryDocumentSnapshot: QueryDocumentSnapshot, imageMeta: DocumentReference, imageServerPath: String)
    {
        let db = Firestore.firestore()
        
        // each key is in fact an user id (dont ask me why)
        let results = Model.call(withImage: sessionImageLocalPath, dataSetPath: URL(fileURLWithPath:DatasetPath))
        .map
        { element -> DocumentReference? in
            if element.key != "Unknown"
            {
                return db.document("/users/\(element.key)")
            }
            
            return nil
            
        }.filter { $0 != nil }.map { $0! }
        
        self.performBatchedUpdateOnProcessingDone(queryDocumentSnapshot: queryDocumentSnapshot, imageMeta: imageMeta, session: session, results: results, sessionImageLocalDir: sessionImageLocalDir, imageServerPath: imageServerPath)
    }
    
    func performBatchedUpdateOnProcessingDone(queryDocumentSnapshot: QueryDocumentSnapshot, imageMeta: DocumentReference, session: DocumentReference, results: [DocumentReference], sessionImageLocalDir: URL, imageServerPath: String)
    {
        let batch = Firestore.firestore().batch()
        
        batch.deleteDocument(queryDocumentSnapshot.reference)
        
        // TODO: write participants
        let imageMetaData = [ ResourceRecord.processed : true ]
        batch.updateData(imageMetaData, forDocument: imageMeta)
        
        let sessionData = [ Session.participants : FieldValue.arrayUnion(results) ]
        batch.updateData(sessionData, forDocument: session)
        
        _ = batch.rx.commit().debug("final step for \(queryDocumentSnapshot.documentID), results: \(results)")
            .subscribe(
            onError:
            { error in
                print(error)
                assertionFailure()
                
                let cleanupBatch = Firestore.firestore().batch()
                
                cleanupBatch.deleteDocument(queryDocumentSnapshot.reference)
                cleanupBatch.deleteDocument(imageMeta)
                
                _ = cleanupBatch.rx.commit()
                    .debug("final step for \(queryDocumentSnapshot.documentID), cleanup onError")
                    .subscribe(
                    onError:
                    { error in
                        print(error)
                        assertionFailure()
                    })
                
                let storage = Storage.storage()
                _ = storage.reference(withPath: imageServerPath).rx.delete().debug("final step for \(queryDocumentSnapshot.documentID), cleanup onError, remove \(imageServerPath)").subscribe()
                
            },
            onDisposed: { [weak self] in
                self?.cleanup(sessionImageLocalDir: sessionImageLocalDir, queryDocumentSnapshot: queryDocumentSnapshot)
            })
    }
    
    func cleanup(sessionImageLocalDir: URL, queryDocumentSnapshot: QueryDocumentSnapshot)
    {
        try? FileManager.default.removeItem(at: sessionImageLocalDir)
        self.mediaObservablesRetainingSubscriptionCache.removeObject(forKey: queryDocumentSnapshot.documentID)
        self.starter.removeObject(forKey: queryDocumentSnapshot.documentID)
    }
}
