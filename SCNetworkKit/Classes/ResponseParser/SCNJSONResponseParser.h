//
//  SCNJSONResponseParser.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2016/11/25.
//  Copyright © 2016年 debugly.cn. All rights reserved.
//

#import "SCNHTTPResponseParser.h"

@interface SCNJSONResponseParser : SCNHTTPResponseParser

///default is YES
@property (nonatomic, assign) BOOL autoRemovesNullValues;
@property (nonatomic, copy) NSString *checkKeyPath;
@property (nonatomic, copy) NSString *okValue;
///不ok时的错误信息
@property (nonatomic, copy) NSString *errMsgKeyPath;

@end
