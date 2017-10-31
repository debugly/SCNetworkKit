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
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>

static NSString * kBoundary = @"0xKhTmLbOuNdArY";

///解析网络请求响应数据的队列
static dispatch_queue_t SCN_Response_Parser_Queue() {
    static dispatch_queue_t scn_response_parser_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scn_response_parser_queue = dispatch_queue_create("com.scnetworking.resp.processing", DISPATCH_QUEUE_CONCURRENT);
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
        
        NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
        
        ua = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)",infoDic[(__bridge NSString *)kCFBundleExecutableKey] ?: infoDic[(__bridge NSString *)kCFBundleIdentifierKey], infoDic[@"CFBundleShortVersionString"] ?: infoDic[(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
    });
    return ua;
}

- (NSString *)description
{
    return [[[self request]URL]description];
}

- (BOOL)isOSVersonLessThanNine
{
    static NSUInteger cv = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cv = [[[UIDevice currentDevice]systemVersion]intValue];
    });
    return cv < 9;
}

- (void)dealloc
{
    [self cancel];
    
    if([self isOSVersonLessThanNine]){
        if (backgroundTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
            backgroundTask = UIBackgroundTaskInvalid;
        }
    }
}

- (instancetype)initWithURLString:(NSString *)aURL
                           params:(NSDictionary *)params
                       httpMethod:(NSString *)method
{
    self = [self init];
    if (self) {
        self.urlString = aURL;
        if (params) {
            [self.parameters addEntriesFromDictionary:params];
        }
        self.httpMethod = method;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.responseParser = [SCNJSONResponseParser parser];
        self.httpMethod = @"GET";
    }
    return self;
}

- (BOOL)isPOSTRequest
{
    return [self.httpMethod.uppercaseString isEqualToString:@"POST"];
}

- (NSMutableURLRequest* )request
{    
    NSURL *url = nil;
    BOOL isPOSTRequest = [self isPOSTRequest];
    if (!isPOSTRequest && (self.parameters.count > 0)) {
        if (NSNotFound != [self.urlString rangeOfString:@"?"].location) {
            NSString *join = @"&";
            if ([self.urlString hasSuffix:@"&"]) {
                join = @"";
            }
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", self.urlString,join,[self.parameters sc_urlEncodedKeyValueString]]];
        }else{
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", self.urlString,[self.parameters sc_urlEncodedKeyValueString]]];
        }
    } else {
        url = [NSURL URLWithString:self.urlString];
    }
    
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
    [createdRequest setHTTPMethod:self.httpMethod];
    
    ///指定了就设置下；否则走session里配置的时间
    if(self.timeoutInterval > 0){
        createdRequest.timeoutInterval = self.timeoutInterval;
    }
    
    if (isPOSTRequest) {
        if (self.attachedData.length > 0) {
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            
            [createdRequest setValue:
             [NSString stringWithFormat:
              @"multipart/form-data; charset=%@; boundary=%@",
              charset, kBoundary]
                  forHTTPHeaderField:@"Content-Type"];
            
            // HEAVY OPERATION! 推迟到发送请求时添加，从而减少 multipartFormData 的创建次数；
            //[createdRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long) [[self multipartFormData] length]] forHTTPHeaderField:@"Content-Length"];

        }else{
            NSString *bodyStringFromParameters = nil;
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            
            switch (self.parameterEncoding) {
                    
                case SCNKParameterEncodingURL: {
                    [createdRequest setValue:
                     [NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
                          forHTTPHeaderField:@"Content-Type"];
                    bodyStringFromParameters = [self.parameters sc_urlEncodedKeyValueString];
                }
                    break;
                case SCNKParameterEncodingJSON: {
                    [createdRequest setValue:
                     [NSString stringWithFormat:@"application/json; charset=%@", charset]
                          forHTTPHeaderField:@"Content-Type"];
                    bodyStringFromParameters = [self.parameters sc_jsonEncodedKeyValueString];
                }
                    break;
                case SCNKParameterEncodingPlist: {
                    [createdRequest setValue:
                     [NSString stringWithFormat:@"application/x-plist; charset=%@", charset]
                          forHTTPHeaderField:@"Content-Type"];
                    bodyStringFromParameters = [self.parameters sc_plistEncodedKeyValueString];
                }
            }
            [createdRequest setHTTPBody:[bodyStringFromParameters dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    //    Accept-Encoding:gzip, deflate
    return createdRequest;
}

- (NSData* )multipartFormData {
    
    if(self.attachedData.length == 0) {
        return nil;
    }
    
    NSMutableData *formData = [NSMutableData data];
    
    [self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSString *formattedKV = [NSString stringWithFormat:
                                     @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
                                     kBoundary, key, obj];
        
        [formData appendData:[formattedKV dataUsingEncoding:NSUTF8StringEncoding]];
        [formData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    NSString *formattedFile = [NSString stringWithFormat:
                                 @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n",
                                 kBoundary,
                                 @"file",
                                 @"avator.png",
                                 @"mimetype"];
    
    [formData appendData:[formattedFile dataUsingEncoding:NSUTF8StringEncoding]];
    [formData appendData:self.attachedData];
    [formData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [formData appendData: [[NSString stringWithFormat:@"--%@--\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return formData;
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
        
        if([self isOSVersonLessThanNine]){
            if (!backgroundTask || backgroundTask == UIBackgroundTaskInvalid) {
                backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (backgroundTask != UIBackgroundTaskInvalid)
                        {
                            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
                            backgroundTask = UIBackgroundTaskInvalid;
                            [self cancel];
                        }
                    });
                }];
            }
        }
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
        
        if([self isOSVersonLessThanNine]){
            if (backgroundTask != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            }
        }
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

@end
