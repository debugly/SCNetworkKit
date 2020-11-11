//
//  SCNUtil.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2020/8/18.
//  Copyright © 2020年 debugly.cn. All rights reserved.
//

#ifndef SCNUtil_h
#define SCNUtil_h

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const SCNErrorDomain;
FOUNDATION_EXPORT NSError * SCNError(NSInteger code,id info);

#define SCNResponseErrCannotPassValidate -9000
///按照指定的keypath找不到目标json
#define SCNResponseErrCannotFindTargetJson -9001

#define __weakSelf_scn_   typeof(self)weakself = self;
#define __strongSelf_scn_ typeof(weakself)self = weakself;

///将block块里的代码在主队列中同步执行
NS_INLINE
void dispatch_sync_to_main_queue(dispatch_block_t block)
{
    if (!block) {
        return;
    }
    if (0 == strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue()))) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@interface SCNUtil : NSObject

+ (NSString *)defaultUA;

@end

#endif /* SCNUtil_h */
