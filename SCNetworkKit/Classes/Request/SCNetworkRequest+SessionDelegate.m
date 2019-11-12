//
//  SCNetworkRequest+SessionDelegate.m
//  SohuCoreFoundation
//
//  Created by 许乾隆 on 2017/11/14.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SCNetworkRequest+SessionDelegate.h"
#import "SCNetworkRequestInternal.h"

@implementation SCNetworkRequest (SessionDelegate)

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    self.respData = [NSData dataWithData:self.mutableData];
    self.response = (NSHTTPURLResponse*) task.response;
    
    if(error) {
        if(error.code == NSURLErrorCancelled){
            [self updateState:SCNKRequestStateCancelled error:error];
        }else{
            [self updateState:SCNKRequestStateError error:error];
        }
    }else{
        [self updateState:SCNKRequestStateCompleted error:nil];
    }
    //clean
    self.mutableData = nil;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    [self updateTransferedData:bytesSent totalBytes:totalBytesSent totalBytesExpected:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    [self onReceivedResponse:response];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.mutableData appendData:data];
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
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
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
    if (self.downloadFileTargetPath) {
        
        ///下载完成后移除断点文件
        if (self.useBreakpointContinuous) {
            NSString *resumeDataFile = [self resumeDataFilePath];
            [[NSFileManager defaultManager] removeItemAtPath:resumeDataFile error:NULL];
        }
        
        NSError *fileManagerError = nil;
        NSURL *targetURL = [NSURL fileURLWithPath:self.downloadFileTargetPath];
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&fileManagerError];
        
        ///已经存在的516错误？
        if (fileManagerError.code == 516) {
            
            [[NSFileManager defaultManager] removeItemAtURL:targetURL error:nil];
            
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:targetURL error:&fileManagerError];
        }
    }
}

@end
