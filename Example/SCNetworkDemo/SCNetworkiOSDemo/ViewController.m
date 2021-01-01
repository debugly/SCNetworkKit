//
//  ViewController.m
//  SCNDemo
//
//  Created by Matt Reach on 2017/7/21.
//  Copyright © 2017年 debuly.cn. All rights reserved.
//

#import "ViewController.h"
#import <SCNetworkKit/SCNetworkKit.h>
#import "TestModel.h"
#import "SCApiTester.h"
#import "SectionModel.h"

#define __weakSelf   typeof(self)weakself = self;
#define __strongSelf typeof(weakself)self = weakself;


#define USE_CUSTOM_PARSER 1

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) UIView *indicator;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSArray <SectionModel *>*sections;

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
    
    SectionModel *section0 = [SectionModel new];
    section0.title = @"Get";
    section0.rows = @[
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Get-Data";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self getData];
            };
            ;row0;
        }),
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Get-JSON";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self getJSON];
            };
            ;row0;
        }),
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Get-Model";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self getModel];
            };
            ;row0;
        }),
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Get-File";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self getFile];
            };
            ;row0;
        })
    ];
    
    SectionModel *section1 = [SectionModel new];
    section1.title = @"Post";
    section1.rows = @[
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Post-No Body";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self postNoBody];
            };
            ;row0;
        }),
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Post-JSON";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self postJSON];
            };
            ;row0;
        }),
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Post-URLEncoding";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self postURLEncoding];
            };
            ;row0;
        }),
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Post-FormData";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self postFormData];
            };
            ;row0;
        }),
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Post-UploadFile";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self postUploadFile];
            };
            ;row0;
        }),
        ({
            RowModel *row0 = [RowModel new];
            row0.title = @"Post-DownloadFile";
            __weakSelf
            row0.action = ^(RowModel *r){
                __strongSelf
                [self postDownloadFile];
            };
            ;row0;
        })
    ];
    
    self.sections = @[section0, section1];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    SectionModel *sec = [self.sections objectAtIndex:section];
    return [sec.rows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    SectionModel *sec = [self.sections objectAtIndex:section];
    return sec.title;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SectionModel *sec = [self.sections objectAtIndex:indexPath.section];
    RowModel *row = sec.rows[indexPath.row];
    cell.textLabel.text = row.title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SectionModel *sec = [self.sections objectAtIndex:indexPath.section];
    RowModel *row = sec.rows[indexPath.row];
    if (row.action) {
        row.action(row);
    }
}

- (void)getData
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

- (void)getJSON
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

- (void)getModel
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

- (void)getFile
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

- (void)postNoBody {
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

- (void)postJSON
{
    __weakSelf
    ///
    [SCApiTester postJSONWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.text = [json description];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    }];
}

- (void)postURLEncoding
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

- (void)postFormData
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

- (void)postUploadFile
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
        self.textView.text = [NSString stringWithFormat:@"progress:%0.4f",p];
    }];
}

- (void)postDownloadFile
{
    __weakSelf
    ///
    [SCApiTester postDownloadFileWithCompletion:^(id json, NSError *err) {
        __strongSelf
        if (json) {
            self.textView.text = [json description];
        }else{
            self.textView.text = [err description];
        }
        [self hiddenIndicator];
    } progress:^(float p) {
        __strongSelf
        self.textView.text = [NSString stringWithFormat:@"progress:%0.4f",p];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

