//
//  SCNResponseParser.h
//  SohuCoreFoundation
//
//  Created by xuqianlong on 2017/7/11.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCNResponseParser <NSObject>

/**
 The response object decoded from the data associated with a specified response.
 
 @param response The response to be processed.
 @param data The response data to be decoded.
 @param error The error that occurred while attempting to decode the response data.
 
 @return The object decoded from the specified response data.
 */
- (nullable id)parseredObjectForResponse:(nullable NSHTTPURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError * _Nullable __autoreleasing *_Nullable)error;

@end
