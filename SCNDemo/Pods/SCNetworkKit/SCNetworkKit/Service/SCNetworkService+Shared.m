//
//  SCNetworkService+Shared.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2017/2/28.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SCNetworkService+Shared.h"

@implementation SCNetworkService (Shared)

+ (instancetype)sharedService
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

@end
