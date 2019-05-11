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

- (void)call
{
    NSString* resourcePath = [[NSBundle bundleWithIdentifier:@"com.uuuu.modelAPI"] resourcePath];
    
    std::string rPath = [resourcePath UTF8String];
    
    std::string template_img_path = "/Users/dyumin/Documents/Diploma/template_dataset/";
    std::string img3 = "/Users/dyumin/Documents/Diploma/test_group_images/Syomin_Utkin_Derduga.jpg";
    auto resMap = UUUU::findLabeledFaceRect(img3, template_img_path, rPath);
    for (std::map< std::string, UUUU::Coords >::iterator i = resMap.begin(); i != resMap.end(); i++)
    {
        std::cout << i->first << '\t' << i->second[0] << ' ' << i->second[1] << ' ' << i->second[2] << ' ' <<  i->second[3] << std::endl;
    }
}

@end
