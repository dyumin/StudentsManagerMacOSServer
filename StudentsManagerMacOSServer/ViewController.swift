//
//  ViewController.swift
//  StudentsManagerMacOSServer
//
//  Created by Дюмин Алексей on 08/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Cocoa

import RxSwift

import FirebaseCore

import FirebaseFirestore

class ViewController: NSViewController
{
    let disposeBag = DisposeBag()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
//        let lostJobsTimer = Observable<Int>.interval(15, scheduler: MainScheduler.instance)
//        
//        let db = Firestore.firestore()
//        
//        Observable.combineLatest(
//        db.collection("processingQueue").whereField(QueueItem.active, isEqualTo: true).rx.listen(),
//        lostJobsTimer).debug("lostJobs worker").subscribe(onNext:
//        { (querySnapshot, _) in
//            
//            querySnapshot.documents.forEach({ (queryDocumentSnapshot) in
//                
//                
//                if let lastUpdateTime = queryDocumentSnapshot.get(QueueItem.lastUpdateTime) as? Timestamp
//                {
//                    let timePassed = Timestamp.init().seconds - lastUpdateTime.seconds
//                    
//                    if timePassed > 60
//                    {
//                        // it is ok, remove sequences will terminate in finite time
//                        _ = queryDocumentSnapshot.reference.rx.updateData(
//                            [QueueItem.active : false,
//                             QueueItem.lastUpdateTime: Timestamp.init()]
//                            ).debug("\(queryDocumentSnapshot.reference.path): set \(QueueItem.active) to false").subscribe()
//                        
//                    }
//                }
//                else
//                {
//                    queryDocumentSnapshot.reference.updateData([QueueItem.lastUpdateTime : Timestamp.init()], completion:
//                    { error in
//                        guard error == nil else { assertionFailure(); return }
//                    })
//                }
//            })
//            
//        }).disposed(by: disposeBag)
//        
//        let workTimer = Observable<Int>.interval(15, scheduler: MainScheduler.instance)
//        Observable.combineLatest(
//            db.collection("processingQueue").whereField(QueueItem.active, isEqualTo: false).rx.listen(),
//            workTimer).debug("worker").subscribe(onNext:
//                { (querySnapshot, _) in
//                    
//                    querySnapshot.documents.forEach({ (queryDocumentSnapshot) in
//                        
//                        // start job, get result
//                        
//                    })
//                    
//            }).disposed(by: disposeBag)


    }
    
//    private func ModelApiRequestFor(queueItem: DocumentSnapshot) -> Observable<Void>
//    {
//        let workingObservable: Observable<Void> = (Observable.create
//        { [weak self] observer -> Disposable in
//            
//            var serverRequestDisposeBag: DisposeBag?
//            let disposable = Disposables.create(with:
//            {
//                serverRequestDisposeBag = nil // drop server request if exists
//            })
//            
//            self.diskRequestsCount += 1
//            self.persistentCache.loadData(forKey: cachePhotoKey, withCallback:
//                { (persistentCacheResponse) in
//                    
//                    if persistentCacheResponse.result == .operationSucceeded
//                        , let image = UIImage(data: persistentCacheResponse.record.data)
//                    {
//                        // TODO: is a little bit inaccurate count, only data suitable for UIImage creation is counted
//                        self.diskBytesReadCount += Int64(persistentCacheResponse.record.data.count)
//                        
//                        self.mediaCache.setObject(image, forKey: cachePhotoKey)
//                        observer.onNext(image)
//                        observer.onCompleted()
//                    }
//                    else // start server request
//                    {
//                        self.serverRequestsCount += 1
//                        
//                        let serverPhotoPath = Api.serverPhotoPath(for: id)
//                        let reference = Storage.storage().reference(withPath: serverPhotoPath).rx
//                        serverRequestDisposeBag = DisposeBag()
//                        
//                        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
//                        reference.getData(maxSize: 1 * 1024 * 1024).debug("Api.userProfilePhoto: \(serverPhotoPath)")
//                            .subscribe(
//                                onNext: { [weak self] data in
//                                    
//                                    self?.serverBytesReadCount += Int64(data.count)
//                                    
//                                    // TODO add caches synchronisation check?
//                                    guard let image = UIImage(data: data) else
//                                    {
//                                        observer.onError(Errors.DataCorrupted)
//                                        return
//                                    }
//                                    
//                                    observer.onNext(image)
//                                    observer.onCompleted()
//                                    
//                                    self?.mediaCache.setObject(image, forKey: cachePhotoKey)
//                                    self?.persistentCache.store(data, forKey: cachePhotoKey, locked: false, withCallback:
//                                        { (persistentCacheResponse) in
//                                            
//                                            print("Api.persistentCache.store got result: \(persistentCacheResponse.result.rawValue) for \(cachePhotoKey)")
//                                            if persistentCacheResponse.result == .operationError
//                                            {
//                                                print("Api.persistentCache.store error: \(persistentCacheResponse.error)")
//                                            }
//                                            
//                                            assert(persistentCacheResponse.result == .operationSucceeded, "Failed to store server request result")
//                                            
//                                    }, on: DispatchQueue.global())
//                                    
//                                },
//                                onError: { error in
//                                    
//                                    if let error = error as? NSError, let code = error.userInfo["ResponseErrorCode"] as? Int
//                                    {
//                                        if code == 404 // not found on server
//                                        {
//                                            // contextual type
//                                            // let nilImage: UIImage? = nil
//                                            self.mediaCache.setObject(NSNull(), forKey: cachePhotoKey)
//                                        }
//                                    }
//                                    
//                                    if !disposable.isDisposed
//                                    {
//                                        observer.onError(error)
//                                    }
//                            },
//                                onCompleted: {
//                                    if !disposable.isDisposed
//                                    {
//                                        observer.onCompleted()
//                                    }
//                            }
//                            ).disposed(by: serverRequestDisposeBag!)
//                    }
//            }, on: DispatchQueue.global())
//            return disposable
//        }).share(replay: 1) // NOTE: BEWARE!, shared later from mediaObservablesCache until it is complete, think of it as some kind of singleton
//        // Also, .forever SubjectLifetimeScope has some strange behaviour and it seems like generally is not recommended to use
//        // https://github.com/ReactiveX/RxSwift/issues/1615
//        
//        return workingObservable
//    }

    override var representedObject: Any?
    {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

