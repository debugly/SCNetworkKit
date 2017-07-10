//
//  NSString+SCAddtions.m
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/26.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "NSString+SCAddtions.h"
@import CoreFoundation;

@implementation NSString (SCAddtions)

- (NSString *)sc_urlEncodedString
{
//    NSCharacterSet *encodeSet = [NSCharacterSet characterSetWithCharactersInString:@"?!@#$^&%*+,:;='\"`<>()[]{}/\\| "];
    
//    NSString *encodedString = [self stringByAddingPercentEncodingWithAllowedCharacters:encodeSet];
    
    CFStringRef encodedCFString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                          (__bridge CFStringRef) self,
                                                                          nil,
                                                                          CFSTR("?!@#$^&%*+,:;='\"`<>()[]{}/\\| "),
                                                                          kCFStringEncodingUTF8);
    
    NSString *encodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString*) encodedCFString];
    
    if(!encodedString)
        encodedString = @"";
    
    return encodedString;
}

- (NSString *)sc_urlDecodedString
{
    CFStringRef decodedCFString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef) self,CFSTR(""),kCFStringEncodingUTF8);
    
    NSString *encodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString*) decodedCFString];
    
//    NSString *encodedString = [self stringByRemovingPercentEncoding];
    if(!encodedString)
        encodedString = @"";
    return encodedString;
}

@end
