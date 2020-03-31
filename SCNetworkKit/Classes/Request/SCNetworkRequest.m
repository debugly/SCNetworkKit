//
//  SCNetworkRequest.m
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNetworkRequest.h"
#import "NSDictionary+SCAddtions.h"
#import "NSString+SCAddtions.h"
#import "SCNetworkRequestInternal.h"
#import "SCNJSONResponseParser.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#endif
#import <sys/sysctl.h>
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
 SCNetworkRequest默认UA格式如下:
 %E6%90%9C%E7%8B%90%E8%A7%86%E9%A2%91/1 SCNDemo/1.0.8 (iPhone; iOS 11.4; Scale/2.00)
 %E6%90%9C%E7%8B%90%E5%BD%B1%E9%9F%B3/1 SCNMacDemo/1.0.8 (MacBookPro11,5; Mac OS X 10.14.5)
 https://stackoverflow.com/questions/36379347/does-nsurlsession-send-user-agent-automatically
 
 不指定时，系统默认的 UA格式如下:
 SCNDemo/1 CFNetwork/901.1 Darwin/18.2.0
 %E6%90%9C%E7%8B%90%E5%BD%B1%E9%9F%B3/17141 CFNetwork/975.0.3 Darwin/18.2.0 (x86_64)
 */
#if TARGET_OS_OSX
+ (NSString *)deviceModel {
    NSString *model = nil;
    
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    
    error = sysctlbyname("hw.model", NULL, &length, NULL, 0);
    if (error == 0) {
        char *cpuModel = (char *)malloc(sizeof(char) * length);
        if (cpuModel != NULL) {
            error = sysctlbyname("hw.model", cpuModel, &length, NULL, 0);
            if (error == 0) {
                model = @(cpuModel);
            }
            free(cpuModel);
        }
    }
    
    return model;
}
#endif

+ (NSString *) defaultUA
{
    static NSString *ua;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
        NSDictionary *localizedInfoDic = [[NSBundle mainBundle] localizedInfoDictionary];
        [infoDic setValuesForKeysWithDictionary:localizedInfoDic];
        
        NSString *bundleName = infoDic[(__bridge NSString *)kCFBundleExecutableKey];
        if (!bundleName) {
            bundleName = infoDic[(__bridge NSString *)kCFBundleIdentifierKey];
        }
        NSString *displayName = infoDic[@"CFBundleDisplayName"];
        if (!displayName) {
            displayName = bundleName;
        }
        ///有可能是中文，必须编码！
        displayName = [displayName sc_urlEncodedString];
        NSString *vk = (__bridge NSString *) kCFBundleVersionKey;
        NSString *buildNum = infoDic[vk];
        NSString *shortVersion = infoDic[@"CFBundleShortVersionString"];
        if (!shortVersion) {
            shortVersion = buildNum;
        }
        
#if TARGET_OS_IPHONE
        ua = [NSString stringWithFormat:@"%@/%@ %@/%@ (%@; iOS %@; Scale/%0.2f)",displayName, buildNum, bundleName, shortVersion, [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
        NSOperatingSystemVersion sysVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
        NSString *osv = [NSString stringWithFormat:@"%ld.%ld.%ld",sysVersion.majorVersion,sysVersion.minorVersion,sysVersion.patchVersion];
        
        ua = [NSString stringWithFormat:@"%@/%@ %@/%@ (%@; Mac OS X %@)", displayName, buildNum, bundleName, shortVersion, [self deviceModel],osv];
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
        self.responseParser = [SCNJSONResponseParser new];
#if TARGET_OS_IPHONE
        self.backgroundTask = UIBackgroundTaskInvalid;
#endif
    }
    return self;
}

- (NSMutableURLRequest *)makeURLRequest:(NSString *)urlString query:(NSDictionary *)query method:(NSString *)method
{
    NSAssert(urlString, @"makeURLRequest:url不能为空");
    NSAssert(method, @"makeURLRequest:method不能为空");
    
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
    
    NSAssert(url, @"makeURLRequest:url不合法");
    
    NSMutableURLRequest *createdRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc]initWithDictionary:self.headers];
    ///没有指定UA时，设置默认的；
    if (![headers objectForKey:@"User-Agent"]) {
        NSString *ua = [SCNetworkRequest defaultUA];
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
    
    ///指定了就设置下；否则走session里配置的时间
    if(self.timeoutInterval > 0){
        createdRequest.timeoutInterval = self.timeoutInterval;
    }
    
    [createdRequest setAllHTTPHeaderFields:headers];
    [createdRequest setHTTPMethod:method];
    
    return createdRequest;
}

- (NSMutableURLRequest* )makeURLRequest
{    
    NSMutableURLRequest *createdRequest = [self makeURLRequest:self.urlString query:self.parameters method:@"GET"];
    
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

- (void)setDownloadFileTargetPath:(NSString *)downloadFileTargetPath
{
    _downloadFileTargetPath = [downloadFileTargetPath copy];
    self.responseParser = nil;
}

- (SCNKRequestState)state
{
    return _state;
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
        
        if(error){
            [self doFinishWithResult:nil error:error];
        }else{
            if (self.responseParser) {
                dispatch_async(SCN_Response_Parser_Queue(), ^{
                    NSError *parserError = nil;
                    id result = [self.responseParser objectWithResponse:self.response data:self.respData error:&parserError];
                    [self doFinishWithResult:result error:parserError];
                });
            }else{
                [self doFinishWithResult:self.respData error:nil];
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

- (void)onReceivedResponse:(NSURLResponse *)response
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.response = response;
        [self.responseHandlers enumerateObjectsUsingBlock:^(SCNetWorkDidReceiveResponseHandler  _Nonnull handler, NSUInteger idx, BOOL * _Nonnull stop) {
            handler(self,response);
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


@implementation SCNetworkDownloadRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.responseParser = nil;
    }
    return self;
}

- (NSFileHandle *)fileHandler
{
    if(!_fileHandler){
        NSParameterAssert(self.downloadFileTargetPath);
        if (![[NSFileManager defaultManager]fileExistsAtPath:self.downloadFileTargetPath]) {
            [[NSFileManager defaultManager] createFileAtPath:self.downloadFileTargetPath contents:nil attributes:NULL];
        }
        _fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:self.downloadFileTargetPath];
        NSParameterAssert(_fileHandler);
        self.offset = [self.fileHandler seekToEndOfFile];
    }
    return _fileHandler;
}

- (NSString *)rangeHeaderField
{
    if (self.fileHandler) {
        return [NSString stringWithFormat:@"bytes=%lld-",self.offset];
    } else {
        NSAssert(NO, @"why?");
        return @"";
    }
}

- (uint64_t)didReceiveData:(NSData *)data
{
    [self.fileHandler writeData:data];
    self.offset += data.length;
    return self.offset;
}

- (void)doFinishWithResult:(id)reslut error:(NSError *)error
{
    [self.fileHandler closeFile];
    self.fileHandler = nil;
    [super doFinishWithResult:reslut error:error];
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

- (NSMutableURLRequest* )makeURLRequest
{
    NSMutableURLRequest *createdRequest = [self makeURLRequest:self.urlString query:self.queryPs method:@"POST"];
    
    if ([self.formFileParts count] > 0) {
        ///强制设置为 FromData ！
        self.parameterEncoding = SCNPostDataEncodingFormData;
    }
    
    {
        NSString *bodyStringFromParameters = nil;
        NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
        
        switch (self.parameterEncoding) {
                
            case SCNPostDataEncodingURL: {
                [createdRequest setValue:
                 [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
                      forHTTPHeaderField:@"Content-Type"];
                bodyStringFromParameters = [self.parameters sc_urlEncodedKeyValueString];
                [createdRequest setHTTPBody:[bodyStringFromParameters dataUsingEncoding:NSUTF8StringEncoding]];
            }
                break;
            case SCNPostDataEncodingJSON: {
                [createdRequest setValue:
                 [NSString stringWithFormat:@"application/json; charset=%@", charset]
                      forHTTPHeaderField:@"Content-Type"];
                bodyStringFromParameters = [self.parameters sc_jsonEncodedKeyValueString];
                [createdRequest setHTTPBody:[bodyStringFromParameters dataUsingEncoding:NSUTF8StringEncoding]];
            }
                break;
            case SCNPostDataEncodingPlist: {
                [createdRequest setValue:
                 [NSString stringWithFormat:@"application/x-plist; charset=%@", charset]
                      forHTTPHeaderField:@"Content-Type"];
                bodyStringFromParameters = [self.parameters sc_plistEncodedKeyValueString];
                [createdRequest setHTTPBody:[bodyStringFromParameters dataUsingEncoding:NSUTF8StringEncoding]];
            }
                break;
            case SCNPostDataEncodingFormData:{
                [self makeFormDataHTTPBodyWithRequest:createdRequest];
            }
                break;
            case SCNPostDataEncodingCustom:{
                
                if (self.customRequestMaker) {
                    self.customRequestMaker(createdRequest);
                }
            }
        }
    }
    //    Accept-Encoding:gzip, deflate
    return createdRequest;
}

- (void)makeCustomRequest:(void (^)(const NSMutableURLRequest *))handler
{
    self.customRequestMaker = handler;
}

@end
