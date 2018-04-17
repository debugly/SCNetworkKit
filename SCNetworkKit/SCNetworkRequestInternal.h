//
//  SCNetworkRequestInternal.h
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNetworkRequest.h"
#import <UIKit/UIApplication.h>

@interface SCNetworkRequest ()
{
    UIBackgroundTaskIdentifier backgroundTask;
}

@property(nonatomic) NSMutableDictionary *parameters;
@property(nonatomic) NSMutableDictionary *headers;
@property(nonatomic) NSMutableArray *completionHandlers;
@property(nonatomic) NSMutableArray *progressChangedHandlers;

@property(nonatomic, readwrite) NSData *respData;
@property(nonatomic, readwrite) SCNKRequestState state;
@property(nonatomic, readwrite) NSURLSessionTask *task;
@property(nonatomic, readwrite) NSUInteger taskIdentifier;
@property(nonatomic, readwrite) NSError *error;
@property(nonatomic, readwrite) NSHTTPURLResponse *response;
///存储session回调数据的
@property(nonatomic, strong) NSMutableData *mutableData;
//更新传输进度
- (void)updateTransferedData:(int64_t)bytes
                  totalBytes:(int64_t)totalBytes
          totalBytesExpected:(int64_t)totalBytesExpected;
- (NSMutableURLRequest *)makeURLRequest;

@end

@interface SCNetworkFormData()

@property(nonatomic,strong) NSDictionary *parameters;//参数键值对

@end

