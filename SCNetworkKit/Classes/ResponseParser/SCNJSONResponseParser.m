//
//  SCNJSONResponseParser.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNJSONResponseParser.h"
#import "SCNUtil.h"

NSString *const SCNParserErrorKey_OkValue = @"OkValue";
NSString *const SCNParserErrorKey_CheckKeyPath = @"CheckKeyPath";
NSString *const SCNParserErrorKey_RealValue = @"RealValue";
NSString *const SCNParserErrorKey_RawJSON = @"RawJSON";
NSString *const SCNParserErrorKey_ErrMsgValue = @"ErrMsgValue";

@implementation SCNJSONResponseParser

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.autoRemovesNullValues = YES;
        self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"application/javascript",@"text/json",@"text/javascript",@"text/plain",@"text/html", nil];
    }
    return self;
}

- (id)removeJSONNullValues:(id)jsonObject
{
    //数组
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        
        NSMutableArray *mutableArray = [NSMutableArray array];
        for (id value in (NSArray *)jsonObject) {
            //先处理下
            id handledValue = [self removeJSONNullValues:value];
            //处理完毕后，不空就添加
            if (!handledValue || [handledValue isEqual:[NSNull null]]) {
                continue;
            }else{
                [mutableArray addObject:handledValue];
            }
        }
        return  [mutableArray copy];
    }
    //字典
    else if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonObject];
        for (id <NSCopying> key in [(NSDictionary *)jsonObject allKeys]) {
            
            id value = (NSDictionary *)jsonObject[key];
            
            if (!value || [value isEqual:[NSNull null]]) {
                [mutableDictionary removeObjectForKey:key];
            } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
                id handledValue = [self removeJSONNullValues:value];;
                if (!handledValue || [handledValue isEqual:[NSNull null]]) {
                    continue;
                }else{
                    mutableDictionary[key] = handledValue;
                }
            }
        }
        return [mutableDictionary copy];
    }
    
    else if ((!jsonObject || [jsonObject isEqual:[NSNull null]])){
        return nil;
    }
    
    return jsonObject;
}

- (id)findSubJSON:(NSDictionary *)json keyPath:(NSString *)keyPath
{
    if (!keyPath || keyPath.length == 0) {
        return json;
    }
    NSArray *pathArr = [keyPath componentsSeparatedByString:@"/"];
    return [self findSubJSON:json keyPathArr:pathArr];
}

- (id)findSubJSON:(NSDictionary *)json keyPathArr:(NSArray *)pathArr
{
    if (!json) {
        return nil;
    }
    if (!pathArr || pathArr.count == 0) {
        return json;
    }
    NSMutableArray *pathArr2 = [NSMutableArray arrayWithArray:pathArr];
    
    while ([pathArr2 firstObject] && [[pathArr2 firstObject] description].length == 0) {
        [pathArr2 removeObjectAtIndex:0];
    }
    if ([pathArr2 firstObject]) {
        json = [json objectForKey:[pathArr2 firstObject]];
        [pathArr2 removeObjectAtIndex:0];
        return [self findSubJSON:json keyPathArr:pathArr2];
    }else{
        return json;
    }
}

- (id)parser:(NSData *)data error:(NSError *__autoreleasing *)error
{
    // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
    // See https://github.com/rails/rails/issues/1742

    //检查数据是否为空
    BOOL isSpace = [data isEqualToData:[NSData dataWithBytes:" " length:1]];
    
    if (data.length == 0 || isSpace)
    {
        if(error){
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"zero data"};
            *error = SCNError(SCNResponseParserError_EmptyData, userInfo);
        }
        return nil;
    }
    
    //数据不空，开始解析
    NSError *serializationError = nil;
    
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&serializationError];
    
    if (serializationError) {
        if(error){
            NSDictionary *userInfo = serializationError.userInfo;
            if (!userInfo) {
                userInfo = @{NSLocalizedDescriptionKey : @"parser data to json failed."};
            }
            *error = SCNError(SCNResponseParserError_SerializationFailed,userInfo);
        }
        return nil;
    }
    
    //正常解析，处理空值
    if (self.autoRemovesNullValues) {
        json = [self removeJSONNullValues:json];
    }
    
    //验证下服务器返回数据
    if (self.checkKeyPath && self.okValue) {
        if ([json isKindOfClass:[NSDictionary class]]) {
            id v = [self findSubJSON:json keyPath:self.checkKeyPath];
            BOOL isValidate = [[v description] isEqualToString:self.okValue];
            //验证不通过
            if(!isValidate){
                if(error){
                    NSMutableDictionary *info = [NSMutableDictionary new];
                    [info setObject:[self.checkKeyPath stringByAppendingString:@" can't pass verify."] forKey:NSLocalizedDescriptionKey];
                    [info setObject:@"check value is not equal to the okValue." forKey:NSLocalizedFailureReasonErrorKey];
                    [info setObject:self.checkKeyPath forKey:SCNParserErrorKey_CheckKeyPath];
                    [info setObject:self.okValue forKey:SCNParserErrorKey_OkValue];
                    [info setObject:v?v:[NSNull null] forKey:SCNParserErrorKey_RealValue];
                    [info setObject:json forKey:SCNParserErrorKey_RawJSON];
                    
                    if(self.errMsgKeyPath){
                        id message = [json objectForKey:self.errMsgKeyPath];
                        if(message){
                            [info setObject:message forKey:SCNParserErrorKey_ErrMsgValue];
                        }
                    }
                    NSInteger code = NSNotFound;
                    //use checkKeyPath value as error code;
                    if ([v respondsToSelector:@selector(intValue)]) {
                        code = [v intValue];
                    }
                    if (code == NSNotFound) {
                        code = SCNResponseParserError_CheckValueInvalidate;
                    }
                    *error = SCNError(code,info);
                }
                return nil;
            }
        } else {
            if (error) {
                NSMutableDictionary *info = [NSMutableDictionary new];
                NSString *msg = [NSString stringWithFormat:@"can't find checkKeyPath:[%@]",self.checkKeyPath];
                [info setObject:msg forKey:NSLocalizedDescriptionKey];
                [info setObject:msg forKey:NSLocalizedFailureReasonErrorKey];
                [info setObject:self.checkKeyPath forKey:SCNParserErrorKey_CheckKeyPath];
                [info setObject:self.okValue forKey:SCNParserErrorKey_OkValue];
                [info setObject:json forKey:SCNParserErrorKey_RawJSON];
                *error = SCNError(SCNResponseParserError_IsNotDictionary,info);
            }
            return nil;
        }
    }
    
    //查找目标json
    if (self.targetKeyPath.length > 0) {
        json = [self findSubJSON:json keyPath:self.targetKeyPath];
    }
    
    if(!json){
        if (error && ! *error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"can't find target json"};
            *error = SCNError(SCNResponseParserError_NoTargetData, userInfo);
        }
    }
    
    return json;
}

- (id)objectWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    id result = [super objectWithResponse:response data:data error:error];
    
    if (result) {
        
        id json = [self parser:result error:error];
        
        if (json) {
            return json;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

@end
