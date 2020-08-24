//
//  SCNUtil.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2020/8/18.
//  Copyright © 2020年 sohu-inc. All rights reserved.
//

#ifndef SCNUtil_h
#define SCNUtil_h

#import <Foundation/Foundation.h>

extern NSError * SCNErrorWithOriginErr(NSError *originError,NSInteger newcode);
extern NSError * SCNError(NSInteger code,id info);

#define SCNResponseErrCannotPassValidate -9000
///按照指定的keypath找不到目标json
#define SCNResponseErrCannotFindTargetJson -9001

#define __weakSelf_scn_   typeof(self)weakself = self;
#define __strongSelf_scn_ typeof(weakself)self = weakself;

@interface SCNUtil : NSObject

+ (NSString *)defaultUA;

@end

#endif /* SCNUtil_h */
