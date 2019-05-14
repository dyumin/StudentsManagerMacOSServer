//
//  AppDelegate.swift
//  StudentsManagerMacOSServer
//
//  Created by Дюмин Алексей on 08/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Cocoa

import RxSwift

import FirebaseCore

//@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    var worker: QueueWatcher?
    
    let disposeBag = DisposeBag()
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        UsersDataset.sharedUsersDataset.ready.distinctUntilChanged()
            .debug("AppDelegate worker")
            .subscribe(
            onNext: { [weak self] ready in
                
                if ready
                {
                    self?.worker = QueueWatcher()
                }
                else
                {
                    self?.worker = nil
                }
                
            }).disposed(by: disposeBag)
        
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }
}

