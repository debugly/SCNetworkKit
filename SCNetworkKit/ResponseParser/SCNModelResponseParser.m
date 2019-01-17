//
//  SCNModelResponseParser.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNModelResponseParser.h"
#import "SCNModelParser.h"

@implementation SCNModelResponseParser
{
    SCNModelParser *_modelParser;
}

+ (void)registerModelParser:(Class<SCNModelParserProtocol>)parser
{
    [SCNModelParser registerModelParser:parser];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _modelParser = [SCNModelParser new];
    }
    return self;
}

- (id)objectWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    id json = [super objectWithResponse:response data:data error:error];
    
    if (json) {
        
        id model = [_modelParser modelWithJson:json
                                        error:error];
        if (model) {
            return model;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSString *)modelName
{
    return [_modelParser modelName];
}

- (void)setModelName:(NSString *)modelName
{
    [_modelParser setModelName:modelName];
}

- (NSString *)modelKeyPath
{
    return [_modelParser modelKeyPath];
}

- (void)setModelKeyPath:(NSString *)modelKeyPath
{
    [_modelParser setModelKeyPath:modelKeyPath];
}

- (id)refObj
{
    return [_modelParser modelKeyPath];
}

- (void)setRefObj:(id)refObj
{
    [_modelParser setRefObj:refObj];
}

@end
