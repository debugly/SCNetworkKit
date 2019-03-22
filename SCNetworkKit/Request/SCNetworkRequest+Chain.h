//
//  SCNetworkRequest+Chain.h
//  SCNetWorkKit
//
//  Created by xuqianlong on 2016/12/1.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//
/// 支持链式编程

#import "SCNetworkRequest.h"

@interface SCNetworkRequest (Chain)

///设置url
- (SCNetworkRequest *(^)(NSString *url))c_URL;
///追加参数
- (SCNetworkRequest *(^)(NSDictionary *parameters))c_Parameters;
///设置响应解析器
- (SCNetworkRequest *(^)(id<SCNResponseParser> responseParser))c_ResponseParser;
///追加着陆回调
- (SCNetworkRequest *(^)(SCNetWorkHandler handler))c_CompletionHandler;
///追加请求响应回调
- (SCNetworkRequest *(^)(SCNetWorkDidReceiveResponseHandler handler))c_ReceivedResponseHandler;

@end
