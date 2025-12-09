//
//  NSString+SCAddtions.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 16/4/26.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "NSString+SCAddtions.h"
#import <CoreFoundation/CFURL.h>

@implementation NSString (SCAddtions)

- (NSString *)sc_urlEncodedString
{
    NSString *encodedString = nil;
    NSString *needPercentCharacters = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| \n\r\t";
    
    if (@available(iOS 9.0,macos 10.11,*)) {
        NSCharacterSet *notAllowedCharacters = [NSCharacterSet characterSetWithCharactersInString:needPercentCharacters];
        NSCharacterSet *allowedCharacters = [notAllowedCharacters invertedSet];
        
        encodedString = [self stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        CFStringRef encodedCFString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                              (__bridge CFStringRef) self,
                                                                              nil,
                                                                              CFSTR("?!@#$^&%*+,:;='\"`<>()[]{}/\\| "),
                                                                              kCFStringEncodingUTF8);
#pragma clang diagnostic pop
        encodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString*) encodedCFString];
    }
    
    if(!encodedString)
        encodedString = @"";
    
    return encodedString;
}

- (NSString *)sc_urlDecodedString
{
    NSString *encodedString = nil;
    
    if (@available(iOS 9.0,macos 10.11,*)) {
        encodedString = [self stringByRemovingPercentEncoding];
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        CFStringRef decodedCFString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef) self,CFSTR(""),kCFStringEncodingUTF8);
        encodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString*) decodedCFString];
#pragma clang diagnostic pop
    }
    
    if(!encodedString)
        encodedString = @"";
    return encodedString;
}

@end
