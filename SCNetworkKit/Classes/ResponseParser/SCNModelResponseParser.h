//
//  SCNModelResponseParser.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNJSONResponseParser.h"
#import "SCNJSON2ModelProtocol.h"

@interface SCNModelResponseParser : SCNJSONResponseParser

@property (nonatomic,copy) NSString *modelName;
@property (nonatomic,copy) NSString *modelKeyPath;
// for JSONUtil
@property (nonatomic,strong) id refObj;

+ (void)registerModelParser:(Class<SCNJSON2ModelProtocol>)parser;

@end
