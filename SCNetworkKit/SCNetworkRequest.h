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
#import "SCNResponseParser.h"

typedef enum : NSUInteger {
    SCNKRequestStateReady,
    SCNKRequestStateStarted,
    SCNKRequestStateCancelled,
    SCNKRequestStateCompleted,
    SCNKRequestStateError,
} SCNKRequestState;

@class SCNetworkRequest;
typedef void(^SCNetWorkHandler)(SCNetworkRequest *request,id result,NSError *err);
typedef void(^SCNKProgressHandler)(SCNetworkRequest *request, int64_t thisTransfered, int64_t totalBytesTransfered, int64_t totalBytesExpected);

///GET 请求
@interface SCNetworkRequest : NSObject<SCCancel>

@property(nonatomic,copy) NSString *urlString;
///default is SCNJSONResponseParser
@property(nonatomic,strong) id<SCNResponseParser>responseParser;
///请求超时时间，默认60s
@property(nonatomic)NSTimeInterval timeoutInterval;
///下载文件路径
@property (nonatomic, copy) NSString *downloadFileTargetPath;

+ (NSString *) SCN_UA;

- (instancetype)initWithURLString:(NSString *)aURL
                           params:(NSDictionary *)params;

//添加参数，如果是POST的form-data请求，则参数会放到表单里！GET请求直接拼接到URL上！
- (void)addParameters:(NSDictionary *)ps;
///当前已经添加的参数；
- (NSDictionary *)ps;
///清理请求参数
- (void)clearPS;

- (void)addHeaders:(NSDictionary *)hs;
///invoked on main thread
- (void)addCompletionHandler:(SCNetWorkHandler)handler;
///invoked on main thread,observer downlaod or upload progress
- (void)addProgressChangedHandler:(SCNKProgressHandler)handler;
- (void)cancel;
- (SCNKRequestState)state;

@end

@interface SCNetworkFormData : NSObject

@property(nonatomic,copy) NSString *mime;//文本类型
@property(nonatomic,copy) NSString *fileName;//文件名
///上传文件的时候，小文件可以使用 attachedData，大文件要使用 fileURL，省得内存暂用过大！
@property(nonatomic,copy) NSString *fileURL;//文件地址
@property(nonatomic,strong) NSData *attachedData;//data数据

@end

typedef enum : NSUInteger {
    SCNKParameterEncodingURL,
    SCNKParameterEncodingJSON,
    SCNKParameterEncodingPlist,
    SCNKParameterEncodingFormData,
} SCNKParameterEncoding;

///POST 请求
@interface SCNetworkPostRequest : SCNetworkRequest

//默认是: application/x-www-form-urlencoded
@property(nonatomic,assign) SCNKParameterEncoding parameterEncoding;
//formData一旦被赋值，则parameterEncoding会强制使用multipart/form-data编码！
@property(nonatomic,strong) SCNetworkFormData *formData;

@end

