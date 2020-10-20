//
//  SCNResponseParserProtocolProtocol.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/7/11.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCNResponseParserProtocol <NSObject>

- (id)objectWithResponse:(NSURLResponse *)response
                    data:(NSData *)data
                   error:(NSError * __autoreleasing *)error;

@end
