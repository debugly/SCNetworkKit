//
//  SCNModelResponseParser+Chain.h
//  SCNetWorkKit
//
//  Created by xuqianlong on 2016/12/1.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNModelResponseParser.h"

@interface SCNModelResponseParser (Chain)

- (SCNModelResponseParser *(^)(NSString *modelName))c_ModelName;
- (SCNModelResponseParser *(^)(NSString *modelKeyPath))c_ModelKeyPath;

@end
