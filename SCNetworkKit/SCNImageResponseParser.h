//
//  SCNImageResponseParser.h
//  SCNetWorkKit
//
//  Created by xuqianlong on 2017/2/9.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SCNHTTPResponseParser.h"
#import <UIKit/UIImage.h>

@protocol SCNImageParserProtocol <NSObject>

@required;
+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale;

@end

///默认支持png 和 jpg；可通过注册的方式扩展！
@interface SCNImageResponseParser : SCNHTTPResponseParser


/**
 注册新的图片解析器和对应的类型

 @param parser 解析器
 @param mime 支持的类型
 */
+ (void)registerParser:(Class<SCNImageParserProtocol>)parser forMime:(NSString *)mime;

@end

