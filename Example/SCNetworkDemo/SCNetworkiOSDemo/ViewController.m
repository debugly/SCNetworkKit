//
//  ViewController.m
//  SCNDemo
//
//  Created by xuqianlong on 2017/7/21.
//  Copyright © 2017年 xuqianlong. All rights reserved.
//

#import "ViewController.h"
#import <SCNetworkKit/SCNetworkKit.h>
#import "TestModel.h"
#import "SCApiTester.h"

#define __weakSelf   typeof(self)weakself = self;
#define __strongSelf typeof(weakself)self = weakself;


#define USE_CUSTOM_PARSER 1

@interface ViewController ()

@property (nonatomic, weak) UIView *indicator;
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
    [SCApiTester getRequestWithDataCompletion:^(NSData *data, NSError *err) {
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
    [SCApiTester getRequestWithJSONCompletion:^(id json, NSError *err) {
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
    [SCApiTester getRequestWithModelCompletion:^(NSArray<TestModel *> *modelArr, NSError *err) {
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
    [SCApiTester getFileWithCompletion:^(NSString *path, NSError *err) {
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

- (IBAction)postNoBody:(id)sender {
    __weakSelf
    [SCApiTester postNoBodyWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.text = [json description];
        }else{
            self.textView.text = [err description];
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
    [SCApiTester postFormDataWithCompletion:^(id json, NSError *err) {
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
    [SCApiTester postUploadFileWithCompletion:^(id json, NSError *err) {
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

