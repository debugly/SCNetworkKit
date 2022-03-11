//
//  SCNHTTPResponseParser.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNHTTPResponseParser.h"
#import "SCNUtil.h"

@implementation SCNHTTPResponseParser

+ (instancetype)parser
{
    return [self new];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return self;
}

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError * __autoreleasing *)error
{
    BOOL responseIsValid = YES;
    NSError *validationError = nil;
    
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        if (self.acceptableContentTypes && ![self.acceptableContentTypes containsObject:[response MIMEType]]) {
            
            NSDictionary *userInfo = @{
                                       @"reason": [NSString stringWithFormat:@"【解析错误】unacceptable content-type: %@", [response MIMEType]],
                                       @"url":[response URL]
                                       };
            
            validationError = SCNError(SCNResponseParserError_ContentTypeInvalidate, userInfo);
            
            responseIsValid = NO;
        }
        
        if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode] && [response URL]) {
            NSDictionary *userInfo = @{
                                       @"statusCode": @(response.statusCode),
                                       @"url":[response URL],
                                       };
            
            validationError = SCNError(SCNResponseParserError_HTTPStatusNotOK, userInfo);
            
            responseIsValid = NO;
        }
    }
    
    if (error && !responseIsValid) {
        *error = validationError;
    }
    
    return responseIsValid;
}

- (id)objectWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if ([self validateResponse:response data:data error:error]) {
        return data;
    }else{
        return nil;
    }
}

@end
