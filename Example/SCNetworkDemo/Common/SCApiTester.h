//
//  SCApiTester.h
//  SCNetworkDemo
//
//  Created by Matt Reach on 2020/8/24.
//

#import <Foundation/Foundation.h>

#define kUSECharles 0

#if kUSECharles
#define kLocalhost @"http://localhost.charlesproxy.com:3000"
#else
#define kLocalhost @"http://localhost:3000"
#endif

#define kTestJSONApi    @"http://debugly.cn/repository/test.json"
#define kTestJSONApi2   kLocalhost   @"/test"
#define kTestUploadApi  kLocalhost   @"/upload-file"
#define kTestPostApi    kLocalhost   @"/users"

#define kTestDownloadApi kLocalhost  @"/images/node.jpg"
#define kTestDownloadApi2 @"http://debugly.github.io/repository/test.mp4"

#define kTestDownloadApi3 kLocalhost @"/movie/aa.rmvb"
#define kTestDownloadApi4 kLocalhost @"/users/download"


NS_ASSUME_NONNULL_BEGIN
@class TestModel;
@interface SCApiTester : NSObject

+ (void)getRequestWithDataCompletion:(void(^)(NSData *data,NSError *err))completion;
+ (void)getRequestWithJSONCompletion:(void(^)(id json, NSError *err))completion;
+ (void)getRequestWithParams:(NSDictionary *)params completion:(void (^)(id _Nonnull, NSError * _Nonnull))completion;
+ (void)getRequestWithModelCompletion:(void(^)(NSArray <TestModel *>*arr, NSError *err))completion;
+ (void)getFileWithCompletion:(void(^)(NSString *path,NSError *err))completion progress:(void(^)(float p))progress;

+ (void)postNoBodyWithCompletion:(void(^)(id json,NSError *err))completion;
+ (void)postURLEncodeWithCompletion:(void(^)(id json,NSError *err))completion;
+ (void)postJSONWithCompletion:(void(^)(id json,NSError *err))completion;
+ (void)postFormDataWithCompletion:(void(^)(id json,NSError *err))completion;
+ (void)postUploadFileWithCompletion:(void(^)(id json,NSError *err))completion progress:(void(^)(float p))progress;
+ (void)postDownloadFileWithCompletion:(void(^)(NSString *path,NSError *err))completion progress:(void(^)(float p))progress;

@end

NS_ASSUME_NONNULL_END
