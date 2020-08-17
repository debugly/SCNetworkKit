//
//  ViewController.m
//  SCNMacDemo
//
//  Created by Matt Reach on 2018/11/26.
//  Copyright © 2018 互动创新事业部. All rights reserved.
//

#import "ViewController.h"
#import <SCNetworkKit/SCNetworkKit.h>
#import "TestModel.h"

#import "SCNHTTPParser.h"
#import "SCNJSONParser.h"
#import "SCNModelParser.h"

#define kTestJSONApi @"http://debugly.cn/repository/test.json"
#define kTestUploadApi @"http://localhost:3000/upload-file"
#define kTestPostApi @"http://localhost:3000/users"

#define kTestDownloadApi @"http://localhost:3000/images/node.jpg"
#define kTestDownloadApi2 @"http://debugly.github.io/repository/test.mp4"

#define kTestDownloadApi3 @"http://localhost.charlesproxy.com:3000/movie/aa.rmvb"
#define kTestDownloadApi4 @"http://localhost.charlesproxy.com/movie/aa.rmvb"

#define __weakSelf   typeof(self)weakself = self;
#define __strongSelf typeof(weakself)self = weakself;


#define USE_CUSTOM_PARSER 1

@interface ViewController ()

@property (nonatomic, weak) NSView *indicator;
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_12
@property (nonatomic, assign) IBOutlet NSTextView *textView;
#else
@property (nonatomic, weak) IBOutlet NSTextView *textView;
#endif

@property (nonatomic, assign) int counter;
@property (nonatomic, strong) NSMutableArray *serviceArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    if (@available(macOS 10.12, *)) {
        [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"并发数：%d",self.counter);
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (IBAction)testMutableSessionConcurrent:(id)sender
{
    static int i = 0;
    ///每次点击发送 step 个请求；
    static int step = 6;
    /*
     每次并发 6 个任务！wifi 时刚发达到最大并发限制！
     */
    SCNetworkService *service = [[SCNetworkService alloc] init];
    if (!_serviceArr) {
        _serviceArr = [NSMutableArray array];
    }
    [_serviceArr addObject:service];
    
    __weakSelf
    for (int j = i ; j < i + step; j ++) {
        //如果将url改为 kTestDownloadApi2,你会惊奇的发现，step改为 100 也没事，笔者测试发现，大约15s左右就能达到 100 个并发！这是因为 github 的 IP 比较多，所以看起来是没受到 6 个并发的限制一样，所以要理解清楚了，HTTPMaximumConnectionsPerHost 这一限制指的是主机，不是域名！更具体来讲是 IP + Port ！
        NSString *url = kTestDownloadApi4;
        SCNetworkDownloadRequest *get = [[SCNetworkDownloadRequest alloc]initWithURLString:url params:@{@"c":@(j)}];
        NSString *name = [NSString stringWithFormat:@"m%d.mp4",j];
        NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:name];
        NSLog(@"download path:%@",path);
        get.downloadFileTargetPath = path;
        get.responseParser = nil;
        [get addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
            NSLog(@"已完成");
            __strongSelf
            self.counter --;
        }];
        
        [get addProgressChangedHandler:^(SCNetworkRequest *request, int64_t thisTransfered, int64_t totalBytesTransfered, int64_t totalBytesExpected) {
            //收到数据后，认为连接建立成功，并发数 ++
            __strongSelf
            if (!request.tag) {
                request.tag = @"1";
                self.counter ++;
            }
        }];
        
        [service startRequest:get];
    }
    i += step;
    
}

- (IBAction)testSingleSessionConcurrent:(id)sender
{
    static int i = 0;
    ///每次点击发送 step 个请求；
    static int step = 7;
    /*
     使用单利 service 意味着底层使用同一个 session；[SCNetworkService sharedService];
     跟使用多个 service 的却别是，当请求连接的是同一主机时，最大连接数就会限制为HTTPMaximumConnectionsPerHost 指定的数量，在默认配置下使用 wifi 网络默认是 6 ！之前版本我设置的是 2; 从 1.0.12 开始解除这一限制，从而开启更大的并发数量！
     */
    
    SCNetworkService *service = [SCNetworkService sharedService];
    
    __weakSelf
    for (int j = i ; j < i + step; j ++) {
        NSString *url = kTestDownloadApi4;
        ///注释打开，则能达到 7 个并发，否者只能是 6 个而已；因为相同IP的不同端口被认为是不同的主机！
//        if (j % 2 == 0) {
//            url = kTestDownloadApi3;
//        } else {
//            url = kTestDownloadApi4;
//        }
        SCNetworkDownloadRequest *get = [[SCNetworkDownloadRequest alloc]initWithURLString:url params:@{@"c":@(j)}];
        NSString *name = [NSString stringWithFormat:@"s%d.mp4",j];
        NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:name];
        NSLog(@"download path:%@",path);
        get.downloadFileTargetPath = path;
        get.responseParser = nil;
        [get addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
            NSLog(@"已完成");
            __strongSelf
            self.counter --;
        }];
        
        [get addProgressChangedHandler:^(SCNetworkRequest *request, int64_t thisTransfered, int64_t totalBytesTransfered, int64_t totalBytesExpected) {
           //收到数据后，认为连接建立成功，并发数 ++
            __strongSelf
            if (!request.tag) {
                request.tag = @"1";
                self.counter ++;
            }
        }];
    
        [service startRequest:get];
    }
    i += step;
    
}

- (void)showIndicator
{
    if (!self.indicator) {
        NSView *mask = [NSView new];
        [self.view addSubview:mask];
        mask.frame = self.view.bounds;
        mask.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        mask.wantsLayer = YES;
        mask.layer.backgroundColor = [[NSColor colorWithWhite:0.5 alpha:0.5]CGColor];
        
        self.indicator = mask;
        
        NSProgressIndicator *indicator = [[NSProgressIndicator alloc]init];
        [indicator setStyle:NSProgressIndicatorStyleSpinning];
        [mask addSubview:indicator];
        [indicator sizeToFit];
        [indicator setFrameOrigin:NSMakePoint(
                                            (NSWidth([mask bounds]) - NSWidth([indicator frame])) / 2,
                                            (NSHeight([mask bounds]) - NSHeight([indicator frame])) / 2
                                            )];
        [indicator setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];

        [indicator startAnimation:nil];
        indicator.displayedWhenStopped = NO;
    }
    
    self.indicator.hidden = NO;
    
    NSProgressIndicator *indicator = (NSProgressIndicator *)[[self.indicator subviews]firstObject];
    [indicator startAnimation:nil];
}

- (void)hiddenIndicator
{
    self.indicator.hidden = YES;
}

- (IBAction)getData:(id)sender
{
    [self showIndicator];
    ///发送网路请求，框架将data返回给我
    __weakSelf
    [self testRequestWithDataCompletion:^(NSData *data, NSError *err) {
        __strongSelf
        if (data) {
            self.textView.string = [data description];
        }else{
            self.textView.string = [err description];
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
            self.textView.string = [json description];
        }else{
            self.textView.string = [err description];
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
            self.textView.string = [modelArr description];
        }else{
            self.textView.string = [err description];
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
            self.textView.string = [NSString stringWithFormat:@"文件下载成功：%@",path];
        }else{
            self.textView.string = [err description];
        }
        [self hiddenIndicator];
    }progress:^(float p) {
        __strongSelf
        self.textView.string = [NSString stringWithFormat:@"下载进度：%0.4f",p];
    }];
}

- (IBAction)postURLEncode:(id)sender
{
    __weakSelf
    ///
    [self testPostURLEncodeWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.string = [json description];
        }else{
            self.textView.string = [err description];
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
            self.textView.string = [json description];
        }else{
            self.textView.string = [err description];
        }
        [self hiddenIndicator];
    }];
}

- (IBAction)postUploadFiles:(id)sender
{
    __weakSelf
    ///
    [self testPostUploadFileWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.string = [json description];
        }else{
            self.textView.string = [err description];
        }
        [self hiddenIndicator];
    }progress:^(float p) {
        __strongSelf
        self.textView.string = [NSString stringWithFormat:@"上传进度：%0.4f",p];
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
    
    [req addReceivedResponseHandler:^(SCNetworkRequest *request, NSURLResponse *response) {
        NSLog(@"response:%@",response);
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
#if USE_CUSTOM_PARSER
    /// BlockResponseParser 给予了自定义解析的全过程，每个环境都可以根据业务去控制；并且这一过程是在子线程里完成的！
    
    SCNBlockResponseParser *customParser = [SCNBlockResponseParser blockParserWithCustomProcess:^id(NSHTTPURLResponse *response, NSData *data, NSError *__autoreleasing *error) {
        
        SCNHTTPParser *httpParser = [SCNHTTPParser new];
        httpParser.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
        
        id httpData = [httpParser objectWithResponse:response data:data error:error];
        
        if(httpData){
            SCNJSONParser *jsonParser = [SCNJSONParser new];
            jsonParser.checkKeyPath = @"code";
            jsonParser.okValue = @"0";
            id json = [jsonParser jsonWithData:httpData error:error];
            
            if (json) {
                SCNModelParser *modelParser = [SCNModelParser new];
                modelParser.modelName = @"TestModel";
                modelParser.modelKeyPath = @"content/entrance";
                
                id model = [modelParser modelWithJson:json error:error];
                
                if (model) {
                    return model;
                }
            }
        }
        return nil;
    }];
    
    req.responseParser = customParser;
#else
    SCNModelResponseParser *responseParser = [SCNModelResponseParser parser];
    ///解析前会检查下JSON是否正确；
    responseParser.checkKeyPath = @"code";
    responseParser.okValue = @"0";
    ///根据服务器返回数据的格式和想要解析结构对应的Model配置解析器
    responseParser.modelName = @"TestModel";
    responseParser.modelKeyPath = @"content/entrance";
    req.responseParser = responseParser;
#endif
    
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    [[SCNetworkService sharedService]startRequest:req];
}

- (void)testGetFileWithCompletion:(void(^)(NSString *path,NSError *err))completion progress:(void(^)(float p))progress
{
    SCNetworkDownloadRequest *get = [[SCNetworkDownloadRequest alloc]initWithURLString:kTestDownloadApi2 params:nil];
    //    NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:@"node.jpg"];
    NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:@"test.mp4"];
    NSLog(@"download path:%@",path);
    get.downloadFileTargetPath = path;
    get.useBreakpointContinuous = NO;
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

- (void)testPostFormDataWithCompletion:(void(^)(id json,NSError *err))completion
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

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
