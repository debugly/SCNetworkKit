//
//  SCNHTTPBodyStream.h
//  SCNDemo
//
//  Created by 许乾隆 on 2018/3/19.
//  Copyright © 2018年 xuqianlong. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const SCNBoundary;

@class SCNetworkFormData;

@interface SCNHTTPBodyStream : NSInputStream

+ (instancetype)bodyStreamWithFormData:(SCNetworkFormData *)formData;

- (NSUInteger)contentLength;

@end
