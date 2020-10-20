//
//  SCNModelResponseParser.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNModelResponseParser.h"
#import "SCNUtil.h"

@implementation SCNModelResponseParser

static Class <SCNJSON2ModelProtocol> MParser;

+ (void)registerModelParser:(Class<SCNJSON2ModelProtocol>)parser
{
    MParser = parser;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSAssert(MParser, @"befor use SCNModelResponseParser must be call +[SCNModelResponseParser registerModelParser]!");
    }
    return self;
}

- (id)modelWithJson:(id)json error:(NSError *__autoreleasing *)error
{
    if (!json) {
        return nil;
    }
    
    id result = json;
    //查找目标JSON
    if (self.modelKeyPath.length > 0) {
        result = [MParser fetchSubJSON:result keyPath:self.modelKeyPath];
    }
    
    if (result) {
        if (self.modelName.length > 0) {
            //解析目标JSON
            result = [MParser JSON2Model:result modelName:self.modelName refObj:self.refObj];
        }else{
            //不需要解析为Model；
            result = [MParser JSON2StringValueJSON:result];
            //SCJSON2StringJOSN(result);
        }
    }else{
        ///如果传了error指针地址了
        if(error){
            ///result is nil;
            NSDictionary *info = @{@"reason":@"【解析错误】找不到对应的Model",
                                   @"origin":json};
            
            NSInteger code = SCNResponseErrCannotFindTargetJson;
            
            *error = SCNError(code,info);
        }
    }
    return result;
}

- (id)objectWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    id json = [super objectWithResponse:response data:data error:error];
    
    if (json) {
        
        id model = [self modelWithJson:json error:error];
        if (model) {
            return model;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

@end
