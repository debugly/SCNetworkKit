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

FOUNDATION_EXPORT NSString *const SCNErrorDomain;

@interface SCNetworkService : NSObject

///可以指定 SessionConfiguration
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configure;

///开始请求；
- (void)startRequest:(SCNetworkRequest *)request;

@end
