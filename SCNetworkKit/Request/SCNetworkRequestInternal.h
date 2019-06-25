//
//  SCNetworkRequestInternal.h
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNetworkRequest.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif

@interface SCNetworkRequest ()
{
    SCNKRequestState _state;
}

@property(nonatomic) NSMutableDictionary *parameters;
@property(nonatomic) NSMutableDictionary *headers;
@property(nonatomic) NSMutableArray <SCNetWorkHandler>*completionHandlers;
@property(nonatomic) NSMutableArray <SCNetWorkProgressDidChangeHandler>*progressChangedHandlers;
@property(nonatomic) NSMutableArray <SCNetWorkDidReceiveResponseHandler>*responseHandlers;
#if TARGET_OS_IPHONE
@property(nonatomic) UIBackgroundTaskIdentifier backgroundTask;
#endif
@property(nonatomic, readwrite) NSData *respData;
@property(nonatomic, readwrite) NSURLSessionTask *task;
@property(nonatomic, readwrite) NSUInteger taskIdentifier;
@property(nonatomic, readwrite) NSURLResponse *response;
///存储session回调数据的
@property(nonatomic, strong) NSMutableData *mutableData;
@property(nonatomic, copy) void (^customRequestMaker)(const NSMutableURLRequest *);

//更新传输进度
- (void)updateTransferedData:(int64_t)bytes
                  totalBytes:(int64_t)totalBytes
          totalBytesExpected:(int64_t)totalBytesExpected;
//更新 response
- (void)onReceivedResponse:(NSURLResponse *)response;
- (NSMutableURLRequest *)makeURLRequest;
- (void)updateState:(SCNKRequestState)state error:(NSError *)error;

@end

@interface SCNetworkPostRequest()

- (BOOL)isStreamHTTPBody;

@end
