//
//  SCNModelParserProtocol.h
//  SohuCoreFoundation
//
//  Created by 许乾隆 on 2017/5/19.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCNModelParserProtocol <NSObject>

@required;
///根据指定的 keypath 找到对应的 json。
+ (id)fetchSubJSON:(id)json keyPath:(NSString *)keypath;
///根据指定的 model 名和对应的 josn 自动创建 model对象；
+ (id)JSON2Model:(id)json modelName:(NSString *)mName;

@end
