//
//  SCNResponseParserProtocolProtocol.h
//  SCNetWorkKit
//
//  Created by xuqianlong on 2017/7/11.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCNResponseParserProtocol <NSObject>

- (id)objectWithResponse:(NSURLResponse *)response
                    data:(NSData *)data
                   error:(NSError * __autoreleasing *)error;

@end
