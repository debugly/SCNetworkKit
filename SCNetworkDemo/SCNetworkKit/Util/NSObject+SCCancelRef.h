//
//  NSObject+SCCancelRef.h
//  SCNetWorkKit
//
//  Created by 许乾隆 on 16/5/17.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//
// 用于自动取消网络请求

#import <Foundation/Foundation.h>

@protocol SCCancel <NSObject>

- (void)cancel;

@end

@interface NSObject (SCCancelRef)

//当前对象销毁时自动取消；
- (void)sc_addCancleObj:(id <SCCancel>)obj;

@end
