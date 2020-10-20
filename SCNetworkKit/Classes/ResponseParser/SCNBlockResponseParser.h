//
//  SCNBlockResponseParser.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/6/13.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCNResponseParserProtocol.h"

typedef id(^SCNParserBlock)(NSHTTPURLResponse *response,NSData *data,NSError * __autoreleasing *error);

@interface SCNBlockResponseParser : NSObject<SCNResponseParserProtocol>

- (void)resetParserBlock:(SCNParserBlock)block;

+ (instancetype)blockParserWithCustomProcess:(SCNParserBlock)block;

@end
