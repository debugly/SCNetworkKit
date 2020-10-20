//
//  SCNHTTPBodyStream.h
//  SCNDemo
//
//  Created by Matt Reach on 2018/3/19.
//  Copyright © 2018年 debuly.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCNetworkFormFilePart;

@interface SCNHTTPBodyStream : NSInputStream

@property (nonatomic, copy, readonly) NSString * boundary;

+ (instancetype)bodyStreamWithParameters:(NSDictionary *)parameters formFileParts:(NSArray <SCNetworkFormFilePart *>*)formFileParts;

- (NSUInteger)contentLength;

@end
