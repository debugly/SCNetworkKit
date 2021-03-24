
//
//  SCNetworkRequest.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 16/4/26.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

//SCNetworkRequest默认UA格式如下，如果需要自定义UA可以在Header里添加 User-Agent 字段
//%E6%90%9C%E7%8B%90%E8%A7%86%E9%A2%91/1 SCNDemo/1.0.8 (iPhone; iOS 11.4; Scale/2.00)
//%E6%90%9C%E7%8B%90%E5%BD%B1%E9%9F%B3/1 SCNMacDemo/1.0.8 (Macintosh; Mac OS X Version 10.14.1 (Build 18B75))

#import "SCNResponseParserProtocol.h"

typedef enum : NSUInteger {
    SCNRequestStateReady,
    SCNRequestStateStarted,
    SCNRequestStateCancelled,
    SCNRequestStateCompleted,
    SCNRequestStateError,
} SCNRequestState;

typedef enum : NSUInteger {
    SCNetworkRequestGetMethod,
    SCNetworkRequestPostMethod
} SCNetworkRequestMethod;

@class SCNetworkBasicRequest;
typedef void(^SCNetWorkHandler)(__kindof SCNetworkBasicRequest *req,id result,NSError *err);
typedef void(^SCNetWorkProgressDidChangeHandler)(__kindof SCNetworkBasicRequest *req, int64_t thisTransfered, int64_t totalBytesTransfered, int64_t totalBytesExpected);
typedef void(^SCNetWorkDidReceiveResponseHandler)(__kindof SCNetworkBasicRequest *req,NSURLResponse *resp);

#pragma mark - 基础请求

API_AVAILABLE(macos(10.10),ios(7.0))

@interface SCNetworkBasicRequest : NSObject

@property (nonatomic, copy) NSString *tag;
///default is SCNJSONResponseParser
@property (nonatomic, strong) id<SCNResponseParserProtocol>responseParser;
///请求超时时间，默认60s
@property (nonatomic) NSTimeInterval timeoutInterval;
///仅当SCNetWorkDidReceiveResponseHandler回调后才能取到值
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
///the request's state
@property (nonatomic, readonly) SCNRequestState state;

@property (nonatomic, strong) NSURLRequest *urlRequest;

///init with a urlRequest
- (instancetype)initWithURLRequest:(NSURLRequest *)aReq NS_DESIGNATED_INITIALIZER;

//---- invoked on main thread,support add multiple times
///when the request finished
- (void)addCompletionHandler:(SCNetWorkHandler)handler;
///invoked on main thread,when downlaod or upload progress did change
- (void)addProgressChangedHandler:(SCNetWorkProgressDidChangeHandler)handler;
///invoked on main thread,when received the response
- (void)addReceivedResponseHandler:(SCNetWorkDidReceiveResponseHandler)handler;
//---- invoked on main thread,support add multiple times

///cancel the request
- (void)cancel;

@end

@interface SCNetworkRequest : SCNetworkBasicRequest

- (instancetype)initWithURLRequest:(NSURLRequest *)aReq NS_UNAVAILABLE;
///该初始化方法传入的参数，会给下面两个属性直接赋值
- (instancetype)initWithURLString:(NSString *)aURL
                           params:(id)params NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) NSString *urlString;
///拼接到URL上的参数
@property (nonatomic, strong) id parameters;
///default is get; when use post can't contain body!
@property (nonatomic, assign) SCNetworkRequestMethod method;

///add HTTP Header
- (void)addHeaders:(NSDictionary *)hs;

@end

///下载文件类
@interface SCNetworkDownloadRequest : SCNetworkRequest

///设置下载文件路径（该操作会把默认responseParser置空）；如果父目录不存在会自动创建
@property (nonatomic, copy) NSString *downloadFileTargetPath;
///使用断点续传，默认不使用 (对于一个没有启用断点续传的任务，然后启用，则从头开始下载！反之亦然！)
@property (nonatomic, assign) BOOL useBreakpointContinuous;

@end

#pragma mark - POST 请求

@interface SCNetworkFormFilePart : NSObject

@property (nonatomic,copy) NSString *mime;//文本类型
@property (nonatomic,copy) NSString *fileName;//上传文件名
@property (nonatomic,copy) NSString *name;//表单的名称，默认为 "file"
///上传文件的时候，小文件可以使用 data，大文件要使用 fileURL，省得内存占用过大！
@property (nonatomic,copy) NSString *fileURL;//文件地址（传了该值时可以不传fileName和mime，内部自动推断）
@property (nonatomic,strong) NSData *data;//二进制数据（必须传fileName和mime，内部不能推断）

@end

typedef enum : NSUInteger {
    SCNPostBodyEncodingURL,
    SCNPostBodyEncodingJSON,
    SCNPostBodyEncodingPlist,
    SCNPostBodyEncodingFormData,
    SCNPostBodyEncodingCustom,
} SCNPostBodyEncoding;

@interface SCNetworkPostRequest : SCNetworkRequest

//默认是: application/x-www-form-urlencoded
@property (nonatomic,assign) SCNPostBodyEncoding bodyEncoding;
/*
 需要通过表单上传的文件使用这个字段；
 支持多文件上传，数组里的每个元素均是一个文件；
 formFileParts 一旦被赋值，则bodyEncoding会强制使用multipart/form-data编码！
 */
@property (nonatomic,strong) NSArray <SCNetworkFormFilePart *>* formFileParts;

/*
 使用 addParameters 方法添加的参数会放到 Body 体里！！
 如果要把参数追加到 URL 上，类似 GET 请求拼接的参数，请用此方法！
*/
- (void)addQueryParameters:(NSDictionary *)ps;

/*
 当 bodyEncoding 为 SCNPostBodyEncodingCustom 时，通过这个回调构造 body 体
 */
- (void)makeCustomRequest:(void(^)(const NSMutableURLRequest* request))handler;

@end

