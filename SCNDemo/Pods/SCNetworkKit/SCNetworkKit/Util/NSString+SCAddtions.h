//
//  NSString+SCAddtions.h
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SCAddtions)

- (NSString *)sc_urlEncodedString;
- (NSString *)sc_urlDecodedString;

@end
