//
//  SCNJSONResponseParser+Chain.h
//  SCNetWorkKit
//
//  Created by xuqianlong on 2016/12/1.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNJSONResponseParser.h"

@interface SCNJSONResponseParser (Chain)

- (SCNJSONResponseParser * (^)(NSString *checkKeyPath))c_CheckKeyPath;
- (SCNJSONResponseParser * (^)(NSString *okValue))c_OkValue;

@end
