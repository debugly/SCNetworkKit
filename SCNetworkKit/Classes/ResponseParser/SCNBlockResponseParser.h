//
//  SCNBlockResponseParser.h
//  SohuCoreFoundation
//
//  Created by xuqianlong on 2017/6/13.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCNResponseParser.h"

typedef id(^SCNParserBlock)(NSHTTPURLResponse *response,NSData *data,NSError * __autoreleasing *error);

@interface SCNBlockResponseParser : NSObject<SCNResponseParser>

- (void)resetParserBlock:(SCNParserBlock)block;

+ (instancetype)blockParserWithCustomProcess:(SCNParserBlock)block;

@end
