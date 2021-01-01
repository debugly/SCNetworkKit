//
//  SectionModel.h
//  SCNetworkiOSDemo
//
//  Created by qianlongxu on 2021/1/1.
//

#import <Foundation/Foundation.h>
#import "RowModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SectionModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSArray <RowModel *>*rows;

@end

NS_ASSUME_NONNULL_END
