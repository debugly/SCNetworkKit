//
//  ViewController.m
//  SCNetworkDemo
//
//  Created by xuqianlong on 2017/7/10.
//  Copyright © 2017年 xuqianlong. All rights reserved.
//

#import "ViewController.h"

#import "SCNetworkKit.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:@"http://debugly.cn/dist/json/test.json" params:nil httpMethod:@"GET"];
    
    req.responseParser = [SCNJSONResponseParser parser];
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        NSLog(@"get json:%@",result);
    }];
    [[SCNetworkService sharedService]sendRequest:req];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
