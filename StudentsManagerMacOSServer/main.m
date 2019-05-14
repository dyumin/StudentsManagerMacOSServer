//
//  main.m
//  StudentsManagerMacOSServer
//
//  Created by Дюмин Алексей on 08/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <FirebaseCore/FirebaseCore.h>

#import <StudentsManagerMacOSServer-Swift.h>

int main(int argc, const char * argv[])
{
    [FIRApp configure];
    [UsersDataset configure];
    
    
    return NSApplicationMain(argc, argv);
}
