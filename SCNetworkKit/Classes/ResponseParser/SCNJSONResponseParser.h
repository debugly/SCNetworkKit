//
//  SCNJSONResponseParser.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNHTTPResponseParser.h"

@interface SCNJSONResponseParser : SCNHTTPResponseParser

///default is YES
@property (nonatomic, assign) BOOL autoRemovesNullValues;
@property (nonatomic, copy) NSString *checkKeyPath;
@property (nonatomic, copy) NSString *okValue;
///不ok时的错误信息
@property (nonatomic, copy) NSString *errMsgKeyPath;

+ (instancetype)parser;

@end
