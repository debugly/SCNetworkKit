//
//  SCNetworkKit.h
//  SCNetworkKit
//
//  Created by 许乾隆 on 2017/5/16.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSDictionary+SCAddtions.h"
#import "NSString+SCAddtions.h"
#import "NSObject+SCCancelRef.h"

#import "SCNetworkService.h"
#import "SCNetworkService+Shared.h"
#import "SCNetworkRequest.h"

#import "SCNResponseParser.h"

/// 可单独使用，或者结合BlockResponseParser做自定义解析
#import "SCNHTTPParser.h"
#import "SCNJSONParser.h"
#import "SCNModelParser.h"
/// 封装好的解析器，可直接使用
#import "SCNJSONResponseParser.h"
#import "SCNModelResponseParser.h"
#import "SCNBlockResponseParser.h"

#import "SCNetworkRequest+Chain.h"
