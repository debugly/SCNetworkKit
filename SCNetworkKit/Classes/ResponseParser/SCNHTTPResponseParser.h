//
//  SCNHTTPResponseParser.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//
//之前对于响应数据的解析不够优雅，于是单独抽取一个类来做这件事

#import <Foundation/Foundation.h>
#import "SCNResponseParserProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCNHTTPResponseParser : NSObject<SCNResponseParserProtocol>

@property (nonatomic, copy, nullable) NSIndexSet *acceptableStatusCodes;
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;

+ (instancetype)parser;

@end

NS_ASSUME_NONNULL_END
