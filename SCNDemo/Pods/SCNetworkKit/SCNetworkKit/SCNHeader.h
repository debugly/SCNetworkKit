//
//  SCNHeader.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2016/11/25.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#ifndef SCNHeader_h
#define SCNHeader_h

extern NSError * SCNErrorWithOriginErr(NSError *originError,NSInteger newcode);
extern NSError * SCNError(NSInteger code,id info);
#endif /* SCNHeader_h */
