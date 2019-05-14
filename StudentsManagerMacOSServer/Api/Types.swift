//
//  Types.swift
//  StudentsManagerMacOSServer
//
//  Created by Дюмин Алексей on 08/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

// TODO: share with server sources
// class representing data structure under processingQueue collection entity
final class ProcessingQueue
{
    static let imagePath = "imagePath" // String
    static let session = "session" // DocumentReference
    static let imageMeta = "imageMeta" // DocumentReference
    
    static let active = "active" // Bool
    static let lastUpdateTime = "lastUpdateTime" // Timestamp
}
