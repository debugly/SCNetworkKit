//
//  ViewController.m
//  SCNDemo
//
//  Created by xuqianlong on 2017/7/21.
//  Copyright © 2017年 xuqianlong. All rights reserved.
//

#import "ViewController.h"
#import "SCNetworkKit.h"
#import "SCJSONUtil.h"
#import "TestModel.h"

#define kTestJSONApi @"http://debugly.cn/repository/test.json"
#define kTestUploadApi @"http://localhost:3000/upload-file"
#define kTestPostApi @"http://localhost:3000/users"
 
#define kTestDownloadApi @"http://localhost:3000/images/node.jpg"
#define kTestDownloadApi2 @"http://debugly.github.io/repository/test.mp4"


#define __weakSelf   typeof(self)weakself = self;
#define __strongSelf typeof(weakself)self = weakself;

@interface ViewController ()

@property (nonatomic, weak) UIView *indicator;

- (IBAction)getData:(id)sender;

- (IBAction)getJSON:(id)sender;

- (IBAction)getModel:(id)sender;

- (IBAction)getFile:(id)sender;

- (IBAction)postURLEncode:(id)sender;

- (IBAction)postFormData:(id)sender;

- (IBAction)postUploadFile:(id)sender;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)showIndicator
{
    if (!self.indicator) {
        UIView *mask = [UIView new];
        [self.view addSubview:mask];
        mask.frame = self.view.bounds;
        mask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mask.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        self.indicator = mask;
        
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.color = [UIColor lightGrayColor];
        [mask addSubview:indicator];
        indicator.center = mask.center;
        [indicator startAnimating];
        indicator.tag = 10000;
        indicator.hidesWhenStopped = YES;
    }
    
    self.indicator.hidden = NO;
    
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self.indicator viewWithTag:10000];
    [indicator startAnimating];
}

- (void)hiddenIndicator
{
    self.indicator.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)getData:(id)sender
{
    [self showIndicator];
    ///发送网路请求，框架将data返回给我
    __weakSelf
    [self testRequestWithDataCompletion:^(NSData *data, NSError *err) {
        __strongSelf
        if (data) {
            self.textView.text = [data description];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    }];
}

- (IBAction)getJSON:(id)sender
{
    [self showIndicator];
    ///发送网路请求，框架将JSON对象返回给我
    __weakSelf
    [self testRequestWithJSONCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.text = [json description];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    }];
}

- (IBAction)getModel:(id)sender
{
    __weakSelf
    ///发送网路请求，框架将Model对象返回给我
    [self testRequestWithModelCompletion:^(NSArray<TestModel *> *modelArr, NSError *err) {
        __strongSelf
        if (modelArr) {
            self.textView.text = [modelArr description];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    }];
}

- (IBAction)getFile:(id)sender
{
    __weakSelf
    ///
    [self testGetFileWithCompletion:^(NSString *path, NSError *err) {
        __strongSelf
        if (!err) {
            self.textView.text = [NSString stringWithFormat:@"文件下载成功：%@",path];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    }progress:^(float p) {
        __strongSelf
        self.textView.text = [NSString stringWithFormat:@"下载进度：%0.4f",p];
    }];
}

- (IBAction)postURLEncode:(id)sender
{
    __weakSelf
    ///
    [self testPostURLEncodeWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.text = [json description];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    }];
}

- (IBAction)postFormData:(id)sender
{
    __weakSelf
    ///
    [self testPostFormDataWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.text = [json description];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    }];
}

- (IBAction)postUploadFile:(id)sender
{
    __weakSelf
    ///
    [self testPostUploadFileWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.text = [json description];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    }progress:^(float p) {
        __strongSelf
        self.textView.text = [NSString stringWithFormat:@"上传进度：%0.4f",p];
    }];
}

- (void)testRequestWithDataCompletion:(void(^)(NSData *data,NSError *err))completion
{
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:kTestJSONApi params:nil];
    ///因为默认解析器是SCNJSONResponseParser；会解析成JSON对象；所以这里不指定解析器，让框架返回data！
    req.responseParser = nil;
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:req];
}

- (void)testRequestWithJSONCompletion:(void(^)(id json, NSError *err))completion
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
    .c_CompletionHandler(^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    });
    [[SCNetworkService sharedService]startRequest:req];
}

- (void)testRequestWithModelCompletion:(void(^)(NSArray <TestModel *>*arr, NSError *err))completion
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
    responseParser.modelKeyPath = @"content/entrance";
    req.responseParser = responseParser;
    
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    [[SCNetworkService sharedService]startRequest:req];
}

- (void)testGetFileWithCompletion:(void(^)(NSString *path,NSError *err))completion progress:(void(^)(float p))progress
{
    SCNetworkRequest *get = [[SCNetworkRequest alloc]initWithURLString:kTestDownloadApi2 params:nil];
//    NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:@"node.jpg"];
    NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:@"test.mp4"];
    NSLog(@"download path:%@",path);
    get.downloadFileTargetPath = path;
    get.responseParser = nil;
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

- (void)testPostURLEncodeWithCompletion:(void(^)(id json,NSError *err))completion
{
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestPostApi params:ps];
    post.parameterEncoding = SCNKParameterEncodingURL;
    [post addQueryParameters:@{
                               @"k3":@"v3",@"k4":@"v4"
                               }];
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

- (void)testPostFormDataWithCompletion:(void(^)(id json,NSError *err))completion
{
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestUploadApi params:ps];
    post.parameterEncoding = SCNKParameterEncodingFormData;
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


- (void)testPostUploadFileWithCompletion:(void(^)(id json,NSError *err))completion progress:(void(^)(float p))progress
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

