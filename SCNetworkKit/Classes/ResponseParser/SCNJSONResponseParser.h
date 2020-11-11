//
//  SCNJSONResponseParser.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNHTTPResponseParser.h"

//err.userInfo[key], blew is keys.
FOUNDATION_EXPORT NSString *const SCNParserErrorKey_OkValue;
FOUNDATION_EXPORT NSString *const SCNParserErrorKey_CheckKeyPath;
FOUNDATION_EXPORT NSString *const SCNParserErrorKey_RealValue;
FOUNDATION_EXPORT NSString *const SCNParserErrorKey_RawJSON;
FOUNDATION_EXPORT NSString *const SCNParserErrorKey_ErrMsgValue;

@interface SCNJSONResponseParser : SCNHTTPResponseParser

///default is YES
@property (nonatomic, assign) BOOL autoRemovesNullValues;
@property (nonatomic, copy) NSString *checkKeyPath;
@property (nonatomic, copy) NSString *okValue;
@property (nonatomic, copy) NSString *targetKeyPath;
///当checkKeyPath的值不等于okValue时，取errMsgKeyPath值；
@property (nonatomic, copy) NSString *errMsgKeyPath;

@end
