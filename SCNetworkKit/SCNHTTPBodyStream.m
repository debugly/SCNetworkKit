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

NSString * const SCNBoundary = @"----Boundary0xKhTmLbOuNdArY";

@interface SCNHTTPBodyStream()

@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, strong) NSArray<SCNetworkFormFilePart *> *formFileParts;

@property (nonatomic, assign) NSUInteger totalURLFileSize;
@property (nonatomic, assign) NSUInteger bodyLength;

@property (nonatomic, strong) NSMutableArray *formParts;
@property (nonatomic, strong) NSInputStream *inputStream;

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

- (instancetype)initWithParameters:(NSDictionary *)parameters formFileParts:(NSArray<SCNetworkFormFilePart *> *)formFileParts
{
    self = [super init];
    if (self) {
        self.parameters = parameters;
        self.formFileParts = formFileParts;
    }
    return self;
}

+ (instancetype)bodyStreamWithParameters:(NSDictionary *)parameters formFileParts:(NSArray<SCNetworkFormFilePart *> *)formFileParts
{
    return [[self alloc]initWithParameters:parameters formFileParts:formFileParts];
}

//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="k1"
//
//v1
//(需要拼接的是这个)\r\n

- (NSData *)makeParametersBoundaryData
{
    NSMutableData *beginBoundaryData = [NSMutableData data];
    
    [self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSString *formattedKV = [NSString stringWithFormat:
                                 @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
                                 SCNBoundary, key, obj];
        
        [beginBoundaryData appendData:[formattedKV dataUsingEncoding:NSUTF8StringEncoding]];
        [beginBoundaryData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    return [beginBoundaryData copy];
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

//------Boundary0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="test.jpg"; filename="node.jpg"
//Content-Type: image/jpeg
//
//....
//(需要拼接的是这个)\r\n
//------Boundary0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="test.jpg"; filename="node.jpg"
//Content-Type: image/jpeg
//
//....
//(需要拼接的是这个)\r\n

- (NSArray *)makeFileOrBinaryBoundaryArray
{
    ///计算之前清空下
    __block NSUInteger totalURLFileSize = 0;
    NSMutableArray *fileBoundaryArray = [NSMutableArray array];
    
    [self.formFileParts enumerateObjectsUsingBlock:^(SCNetworkFormFilePart * part, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *mime = part.mime;
        NSString *fileName = part.fileName;
        NSString *name = part.name;
        
        if (part.fileURL) {
            NSDictionary *attr = [[NSFileManager defaultManager]attributesOfItemAtPath:part.fileURL error:nil];
            //文件大小累加
            totalURLFileSize += [attr[NSFileSize] unsignedIntegerValue];
            if (!fileName) {
                fileName = [part.fileURL lastPathComponent];
            }
            if(!mime){
                mime = SCNContentTypeForPathExtension([fileName pathExtension]);
            }
        }
        
        if (!name) {
            name = @"file";
        }
        NSParameterAssert(mime);
        NSParameterAssert(fileName);
        
        NSString *formattedFileBoundary = [NSString stringWithFormat:
                                           @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n",
                                           SCNBoundary,
                                           name,
                                           fileName,
                                           mime];
        
        NSData *data = [formattedFileBoundary dataUsingEncoding:NSUTF8StringEncoding];
    
        ///kv
        [fileBoundaryArray addObject:data];
        ///file data or file path
        if (part.fileURL) {
            [fileBoundaryArray addObject:part.fileURL];
        }else{
            [fileBoundaryArray addObject:part.data];
        }
        [fileBoundaryArray addObject:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    self.totalURLFileSize = totalURLFileSize;
    return [fileBoundaryArray copy];
}

- (NSData *)makeEndBoundaryData
{
    NSData *endBoundaryData = [[NSString stringWithFormat:@"--%@--\r\n", SCNBoundary] dataUsingEncoding:NSUTF8StringEncoding];
    
    return endBoundaryData;
}

- (void)makeBodyIfNeed
{
    if(!self.isInitBody){
        NSData * parametersBoundaryData = [self makeParametersBoundaryData];
        NSArray *fileBoundaryDataArray = [self makeFileOrBinaryBoundaryArray];
        NSData * endBoundaryData = [self makeEndBoundaryData];
        
        NSMutableArray *formParts = [NSMutableArray array];
        [formParts addObject:parametersBoundaryData];
        [formParts addObjectsFromArray:fileBoundaryDataArray];
        [formParts addObject:endBoundaryData];
        
        self.formParts = formParts;
        
        __block NSUInteger boundaryDataLength = 0;
        [formParts enumerateObjectsUsingBlock:^(NSData * _Nonnull data, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([data isKindOfClass:[NSData class]]) {
                boundaryDataLength += data.length;
            }
        }];
        
        self.bodyLength = boundaryDataLength + self.totalURLFileSize;
        self.isInitBody = YES;
    }
}

- (NSUInteger)contentLength
{
    [self makeBodyIfNeed];
    return self.bodyLength;
}

- (void)open
{
    if (self.streamStatus == NSStreamStatusOpen) {
        return;
    }
    
    // 状态标记为打开
    self.streamStatus = NSStreamStatusOpen;
    //构建body体，并统计下长度
    [self makeBodyIfNeed];
}

- (void)close
{
    //do nothing.
    if(self.inputStream){
        [self.inputStream close];
        self.inputStream = nil;
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

- (void)prepareInputStream
{
    if (!self.inputStream && [self.formParts count] > 0) {
        
        id formPart = [self.formParts firstObject];
        if([formPart isKindOfClass:[NSString class]]) {
            self.inputStream = [NSInputStream inputStreamWithFileAtPath:formPart];
        }else if([formPart isKindOfClass:[NSData class]]){
            self.inputStream = [NSInputStream inputStreamWithData:formPart];
        }
        
        [self.formParts removeObjectAtIndex:0];
        
        if(self.inputStream){
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [self.inputStream open];
        }else{
            ///读取下一个
            [self prepareInputStream];
        }
    }
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)wantReadLength
{
    NSInteger numberOfBytesRead = 0;
    
    while (numberOfBytesRead < wantReadLength) {
        
        ///读完了
        if ([self.formParts count] == 0) {
            return numberOfBytesRead;
        }
        
        NSInteger thisReadLength = 0;
        [self prepareInputStream];
        thisReadLength = [self.inputStream read:buffer maxLength:wantReadLength];
        
        if (thisReadLength <= 0) {
            [self.inputStream close];
            self.inputStream = nil;
            continue;
        }
        
        numberOfBytesRead += thisReadLength;
        buffer            += thisReadLength;
        wantReadLength    -= thisReadLength;
    }
    return numberOfBytesRead;
}

@end
