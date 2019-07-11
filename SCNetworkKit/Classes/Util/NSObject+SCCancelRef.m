//
//  NSObject+SCCancelRef.m
//  SCNetWorkKit
//
//  Created by 许乾隆 on 16/5/17.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "NSObject+SCCancelRef.h"
#import "objc/runtime.h"

@interface SCWeakPrivateRef : NSObject

@property (nonatomic, weak) id <SCCancel>obj;

+ (instancetype)refWithObj:(id<SCCancel>)obj;

@end

@implementation SCWeakPrivateRef

- (void)dealloc
{
    if (self.obj) {
        [self.obj cancel];
    }
}

- (instancetype)initWithObj:(id<SCCancel>)obj
{
    self = [super init];
    if (self) {
        self.obj = obj;
    }
    return self;
}

+ (instancetype)refWithObj:(id<SCCancel>)obj
{
    return [[self alloc]initWithObj:obj];
}

@end

@interface SCCancelPair : NSObject

@property (nonatomic,strong) NSMutableArray *cancleRefs;

- (void)addCancleObj:(id<SCCancel>)obj;

@end

@implementation SCCancelPair

- (void)addCancleObj:(id<SCCancel>)obj
{
    if (!obj || ![obj respondsToSelector:@selector(cancel)]) {
        return;
    }
    
    SCWeakPrivateRef *ref = [SCWeakPrivateRef refWithObj:obj];
    if (!_cancleRefs) {
        _cancleRefs = [[NSMutableArray alloc]init];
    }
    [self.cancleRefs addObject:ref];
}

@end

@implementation NSObject (SCCancelRef)

- (void)sc_addCancleObj:(id<SCCancel>)obj
{
    [[self sc_cancelPair]addCancleObj:obj];
}

- (SCCancelPair *)sc_cancelPair
{
    SCCancelPair *cancelPair = objc_getAssociatedObject(self, _cmd);
    if (!cancelPair) {
        cancelPair = [[SCCancelPair alloc]init];
        objc_setAssociatedObject(self, _cmd, cancelPair, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cancelPair;
}

@end
