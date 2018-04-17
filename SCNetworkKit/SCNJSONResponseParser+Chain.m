//
//  SCNJSONResponseParser+Chain.m
//  SCNetWorkKit
//
//  Created by xuqianlong on 2016/12/1.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNJSONResponseParser+Chain.h"

@implementation SCNJSONResponseParser (Chain)

- (SCNJSONResponseParser * (^)(NSString *checkKeyPath))c_CheckKeyPath
{
    return  ^ SCNJSONResponseParser *(NSString *checkKeyPath){
        self.checkKeyPath = checkKeyPath;
        return self;
    };
}

- (SCNJSONResponseParser * (^)(NSString *okValue))c_OkValue
{
    return  ^ SCNJSONResponseParser *(NSString *okValue){
        self.okValue = okValue;
        return self;
    };
}


@end
