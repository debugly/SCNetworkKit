//
//  NSString+SCAddtions.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 16/4/26.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SCAddtions)

- (NSString *)sc_urlEncodedString;
- (NSString *)sc_urlDecodedString;

@end
