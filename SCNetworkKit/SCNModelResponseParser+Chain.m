//
//  SCNModelResponseParser+Chain.m
//  SCNetWorkKit
//
//  Created by xuqianlong on 2016/12/1.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNModelResponseParser+Chain.h"

@implementation SCNModelResponseParser (Chain)

- (SCNModelResponseParser *(^)(NSString *modelName))c_ModelName
{
    return ^ SCNModelResponseParser *(NSString *modelName){
        self.modelName = modelName;
        return self;
    };
}

- (SCNModelResponseParser *(^)(NSString *modelKeyPath))c_ModelKeyPath
{
    return ^ SCNModelResponseParser *(NSString *modelKeyPath){
        self.modelKeyPath = modelKeyPath;
        return self;
    };
}

@end
