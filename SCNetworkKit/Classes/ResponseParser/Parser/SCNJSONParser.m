//
//  SCNJSONParser.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNJSONParser.h"
#import "SCNUtil.h"

static id SCNRemoveJSONNullValues(id JSONObject) {
    ///数组
    if ([JSONObject isKindOfClass:[NSArray class]]) {
        
        NSMutableArray *mutableArray = [NSMutableArray array];
        for (id value in (NSArray *)JSONObject) {
            ///先处理下
            id handledValue = SCNRemoveJSONNullValues(value);
            ///处理完毕后，不空就添加
            if (!handledValue || [handledValue isEqual:[NSNull null]]) {
                continue;
            }else{
                [mutableArray addObject:handledValue];
            }
        }
        return  [mutableArray copy];
    }
    ///字典
    else if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:JSONObject];
        for (id <NSCopying> key in [(NSDictionary *)JSONObject allKeys]) {
            
            id value = (NSDictionary *)JSONObject[key];
            
            if (!value || [value isEqual:[NSNull null]]) {
                [mutableDictionary removeObjectForKey:key];
            } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
                id handledValue = SCNRemoveJSONNullValues(value);

                if (!handledValue || [handledValue isEqual:[NSNull null]]) {
                    continue;
                }else{
                    mutableDictionary[key] = handledValue;
                }
            }
        }
        return [mutableDictionary copy];
    }
    
    else if ((!JSONObject || [JSONObject isEqual:[NSNull null]])){
        return nil;
    }
    
    return JSONObject;
}

@implementation SCNJSONParser

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.autoRemovesNullValues = YES;
    }
    return self;
}

- (id)jsonWithData:(NSData *)data
             error:(NSError *__autoreleasing *)error
{
    // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
    // See https://github.com/rails/rails/issues/1742

    ///检查数据是否为空
    BOOL isSpace = [data isEqualToData:[NSData dataWithBytes:" " length:1]];
    
    if (data.length == 0 || isSpace)
    {
        if(error){
            *error = SCNError(NSURLErrorZeroByteResource,@"SCN:数据为空");
        }
        return nil;
    }
    
    ///数据不空，开始解析
    NSError *serializationError = nil;
    
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&serializationError];
    
    if (serializationError) {
        if(error){
            *error = SCNErrorWithOriginErr(serializationError, NSURLErrorCannotParseResponse);
        }
        return nil;
    }
    
    ///正常解析，处理空值
    if (self.autoRemovesNullValues) {
        json = SCNRemoveJSONNullValues(json);
    }
    
    //验证下服务器返回数据
    if (self.checkKeyPath && self.okValue) {
        id v = [json objectForKey:self.checkKeyPath];
        ///兼容服务器不返回check字段的情况
        if (!v){
            v = @"";
        } else {
            v = [v description];
        }
        BOOL isValidate = [v isEqualToString:self.okValue];
        
        ///验证不通过
        if(!isValidate){
            if(error){
                NSMutableDictionary *info = [NSMutableDictionary new];
                [info setObject:@"【解析错误】服务器返回了错误" forKey:@"reason"];
                
                NSInteger code = SCNResponseErrCannotPassValidate;
                
                if ([v respondsToSelector:@selector(intValue)]) {
                    code = [v intValue];//v = @"测试";
                    if(code == 0){
                        code = SCNResponseErrCannotPassValidate;
                    }
                    
                    if(self.errMsgKeyPath){
                        id message = [json objectForKey:self.errMsgKeyPath];
                        if(message){
                            [info setObject:[message description] forKey:NSLocalizedDescriptionKey];
                        }
                    }
                }
                *error = SCNError(code,info);
            }
            return nil;
        }
    }
    
    return json;
}

@end
