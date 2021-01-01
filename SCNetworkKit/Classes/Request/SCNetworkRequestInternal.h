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

@interface SCNetworkRequest ()

@property (nonatomic) NSMutableDictionary *headers;
@property (nonatomic) NSMutableArray <SCNetWorkHandler>*completionHandlers;
@property (nonatomic) NSMutableArray <SCNetWorkProgressDidChangeHandler>*progressChangedHandlers;
@property (nonatomic) NSMutableArray <SCNetWorkDidReceiveResponseHandler>*responseHandlers;
#if TARGET_OS_IPHONE
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
#endif
@property (nonatomic, readwrite) SCNKRequestState state;
@property (nonatomic, readwrite) NSURLSessionTask *task;
@property (nonatomic, readwrite) NSUInteger taskIdentifier;
@property (nonatomic, readwrite) NSHTTPURLResponse *response;
///存储dataTask回调的数据，不包括文件下载续传类型
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, copy) void (^customRequestMaker)(const NSMutableURLRequest *);

//更新传输进度
- (void)updateTransferedData:(int64_t)bytes
                  totalBytes:(int64_t)totalBytes
          totalBytesExpected:(int64_t)totalBytesExpected;
//更新 response
- (NSURLSessionResponseDisposition)onReceivedResponse:(NSHTTPURLResponse *)response;
- (NSMutableURLRequest *)makeURLRequest;
- (void)updateState:(SCNKRequestState)state error:(NSError *)error;
- (uint64_t)didReceiveData:(NSData *)data;

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

- (NSString *)rangeHeaderField;
- (uint64_t)didReceiveData:(NSData *)data;

@end

@interface SCNetworkPostRequest()

- (BOOL)isStreamHTTPBody;

@end
