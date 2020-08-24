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
#import "SCApiTester.h"

#define __weakSelf   typeof(self)weakself = self;
#define __strongSelf typeof(weakself)self = weakself;


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
    
    if (@available(macOS 10.12, *)) {
        [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"并发数：%d",self.counter);
        }];
    } else {
        // Fallback on earlier versions
    }
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
    
    if (@available(macOS 10.12, *)) {
        [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"并发数：%d",self.counter);
        }];
    } else {
        // Fallback on earlier versions
    }
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
    [SCApiTester getRequestWithDataCompletion:^(NSData *data, NSError *err) {
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
    [SCApiTester getRequestWithJSONCompletion:^(id json, NSError *err) {
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
    [SCApiTester getRequestWithModelCompletion:^(NSArray<TestModel *> *modelArr, NSError *err) {
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
    [SCApiTester getFileWithCompletion:^(NSString *path, NSError *err) {
        __strongSelf
        if (!err) {
            self.textView.string = [NSString stringWithFormat:@"文件下载成功：\n%@",path];
        } else {
            self.textView.string = [NSString stringWithFormat:@"文件下载失败：\n%@",[err description]];
        }
        [self hiddenIndicator];
    } progress:^(float p) {
        __strongSelf
        self.textView.string = [NSString stringWithFormat:@"下载进度：%0.4f",p];
    }];
}

- (IBAction)testBasicPost:(id)sender
{
    __weakSelf
    [SCApiTester postNoBodyWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.string = [json description];
        }else{
            self.textView.string = [err description];
        }
        [self hiddenIndicator];
    }];
}

- (IBAction)postURLEncode:(id)sender
{
    __weakSelf
    ///
    [SCApiTester postURLEncodeWithCompletion:^(id json, NSError *err) {
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
    [SCApiTester postFormDataWithCompletion:^(id json, NSError *err) {
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
    [SCApiTester postUploadFileWithCompletion:^(id json, NSError *err) {
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

@end
