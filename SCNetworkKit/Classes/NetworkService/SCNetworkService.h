//
//  SCNetworkService.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 16/4/26.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

//iOS 9 使用session 的 shouldUseExtendedBackgroundIdleMode，其他版本使用 beginBackgroundTaskWithExpirationHandler

#import <Foundation/Foundation.h>
#import "SCNetworkRequest.h"

FOUNDATION_EXPORT NSString *const SCNetworkKitErrorDomain;

@interface SCNetworkService : NSObject

///可以指定 SessionConfiguration
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configure NS_DESIGNATED_INITIALIZER;

+ (NSURLSessionConfiguration *)defaultSessionConfiguration;

///开始请求；
- (void)startRequest:(__kindof SCNetworkBasicRequest *)request;

@end
