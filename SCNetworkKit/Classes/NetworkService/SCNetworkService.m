//
//  SCNetworkService.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 16/4/26.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

/*
 2016-04-26 19:14:18.852 SOHUVideo[1224:1040470] [CRASH]: Upload tasks from NSData are not supported in background sessions.
 */
#import "SCNetworkService.h"
#import "SCNetworkRequestInternal.h"
#import "SCNetworkRequest+SessionDelegate.h"
#import "SCNUtil.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface SCNetworkService ()<NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate>

@property (nonatomic, strong) dispatch_queue_t taskSynzQueue;
@property (nonatomic, strong) NSMutableDictionary *taskRequestMap;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) BOOL (^willSendRequestBlcok)(__kindof SCNetworkBasicRequest *);

@end

@implementation SCNetworkService

- (instancetype)init
{
    NSURLSessionConfiguration *configure = nil;
    configure = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    if (@available(ios 7.0,macOS 10.10, *)) {
        configure.discretionary = YES;
    }
    configure.networkServiceType = NSURLNetworkServiceTypeDefault;
    //数据请求超时时间
    configure.timeoutIntervalForRequest = 60;
    //资源请求超时时间
    configure.timeoutIntervalForResource = 60;
    //允许移动网络访问
    configure.allowsCellularAccess = YES;
    configure.HTTPCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    configure.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    configure.HTTPShouldSetCookies = YES;
    configure.HTTPShouldUsePipelining = YES;
    //configure.HTTPMaximumConnectionsPerHost = 2; wifi default is 6;
    configure.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    configure.URLCache = nil;
    
    if (@available(iOS 9.0,macOS 10.11,*)) {
        configure.shouldUseExtendedBackgroundIdleMode = YES;
    }
    //清理所有缓存；
    //[[NSURLCache sharedURLCache]removeAllCachedResponses];
    
    self = [self initWithSessionConfiguration:configure];
    return self;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configure
{
    NSAssert(configure, @"URLSessionConfiguration 不能为空！");
    
    self = [super init];
    
    if (self) {
        const char * label = [[[[NSBundle mainBundle]bundleIdentifier] stringByAppendingString:@"-scn"]UTF8String];
        self.taskSynzQueue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
        self.taskRequestMap = [NSMutableDictionary dictionary];
        
        NSOperationQueue *delegateQueue =  [[NSOperationQueue alloc]init];
        NSInteger count = 6;
        if (configure.HTTPMaximumConnectionsPerHost > 0) {
            count = configure.HTTPMaximumConnectionsPerHost * 2;
        }
        
        delegateQueue.maxConcurrentOperationCount = count;
        self.session = [NSURLSession sessionWithConfiguration:configure
                                                     delegate:self
                                                delegateQueue:delegateQueue];
    }
    return self;
}

- (void)willSendRequest:(BOOL (^)(__kindof SCNetworkBasicRequest *))block
{
    self.willSendRequestBlcok = block;
}

- (void)startRequest:(__kindof SCNetworkBasicRequest *)request
{
    if (self.willSendRequestBlcok) {
        BOOL send = self.willSendRequestBlcok(request);
        if (!send) {
            [request cancel];
            return;
        }
    }
    
    NSURLRequest * urlRequest = request.urlRequest;
    if(!request || !urlRequest) {
        NSAssert((request && urlRequest),
                 @"Request is nil, check your URL and other parameters you use to build your request");
        return;
    }
    /*
         __NSCFLocalDataTask
         Completion handler blocks are not supported in background sessions. Use a delegate instead.
         NSURLSessionDataTask *task = [self.defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
         }];
     */
    
    //目前只有post请求，并且使用form-data格式的才走StreamRequest
    if ([urlRequest HTTPBodyStream]) {
        /*
         NSData *formData = [request multipartFormData];
         //在这里设置下内容的长度，这个问题处理的不够优雅，但是提升了性能。。。
         [urlRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long) [formData length]] forHTTPHeaderField:@"Content-Length"];
          request.task = [self.session uploadTaskWithRequest:urlRequest fromData:formData];
         */
        request.task = [self.session uploadTaskWithStreamedRequest:urlRequest];
    } else {
        /*
         SCNetworkDownloadRequest *downloadReq = (SCNetworkDownloadRequest *)request;
         //downloadTask can't handle bad response such as 404.we use dataTask then become downloadTask!
         request.task = [self.session downloadTaskWithRequest:urlRequest];
         */
        request.task = [self.session dataTaskWithRequest:urlRequest];
    }

    [self assignMappingForRequest:request];
    [request updateState:SCNKRequestStateStarted error:nil];
}

- (SCNetworkRequest *)requestForTask:(NSURLSessionTask *)task
{
    __block SCNetworkRequest *request = nil;
    dispatch_sync(self.taskSynzQueue, ^{
        request = [self.taskRequestMap objectForKey:@(task.taskIdentifier)];
    });
    return request;
}

- (void)assignMappingForRequest:(SCNetworkRequest *)request
{
    dispatch_sync(self.taskSynzQueue, ^{
        [self.taskRequestMap setObject:request forKey:@(request.task.taskIdentifier)];
    });
}

- (void)removeRequestMappingForTask:(NSURLSessionTask *)task
{
    dispatch_sync(self.taskSynzQueue, ^{
        [self.taskRequestMap removeObjectForKey:@(task.taskIdentifier)];
    });
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    SCNetworkRequest *request = [self requestForTask:task];
    if (request) {
        [request URLSession:session task:task didCompleteWithError:error];
        [self removeRequestMappingForTask:task];
    }
    [[NSURLCache sharedURLCache]removeCachedResponseForRequest:task.currentRequest];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    SCNetworkRequest *request = [self requestForTask:task];
    if (request) {
        [request URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
//    NSLog(@"[%ld]:%@",(long)[response statusCode],request);
    completionHandler(request);
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    SCNetworkRequest *request = [self requestForTask:dataTask];
    if (request) {
        [request URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    SCNetworkRequest *request = [self requestForTask:dataTask];
    if (request) {
        [request URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    SCNetworkRequest *request = [self requestForTask:dataTask];
    if (request) {
        [self removeRequestMappingForTask:dataTask];
        request.task = downloadTask;
        [self assignMappingForRequest:request];
        [downloadTask resume];
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    SCNetworkRequest *request = [self requestForTask:downloadTask];
    if (request) {
        [request URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    SCNetworkRequest *request = [self requestForTask:downloadTask];
    if (request) {
        [request URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    }
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    //TODO
}

@end
