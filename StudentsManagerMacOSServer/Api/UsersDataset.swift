//
//  UsersDataset.swift
//  StudentsManagerMacOSServer
//
//  Created by Дюмин Алексей on 10/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import FirebaseFirestore
import FirebaseStorage

import RxFirebaseStorage

let DatasetPath = FileManager.default.applicationSupportDirectory()!.appending("/users/dataset")

private func ServerPhotoPath(for id: String) -> String
{
    return "/users/\(id)/datasetPhotos/\(id).jpg"
}

class UsersDataset: NSObject
{
    let disposeBag = DisposeBag()
    var workers: [String : DisposeBag] = [:]
    
    let ready: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    private static let queueName = "\(UsersDataset.self.className()).workers.queue"
    
    private static var _sharedUsersDataset: UsersDataset? = nil
    
    static var sharedUsersDataset: UsersDataset
    {
        get
        {
            assert(_sharedUsersDataset != nil, "sharedUsersDataset called before configure()")
            return _sharedUsersDataset!
        }
    }
    
    let datasetPath: String
    
    @objc static func configure()
    {
        _sharedUsersDataset = UsersDataset()
    }
    
    private override init()
    {
        datasetPath = DatasetPath
        
        super.init()
        
        if !FileManager.default.fileExists(atPath: datasetPath)
        {
            try! FileManager.default.createDirectory(atPath: datasetPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        let db = Firestore.firestore()
        
        let allUsers = db.collection("users").order(by: ApiUser.displayName, descending: false).rx.listen()
        
        allUsers.debug("datasetStartupChecker").subscribe(
        onNext: { [weak self] event in
            
            event.documents.forEach(
            { [weak self] (queryDocumentSnapshot) in
                
                guard let self = self else { return }
                
                let id = queryDocumentSnapshot.documentID
                
                let localDSetPhotoUrl = URL(fileURLWithPath: self.datasetPath.appending("/\(id).jpg"))
                
                if !FileManager.default.fileExists(atPath: localDSetPhotoUrl.path)
                {
                    self.ready.accept(false)
                    
                    let serverPhotoPath = ServerPhotoPath(for: id)
                    let reference = Storage.storage().reference(withPath: serverPhotoPath).rx
                    let serverRequestDisposeBag = DisposeBag()
                    
                    // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
                    reference.write(toFile: localDSetPhotoUrl).debug(serverPhotoPath).subscribe(
                    onError:
                    { error in
                        if let error = error as? NSError, let code = error.userInfo["ResponseErrorCode"] as? Int
                        {
                            if code != 404 // not found on server
                            {
                                assertionFailure()
                            }
                        }
                    },
                    onDisposed:{ [weak self] in
                        
                        guard let self = self else { return }
                        
                        DispatchQueue(label: UsersDataset.queueName).sync
                        {  
                            self.workers.removeValue(forKey: id)
                            
                            if self.workers.isEmpty
                            {
                                self.ready.accept(true)
                            }
                        }
                        
                    }).disposed(by: serverRequestDisposeBag)
                    
                    DispatchQueue(label: UsersDataset.queueName).sync
                    {
                        self.workers[id] = serverRequestDisposeBag
                    }
                }
            })
            
        }).disposed(by: disposeBag)
    }
}
