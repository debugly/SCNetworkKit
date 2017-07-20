//
//  SCNetworkService.h
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//
//网络请求服务层；
//Not Support SSL
//Not Support Download file

//iOS 9 使用session 的 shouldUseExtendedBackgroundIdleMode，其他版本使用 beginBackgroundTaskWithExpirationHandler

#import <Foundation/Foundation.h>
#import "SCNetworkRequest.h"

@interface SCNetworkService : NSObject

///默认请求头
@property (nonatomic, strong) NSDictionary *defaultHeaders;

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configure;

///开始请求；
- (void) startRequest:(SCNetworkRequest *)request;

///开始下载请求，并指定文件路径；
- (void)startRequest:(SCNetworkRequest *)request downloadFileTargetUrl:(NSURL *)targetURL;

@end
