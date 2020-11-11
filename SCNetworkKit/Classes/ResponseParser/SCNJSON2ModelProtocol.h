//
//  SCNJSON2ModelProtocol.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/5/19.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCNJSON2ModelProtocol <NSObject>

@required;
+ (id)JSON2Model:(id)json modelName:(NSString *)mName refObj:(id)refObj;

@end
