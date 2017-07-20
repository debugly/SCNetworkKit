//
//  SCNHTTPResponseParser.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//
//目前对于响应数据的解析,不够优雅，于是单独抽取一个类来做这件事

#import <Foundation/Foundation.h>

extern NSInteger SCNResponseErrCannotPassValidate;

NS_ASSUME_NONNULL_BEGIN

@protocol SCNHTTPResponseParser <NSObject>

/**
 The response object decoded from the data associated with a specified response.
 
 @param response The response to be processed.
 @param data The response data to be decoded.
 @param error The error that occurred while attempting to decode the response data.
 
 @return The object decoded from the specified response data.
 */
- (nullable id)parseredObjectForResponse:(nullable NSHTTPURLResponse *)response
                           data:(nullable NSData *)data
                          error:(NSError * _Nullable __autoreleasing *)error;

@end

@interface SCNHTTPResponseParser : NSObject<SCNHTTPResponseParser>

@property (nonatomic, copy, nullable) NSIndexSet *acceptableStatusCodes;
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;

+ (instancetype)parser;

@end

NS_ASSUME_NONNULL_END
