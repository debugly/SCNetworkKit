//
//  SCNModelParser.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNModelParser.h"
#import "SCNHeader.h"

@implementation SCNModelParser

static Class <SCNModelParserProtocol> MParser;

+ (void)registerModelParser:(Class<SCNModelParserProtocol>)parser
{
    MParser = parser;
}

- (id)modelWithJson:(id)json
              error:(NSError *__autoreleasing *)error
{
    if (!json) {
        return nil;
    }
    
    if (!MParser) {
        NSAssert(NO, @"SCNModelResponseParser:使用前必须注册Model解析器！使用 registerModelParser 方法！");
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

@end
