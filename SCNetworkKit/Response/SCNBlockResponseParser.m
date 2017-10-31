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

- (void)resetParserBlock:(SCNParserBlock)block
{
    self.parserBlock = block;
}

+ (instancetype)blockParserWithCustomProcess:(SCNParserBlock)block
{
    SCNBlockResponseParser *parser = [SCNBlockResponseParser parser];
    [parser resetParserBlock:block];
    return parser;
}

- (id)parseredObjectForResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error
{
    NSError *err = nil;
    NSData *result = [super parseredObjectForResponse:response data:data error:&err];
    if (result) {
        if (self.parserBlock) {
           return self.parserBlock(result, error);
        }
        return result;
    }else{
        if(error){
            *error = err;
        }
        return nil;
    }
}

@end
