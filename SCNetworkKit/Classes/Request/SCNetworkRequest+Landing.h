//
//  SCNetworkRequest+Landing.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/11/14.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//
// NSURLSession 的相关回调切入口

#import "SCNetworkRequest.h"

@interface SCNetworkBasicRequest (basic)

- (void)didCompleteWithError:(NSError *)error
                        resp:(NSHTTPURLResponse*)resp;

- (void)didReceiveResponse:(NSURLResponse *)response
         completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler;

- (void)didReceiveData:(NSData *)data;

@end

@interface SCNetworkPostRequest (upload)

- (void)didSendBodyData:(int64_t)bytesSent
         totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;

@end

@interface SCNetworkDownloadRequest (download)

- (void)didFinishDownloadingToURL:(NSURL *)location;

@end
