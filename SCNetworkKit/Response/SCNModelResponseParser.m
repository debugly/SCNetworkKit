//
//  SCNModelResponseParser.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNModelResponseParser.h"
#import "SCNHeader.h"

NSInteger SCNResponseErrCannotFindTargetJson = -9001; ///按照指定的keypath找不到目标json；

@interface SCNModelResponseParser()

///用于调试，输出原始json
@property (nonatomic,copy) void (^debugWatch)(id json);

@end

@implementation SCNModelResponseParser

static Class <SCNModelParserProtocol> MParser;

+ (void)registerModelParser:(Class<SCNModelParserProtocol>)parser
{
    MParser = parser;
}

- (id)parseredObjectForResponse:(NSHTTPURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (!MParser) {
        NSAssert(NO, @"是不是忘记注册Model解析器了？");
    }
    // 获取解析后的 JSON ；
    id repJOSN = [super parseredObjectForResponse:response data:data error:error];
    
    if (!repJOSN) {
        return nil;
    }
    
    id result = repJOSN;
    
    if (self.debugWatch) {
        self.debugWatch(result);
    }
    
    //查找目标JSON
    if (self.modelKeyPath.length > 0) {
        result = [MParser fetchSubJSON:repJOSN keyPath:self.modelKeyPath];
        //SCFindJSONwithKeyPath(self.modelKeyPath, repJOSN);
    }
    
    if (result) {
        if (self.modelName.length > 0) {
            //解析目标JSON
            result = [MParser JSON2Model:result modelName:self.modelName];
            //SCJSON2Model(result,self.modelName);
        }else{
            //不需要解析为Model；
            result = [MParser JSON2StringValueJSON:result];
            //SCJSON2StringJOSN(result);
        }
    }else{
        ///result is nil;
        NSDictionary *info = @{@"reason":@"SCN:根据keypath不能找到目标json",
                               @"origin":repJOSN};
        
        NSInteger code = SCNResponseErrCannotFindTargetJson;
        
        *error = SCNError(code,info);
    }
    
    return result;
}

- (void)watchJson:(void (^)(id))block
{
    self.debugWatch = block;
}

@end
