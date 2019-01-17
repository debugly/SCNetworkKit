//
//  SCNModelParser.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCNModelParserProtocol.h"

@interface SCNModelParser : NSObject

@property (nonatomic,copy) NSString *modelName;
@property (nonatomic,copy) NSString *modelKeyPath;

+ (void)registerModelParser:(Class<SCNModelParserProtocol>)parser;

- (id)modelWithJson:(id)json
              error:(NSError *__autoreleasing *)error;

@end
