//
//  SCNetworkRequest.h
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//
/*
  Only support iOS 7+;
  USE iOS7 new feature; NSURLSession
*/
#import <Foundation/Foundation.h>
#import "NSObject+SCCancelRef.h"
#import "SCNHTTPResponseParser.h"

typedef enum : NSUInteger {
    SCNKParameterEncodingURL,
    SCNKParameterEncodingJSON,
    SCNKParameterEncodingPlist,
} SCNKParameterEncoding;

typedef enum : NSUInteger {
    SCNKRequestStateReady,
    SCNKRequestStateStarted,
    SCNKRequestStateCancelled,
    SCNKRequestStateCompleted,
    SCNKRequestStateError,
} SCNKRequestState;

@class SCNetworkRequest;
typedef void(^SCNetWorkHandler)(SCNetworkRequest *request,id result,NSError *err);
typedef void(^SCNKProgressHandler)(SCNetworkRequest *request,int64_t transfered,int64_t totalBytes,int64_t totalBytesExpected);

@interface SCNetworkRequest : NSObject<SCCancel>

@property(nonatomic,copy) NSString *urlString;
///default is GET;
@property(nonatomic,copy) NSString *httpMethod;
@property(nonatomic,assign) SCNKParameterEncoding parameterEncoding;
@property(nonatomic,strong) NSData *attachedData;//post的时候指定
///default is SCNJSONResponseParser
@property(nonatomic,strong) id<SCNHTTPResponseParser>responseParser;
///请求超时时间，默认60s
@property(nonatomic)NSTimeInterval timeoutInterval;

- (instancetype)initWithURLString:(NSString *)aURL
                           params:(NSDictionary *)params
                       httpMethod:(NSString *)method;

- (BOOL)isPOSTRequest;

//utils
- (void)addParameters:(NSDictionary *)ps;
///当前已经添加的参数；
- (NSDictionary *)ps;

- (void)addHeaders:(NSDictionary *)hs;
///revoked on main thread
- (void)addCompletionHandler:(SCNetWorkHandler)handler;
///revoked on main thread
- (void)addProgressChangedHandler:(SCNKProgressHandler)handler;
- (void)cancel;
- (SCNKRequestState)state;

@end
