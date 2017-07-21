//
//  SCNModelParser.m
//  SohuCoreFoundation
//
//  Created by 许乾隆 on 2017/5/19.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SCNModelParser.h"
#import <SCJSONUtil/SCJSONUtil.h>

@implementation SCNModelParser

+ (id)fetchSubJSON:(id)json keyPath:(NSString *)keypath
{
//    return nil;
    return SCFindJSONwithKeyPath(keypath, json);
}

+ (id)JSON2Model:(id)json modelName:(NSString *)mName
{
//    return nil;
    return SCJSON2Model(json, mName);
}

@end
