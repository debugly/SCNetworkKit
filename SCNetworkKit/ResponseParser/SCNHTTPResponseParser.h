//
//  SCNHTTPResponseParser.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//
//之前对于响应数据的解析不够优雅，于是单独抽取一个类来做这件事

#import <Foundation/Foundation.h>
#import "SCNResponseParser.h"

@interface SCNHTTPResponseParser : NSObject<SCNResponseParser>

@property (nonatomic, copy) NSIndexSet *acceptableStatusCodes;
@property (nonatomic, copy) NSSet <NSString *> *acceptableContentTypes;

+ (instancetype)parser;

@end
