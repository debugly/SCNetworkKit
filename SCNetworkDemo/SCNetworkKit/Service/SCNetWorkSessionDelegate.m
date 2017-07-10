//
//  SCNetWorkSessionDelegate.m
//  SCNetWorkKit
//
//  Created by qianlongxu on 16/4/29.
//  Copyright © 2016年 sohu-inc. All rights reserved.
//

#import "SCNetWorkSessionDelegate.h"
#import "SCNetworkRequestInternal.h"
#import "SCNHeader.h"

@interface SCNetWorkSessionDelegate ()

@property(nonatomic,strong) SCNetworkRequest *request;
@property(nonatomic,strong) NSMutableData *mutableData;

@end

@implementation SCNetWorkSessionDelegate

- (instancetype)initWithRequest:(SCNetworkRequest *)request
{
    self = [super init];
    if (self) {
        self.request = request;
    }
    return self;
}

- (NSMutableData *)mutableData
{
    if (!_mutableData) {
        _mutableData = [NSMutableData data];
    }
    return _mutableData;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    if (!self || !self.request) {
        return;
    }
    
    self.request.respData = [NSData dataWithData:self.mutableData];
    self.request.response = (NSHTTPURLResponse*) task.response;
    self.request.error = error;

    if(error) {
        if(error.code == NSURLErrorCancelled){
            self.request.state = SCNKRequestStateCancelled;
        }else{
            self.request.state = SCNKRequestStateError;
        }
    }else{
        self.request.state = SCNKRequestStateCompleted;
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
    [self.request updateTransferedData:bytesSent totalBytes:totalBytesSent totalBytesExpected:totalBytesExpectedToSend];
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
    
    NSData *multipartData = [self.request multipartFormData];
    inputStream = [NSInputStream inputStreamWithData:multipartData];
    
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
    
    [self.request updateTransferedData:bytesWritten totalBytes:totalBytesWritten totalBytesExpected:totalBytesExpectedToWrite];
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
    if (self.downloadFileTargetUrl) {
        NSError *fileManagerError = nil;
        
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:self.downloadFileTargetUrl error:&fileManagerError];
        
        ///已经存在的516错误？
        if (fileManagerError) {
            
            [[NSFileManager defaultManager] removeItemAtURL:self.downloadFileTargetUrl error:nil];
            
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:self.downloadFileTargetUrl error:&fileManagerError];
        }
    }
}

@end
