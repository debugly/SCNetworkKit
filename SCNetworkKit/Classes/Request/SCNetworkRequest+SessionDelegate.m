//
//  SCNetworkRequest+SessionDelegate.m
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/11/14.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

#import "SCNetworkRequest+SessionDelegate.h"
#import "SCNetworkRequestInternal.h"
#import "SCNUtil.h"

@implementation SCNetworkBasicRequest (SessionDelegate)

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    self.response = (NSHTTPURLResponse*)task.response;
    
    if(error) {
        if(error.code == NSURLErrorCancelled) {
            //处理下下载时，返回404之类的错误，需要给上层一个回调！
            if ([self isKindOfClass:[SCNetworkDownloadRequest class]]) {
                SCNetworkDownloadRequest *downloadReq = (SCNetworkDownloadRequest *)self;
                if (SCNetworkDownloadRecordBadResponse == downloadReq.recordCode) {
                    NSError *aError = SCNError(self.response.statusCode, self.response.allHeaderFields);
                    [self updateState:SCNKRequestStateError error:aError];
                } else if (SCNetworkDownloadRecordAlreadyFinished == downloadReq.recordCode) {
                    [self updateState:SCNKRequestStateCompleted error:nil];
                } else if (SCNetworkDownloadRecordBadRangeRequest == downloadReq.recordCode) {
                    NSError *aError = SCNError(self.response.statusCode, self.response.allHeaderFields);
                    [self updateState:SCNKRequestStateError error:aError];
                } else {
                    NSError *aError = SCNError(self.response.statusCode, self.response.allHeaderFields);
                    [self updateState:SCNKRequestStateCancelled error:aError];
                }
            } else {
                [self updateState:SCNKRequestStateCancelled error:error];
            }
        }else {
            [self updateState:SCNKRequestStateError error:error];
        }
    } else {
        [self updateState:SCNKRequestStateCompleted error:nil];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    [self updateTransferedData:bytesSent totalBytes:totalBytesSent totalBytesExpected:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    //处理下载文件遇到 404 等情况
    completionHandler([self onReceivedResponse:(NSHTTPURLResponse*)response]);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    int64_t totalBytesWritten = [self didReceiveData:data];
    
    //断点续传时使用 dataTask 来做的，因此这里调用下代理方法，回调下载进度
    if ([self isKindOfClass:[SCNetworkDownloadRequest class]]) {
        SCNetworkDownloadRequest *downloadReq = (SCNetworkDownloadRequest *)self;
        //invoke the download progress.
        [self URLSession:session
            downloadTask:dataTask
            didWriteData:data.length
       totalBytesWritten:totalBytesWritten
totalBytesExpectedToWrite:dataTask.response.expectedContentLength + downloadReq.startOffset];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    NSInputStream *inputStream = nil;
//    if(self.formData.fileURL){
//        inputStream = [NSInputStream inputStreamWithFileAtPath:self.formData.fileURL];
//    }else{
//        NSData *multipartData = [self multipartFormData];
//        inputStream = [NSInputStream inputStreamWithData:multipartData];
//    }
    
    if (completionHandler) {
        completionHandler(inputStream);
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{    
    [self updateTransferedData:bytesWritten totalBytes:totalBytesWritten totalBytesExpected:totalBytesExpectedToWrite];
}

//- (void)URLSession:(NSURLSession *)session
//      downloadTask:(NSURLSessionDownloadTask *)downloadTask
// didResumeAtOffset:(int64_t)fileOffset
//expectedTotalBytes:(int64_t)expectedTotalBytes{
//
//    self.downloadProgress.totalUnitCount = expectedTotalBytes;
//    self.downloadProgress.completedUnitCount = fileOffset;
//}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    if ([self isKindOfClass:[SCNetworkDownloadRequest class]]) {
        SCNetworkDownloadRequest *download = (SCNetworkDownloadRequest *)self;
        if (download.downloadFileTargetPath) {
            NSError *err = nil;
            NSURL *targetURL = [NSURL fileURLWithPath:download.downloadFileTargetPath];
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&err];
            //516:文件已经存在
            if (err.code == NSFileWriteFileExistsError) {
                [[NSFileManager defaultManager] removeItemAtURL:targetURL error:nil];
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&err];
            }
            //4:文件夹不存在
            else if (err.code == NSFileNoSuchFileError) {
                NSString *dir = [download.downloadFileTargetPath stringByDeletingLastPathComponent];
                if (dir) {
                    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
                    [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&err];
                }
            }
        }
    }
}

@end
