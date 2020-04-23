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
typedef void(^SCNetWorkProgressDidChangeHandler)(SCNetworkRequest *request, int64_t thisTransfered, int64_t totalBytesTransfered, int64_t totalBytesExpected);
typedef void(^SCNetWorkDidReceiveResponseHandler)(SCNetworkRequest *request,NSURLResponse *response);

#pragma mark - GET 请求

@interface SCNetworkRequest : NSObject

@property(nonatomic, copy) NSString *tag;
@property(nonatomic, copy) NSString *urlString;
///default is SCNJSONResponseParser
@property(nonatomic, strong) id<SCNResponseParser>responseParser;
///请求超时时间，默认60s
@property(nonatomic)NSTimeInterval timeoutInterval;
///设置下载文件路径（该操作会把默认responseParser置空）
@property (nonatomic, copy) NSString *downloadFileTargetPath;
///仅当SCNetWorkDidReceiveResponseHandler回调后才能取到值
@property (nonatomic, strong, readonly) NSURLResponse *response;
//SCNetworkRequest默认UA格式如下:
//%E6%90%9C%E7%8B%90%E8%A7%86%E9%A2%91/1 SCNDemo/1.0.8 (iPhone; iOS 11.4; Scale/2.00)
//%E6%90%9C%E7%8B%90%E5%BD%B1%E9%9F%B3/1 SCNMacDemo/1.0.8 (Macintosh; Mac OS X Version 10.14.1 (Build 18B75))
+ (NSString *)defaultUA;

- (instancetype)initWithURLString:(NSString *)aURL
                           params:(NSDictionary *)params;

//添加参数，如果是POST的form-data请求，则参数会放到表单里！GET请求直接拼接到URL上！
- (void)addParameters:(NSDictionary *)ps;
///当前已经添加的参数；
- (NSDictionary *)ps;
///清理请求参数
- (void)clearPS;
///add HTTP Header
- (void)addHeaders:(NSDictionary *)hs;
///invoked on main thread,,on the request finished
- (void)addCompletionHandler:(SCNetWorkHandler)handler;
///invoked on main thread,on downlaod or upload progress changed
- (void)addProgressChangedHandler:(SCNetWorkProgressDidChangeHandler)handler;
///invoked on main thread,on received the response
- (void)addReceivedResponseHandler:(SCNetWorkDidReceiveResponseHandler)handler;
///cancel the request
- (void)cancel;
///the request's state
- (SCNKRequestState)state;

@end

///支持断点续传
@interface SCNetworkDownloadRequest : SCNetworkRequest

@end

#pragma mark - POST 请求

@interface SCNetworkFormFilePart : NSObject

@property(nonatomic,copy) NSString *mime;//文本类型
@property(nonatomic,copy) NSString *fileName;//上传文件名
@property(nonatomic,copy) NSString *name;//表单的名称，默认为 "file"
///上传文件的时候，小文件可以使用 data，大文件要使用 fileURL，省得内存暂用过大！
@property(nonatomic,copy) NSString *fileURL;//文件地址，此时可以不传fileName和mime，内部自动推断
@property(nonatomic,strong) NSData *data;//二进制数据，必须传fileName和mime，内部不能推断

@end

typedef enum : NSUInteger {
    SCNPostDataEncodingURL,
    SCNPostDataEncodingJSON,
    SCNPostDataEncodingPlist,
    SCNPostDataEncodingFormData,
    SCNPostDataEncodingCustom,
} SCNPostDataEncoding;

@interface SCNetworkPostRequest : SCNetworkRequest

//默认是: application/x-www-form-urlencoded
@property(nonatomic,assign) SCNPostDataEncoding parameterEncoding;
/*
 需要通过表单上传的文件使用这个字段；
 支持多文件上传，数组里的每个元素均是一个文件；
 formFileParts 一旦被赋值，则parameterEncoding会强制使用multipart/form-data编码！
 */
@property(nonatomic,strong) NSArray <SCNetworkFormFilePart *>* formFileParts;

/* 添加URL query参数!!该方法会把参数追加到 URL 上，类似 GET 请求的参数拼！
 当使用 parameterEncoding 是 SCNPostDataEncodingFormData 形式编码时,
    (1. 指定 parameterEncoding)
    (2. formFileParts 不空，被强制指定)
 使用 addParameters 方法添加的参数会放到表单里！！
 反之，该方法和 addParameters 功能相同。
*/
- (void)addQueryParameters:(NSDictionary *)ps;

- (void)makeCustomRequest:(void(^)(const NSMutableURLRequest* request))handler;

@end

