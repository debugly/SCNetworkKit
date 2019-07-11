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
    SCNBlockResponseParser *parser = [SCNBlockResponseParser new];
    [parser resetParserBlock:block];
    return parser;
}

- (id)objectWithResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *__autoreleasing  _Nullable *)error
{
    if (self.parserBlock) {
        return self.parserBlock(response,data, error);
    }
    NSAssert(NO, @"SCNBlockResponseParser:没有定义解析过程");
    return nil;
}

@end
