//
//  NSDictionary+SCAddtions.h
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SCAddtions)

- (NSString *)sc_urlEncodedKeyValueString;
- (NSString *)sc_jsonEncodedKeyValueString;
- (NSString *)sc_plistEncodedKeyValueString;

@end
