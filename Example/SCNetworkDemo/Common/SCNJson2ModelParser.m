//
//  SCNJson2ModelParser.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/5/19.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import "SCNJson2ModelParser.h"
#import <SCJSONUtil/SCJSONUtil.h>

@implementation SCNJson2ModelParser

+ (id)JSON2Model:(id)json modelName:(NSString *)mName refObj:(id)refObj
{
    return SCJSON2ModelV2(json, mName,refObj);
}

@end
