//
//  SCNBlockResponseParser.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/6/13.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCNResponseParserProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^SCNParserBlock)(NSHTTPURLResponse *response, NSData * _Nullable data, NSError * __autoreleasing * _Nullable error);

@interface SCNBlockResponseParser : NSObject<SCNResponseParserProtocol>

- (void)resetParserBlock:(SCNParserBlock)block;

+ (instancetype)blockParserWithCustomProcess:(SCNParserBlock)block;

@end

NS_ASSUME_NONNULL_END
