//
//  SCNHTTPBodyStream.h
//  SCNDemo
//
//  Created by 许乾隆 on 2018/3/19.
//  Copyright © 2018年 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const SCNBoundary;

@class SCNetworkFormFilePart;

@interface SCNHTTPBodyStream : NSInputStream

+ (instancetype)bodyStreamWithParameters:(NSDictionary *)parameters formFileParts:(NSArray <SCNetworkFormFilePart *>*)formFileParts;

- (NSUInteger)contentLength;

@end
