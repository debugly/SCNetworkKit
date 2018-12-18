//
//  SCNetworkRequest.m
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNetworkRequest.h"
#import "NSDictionary+SCAddtions.h"
#import "SCNetworkRequestInternal.h"
#import "SCNJSONResponseParser.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#endif
#import "SCNHTTPBodyStream.h"
#import "SCNHeader.h"

///解析网络请求响应数据的队列
static dispatch_queue_t SCN_Response_Parser_Queue() {
    static dispatch_queue_t scn_response_parser_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char * label = [[[[NSBundle mainBundle]bundleIdentifier] stringByAppendingString:@"-scnetworking.resp.processing"]UTF8String];
        scn_response_parser_queue = dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT);
    });
    return scn_response_parser_queue;
}


@implementation SCNetworkRequest

/*
 发送请求带上默认的UA
 SohuLiveDemo/1.0 (iPhone; iOS 10.2; Scale/2.00)
 */
+ (NSString *) SCN_UA
{
    static NSString *ua;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if TARGET_OS_IPHONE
        NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
        ua = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)",infoDic[(__bridge NSString *)kCFBundleExecutableKey] ?: infoDic[(__bridge NSString *)kCFBundleIdentifierKey], infoDic[@"CFBundleShortVersionString"] ?: infoDic[(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
        ua = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
    });
    return ua;
}

- (NSString *)description
{
    return [[[self makeURLRequest]URL]description];
}

- (void)dealloc
{
    [self cancel];
#if TARGET_OS_IPHONE
    if (@available(iOS 9.0, *)) {} else {
        if (self.backgroundTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        }
    }
#endif
}

- (instancetype)initWithURLString:(NSString *)aURL
                           params:(NSDictionary *)params
{
    self = [self init];
    if (self) {
        self.urlString = aURL;
        if (params) {
            [self.parameters addEntriesFromDictionary:params];
        }
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.responseParser = [SCNJSONResponseParser parser];
#if TARGET_OS_IPHONE
        self.backgroundTask = UIBackgroundTaskInvalid;
#endif
    }
    return self;
}

- (NSURL *)makeURL:(NSString *)urlString query:(NSDictionary *)query
{
    NSURL *url = nil;
    
    if (query.count > 0) {
        if (NSNotFound != [urlString rangeOfString:@"?"].location) {
            NSString *join = @"&";
            if ([urlString hasSuffix:@"&"]) {
                join = @"";
            }
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", urlString,join,[query sc_urlEncodedKeyValueString]]];
        } else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", urlString,[query sc_urlEncodedKeyValueString]]];
        }
    } else {
        url = [NSURL URLWithString:urlString];
    }
    
    return url;
}

- (NSMutableURLRequest* )makeURLRequest
{    
    NSURL *url = [self makeURL:self.urlString query:self.parameters];
    
    if(url == nil) {
        return nil;
    }
    
    NSMutableURLRequest *createdRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc]initWithDictionary:self.headers];
    ///没有指定UA时，设置默认的；
    if (![headers objectForKey:@"User-Agent"]) {
        NSString *ua = [SCNetworkRequest SCN_UA];
        [headers setObject:ua forKey:@"User-Agent"];
    }
    
    [createdRequest setAllHTTPHeaderFields:headers];
    [createdRequest setHTTPMethod:@"GET"];
    
    ///指定了就设置下；否则走session里配置的时间
    if(self.timeoutInterval > 0){
        createdRequest.timeoutInterval = self.timeoutInterval;
    }
    // Accept-Encoding:gzip, deflate
    return createdRequest;
}

- (void)addParameters:(NSDictionary *)ps
{
    if (ps) {
        [self.parameters addEntriesFromDictionary:ps];
    }
}

- (NSDictionary *)ps
{
    return [self.parameters copy];
}

///清理请求参数
- (void)clearPS
{
    if (self.parameters.count > 0) {
        [self.parameters removeAllObjects];
    }
}

- (void)addHeaders:(NSDictionary *)hs
{
    if (hs) {
        [self.headers addEntriesFromDictionary:hs];
    }
}

- (void)addCompletionHandler:(SCNetWorkHandler)handler
{
    if (handler) {
        [self.completionHandlers addObject:handler];
    }
}

- (void)addProgressChangedHandler:(SCNKProgressHandler)handler
{
    if (handler) {
        [self.progressChangedHandlers addObject:handler];
    }
}

- (void)cancel
{
    if (SCNKRequestStateStarted == self.state) {
        [self.task cancel];
        self.state = SCNKRequestStateCancelled;
    }
}

- (void)setState:(SCNKRequestState)state
{
    _state = state;
    
    if (SCNKRequestStateStarted == state) {
        
        [self.task resume];
#if TARGET_OS_IPHONE
        if (@available(iOS 9.0, *)) {} else {
            if (self.backgroundTask == UIBackgroundTaskInvalid) {
                __weakSelf_scn_
                self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strongSelf_scn_
                        if (self.backgroundTask != UIBackgroundTaskInvalid)
                        {
                            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
                            self.backgroundTask = UIBackgroundTaskInvalid;
                            [self cancel];
                        }
                    });
                }];
            }
        }
#endif
    }
    
    else if ((SCNKRequestStateCompleted == state) || (state == SCNKRequestStateError)){
        
        if(self.error){
            [self doFinishWithResult:nil];
        }else{
            if (self.responseParser) {
                dispatch_async(SCN_Response_Parser_Queue(), ^{
                    NSError *parserError = nil;
                    id result = [self.responseParser parseredObjectForResponse:self.response data:self.respData error:&parserError];
                    self.error = parserError;
                    [self doFinishWithResult:result];
                });
            }else{
                [self doFinishWithResult:self.respData];
            }
        }
    }
    
    else{
        //SCNKRequestStateReady do nothing
    }
}

- (void)doFinishWithResult:(id)reslut
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.completionHandlers enumerateObjectsUsingBlock:^(_Nonnull SCNetWorkHandler handler, NSUInteger idx, BOOL * _Nonnull stop) {
            handler(self,reslut,self.error);
        }];
#if TARGET_OS_IPHONE
        if (@available(iOS 9.0, *)) {} else {
            if (self.backgroundTask != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
                self.backgroundTask = UIBackgroundTaskInvalid;
            }
        }
#endif
    });
}
- (void)updateTransferedData:(int64_t)bytes
                  totalBytes:(int64_t)totalBytes
          totalBytesExpected:(int64_t)totalBytesExpected
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressChangedHandlers enumerateObjectsUsingBlock:^(_Nonnull SCNKProgressHandler handler, NSUInteger idx, BOOL *stop) {
            handler(self,bytes,totalBytes,totalBytesExpected);
        }];
    });
}

- (void)setTask:(NSURLSessionTask *)task
{
    if (_task != task) {
        _task = task;
        _taskIdentifier = task.taskIdentifier;
    }
}

#pragma mark 
#pragma mark - lazy getters

- (NSMutableDictionary *)parameters
{
    if(!_parameters)
    {
        _parameters = [NSMutableDictionary dictionary];
    }
    return _parameters;
}

- (NSMutableDictionary *)headers
{
    if(!_headers)
    {
        _headers = [NSMutableDictionary dictionary];
    }
    return _headers;
}

- (NSMutableArray *)completionHandlers
{
    if(!_completionHandlers)
    {
        _completionHandlers = [NSMutableArray array];
    }
    return _completionHandlers;
}

- (NSMutableArray *)progressChangedHandlers
{
    if(!_progressChangedHandlers)
    {
        _progressChangedHandlers = [NSMutableArray array];
    }
    return _progressChangedHandlers;
}

- (NSMutableData *)mutableData
{
    if (!_mutableData) {
        _mutableData = [NSMutableData data];
    }
    return _mutableData;
}

@end

@implementation SCNetworkFormFilePart

@end

@interface SCNetworkPostRequest()

@property(nonatomic) NSMutableDictionary *queryPs;

@end

@implementation SCNetworkPostRequest

- (NSMutableDictionary *)queryPs
{
    if(!_queryPs)
    {
        _queryPs = [NSMutableDictionary dictionary];
    }
    return _queryPs;
}

- (void)addQueryParameters:(NSDictionary *)ps
{
    if (ps) {
        [self.queryPs addEntriesFromDictionary:ps];
    }
}

- (BOOL)isStreamHTTPBody
{
    return SCNKParameterEncodingFormData == self.parameterEncoding;
}

- (void)makeFormDataHTTPBodyWithRequest:(NSMutableURLRequest *)createdRequest
{
    SCNHTTPBodyStream *inputStream = [SCNHTTPBodyStream bodyStreamWithParameters:self.parameters formFileParts:self.formFileParts];
    
    [createdRequest setHTTPBodyStream:inputStream];
    
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    [createdRequest setValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@",charset, SCNBoundary] forHTTPHeaderField:@"Content-Type"];
    [createdRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[inputStream contentLength]] forHTTPHeaderField:@"Content-Length"];
}

- (NSMutableURLRequest* )makeURLRequest
{
    NSURL *url = [self makeURL:self.urlString query:self.queryPs];
    
    NSMutableURLRequest *createdRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc]initWithDictionary:self.headers];
    ///没有指定UA时，设置默认的；
    if (![headers objectForKey:@"User-Agent"]) {
        NSString *ua = [SCNetworkRequest SCN_UA];
        [headers setObject:ua forKey:@"User-Agent"];
    }
    
    [createdRequest setAllHTTPHeaderFields:headers];
    [createdRequest setHTTPMethod:@"POST"];
    
    ///指定了就设置下；否则走session里配置的时间
    if(self.timeoutInterval > 0){
        createdRequest.timeoutInterval = self.timeoutInterval;
    }
    
    if ([self.formFileParts count] > 0) {
        ///强制设置为 FromData ！
        self.parameterEncoding = SCNKParameterEncodingFormData;
    }
    
    {
        NSString *bodyStringFromParameters = nil;
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
        
        switch (self.parameterEncoding) {
                
            case SCNKParameterEncodingURL: {
                [createdRequest setValue:
                 [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
                      forHTTPHeaderField:@"Content-Type"];
                bodyStringFromParameters = [self.parameters sc_urlEncodedKeyValueString];
                [createdRequest setHTTPBody:[bodyStringFromParameters dataUsingEncoding:NSUTF8StringEncoding]];
            }
                break;
            case SCNKParameterEncodingJSON: {
                [createdRequest setValue:
                 [NSString stringWithFormat:@"application/json; charset=%@", charset]
                      forHTTPHeaderField:@"Content-Type"];
                bodyStringFromParameters = [self.parameters sc_jsonEncodedKeyValueString];
                [createdRequest setHTTPBody:[bodyStringFromParameters dataUsingEncoding:NSUTF8StringEncoding]];
            }
                break;
            case SCNKParameterEncodingPlist: {
                [createdRequest setValue:
                 [NSString stringWithFormat:@"application/x-plist; charset=%@", charset]
                      forHTTPHeaderField:@"Content-Type"];
                bodyStringFromParameters = [self.parameters sc_plistEncodedKeyValueString];
                [createdRequest setHTTPBody:[bodyStringFromParameters dataUsingEncoding:NSUTF8StringEncoding]];
            }
                break;
            case SCNKParameterEncodingFormData:{
                [self makeFormDataHTTPBodyWithRequest:createdRequest];
            }
                break;
        }
    }
    //    Accept-Encoding:gzip, deflate
    return createdRequest;
}

@end
