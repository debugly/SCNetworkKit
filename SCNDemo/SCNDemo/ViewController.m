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
#import "TestModel.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    ///发送网路请求，框架将data返回给我
    [self testRequestWithDataCompletion:^(NSData *data) {
        NSLog(@"get data:%@",data);
    }];
    
    ///发送网路请求，框架将JSON对象返回给我
    __weak typeof(self)weakself = self;
    [self testRequestWithJSONCompletion:^(id json) {
        __strong typeof(weakself)self = weakself;
        if (json) {
            self.textView.text = [result description];
        }else{
            self.textView.text = [err description];
        }
    }];
    
    ///发送网路请求，框架将Model对象返回给我
    [self testRequestWithModelCompletion:^(NSArray<TestModel *> *modelArr) {
        NSLog(@"get models:%@",modelArr);
    }];

    
}

- (void)testRequestWithDataCompletion:(void(^)(NSData *data))completion
{
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:@"http://debugly.cn/dist/json/test.json" params:nil httpMethod:@"GET"];
    ///因为默认解析器是SCNJSONResponseParser；会解析成JSON对象；所以这里不指定解析器，让框架返回data！
    req.responseParser = nil;
    [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result);
        }
    }];
    
    [[SCNetworkService sharedService]sendRequest:req];
}

- (void)testRequestWithJSONCompletion:(void(^)(id json))completion
{
    SCNJSONResponseParser *responseParser = [SCNJSONResponseParser parser];
    ///框架会检查接口返回的 code 是不是 0 ，如果不是 0 ，那么返回给你一个err，并且result是 nil;
    responseParser.checkKeyPath = @"code";
    responseParser.okValue = @"0";
    
    ///support chain
    
    SCNetworkRequest *req = [[SCNetworkRequest alloc]init];
    
    req.c_URL(@"http://debugly.cn/dist/json/test.json")
    .c_Method(@"GET")
    .c_ResponseParser(responseParser)
    .c_CompletionHandler(^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result);
        }
    });
    [[SCNetworkService sharedService]sendRequest:req];
}

- (void)testRequestWithModelCompletion:(void(^)(NSArray <TestModel *>*))completion
{
    /*
     ////服务器响应数据结构////
     
     {code = 0;
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
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:@"http://debugly.cn/dist/json/test.json" params:nil httpMethod:@"GET"];
    
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
            completion(result);
        }
    }];
    [[SCNetworkService sharedService]sendRequest:req];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
