//
//  SCNResponseParserProtocolProtocol.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/7/11.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SCNResponseParserError_ContentTypeInvalidate     = -5000,   //类型不支持
    SCNResponseParserError_CheckValueInvalidate      = -5001,   //CheckPath返回值没有
    SCNResponseParserError_IsNotDictionary           = -5002,   //服务端返回数据不是字典
    SCNResponseParserError_EmptyData                 = -5003,   //空数据
    SCNResponseParserError_SerializationFailed       = -5004,   //json解析失败
    SCNResponseParserError_NoTargetData              = -5005,   //没有目标数据
    SCNResponseParserError_ConvertModelFailed        = -5006,   //转model失败
    SCNResponseParserError_HTTPStatusNotOK           = -5007,   //HTTP状态码非 OK
} SCNResponseParserErrorCode;

@protocol SCNResponseParserProtocol <NSObject>

- (id)objectWithResponse:(NSURLResponse *)response
                    data:(NSData *)data
                   error:(NSError * __autoreleasing *)error;

@end
