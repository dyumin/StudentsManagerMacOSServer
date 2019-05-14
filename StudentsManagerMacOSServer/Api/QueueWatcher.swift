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
    
    init()
    {
        let lostJobsTimer = Observable<Int>.interval(15, scheduler: MainScheduler.instance)
        
        let db = Firestore.firestore()
        
        Observable.combineLatest(
        db.collection("processingQueue").whereField(ProcessingQueue.active, isEqualTo: true).rx.listen(),
        lostJobsTimer).debug("lostJobs worker").subscribe(onNext:
        { (querySnapshot, _) in
            
            querySnapshot.documents.forEach({ (queryDocumentSnapshot) in
            
                if let lastUpdateTime = queryDocumentSnapshot.get(ProcessingQueue.lastUpdateTime) as? Timestamp
                {
                    let timePassed = Timestamp.init().seconds - lastUpdateTime.seconds
                    
                    // TODO: check mediaObservablesRetainingSubscriptionCache?
                    if timePassed > 60
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
                    
                    queryDocumentSnapshot.reference.rx
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
        Observable.combineLatest(
        db.collection("processingQueue").whereField(ProcessingQueue.active, isEqualTo: false).rx.listen(),
        workTimer).debug("worker").subscribe(onNext:
        { [weak self] (querySnapshot, _) in
            
            guard let self = self else { return }
            
            querySnapshot.documents.forEach({ (queryDocumentSnapshot) in
                
                // already processing, return
                if let imageObservable = self.mediaObservablesRetainingSubscriptionCache.object(forKey: queryDocumentSnapshot.documentID)
                {
                    return
                }
                
                guard let imageServerPath = queryDocumentSnapshot.get(ProcessingQueue.imagePath) as? String else { assertionFailure(); return }
                
                let sessionImageLocalPathString = FileManager.default.applicationSupportDirectory()!.appending(imageServerPath)
                let sessionImageLocalPath = URL(fileURLWithPath: sessionImageLocalPathString)
                let sessionImageLocalDir = sessionImageLocalPath.deletingLastPathComponent()
 
                try! FileManager.default.createDirectory(at: sessionImageLocalDir, withIntermediateDirectories: true, attributes: nil)
                
                let bag = DisposeBag()
                
                let storage = Storage.storage()
                // TODO: what if it is already downloaded
                storage.reference(withPath: imageServerPath).rx
                    .write(toFile: sessionImageLocalPath)
                    .debug("downloading \(sessionImageLocalPath)")
                    .subscribe(onNext: { [weak self] event in
                        // call api, get results
                        
//                        let result = Model.call(withImage: sessionImageLocalPath, dataSetPath: URL(fileURLWithPath:DatasetPath))
//                        
//                        print(result)
                    },
                    onError: { error in
                        print(error)
                        assertionFailure()
                        try! FileManager.default.removeItem(at: sessionImageLocalDir)
                    },
                    onDisposed:
                    {
                        self.mediaObservablesRetainingSubscriptionCache.removeObject(forKey: queryDocumentSnapshot.documentID)
                    }).disposed(by: bag)
                
                self.mediaObservablesRetainingSubscriptionCache.setObject(bag, forKey: queryDocumentSnapshot.documentID)
            })
                
        }).disposed(by: disposeBag)
    }
}
