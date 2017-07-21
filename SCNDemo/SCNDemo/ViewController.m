//
//  ViewController.m
//  SCNDemo
//
//  Created by xuqianlong on 2017/7/21.
//  Copyright © 2017年 xuqianlong. All rights reserved.
//

#import "ViewController.h"
#import <SCNetworkKit/SCNetworkKit.h>
#import <SCJSONUtil/SCJSONUtil.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    __weak typeof(self)weakself = self;
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:@"http://debugly.cn/dist/json/test.json" params:nil httpMethod:@"GET"];
    [req addCompletionHandler:^(SCNetworkRequest *request, NSDictionary *result, NSError *err) {
        __strong typeof(weakself)self = weakself;
        if (result) {
            self.textView.text = [result description];
        }else{
            self.textView.text = [err description];
        }
    }];
    [[SCNetworkService sharedService]sendRequest:req];
    
    
    [NSString sc_instanceFormDic:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
