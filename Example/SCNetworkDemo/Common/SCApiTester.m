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
    //因为默认解析器是SCNJSONResponseParser；会解析成JSON对象；所以这里不指定解析器，让框架返回data！
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
    //框架会检查接口返回的 code 是不是 0 ，如果不是 0 ，那么返回给你一个err，并且result是 nil;
    responseParser.checkKeyPath = @"code";
    responseParser.okValue = @"0";
    
    //support chain
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:kTestJSONApi params:nil];
    req.responseParser = responseParser;
    [req addReceivedResponseHandler:^(SCNetworkRequest *request, NSURLResponse *response) {
        NSLog(@"response:%@",response);
    }];
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        if (completion) {
            completion(result,err);
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:req];
}

+ (void)getRequestWithParams:(NSDictionary *)params completion:(void (^)(id _Nonnull, NSError * _Nonnull))completion
{
    SCNJSONResponseParser *responseParser = [SCNJSONResponseParser parser];
    //框架会检查接口返回的 status 是不是 200 ，如果不是 200 ，那么返回给你一个err，并且result是 nil;
    responseParser.checkKeyPath = @"status";
    responseParser.okValue = @"200";
    
    //support chain
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:kTestJSONApi2 params:params];
    req.responseParser = responseParser;
    
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        if (completion) {
            completion(result,err);
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:req];
}

+ (void)getRequestWithModelCompletion:(void(^)(NSArray <TestModel *>*arr, NSError *err))completion
{
    /*
     ///服务器响应数据结构///
     
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
    //解析前会检查下JSON是否正确；
    responseParser.checkKeyPath = @"code";
    responseParser.okValue = @"0";
    //根据服务器返回数据的格式和想要解析结构对应的Model配置解析器
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
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"abc"];
    path = [path stringByAppendingPathComponent:[url lastPathComponent]];
    NSLog(@"download path:%@",path);
    get.downloadFileTargetPath = path;
    get.useBreakpointContinuous = NO;
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
    NSDictionary *ps = @{@"name":@"Matt Reach",@"key":@"body params",@"date":[[NSDate new]description]};
    
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@"Matt"];
    [arr addObject:@"Reach"];
    
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestPostApi params:ps];
    [post addQueryParameters:@{@"key":@"query params"}];
    post.bodyEncoding = SCNPostBodyEncodingURL;
    [post addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:post];
}

//POST /users HTTP/1.1
//Host: localhost.charlesproxy.com:3000
//Content-Type: application/json; charset=utf-8
//Connection: keep-alive
//Accept: */*
//User-Agent: SCNetworkiOSDemo/1 SCNetworkiOSDemo/1.0 (iPhone; iOS 14.3; Scale/2.00)
//Accept-Language: en;q=1
//Content-Length: 76
//Accept-Encoding: gzip, deflate
//
//[{"date":"2021-01-01 15:55:37 +0000","name":"Matt Reach","k2":"v2","k1":"v1"}]

+ (void)postJSONWithCompletion:(void(^)(id json,NSError *err))completion
{
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestPostApi params:@[ps]];
    [post addQueryParameters:@{@"key":@"query params"}];
    post.bodyEncoding = SCNPostBodyEncodingJSON;
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
    [post addQueryParameters:@{@"key":@"query params"}];
    post.bodyEncoding = SCNPostBodyEncodingFormData;
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
    [post addQueryParameters:@{@"key":@"query params"}];
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
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkDownloadRequest *post = [[SCNetworkDownloadRequest alloc]initWithURLString:url params:ps];
    post.method = SCNetworkRequestPostMethod;
    NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:[url lastPathComponent]];

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
            
            if (progress) {
                progress(p);
            }
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:post];
}
@end
