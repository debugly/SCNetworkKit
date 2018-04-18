//
//  SCNHTTPBodyStream.m
//  SCNDemo
//
//  Created by 许乾隆 on 2018/3/19.
//  Copyright © 2018年 xuqianlong. All rights reserved.
//

#import "SCNHTTPBodyStream.h"
#import "SCNetworkRequestInternal.h"
#import <MobileCoreServices/MobileCoreServices.h>

static NSString * kBoundary = @"0xKhTmLbOuNdArY";

@interface SCNHTTPBodyStream()

@property (nonatomic, strong) SCNetworkFormData *formData;
@property (nonatomic, copy) NSData *topBoundaryData;
@property (nonatomic, copy) NSData *fileBoundaryData;
@property (nonatomic, assign) NSUInteger fileSize;
@property (nonatomic, copy) NSData *endBoundaryData;
@property (nonatomic, assign) NSUInteger bodyLength;
@property (nonatomic, assign) NSUInteger readLength;

@property (nonatomic, strong) NSInputStream *fileStream;

@property (readwrite) NSStreamStatus streamStatus;

@property (nonatomic, assign) BOOL isInitBody;
    
@end

@implementation SCNHTTPBodyStream

@synthesize streamStatus;
@synthesize delegate;
@synthesize streamError;

- (id)propertyForKey:(__unused NSString *)key {
    return nil;
}

- (BOOL)setProperty:(__unused id)property
             forKey:(__unused NSString *)key
{
    return NO;
}

- (void)scheduleInRunLoop:(__unused NSRunLoop *)aRunLoop
                  forMode:(__unused NSString *)mode
{}

- (void)removeFromRunLoop:(__unused NSRunLoop *)aRunLoop
                  forMode:(__unused NSString *)mode
{}

- (instancetype)initWithFormData:(SCNetworkFormData *)formData
{
    self = [super init];
    if (self) {
        self.formData = formData;
    }
    return self;
}

+ (instancetype)bodyStreamWithFormData:(SCNetworkFormData *)formData
{
    return [[self alloc]initWithFormData:formData];
}

- (NSData *)makeTopBoundaryData
{
    NSMutableData *topBoundaryData = [NSMutableData data];
    
    [self.formData.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSString *formattedKV = [NSString stringWithFormat:
                                 @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
                                 kBoundary, key, obj];
        
        [topBoundaryData appendData:[formattedKV dataUsingEncoding:NSUTF8StringEncoding]];
        [topBoundaryData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    return [topBoundaryData copy];
}

static inline NSString * SCNContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

- (NSData *)makeFileOrBinaryBoundaryData
{
    if (self.formData.attachedData || self.formData.fileURL) {
        
        NSString *originalFileName = nil;
        NSString *mime = self.formData.mime;
        NSString *fileName = self.formData.fileName;
        
        if (self.formData.fileURL) {
            NSDictionary *attr = [[NSFileManager defaultManager]attributesOfItemAtPath:self.formData.fileURL error:nil];
            self.fileSize = [attr[NSFileSize] unsignedIntegerValue];
            originalFileName = [self.formData.fileURL lastPathComponent];
            if(!mime){
                mime = SCNContentTypeForPathExtension([originalFileName pathExtension]);
            }
        }else if(self.formData.attachedData){
            self.fileSize = self.formData.attachedData.length;
            originalFileName = fileName;
        }
        
        NSParameterAssert(originalFileName);
        NSParameterAssert(mime);
        NSParameterAssert(fileName);
        
        NSString *formattedFileBoundary = [NSString stringWithFormat:
                                           @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n",
                                           kBoundary,
                                           fileName,
                                           originalFileName,
                                           mime];
        
        return [formattedFileBoundary dataUsingEncoding:NSUTF8StringEncoding];
    }else{
        return nil;
    }
}

- (NSData *)makeEndBoundaryData
{
    NSData *endBoundaryData = [[NSString stringWithFormat:@"\r\n--%@--\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding];
    
    return endBoundaryData;
}

- (void)makeBody
{
    if(!self.isInitBody){
        self.topBoundaryData = [self makeTopBoundaryData];
        self.fileBoundaryData = [self makeFileOrBinaryBoundaryData];
        self.endBoundaryData = [self makeEndBoundaryData];
        self.isInitBody = YES;
    }
}

- (NSUInteger)contentLength
{
    [self makeBody];
    return self.topBoundaryData.length + self.fileBoundaryData.length + self.fileSize + self.endBoundaryData.length;
}

- (void)prepareInputStream
{
    if (!self.fileStream) {
        if (self.formData.fileURL) {
            self.fileStream = [NSInputStream inputStreamWithFileAtPath:self.formData.fileURL];
        }else if(self.formData.attachedData){
            self.fileStream = [NSInputStream inputStreamWithData:self.formData.attachedData];
        }
        if(self.fileStream){
            [self.fileStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [self.fileStream open];
        }
    }
}

- (void)open
{
    if (self.streamStatus == NSStreamStatusOpen) {
        return;
    }
    // 状态标记为打开
    self.streamStatus = NSStreamStatusOpen;
    
    //统计下长度
    self.bodyLength = [self contentLength];
}

- (void)close
{
    //do nothing.
    if(self.fileStream){
        [self.fileStream close];
        self.fileStream = nil;
    }
    self.streamStatus = NSStreamStatusClosed;
}

- (BOOL)getBuffer:(__unused uint8_t **)buffer
           length:(__unused NSUInteger *)len
{
    return NO;
}

- (BOOL)hasBytesAvailable {
    return [self streamStatus] == NSStreamStatusOpen;
// 用下面的判断会导致该流一直收不到close，直到超时报错！
//     return  self.readLength < self.bodyLength;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    NSInteger numberOfBytesRead = 0;
    
    uint8_t *out_buffer = buffer;
    NSUInteger wantReadLength = len;
    
    while (numberOfBytesRead < MIN(len, self.bodyLength - self.readLength)) {
        ///读完了
        if (self.readLength >= self.bodyLength) {
            break;
        }
        
        NSInteger thisReadLength = 0;
        
        if (self.readLength < self.topBoundaryData.length) {
            thisReadLength = MIN(wantReadLength, self.topBoundaryData.length-self.readLength);
            [self.topBoundaryData getBytes:out_buffer range:NSMakeRange(self.readLength, thisReadLength)];
        }else if (self.readLength < self.topBoundaryData.length + self.fileBoundaryData.length){
            thisReadLength = MIN(wantReadLength, self.fileBoundaryData.length);
            NSRange range = NSMakeRange(self.readLength-self.topBoundaryData.length, thisReadLength);
            [self.fileBoundaryData getBytes:out_buffer range:range];
            if (range.location + range.length >= self.fileBoundaryData.length) {
                ////准备读文件了，创建个输入流；下次回调的时候读
                [self prepareInputStream];
            }
        }else if (self.readLength < self.topBoundaryData.length + self.fileBoundaryData.length + self.fileSize){
            thisReadLength = [self.fileStream read:out_buffer maxLength:wantReadLength];
            if (thisReadLength == -1) {
                return -1;
            }
        }else if(self.readLength < self.bodyLength){
            if(self.fileStream){
                [self.fileStream close];
                self.fileStream = nil;
            }
            thisReadLength = MIN(wantReadLength, self.endBoundaryData.length);
            NSRange range = NSMakeRange(self.readLength-(self.topBoundaryData.length + self.fileBoundaryData.length + self.fileSize), thisReadLength);
            [self.endBoundaryData getBytes:out_buffer range:range];
        }
        
        numberOfBytesRead += thisReadLength;
        out_buffer        += thisReadLength;
        self.readLength   += thisReadLength;
        wantReadLength    -= thisReadLength;
    }
    return numberOfBytesRead;
}

@end
