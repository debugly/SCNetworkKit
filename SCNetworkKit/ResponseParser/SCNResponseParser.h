//
//  SCNResponseParser.h
//  SohuCoreFoundation
//
//  Created by xuqianlong on 2017/7/11.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCNResponseParser <NSObject>

- (nullable id)objectWithResponse:(nullable NSURLResponse *)response
                             data:(nullable NSData *)data
                            error:(NSError * _Nullable __autoreleasing *_Nullable)error;

@end
