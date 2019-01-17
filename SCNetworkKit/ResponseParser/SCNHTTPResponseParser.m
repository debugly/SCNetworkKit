//
//  SCNHTTPResponseParser.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNHTTPResponseParser.h"
#import "SCNHTTPParser.h"

@implementation SCNHTTPResponseParser
{
    SCNHTTPParser *_httpParser;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _httpParser = [SCNHTTPParser new];
    }
    return self;
}

- (id)objectWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    return [_httpParser objectWithResponse:response data:data error:error];
}

- (NSIndexSet *)acceptableStatusCodes
{
    return [_httpParser acceptableStatusCodes];
}

- (void)setAcceptableStatusCodes:(NSIndexSet *)acceptableStatusCodes
{
    _httpParser.acceptableStatusCodes = acceptableStatusCodes;
}

- (NSSet<NSString *> *)acceptableContentTypes
{
    return [_httpParser acceptableContentTypes];
}

- (void)setAcceptableContentTypes:(NSSet<NSString *> *)acceptableContentTypes
{
    _httpParser.acceptableContentTypes = acceptableContentTypes;
}

@end
