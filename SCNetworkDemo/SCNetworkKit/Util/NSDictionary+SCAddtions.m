//
//  NSDictionary+SCAddtions.m
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
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

- (NSString *)sc_jsonEncodedKeyValueString
{
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self
                                                   options:0 // non-pretty printing
                                                     error:&error];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

-(NSString*)sc_plistEncodedKeyValueString
{
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0 error:&error];
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


@end
