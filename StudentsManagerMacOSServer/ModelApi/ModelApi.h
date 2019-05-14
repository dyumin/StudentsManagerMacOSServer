//
//  ModelApi.h
//  StudentsManagerMacOSServer
//
//  Created by Дюмин Алексей on 11/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ModelApi : NSObject

- (NSDictionary<NSString*, NSString*>*)callWithImage:(NSURL*)path dataSetPath:(NSURL*)dataSetPath;

@end

NS_ASSUME_NONNULL_END
