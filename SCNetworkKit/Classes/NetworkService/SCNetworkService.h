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

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const SCNetworkKitErrorDomain;

@interface SCNetworkService : NSObject

///可以指定 SessionConfiguration
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configure;

///开始请求；
- (void)startRequest:(__kindof SCNetworkBasicRequest *)request;
///将要发送请求，可以在发送前修改这个 request, 返回 NO 将取消此次请求
- (void)willSendRequest:(BOOL(^)(__kindof SCNetworkBasicRequest *request))block;

@end

NS_ASSUME_NONNULL_END
