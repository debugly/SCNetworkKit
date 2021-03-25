//
//  SCNetworkRequest+SessionDelegate.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/11/14.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import "SCNetworkRequest+Landing.h"
#import "SCNetworkRequestInternal.h"
#import "SCNUtil.h"

@implementation SCNetworkBasicRequest (basic)

- (void)didCompleteWithError:(NSError *)error resp:(NSHTTPURLResponse*)resp
{
    self.response = resp;
    
    if(error) {
        if(error.code == NSURLErrorCancelled) {
            //处理下下载时，返回404之类的错误，需要给上层一个回调！
            if ([self isKindOfClass:[SCNetworkDownloadRequest class]]) {
                SCNetworkDownloadRequest *downloadReq = (SCNetworkDownloadRequest *)self;
                if (SCNetworkDownloadRecordBadResponse == downloadReq.recordCode) {
                    NSError *aError = SCNError(self.response.statusCode, self.response.allHeaderFields);
                    [self updateState:SCNRequestStateError error:aError];
                } else if (SCNetworkDownloadRecordAlreadyFinished == downloadReq.recordCode) {
                    [self updateState:SCNRequestStateCompleted error:nil];
                } else if (SCNetworkDownloadRecordBadRangeRequest == downloadReq.recordCode) {
                    NSError *aError = SCNError(self.response.statusCode, self.response.allHeaderFields);
                    [self updateState:SCNRequestStateError error:aError];
                } else {
                    NSError *aError = SCNError(self.response.statusCode, self.response.allHeaderFields);
                    [self updateState:SCNRequestStateCancelled error:aError];
                }
            } else {
                [self updateState:SCNRequestStateCancelled error:error];
            }
        } else {
            [self updateState:SCNRequestStateError error:error];
        }
    } else {
        [self updateState:SCNRequestStateCompleted error:nil];
    }
}

- (void)didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    //处理下载文件遇到 404 等情况
    completionHandler([self onReceivedResponse:(NSHTTPURLResponse*)response]);
}

- (void)didReceiveData:(NSData *)data
{
    [self didReceiveResponseData:data];
}

@end

@implementation SCNetworkPostRequest (upload)

- (void)didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    [self updateTransferedData:bytesSent totalBytes:totalBytesSent totalBytesExpected:totalBytesExpectedToSend];
}

@end

@implementation SCNetworkDownloadRequest (download)

- (void)didFinishDownloadingToURL:(NSURL *)location
{
    if (self.downloadFileTargetPath) {
        NSError *err = nil;
        NSURL *targetURL = [NSURL fileURLWithPath:self.downloadFileTargetPath];
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&err];
        //516:文件已经存在
        if (err.code == NSFileWriteFileExistsError) {
            [[NSFileManager defaultManager] removeItemAtURL:targetURL error:nil];
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&err];
        }
        //4:文件夹不存在
        else if (err.code == NSFileNoSuchFileError) {
            NSString *dir = [self.downloadFileTargetPath stringByDeletingLastPathComponent];
            if (dir) {
                [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&err];
            }
        }
    }
}

@end
