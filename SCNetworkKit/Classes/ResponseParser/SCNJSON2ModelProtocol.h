//
//  SCNJSON2ModelProtocol.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2017/5/19.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCNJSON2ModelProtocol <NSObject>

@required;
+ (id)fetchSubJSON:(id)json keyPath:(NSString *)keypath;
+ (id)JSON2Model:(id)json modelName:(NSString *)mName refObj:(id)refObj;
+ (id)JSON2StringValueJSON:(id)json;

@end
