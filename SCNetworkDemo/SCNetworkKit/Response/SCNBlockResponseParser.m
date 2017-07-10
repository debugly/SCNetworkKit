//
//  SCNBlockResponseParser.m
//  SohuCoreFoundation
//
//  Created by xuqianlong on 2017/6/13.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SCNBlockResponseParser.h"

@interface SCNBlockResponseParser ()

@property (nonatomic, copy)SCNParserBlock parserBlock;

@end

@implementation SCNBlockResponseParser

- (void)addParserBlock:(SCNParserBlock)block
{
    self.parserBlock = block;
}

- (id)parseredObjectForResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error
{
    NSData *result = [super parseredObjectForResponse:response data:data error:error];
    if (result) {
        if (self.parserBlock) {
           return self.parserBlock(result, error);
        }
        return result;
    }else{
        return nil;
    }
}

@end
