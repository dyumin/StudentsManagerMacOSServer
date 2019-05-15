//
//  ModelApi.m
//  StudentsManagerMacOSServer
//
//  Created by Дюмин Алексей on 11/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

#import "ModelApi.h"

#include <modelAPI/vgg-face-api.h>
#include <iostream>

@implementation ModelApi

static const std::string resourcePathStd = [[[NSBundle bundleWithIdentifier:@"com.uuuu.modelAPI"] resourcePath] UTF8String];

- (NSDictionary<NSString*, NSString*>*)callWithImage:(NSURL*)path dataSetPath:(NSURL*)dataSetPath;
{
    const std::string pathStd = std::string(path.path.UTF8String);
    const std::string dataSetPathStd = std::string(dataSetPath.path.UTF8String);
    
    const auto results = UUUU::findLabeledFaceRect(pathStd, dataSetPathStd, resourcePathStd);
    
    NSMutableDictionary<NSString*, NSString*>* resultObjc = [NSMutableDictionary new];
    
    for (const auto& result: results.first)
    {
        NSString* userId = [NSString stringWithUTF8String:result.first.c_str()];
        resultObjc[userId] = @"";
    }
    
    return resultObjc;
}

@end
