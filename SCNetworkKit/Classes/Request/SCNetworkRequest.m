//
//  SCNetworkRequest.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 16/4/26.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNetworkRequest.h"
#import "SCNetworkRequestInternal.h"
#import "NSDictionary+SCAddtions.h"
#import "SCNJSONResponseParser.h"
#import "SCNHTTPBodyStream.h"
#import "SCNUtil.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#endif

//解析网络请求响应数据的队列
static dispatch_queue_t SCN_Response_Parser_Queue() {
    static dispatch_queue_t scn_response_parser_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char * label = [[[[NSBundle mainBundle]bundleIdentifier] stringByAppendingString:@"-scnetworking.resp.processing"]UTF8String];
        scn_response_parser_queue = dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT);
    });
    return scn_response_parser_queue;
}

@implementation SCNetworkBasicRequest

- (instancetype)initWithURLRequest:(NSURLRequest *)aReq
{
    self = [self init];
    if (self) {
        _urlRequest = aReq;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.responseParser = [SCNJSONResponseParser new];
        self.method = SCNetworkRequestGetMethod;
#if TARGET_OS_IPHONE
        self.backgroundTask = UIBackgroundTaskInvalid;
#endif
    }
    return self;
}

- (NSURLRequest *)urlRequest
{
    return _urlRequest;
}

- (NSString *)description
{
    return [[self.urlRequest URL]description];
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

- (void)addCompletionHandler:(SCNetWorkHandler)handler
{
    if (handler) {
        [self.completionHandlers addObject:handler];
    }
}

- (void)addProgressChangedHandler:(SCNetWorkProgressDidChangeHandler)handler
{
    if (handler) {
        [self.progressChangedHandlers addObject:handler];
    }
}

- (void)addReceivedResponseHandler:(SCNetWorkDidReceiveResponseHandler)handler
{
    if (handler) {
        [self.responseHandlers addObject:handler];
    }
}

- (void)cancel
{
    if (SCNKRequestStateStarted == self.state) {
        [self.task cancel];
        [self updateState:SCNKRequestStateCancelled error:nil];
    }
}

// 更新状态机，请求的开始和结束，都走这里
- (void)updateState:(SCNKRequestState)state error:(NSError *)error
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
        
        if (error) {
            [self doFinishWithResult:nil error:error];
        } else {
            NSData *data = [_mutableData copy];
            if (self.responseParser) {
                dispatch_async(SCN_Response_Parser_Queue(), ^{
                    NSError *parserError = nil;
                    id result = [self.responseParser objectWithResponse:self.response data:data error:&parserError];
                    [self doFinishWithResult:result error:parserError];
                });
            } else {
                [self doFinishWithResult:data error:nil];
            }
        }
    }
    
    else if(SCNKRequestStateCancelled == state){
        //SCNKRequestStateCancelled do nothing
        
    }
    
    else{
        //SCNKRequestStateReady do nothing
    }
}

- (NSURLSessionResponseDisposition)onReceivedResponse:(NSHTTPURLResponse *)response
{
    dispatch_sync_to_main_queue(^{
        self.response = response;
        [self.responseHandlers enumerateObjectsUsingBlock:^(SCNetWorkDidReceiveResponseHandler  _Nonnull handler, NSUInteger idx, BOOL * _Nonnull stop) {
            handler(self,response);
        }];
    });
    
    return NSURLSessionResponseAllow;
}

- (uint64_t)didReceiveData:(NSData *)data
{
    [self.mutableData appendData:data];
    return (uint64_t)[self.mutableData length];
}

- (void)doFinishWithResult:(id)reslut error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.completionHandlers enumerateObjectsUsingBlock:^(_Nonnull SCNetWorkHandler handler, NSUInteger idx, BOOL * _Nonnull stop) {
            handler(self,reslut,error);
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
        [self.progressChangedHandlers enumerateObjectsUsingBlock:^(_Nonnull SCNetWorkProgressDidChangeHandler handler, NSUInteger idx, BOOL *stop) {
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

- (NSMutableArray *)responseHandlers
{
    if(!_responseHandlers)
    {
        _responseHandlers = [NSMutableArray array];
    }
    return _responseHandlers;
}

- (NSMutableData *)mutableData
{
    if (!_mutableData) {
        _mutableData = [NSMutableData data];
    }
    return _mutableData;
}

@end

@implementation SCNetworkRequest

- (instancetype)initWithURLString:(NSString *)aURL
                           params:(id)params
{
    self = [self init];
    if (self) {
        self.urlString = aURL;
        self.parameters = params;
    }
    return self;
}

- (NSMutableURLRequest *)_makeURLRequest:(NSString *)urlString
                                   query:(NSDictionary *)parameters
{
    NSAssert(urlString, @"makeURLRequest:url不能为空");
    NSString *queryStr = [SCNUtil makeUrlEncodeingString:parameters];
    
    if (NSNotFound != [urlString rangeOfString:@"?"].location) {
        NSString *join = @"&";
        if ([urlString hasSuffix:@"&"]) {
            join = @"";
        }
        urlString = [NSString stringWithFormat:@"%@%@%@", urlString,join,queryStr];
    } else {
        urlString = [NSString stringWithFormat:@"%@?%@", urlString,queryStr];
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSAssert(url, @"makeURLRequest:url不合法");
    
    NSMutableURLRequest *createdRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc]initWithDictionary:self.headers];
    //没有指定UA时，设置默认的；
    if (![headers objectForKey:@"User-Agent"]) {
        NSString *ua = [SCNUtil defaultUA];
        [headers setObject:ua forKey:@"User-Agent"];
    }
    
    if (![headers objectForKey:@"Accept-Language"]) {
        NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
        [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            float q = 1.0f - (idx * 0.1f);
            [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
            *stop = q <= 0.5f;
        }];
        [headers setObject:[acceptLanguagesComponents componentsJoinedByString:@", "] forKey:@"Accept-Language"];
    }
    
    //指定了就设置下；否则走session里配置的时间
    if(self.timeoutInterval > 0){
        createdRequest.timeoutInterval = self.timeoutInterval;
    }
    
    [createdRequest setAllHTTPHeaderFields:headers];
    NSString *method = self.method == SCNetworkRequestGetMethod ? @"GET" : @"POST";
    [createdRequest setHTTPMethod:method];
    
    return createdRequest;
}

#pragma mark - override super methods.

- (NSURLRequest *)urlRequest
{
    if (!_urlRequest) {
        _urlRequest = [self _makeURLRequest:self.urlString query:self.parameters];
    }
    return _urlRequest;
}

- (void)addHeaders:(NSDictionary *)hs
{
    if (hs) {
        [self.headers addEntriesFromDictionary:hs];
    }
}

#pragma mark
#pragma mark - lazy getters

- (NSMutableDictionary *)headers
{
    if(!_headers)
    {
        _headers = [NSMutableDictionary dictionary];
    }
    return _headers;
}

@end

#pragma mark - SCNetworkDownloadRequest

@implementation SCNetworkDownloadRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.responseParser = nil;
    }
    return self;
}

- (void)dealloc
{
    [_fileHandler synchronizeFile];
    _fileHandler = nil;
}

- (void)setDownloadFileTargetPath:(NSString *)downloadFileTargetPath
{
    _downloadFileTargetPath = downloadFileTargetPath;
    self.responseParser = nil;
}

- (NSFileHandle *)fileHandler
{
    if(!_fileHandler){
        NSParameterAssert(self.downloadFileTargetPath);
        if (![[NSFileManager defaultManager]fileExistsAtPath:self.downloadFileTargetPath]) {
            NSString *dir = [self.downloadFileTargetPath stringByDeletingLastPathComponent];
            if (dir) {
                [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            [[NSFileManager defaultManager] createFileAtPath:self.downloadFileTargetPath contents:nil attributes:NULL];
        }
        _fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:self.downloadFileTargetPath];
        NSParameterAssert(_fileHandler);
        self.currentOffset = [_fileHandler seekToEndOfFile];
    }
    return _fileHandler;
}

- (NSString *)rangeHeaderField
{
    if (self.fileHandler) {
        //record the offset.
        self.startOffset = self.currentOffset;
        return [NSString stringWithFormat:@"bytes=%lld-",self.currentOffset];
    } else {
        NSAssert(NO, @"why?");
        return nil;
    }
}

#pragma mark - override super methods.

- (NSURLRequest *)urlRequest
{
    if (!_urlRequest) {
        NSMutableURLRequest *createdRequest = [self _makeURLRequest:self.urlString query:self.parameters];
        if (self.useBreakpointContinuous) {
            NSString *rangeField = [self rangeHeaderField];
            if (rangeField) {
                [createdRequest addValue:rangeField forHTTPHeaderField:@"Range"];
            }
        }
        _urlRequest = createdRequest;
    }
    return _urlRequest;
}

- (NSURLSessionResponseDisposition)onReceivedResponse:(NSHTTPURLResponse *)response
{
    NSURLSessionResponseDisposition r = [super onReceivedResponse:response];
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
    if(httpResp.statusCode == 416) {
        NSString *range = [[httpResp allHeaderFields] objectForKey:@"Content-Range"];
        NSArray *items = [range componentsSeparatedByString:@"/"];
        NSString *maxLengthStr = [items lastObject];
        if (maxLengthStr) {
            long maxlenght = (long)[maxLengthStr longLongValue];
            NSString *reqByteRange =  [self.task.originalRequest valueForHTTPHeaderField:@"Range"];
            NSString *reqRange = [[reqByteRange componentsSeparatedByString:@"="] lastObject];
            if (reqRange) {
                NSString *beginStr = [[reqRange componentsSeparatedByString:@"-"] firstObject];
                long begin = (long)[beginStr longLongValue];
                if (maxlenght == begin) {
                    self.recordCode = SCNetworkDownloadRecordAlreadyFinished;
                    return NSURLSessionResponseCancel;
                }
            }
        }
        //
        self.recordCode = SCNetworkDownloadRecordBadRangeRequest;
        return NSURLSessionResponseCancel;
    } else if (httpResp.statusCode >= 200 && httpResp.statusCode < 300) {
        //let dataTask become downloadTask!
        if (!self.useBreakpointContinuous) {
            return NSURLSessionResponseBecomeDownload;
        }
        return r;
    } else {
        //record the special case; cancel the bad response request!
        self.recordCode = SCNetworkDownloadRecordBadResponse;
        return NSURLSessionResponseCancel;
    }
}

- (uint64_t)didReceiveData:(NSData *)data
{
    [self.fileHandler writeData:data];
    self.currentOffset += data.length;
    return self.currentOffset;
}

- (void)doFinishWithResult:(id)reslut error:(NSError *)error
{
    [_fileHandler closeFile];
    _fileHandler = nil;
    //same as super finish.
    [super doFinishWithResult:reslut error:error];
}

@end

@implementation SCNetworkFormFilePart

@end

@interface SCNetworkPostRequest()

@property (nonatomic) NSMutableDictionary *queryPs;

@end

@implementation SCNetworkPostRequest

- (SCNetworkRequestMethod)method
{
    return SCNetworkRequestPostMethod;
}

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
    return SCNPostDataEncodingFormData == self.parameterEncoding;
}

- (void)makeFormDataHTTPBodyWithRequest:(NSMutableURLRequest *)createdRequest
{
    SCNHTTPBodyStream *inputStream = [SCNHTTPBodyStream bodyStreamWithParameters:self.parameters formFileParts:self.formFileParts];
    
    [createdRequest setHTTPBodyStream:inputStream];
    
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    [createdRequest setValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@",charset, inputStream.boundary] forHTTPHeaderField:@"Content-Type"];
    [createdRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[inputStream contentLength]] forHTTPHeaderField:@"Content-Length"];
}

#pragma mark - 覆盖 makeURLRequest 方法

- (NSURLRequest *)urlRequest
{
    if (!_urlRequest) {
        
        if ([self.formFileParts count] > 0) {
            //强制设置为 FromData ！
            self.parameterEncoding = SCNPostDataEncodingFormData;
        }
        
        NSMutableURLRequest *createdRequest = [self _makeURLRequest:self.urlString query:self.queryPs];
        [self makeURLRequestBody:createdRequest];
        _urlRequest = createdRequest;
    }
    return _urlRequest;
}

- (void)makeURLRequestBody:(NSMutableURLRequest*)createdRequest
{
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    switch (self.parameterEncoding) {
            
        case SCNPostDataEncodingURL: {
            [createdRequest setValue:
             [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
                  forHTTPHeaderField:@"Content-Type"];
            NSString *bodyStr = [SCNUtil makeUrlEncodeingString:self.parameters];
            NSData *body = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
            if (body) {
                [createdRequest setHTTPBody:body];
            }
        }
            break;
        case SCNPostDataEncodingJSON: {
            [createdRequest setValue:
             [NSString stringWithFormat:@"application/json; charset=%@", charset]
                  forHTTPHeaderField:@"Content-Type"];
            if (self.parameters) {
                NSError *error = nil;
                NSData *data = [NSJSONSerialization dataWithJSONObject:self.parameters
                                                               options:0 // non-pretty printing
                                                                 error:&error];
                if (error) {
                    NSLog(@"encoding json:%@ failed:%@",self.parameters,error);
                } else {
                    [createdRequest setHTTPBody:data];
                }
            }
        }
            break;
        case SCNPostDataEncodingPlist: {
            [createdRequest setValue:
             [NSString stringWithFormat:@"application/x-plist; charset=%@", charset]
                  forHTTPHeaderField:@"Content-Type"];
            if (self.parameters) {
                NSError *error = nil;
                NSData *data = [NSPropertyListSerialization dataWithPropertyList:self.parameters
                                                                          format:NSPropertyListXMLFormat_v1_0
                                                                         options:0
                                                                           error:&error];
                if (error) {
                    NSLog(@"encoding plist:%@ failed:%@",self.parameters,error);
                } else {
                    [createdRequest setHTTPBody:data];
                }
            }
        }
            break;
        case SCNPostDataEncodingFormData: {
            [self makeFormDataHTTPBodyWithRequest:createdRequest];
        }
            break;
        case SCNPostDataEncodingCustom: {
            if (self.customRequestMaker) {
                self.customRequestMaker(createdRequest);
            }
        }
    }
}

- (void)makeCustomRequest:(void(^)(const NSMutableURLRequest *))handler
{
    self.customRequestMaker = handler;
}

@end
