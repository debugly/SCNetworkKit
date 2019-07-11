//
//  SCNHTTPParser.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//
//目前对于响应数据的解析,不够优雅，于是单独抽取一个类来做这件事

#import <Foundation/Foundation.h>
#import "SCNResponseParser.h"

@interface SCNHTTPParser : NSObject<SCNResponseParser>

@property (nonatomic, copy, nullable) NSIndexSet *acceptableStatusCodes;
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;

@end
