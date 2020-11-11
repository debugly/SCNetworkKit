//
//  SCApiTester.m
//  SCNetworkDemo
//
//  Created by Matt Reach on 2020/8/24.
//

#import "SCApiTester.h"
#import <SCNetworkKit/SCNetworkKit.h>

@implementation SCApiTester

+ (void)getRequestWithDataCompletion:(void(^)(NSData *data,NSError *err))completion
{
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:kTestJSONApi params:nil];
    ///因为默认解析器是SCNJSONResponseParser；会解析成JSON对象；所以这里不指定解析器，让框架返回data！
    req.responseParser = nil;
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    
    [req addReceivedResponseHandler:^(SCNetworkRequest *request, NSURLResponse *response) {
        NSLog(@"response:%@",response);
    }];
    
    [[SCNetworkService sharedService]startRequest:req];
}

+ (void)getRequestWithJSONCompletion:(void(^)(id json, NSError *err))completion
{
    SCNJSONResponseParser *responseParser = [SCNJSONResponseParser parser];
    ///框架会检查接口返回的 code 是不是 0 ，如果不是 0 ，那么返回给你一个err，并且result是 nil;
    responseParser.checkKeyPath = @"code";
    responseParser.okValue = @"0";
    
    ///support chain
    SCNetworkRequest *req = [[SCNetworkRequest alloc]init];
    
    req
    .c_URL(kTestJSONApi)
    .c_ResponseParser(responseParser)
    .c_ReceivedResponseHandler(^(SCNetworkRequest *request,NSURLResponse *response){
        NSLog(@"response:%@",response);
    })
    .c_CompletionHandler(^(SCNetworkRequest *request, id result, NSError *err) {
        if (completion) {
            completion(result,err);
        }
    });
    
    [[SCNetworkService sharedService]startRequest:req];
}

+ (void)getRequestWithModelCompletion:(void(^)(NSArray <TestModel *>*arr, NSError *err))completion
{
    /*
     ////服务器响应数据结构////
     
     {   code = 0;
     content =     {
     entrance =         (
     {
     isFlagship = 0;
     name = "\U65f6\U5c1a\U6f6e\U65f6\U5c1a";
     pic = "http://pic12.shangpin.com/e/s/15/03/03/20150303151320537363-10-10.jpg";
     refContent = "http://m.shangpin.com/meet/185";
     type = 5;
     },
     {
     //....
     }
     )
     }
     }
     */
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:kTestJSONApi params:nil];

    SCNModelResponseParser *responseParser = [SCNModelResponseParser parser];
    ///解析前会检查下JSON是否正确；
    responseParser.checkKeyPath = @"code";
    responseParser.okValue = @"0";
    ///根据服务器返回数据的格式和想要解析结构对应的Model配置解析器
    responseParser.modelName = @"TestModel";
    responseParser.targetKeyPath = @"content/entrance";
    req.responseParser = responseParser;
    
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    [[SCNetworkService sharedService]startRequest:req];
}

+ (void)getFileWithCompletion:(void(^)(NSString *path,NSError *err))completion progress:(void(^)(float p))progress
{
    NSString *url = kTestDownloadApi;
    SCNetworkDownloadRequest *get = [[SCNetworkDownloadRequest alloc]initWithURLString:url params:nil];
    NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:[url lastPathComponent]];
    NSLog(@"download path:%@",path);
    get.downloadFileTargetPath = path;
    get.useBreakpointContinuous = YES;
    [get addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        if (completion) {
            completion(path,err);
        }
    }];
    
    [get addProgressChangedHandler:^(SCNetworkRequest *request, int64_t thisTransfered, int64_t totalBytesTransfered, int64_t totalBytesExpected) {
        
        if (totalBytesExpected > 0) {
            float p = 1.0 * totalBytesTransfered / totalBytesExpected;
            NSLog(@"download progress:%0.4f",p);
            if (progress) {
                progress(p);
            }
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:get];
}

+ (void)postNoBodyWithCompletion:(void(^)(id json,NSError *err))completion
{
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkRequest *post = [[SCNetworkRequest alloc]initWithURLString:kTestPostApi params:ps];
    
    post.method = SCNetworkRequestPostMethod;
    [post addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:post];
}


//POST /users HTTP/1.1
//Host: localhost:3000
//Content-Type: application/x-www-form-urlencoded; charset=utf-8
//Connection: keep-alive
//Accept: */*
//User-Agent: SCNDemo/1.0 (iPhone; iOS 11.3; Scale/3.00)
//Content-Length: 70
//Accept-Language: en-us
//Accept-Encoding: gzip, deflate
//
//k1=v1&name=Matt%20Reach&k2=v2&date=2018-04-17%2015%3A12%3A38%20%2B0000

+ (void)postURLEncodeWithCompletion:(void(^)(id json,NSError *err))completion
{
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestPostApi params:ps];
    post.parameterEncoding = SCNPostDataEncodingURL;
    [post addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:post];
}

//POST /upload-file HTTP/1.1
//Host: localhost:3000
//Content-Type: multipart/form-data; charset=utf-8; boundary=0xKhTmLbOuNdArY
//Connection: keep-alive
//Accept: */*
//User-Agent: SCNDemo/1.0 (iPhone; iOS 11.3; Scale/3.00)
//Content-Length: 330
//Accept-Language: en-us
//Accept-Encoding: gzip, deflate
//
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="k1"
//
//v1
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="name"
//
//Matt Reach
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="k2"
//
//v2
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="date"
//
//2018-04-17 16:01:35 +0000
//
//--0xKhTmLbOuNdArY--

+ (void)postFormDataWithCompletion:(void(^)(id json,NSError *err))completion
{
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestUploadApi params:ps];
    post.parameterEncoding = SCNPostDataEncodingFormData;
    [post addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:post];
}

//POST /upload-file HTTP/1.1
//Host: localhost:3000
//Content-Type: multipart/form-data; charset=utf-8; boundary=0xKhTmLbOuNdArY
//Connection: keep-alive
//Accept: */*
//User-Agent: SCNDemo/1.0 (iPhone; iOS 11.3; Scale/3.00)
//Content-Length: 50311
//Accept-Language: en-us
//Accept-Encoding: gzip, deflate
//
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="k1"
//
//v1
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="name"
//
//Matt Reach
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="k2"
//
//v2
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="date"
//
//2018-04-17 15:58:37 +0000
//--0xKhTmLbOuNdArY
//Content-Disposition: form-data; name="test.jpg"; filename="node.jpg"
//Content-Type: image/jpeg
//
//乱码的图像数据
//....
//--0xKhTmLbOuNdArY--


+ (void)postUploadFileWithCompletion:(void(^)(id json,NSError *err))completion progress:(void(^)(float p))progress
{
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestUploadApi params:ps];
    
    SCNetworkFormFilePart *filePart = [SCNetworkFormFilePart new];
    NSString *fileURL = [[NSBundle mainBundle]pathForResource:@"logo" ofType:@"png"];
    filePart.data = [[NSData alloc]initWithContentsOfFile:fileURL];
    filePart.fileName = @"logo.png";
    filePart.mime = @"image/jpg";
    filePart.name = @"logo";
    
    SCNetworkFormFilePart *filePart2 = [SCNetworkFormFilePart new];
    filePart2.fileURL = [[NSBundle mainBundle]pathForResource:@"node" ofType:@"txt"];
    
    post.formFileParts = @[filePart,filePart2];
    [post addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    
    [post addProgressChangedHandler:^(SCNetworkRequest *request, int64_t thisTransfered, int64_t totalBytesTransfered, int64_t totalBytesExpected) {
        
        if (totalBytesExpected > 0) {
            float p = 1.0 * totalBytesTransfered / totalBytesExpected;
            NSLog(@"upload progress:%0.4f",p);
            if (progress) {
                progress(p);
            }
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:post];
}

+ (void)postDownloadFileWithCompletion:(void(^)(NSString *path,NSError *err))completion progress:(void(^)(float p))progress
{
    NSString *url = kTestDownloadApi4;
    SCNetworkDownloadRequest *post = [[SCNetworkDownloadRequest alloc]initWithURLString:url params:nil];
    post.method = SCNetworkRequestPostMethod;
    NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:[url lastPathComponent]];
    NSLog(@"download path:%@",path);
    post.downloadFileTargetPath = path;
    post.useBreakpointContinuous = YES;
    [post addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        if (completion) {
            completion(path,err);
        }
    }];
    
    [post addProgressChangedHandler:^(SCNetworkRequest *request, int64_t thisTransfered, int64_t totalBytesTransfered, int64_t totalBytesExpected) {
        
        if (totalBytesExpected > 0) {
            float p = 1.0 * totalBytesTransfered / totalBytesExpected;
            NSLog(@"download progress:%0.4f",p);
            if (progress) {
                progress(p);
            }
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:post];
}
@end
