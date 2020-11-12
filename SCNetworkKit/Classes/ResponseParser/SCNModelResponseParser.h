//
//  SCNModelResponseParser.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNJSONResponseParser.h"
#import "SCNModelParserProtocol.h"

FOUNDATION_EXPORT NSString *const SCNParserErrorKey_ModelName;

@interface SCNModelResponseParser : SCNJSONResponseParser

@property (nonatomic,copy) NSString *modelName;
// for JSONUtil
@property (nonatomic,strong) id refObj;

+ (void)registerModelParser:(Class<SCNModelParserProtocol>)parser;
+ (Class<SCNModelParserProtocol>)modelParser;

@end
