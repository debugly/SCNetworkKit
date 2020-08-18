//
//  SCNUtil.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 2020/8/18.
//  Copyright © 2020年 sohu-inc. All rights reserved.
//
#import "SCNUtil.h"

NSString *const SCNURLErrorDomain = @"com.sohu.sdk.scn";

NSError * SCNError(NSInteger code,id info)
{
    if(!info){
        info = @"未知错误";
    }
    NSDictionary *infoDic = nil;
    if(![info isKindOfClass:[NSDictionary class]]){
        infoDic = @{NSLocalizedDescriptionKey:info};
    }else{
        infoDic = info;
    }
    return [[NSError alloc] initWithDomain:SCNURLErrorDomain code:code userInfo:infoDic];
}

NSError * SCNErrorWithOriginErr(NSError *originError,NSInteger newcode)
{
    NSMutableDictionary *mulInfo = [NSMutableDictionary dictionary];
    NSDictionary *originInfo = originError.userInfo;
    if (originInfo) {
        NSString *desc = originInfo[NSLocalizedDescriptionKey];
        if (desc) {
            [mulInfo setObject:desc forKey:@"origin-err"];
        }
        [mulInfo setObject:@(originError.code) forKey:@"origin-errcode"];
    }
    
    return SCNError(newcode, mulInfo);
}
