//
//  SCNBlockResponseParser.h
//  SohuCoreFoundation
//
//  Created by xuqianlong on 2017/6/13.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SCNHTTPResponseParser.h"

typedef id(^SCNParserBlock)(NSData *data,NSError * __autoreleasing *error);

@interface SCNBlockResponseParser : SCNHTTPResponseParser

- (void)resetParserBlock:(SCNParserBlock)block;

+ (instancetype)blockParserWithCustomProcess:(SCNParserBlock)block;

@end
