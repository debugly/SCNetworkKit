//
//  SCNJSONResponseParser.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNJSONResponseParser.h"
#import "SCNHTTPParser.h"
#import "SCNJSONParser.h"

@implementation SCNJSONResponseParser
{
    SCNJSONParser *_jsonParser;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _jsonParser = [SCNJSONParser new];
        self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"application/javascript", @"text/json", @"text/javascript",@"text/plain",@"text/html", nil];
    }
    return self;
}

- (id)objectWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    id result = [super objectWithResponse:response data:data error:error];
    
    if (result) {
        
        id json = [_jsonParser jsonWithData:result error:error];
        
        if (json) {
            return json;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

- (BOOL)autoRemovesNullValues
{
    return [_jsonParser autoRemovesNullValues];
}

- (void)setAutoRemovesNullValues:(BOOL)autoRemovesNullValues
{
    _jsonParser.autoRemovesNullValues = autoRemovesNullValues;
}

- (NSString *)checkKeyPath
{
    return [_jsonParser checkKeyPath];
}

- (void)setCheckKeyPath:(NSString *)checkKeyPath
{
    [_jsonParser setCheckKeyPath:checkKeyPath];
}

- (NSString *)okValue
{
    return [_jsonParser okValue];
}

- (void)setOkValue:(NSString *)okValue
{
    [_jsonParser setOkValue:okValue];
}

- (NSString *)errMsgKeyPath
{
    return [_jsonParser errMsgKeyPath];
}

- (void)setErrMsgKeyPath:(NSString *)errMsgKeyPath
{
    [_jsonParser setErrMsgKeyPath:errMsgKeyPath];
}

+ (instancetype)parser
{
    return [self new];
}

@end
