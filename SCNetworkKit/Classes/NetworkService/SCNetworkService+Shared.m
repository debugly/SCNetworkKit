//
//  SCNetworkService+Shared.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/2/28.
//  Copyright © 2017年 debugly.cn. All rights reserved.
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
