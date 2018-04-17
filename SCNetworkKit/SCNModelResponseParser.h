//
//  SCNModelResponseParser.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNJSONResponseParser.h"
#import "SCNModelParserProtocol.h"

extern NSInteger SCNResponseErrCannotFindTargetJson;

@interface SCNModelResponseParser : SCNJSONResponseParser

@property (nonatomic,copy) NSString *modelName;
@property (nonatomic,copy) NSString *modelKeyPath;

+ (void)registerModelParser:(Class<SCNModelParserProtocol>)parser;

@end
