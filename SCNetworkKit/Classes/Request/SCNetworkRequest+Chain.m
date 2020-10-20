//
//  SCNetworkRequest+Chain.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/12/1.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNetworkRequest+Chain.h"

@implementation SCNetworkRequest (Chain)

- (SCNetworkRequest *(^)(NSString *url))c_URL
{
    return ^ SCNetworkRequest * (NSString *url){
        self.urlString = url;
        return self;
    };
}

- (SCNetworkRequest *(^)(NSDictionary *parameters))c_Parameters
{
    return ^ SCNetworkRequest * (NSDictionary *parameters){
        [self addParameters:parameters];
        return self;
    };
}

- (SCNetworkRequest *(^)(id<SCNResponseParserProtocol> responseParser))c_ResponseParser
{
    return ^ SCNetworkRequest * (id<SCNResponseParserProtocol> responseParser){
        [self setResponseParser:responseParser];
        return self;
    };
}

- (SCNetworkRequest *(^)(SCNetWorkHandler handler))c_CompletionHandler
{
    return ^ SCNetworkRequest * (SCNetWorkHandler handler){
        [self addCompletionHandler:handler];
        return self;
    };
}

- (SCNetworkRequest *(^)(SCNetWorkDidReceiveResponseHandler handler))c_ReceivedResponseHandler
{
    return ^ SCNetworkRequest * (SCNetWorkDidReceiveResponseHandler handler){
        [self addReceivedResponseHandler:handler];
        return self;
    };
}

@end
