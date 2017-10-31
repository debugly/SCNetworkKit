//
//  SCNetworkService.m
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

/*
 2016-04-26 19:14:18.852 SOHUVideo[1224:1040470] [CRASH]: Upload tasks from NSData are not supported in background sessions.
 */
#import "SCNetworkService.h"
#import "SCNetWorkSessionDelegate.h"
#import "SCNetworkRequestInternal.h"
#import "SCNHeader.h"
#import <UIKit/UIKit.h>

@interface SCNetworkService ()<NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDownloadDelegate>

@property(nonatomic, strong) dispatch_queue_t taskSynzQueue;
@property(nonatomic, strong) NSMutableDictionary *taskMap;
@property(nonatomic, strong) NSURLSession *session;

@end

@implementation SCNetworkService

- (BOOL)isOSVersonGreaterThanOrEqualNice
{
    static NSUInteger cv = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cv = [[[UIDevice currentDevice]systemVersion]intValue];
    });
    return cv >= 9;
}

- (instancetype)init
{
    NSURLSessionConfiguration *configure = nil;
    configure = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    configure.discretionary = YES;
    configure.networkServiceType = NSURLNetworkServiceTypeDefault;
    configure.timeoutIntervalForRequest = 60;
    configure.timeoutIntervalForResource = 60;
    configure.allowsCellularAccess = YES;
    configure.HTTPCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    configure.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    configure.HTTPShouldSetCookies = YES;
    configure.HTTPShouldUsePipelining = YES;
    configure.HTTPMaximumConnectionsPerHost = 2;
    configure.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    configure.URLCache = nil;
    ///发现每次发送请求，都会被系统存到沙河里，导致沙河持续变大，因此这里清理所有缓存；如果你的工程里使用了 URLCache 请注意！！！
    [[NSURLCache sharedURLCache]removeAllCachedResponses];
    self = [self initWithSessionConfiguration:configure];
    return self;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configure
{
    NSAssert(configure, @"URLSessionConfiguration 不能为空！");
    
    if([self isOSVersonGreaterThanOrEqualNice]){
        configure.shouldUseExtendedBackgroundIdleMode = YES;
    }
    
    self = [super init];
    if (self) {
        self.taskSynzQueue = dispatch_queue_create("com.sohu.live", DISPATCH_QUEUE_SERIAL);
        self.taskMap = [NSMutableDictionary dictionary];
        
        NSOperationQueue *delegateQueue =  [[NSOperationQueue alloc]init];
        delegateQueue.maxConcurrentOperationCount = 3;
        self.session = [NSURLSession sessionWithConfiguration:configure
                                                     delegate:self
                                                delegateQueue:delegateQueue];
    }
    return self;
}

- (void)startRequest:(SCNetworkRequest *)request
{
    NSMutableURLRequest * urlRequest = request.request;
    if(!request || !urlRequest) {
        
        NSAssert((request && urlRequest),
                 @"Request is nil, check your URL and other parameters you use to build your request");
        return;
    }
    //__NSCFLocalDataTask
//    Completion handler blocks are not supported in background sessions. Use a delegate instead.
//    NSURLSessionDataTask *task = [self.defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//    }];
    
    if(request.isPOSTRequest){
        NSData *formData = [request multipartFormData];
        ///在这里设置下内容的长度，这个问题处理的不够优雅，但是提升了性能。。。
        [urlRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long) [formData length]] forHTTPHeaderField:@"Content-Length"];
        request.task = [self.session uploadTaskWithRequest:urlRequest fromData:formData];
    }else{
        request.task = [self.session dataTaskWithRequest:urlRequest];
    }

    [self assignDelegateForRequest:request];
    request.state = SCNKRequestStateStarted;
}

- (void)startRequest:(SCNetworkRequest *)request downloadFileTargetUrl:(NSURL *)targetURL
{
    NSMutableURLRequest * urlRequest = request.request;
    if(!request || !urlRequest || !targetURL) {
        
        NSAssert((request && urlRequest),
                 @"Request is nil, check your URL and other parameters you use to build your request");
        return;
    }
    request.task = [self.session downloadTaskWithRequest:urlRequest];
    SCNetWorkSessionDelegate *delegate = [self assignDelegateForRequest:request];
    delegate.downloadFileTargetUrl = targetURL;
    request.state = SCNKRequestStateStarted;
}

- (SCNetWorkSessionDelegate *)delegateForTask:(NSURLSessionTask *)task
{
    __block SCNetWorkSessionDelegate *delegate = nil;
    dispatch_sync(self.taskSynzQueue, ^{
        delegate = [self.taskMap objectForKey:@(task.taskIdentifier)];
    });
    return delegate;
}

- (SCNetWorkSessionDelegate *)assignDelegateForRequest:(SCNetworkRequest *)request
{
    __block SCNetWorkSessionDelegate *delegate = nil;
    dispatch_sync(self.taskSynzQueue, ^{
        delegate = [[SCNetWorkSessionDelegate alloc]initWithRequest:request];
        [self.taskMap setObject:delegate forKey:@(request.task.taskIdentifier)];
    });
    return delegate;
}

- (void)removeDelegateForTask:(NSURLSessionTask *)task
{
    dispatch_sync(self.taskSynzQueue, ^{
        [self.taskMap removeObjectForKey:@(task.taskIdentifier)];
    });
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    SCNetWorkSessionDelegate *delegate = [self delegateForTask:task];
    if (delegate) {
        [delegate URLSession:session task:task didCompleteWithError:error];
        [self removeDelegateForTask:task];
    }
    [[NSURLCache sharedURLCache]removeCachedResponseForRequest:task.currentRequest];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    SCNetWorkSessionDelegate *delegate = [self delegateForTask:task];
    if (delegate) {
        [delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    SCNetWorkSessionDelegate *delegate = [self delegateForTask:dataTask];
    if (delegate) {
        [delegate URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    SCNetWorkSessionDelegate *delegate = [self delegateForTask:task];
    if (delegate) {
        [delegate URLSession:session task:task needNewBodyStream:completionHandler];
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    SCNetWorkSessionDelegate *delegate = [self delegateForTask:downloadTask];
    if (delegate) {
        [delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    SCNetWorkSessionDelegate *delegate = [self delegateForTask:downloadTask];
    if (delegate) {
        [delegate URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
//    NSLog(@"[%ld]:%@",(long)[response statusCode],request);
    completionHandler(request);
}

NSError * SCNError(NSInteger code,id info)
{
    if(!info){
        info = @"未知错误";
    }
    NSDictionary *infoDic = nil;
    if(![info isKindOfClass:[NSDictionary class]]){
        infoDic = @{NSLocalizedDescriptionKey:info};
    }else{
        infoDic = info;
    }
    return [[NSError alloc] initWithDomain:@"com.sohu.sdk.scn" code:code userInfo:infoDic];
}

NSError * SCNErrorWithOriginErr(NSError *originError,NSInteger newcode)
{
    NSMutableDictionary *mulInfo = [NSMutableDictionary dictionary];
    NSDictionary *originInfo = originError.userInfo;
    if (originInfo) {
        NSString *desc = originInfo[NSLocalizedDescriptionKey];
        if (desc) {
            [mulInfo setObject:desc forKey:@"origin-err"];
        }
        [mulInfo setObject:@(originError.code) forKey:@"origin-errcode"];
    }
    
    return SCNError(newcode, mulInfo);
}

@end
