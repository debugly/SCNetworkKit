//
//  NSDictionary+SCAddtions.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 16/4/26.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "NSDictionary+SCAddtions.h"
#import "NSString+SCAddtions.h"

@implementation NSDictionary(SCAddtions)

- (NSString *)sc_urlEncodedKeyValueString
{
    NSMutableString *string = [NSMutableString string];
    for (NSString *key in self) {
        
        NSObject *value = [self valueForKey:key];
        if([value isKindOfClass:[NSString class]])
            [string appendFormat:@"%@=%@&", [key sc_urlEncodedString], [((NSString*)value) sc_urlEncodedString]];
        else
            [string appendFormat:@"%@=%@&", [key sc_urlEncodedString], value];
    }
    
    if([string length] > 0)
        [string deleteCharactersInRange:NSMakeRange([string length] - 1, 1)];
    
    return string;
}

@end
