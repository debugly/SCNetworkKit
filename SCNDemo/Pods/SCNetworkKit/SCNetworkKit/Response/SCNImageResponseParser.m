//
//  SCNImageResponseParser.m
//  SCNetWorkKit
//
//  Created by xuqianlong on 2017/2/9.
//  Copyright © 2017年 sohu-inc. All rights reserved.
//

#import "SCNImageResponseParser.h"
#import <UIKit/UIScreen.h>
#import <ImageIO/ImageIO.h>

static UIImage * SCImageWithDataAtScale(NSData *data, CGFloat scale) {
    UIImage *image = [UIImage imageWithData:data];
    if (image.images) {
        return image;
    }
    
    return [[UIImage alloc] initWithCGImage:[image CGImage] scale:scale orientation:image.imageOrientation];
}

static bool isOSVersonEqualEight()
{
    static NSUInteger cv = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cv = [[[UIDevice currentDevice]systemVersion]intValue];
    });
    return cv == 8;
}

static UIImage * SCInflatedImageFromResponseWithDataAtScale(NSData *data, CGFloat scale, BOOL isPng) {
    
    CGImageRef imageRef = NULL;
    
    //ios8.1上测试，偶尔会出现解析出错导致一半图像为黑的情况，在8系统上暂时不用dataProvider
    if(!isOSVersonEqualEight()){
        CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
        if (isPng) {
            imageRef = CGImageCreateWithPNGDataProvider(dataProvider,  NULL, true, kCGRenderingIntentDefault);
        } else{
            imageRef = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, true, kCGRenderingIntentDefault);
            
            if (imageRef) {
                CGColorSpaceRef imageColorSpace = CGImageGetColorSpace(imageRef);
                CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(imageColorSpace);
                
                // CGImageCreateWithJPEGDataProvider does not properly handle CMKY, so fall back to AFImageWithDataAtScale
                if (imageColorSpaceModel == kCGColorSpaceModelCMYK) {
                    CGImageRelease(imageRef);
                    imageRef = NULL;
                }
            }
        }
        CGDataProviderRelease(dataProvider);
    }
    
    UIImage *image = SCImageWithDataAtScale(data, scale);
    if (!imageRef) {
        if (image.images || !image) {
            return image;
        }
        
        imageRef = CGImageCreateCopy([image CGImage]);
        if (!imageRef) {
            return nil;
        }
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    
    if (width * height > 1024 * 1024 || bitsPerComponent > 8) {
        CGImageRelease(imageRef);
        
        return image;
    }
    
    // CGImageGetBytesPerRow() calculates incorrectly in iOS 5.0, so defer to CGBitmapContextCreate
    size_t bytesPerRow = 0;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    if (colorSpaceModel == kCGColorSpaceModelRGB) {
        uint32_t alpha = (bitmapInfo & kCGBitmapAlphaInfoMask);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
        if (alpha == kCGImageAlphaNone) {
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaNoneSkipFirst;
        } else if (!(alpha == kCGImageAlphaNoneSkipFirst || alpha == kCGImageAlphaNoneSkipLast)) {
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaPremultipliedFirst;
        }
#pragma clang diagnostic pop
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        CGImageRelease(imageRef);
        
        return image;
    }
    
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), imageRef);
    CGImageRef inflatedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage *inflatedImage = [[UIImage alloc] initWithCGImage:inflatedImageRef scale:scale orientation:image.imageOrientation];
    
    CGImageRelease(inflatedImageRef);
    CGImageRelease(imageRef);
    
    return inflatedImage;
}

@interface SCNJpegResponseParser : NSObject<SCNImageParserProtocol>

@end

@implementation SCNJpegResponseParser

+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale
{
    if (!data || [data length] == 0) {
        return nil;
    }
    return SCInflatedImageFromResponseWithDataAtScale(data, scale, NO);
}

@end

@interface SCNPngResponseParser : NSObject<SCNImageParserProtocol>

@end

@implementation SCNPngResponseParser

+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale
{
    if (!data || [data length] == 0) {
        return nil;
    }
    return SCInflatedImageFromResponseWithDataAtScale(data, scale, YES);
}

@end

@interface SCNGifResponseParser : NSObject<SCNImageParserProtocol>

@end

@implementation SCNGifResponseParser

+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale
{
    if (!data || [data length] == 0) {
        return nil;
    }
    
    //获取数据源
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    // 获取图片数量(如果传入的是gif图的二进制，那么获取的是图片帧数)
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {
        NSMutableArray *images = [NSMutableArray array];
        
        NSTimeInterval duration = 0.0f;
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            
            duration += [self sc_frameDurationAtIndex:i source:source];
            
            [images addObject:[UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp]];
            
            CGImageRelease(image);
        }
        // 如果上面的计算播放时间方法没有成功，就按照下面方法计算
        // 计算一次播放的总时间：每张图播放1/10秒 * 图片总数
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    
    CFRelease(source);
    
    return animatedImage;
}

//计算每帧需要播放的时间
+ (float)sc_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    // 获取这一帧的属性字典
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    // 从字典中获取这一帧持续的时间
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

@end

@implementation SCNImageResponseParser

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [[self class] registerParser:[SCNPngResponseParser class] forMime:@"image/png"];
        [[self class] registerParser:[SCNJpegResponseParser class] forMime:@"image/jpeg"];
        [[self class] registerParser:[SCNJpegResponseParser class] forMime:@"image/jpg"];
        [[self class] registerParser:[SCNGifResponseParser class] forMime:@"image/gif"];
        
        NSMutableSet *mimeSet = [NSMutableSet set];
        for (NSString *mime in [[[self class]extensionParsers]allKeys]) {
            [mimeSet addObject:mime];
        }
        self.acceptableContentTypes = [mimeSet copy];
    }
    return self;
}

- (UIImage *)parseredObjectForResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error
{
    NSData * respData = [super parseredObjectForResponse:response data:data error:error];
    if (*error) {
        return nil;
    }
    return  [self parserResponseData2Image:respData mimeType:response.MIMEType];
}

- (UIImage *)parserResponseData2Image:(NSData *)data mimeType:(NSString *)mime
{
    if (data.length == 0) {
        return nil;
    }
    CGFloat scale = [[UIScreen mainScreen] scale];
    NSString *clazz = [[[self class]extensionParsers]objectForKey:mime];
    if (clazz) {
        Class <SCNImageParserProtocol> parser = NSClassFromString(clazz);
        return [parser imageWithData:data scale:scale];
    }
    return nil;
}

+ (void)registerParser:(Class<SCNImageParserProtocol>)parser forMime:(NSString *)mime
{
    if (parser && mime.length > 0) {
        [[self extensionParsers]setObject:NSStringFromClass(parser) forKey:mime];
    }
}

+ (NSMutableDictionary *)extensionParsers
{
    static NSMutableDictionary *eps = nil;
    if (!eps) {
        eps = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return eps;
}

@end
