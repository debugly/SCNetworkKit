//
//  TestModel.h
//  SCNetworkDemo
//
//  Created by xuqianlong on 2017/7/13.
//  Copyright © 2017年 xuqianlong. All rights reserved.
//
// 解析框架会根据你指定的类型去解析！

#import <Foundation/Foundation.h>

@interface TestModel : NSObject

@property (nonatomic, assign) BOOL isFlagship;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSURL *pic;
@property (nonatomic, copy) NSString *refContent;
@property (nonatomic, assign) NSInteger type;

@end
