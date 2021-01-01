//
//  RowModel.h
//  SCNetworkiOSDemo
//
//  Created by qianlongxu on 2021/1/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RowModel;
@interface RowModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) void (^action)(RowModel *);

@end

NS_ASSUME_NONNULL_END
