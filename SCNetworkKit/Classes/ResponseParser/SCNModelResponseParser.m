//
//  SCNModelResponseParser.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNModelResponseParser.h"
#import "SCNUtil.h"

NSString *const SCNParserErrorKey_ModelName = @"ModelName";

@implementation SCNModelResponseParser

static Class <SCNJSON2ModelProtocol> MParser;

+ (void)registerModelParser:(Class<SCNJSON2ModelProtocol>)parser
{
    MParser = parser;
}

+ (Class<SCNJSON2ModelProtocol>)modelParser
{
    return MParser;
}

- (id)modelWithJson:(id)json error:(NSError *__autoreleasing *)errp
{
    if (self.modelName.length > 0) {
        if (!MParser) {
            NSAssert(NO, @"must call +[SCNModelResponseParser registerModelParser:] befor use.");
        }
        //解析目标JSON
        id model = [MParser JSON2Model:json modelName:self.modelName refObj:self.refObj];
        //model is nil ?
        if(!model){
            //传了errp 指针地址了?
            if(errp){
                NSDictionary *info = @{NSLocalizedDescriptionKey:@"can't convert target json to model",
                                       NSLocalizedFailureReasonErrorKey:@"can't convert target json to model",
                                       SCNParserErrorKey_RawJSON:json,
                                       SCNParserErrorKey_ModelName:self.modelName};
                *errp = SCNError(NSURLErrorCannotParseResponse, info);
            }
        }
        return model;
    } else {
        return json;
    }
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
