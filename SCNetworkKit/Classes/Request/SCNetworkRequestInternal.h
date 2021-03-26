//
//  SCNetworkRequestInternal.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 16/4/26.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNetworkRequest.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif
#import <Foundation/NSURLSession.h>

@interface SCNetworkBasicRequest()
{
@protected
    NSURLRequest *_urlRequest;
    NSDictionary *_allHandlers;
}

- (NSMutableArray <SCNetWorkHandler>*) completionHandlers;
- (NSMutableArray <SCNetWorkDidReceiveResponseHandler>*) responseHandlers;
- (NSMutableArray <SCNetWorkDidReceiveDataHandler>*) dataHandlers;

#if TARGET_OS_IPHONE
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
#endif
@property (atomic, readwrite) SCNRequestState state;
@property (nonatomic, readwrite) NSURLSessionTask *task;
@property (nonatomic, readwrite) NSUInteger taskIdentifier;
@property (nonatomic, readwrite) NSHTTPURLResponse *response;
///存储dataTask回调的数据，不包括文件下载续传类型
@property (nonatomic) NSMutableData *respBuffer;

//更新 response
- (NSURLSessionResponseDisposition)onReceivedResponse:(NSHTTPURLResponse *)response;
- (void)updateState:(SCNRequestState)state error:(NSError *)error;
- (void)didReceiveResponseData:(NSData *)data;

@end

@interface SCNetworkRequest ()

@property (nonatomic) NSMutableDictionary *headers;
@property (nonatomic, copy) void (^customRequestMaker)(const NSMutableURLRequest *);

- (NSMutableURLRequest *)_makeURLRequest:(NSString *)urlString
                                   query:(NSDictionary *)parameters;

@end

typedef NS_ENUM(NSUInteger, SCNetworkDownloadRecordCode) {
    SCNetworkDownloadRecordUnknown,
    SCNetworkDownloadRecordBadResponse,
    SCNetworkDownloadRecordBadRangeRequest,
    SCNetworkDownloadRecordAlreadyFinished,
};

@interface SCNetworkDownloadRequest ()

@property (nonatomic, strong) NSFileHandle *fileHandler;
@property (nonatomic, assign) uint64_t startOffset;
@property (nonatomic, assign) uint64_t currentOffset;
@property (nonatomic, assign) SCNetworkDownloadRecordCode recordCode;

- (NSMutableArray <SCNetWorkProgressDidChangeHandler>*) progressChangedHandlers;
//更新下载进度
- (void)updateDownloadTransfered:(int64_t)bytes
                      totalBytes:(int64_t)totalBytes
              totalBytesExpected:(int64_t)totalBytesExpected;

@end

@interface SCNetworkPostRequest()

- (BOOL)isStreamHTTPBody;
- (NSMutableArray <SCNetWorkProgressDidChangeHandler>*) progressChangedHandlers;
//更新上传进度
- (void)updateUploadTransfered:(int64_t)bytes
                    totalBytes:(int64_t)totalBytes
            totalBytesExpected:(int64_t)totalBytesExpected;

@end
