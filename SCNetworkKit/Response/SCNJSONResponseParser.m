//
//  SCNJSONResponseParser.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNJSONResponseParser.h"
#import "SCNHeader.h"

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


@implementation SCNJSONResponseParser

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"application/javascript", @"text/json", @"text/javascript",@"text/plain",@"text/html", nil];
        self.autoRemovesNullValues = YES;
    }
    return self;
}

- (id)parseredObjectForResponse:(NSHTTPURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    NSError *e = nil;
    NSData *respData = [super parseredObjectForResponse:response data:data error:&e];
    // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
    // See https://github.com/rails/rails/issues/1742
    if (e) {
        if(error){
            *error = e;
        }
        return nil;
    }
    
    ///检查数据是否为空
    BOOL isSpace = [respData isEqualToData:[NSData dataWithBytes:" " length:1]];
    
    if (respData.length == 0 || isSpace)
    {
        if(error){
            *error = SCNError(NSURLErrorZeroByteResource,@"SCN:数据为空");
        }
        return nil;
    }
    
    ///数据不空，开始解析
    NSError *serializationError = nil;
    
    id responseObject = [NSJSONSerialization JSONObjectWithData:respData options:NSJSONReadingMutableContainers error:&serializationError];
    
    if (serializationError) {
        if(error){
            *error = SCNErrorWithOriginErr(serializationError, NSURLErrorCannotParseResponse);
        }
        return nil;
    }
    
    ///正常解析，处理空值
    if (self.autoRemovesNullValues) {
        responseObject = SCNRemoveJSONNullValues(responseObject);
    }
    
    //验证下服务器返回数据
    if (self.checkKeyPath && self.okValue) {
        id v = [responseObject objectForKey:self.checkKeyPath];
        BOOL isValidate = [[v description] isEqualToString:self.okValue];
        
        ///验证不通过
        if(!isValidate){
            if(error){
                NSDictionary *info = @{@"reason":@"SCN:验证错误",
                                       @"result":responseObject?:@"nil"};
                NSInteger code = SCNResponseErrCannotPassValidate;
                
                if ([v respondsToSelector:@selector(intValue)]) {
                    code = [v intValue];//v = @"测试";
                    if(code == 0){
                        code = SCNResponseErrCannotPassValidate;
                    }
                }
                *error = SCNError(code,info);
            }
            return nil;
        }
    }
    
    return responseObject;
}

@end
