## SCNetworkKit

SCNetworkKit 是一个结合了 [MKNetworkKit](https://github.com/MugunthKumar/MKNetworkKit) 和 [AFNetworking](https://github.com/AFNetworking/AFNetworking) 架构的网络库，融入了自己的一些最佳实践。

- 最低支持 iOS 7.0 / OS X 10.9
- 使用 Objective-C 语言编写
- 底层封装了 NSURLSession
- 采用 Service + Request 分工模式；从 MKNetworkKit 学习而来
- 采用可配置的响应解析器模式，可以将数据异步解析为 JSON，Model，其中 Model 解析这块算是对 AFNetworking 响应解析模块学习的一个升华，按照自己的思路去完成的
- 采用 Maker 方式精简对外公开的API长度，使用更方便；从 [Masonry](https://github.com/desandro/masonry) 学习而来
- 支持了 HTTPBodyStream，轻松搞定大文件上传；可以说是弥补了 MKNetworkKit 的一个缺憾
- 自创自动取消机制，可在某个对象（通常是UIViewController）销毁时自动取消已经发起的网络请求
- 支持链式编程
- 完成，进度回调等完全 Block 化，没有支持代理（个人偏爱 Block）

## SCNetworkKit 演变过程

有段时间我专业从事 SDK 的开发工作，要确保提供出去的 SDK 容易集成，防止由于类冲突导致的报错问题，所以要尽量避免依赖开源库！我需要一个稳定的网络请求框架，能够为 SDK 提供可靠的网络服务，因此有了如下演变过程:

`SVPNetworkKit` -> `SLNetworkKit` -> `SCNetworkKit`

- SVPNetworkKit : 为上传模块写的一个独立的网络请求模块，是完全基于 MKNetworkKit 的，毫不保留的说就是在 MKNetworkKit 之上修改而成的，并没有大的创新。
- SLNetworkKit : 转向 SDK 开发工作后，不想让 SDK 和日后集成的 APP 产生库冲突，因此决定使用 SVPNetworkKit 的基础上改。这个阶段主要对调用API采用 Maker 方式重新设计、支持了Model解析、响应异步解析、自动取消机制等。
- SCNetworkKit : 随着 SDK 业务的增多，SL这个前缀已经不符合当下了，所以提取了一个核心库，故而改前缀为 SC ！这个阶段主要将POST请求抽取出来，支持了HTTPBodyStream，方便大文件上传！

## 目录结构

```
├── LICENSE
├── README.md
├── SCNDemo
├── SCNetworkKit
├── SCNetworkKit.podspec
├── Server
└── _config.yml
```

- SCNDemo : 可直接运行的 Demo（有可能需要修改下接口 API 地址）
- SCNetworkKit : 库源码
- Server : 使用 Express 库编写的服务器，主要为 Demo 提供 POST 请求支持，客户端上传的文件都放在 `Server/upload` 文件夹下面。
    - 查看已经上传的文件: [http://localhost:3000/peek](http://localhost:3000/peek) 
    - 查看已经上传的文件（json形式）: [http://localhost:3000/peek?json=1](http://localhost:3000/peek?json=1) 
    - 使用浏览器上传的文件: [http://localhost:3000/](http://localhost:3000/) 

Server 使用方法:

```shell
cd Server
//第一次运行需要安装下依赖库，以后执行就不用了
npm install
npm start
```

## 安装方式

- 使用 CocoaPods 安装

    ```
    source 'https://github.com/CocoaPods/Specs.git'
    platform :ios, '7.0'
    
    target 'TargetName' do
    pod 'SCNetworkKit', '~> 1.0.6'
    end
    ```

- 使用源码

    下载最新 [release](https://github.com/debugly/SCNetworkKit/releases) 代码，找到 SCNetworkKit 目录，拖到工程里即可。


## 使用范例

假设服务器返回的数据格式如下：

```
{ 
  code = 0;
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

```

下面演示如何通过配置不同的解析器，从而达到着陆 block 回调不同结果的效果:


- 发送 GET请求，回调原始Data，不做解析

    ```objc
    SCNetworkRequest *req = [[SCNetworkRequest alloc]initWithURLString:@"http://debugly.cn/dist/json/test.json" params:nil httpMethod:@"GET"];
        ///因为默认解析器是SCNJSONResponseParser；会解析成JSON对象；所以这里不指定解析器，让框架返回data！
        req.responseParser = nil;
        [req addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
            
            if (completion) {
                completion(result);
            }
        }];
    [[SCNetworkService sharedService]sendRequest:req];
    ```

- 发送 GET请求，回调 JOSN 对象

    ```objc
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
    ```

- 发送 GET请求，回调 Model 对象

    ```objc
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
    ```

由于上面有 JSON 转 Model 的过程，因此在使用之前需要注册一个对应的解析器，你可以到 demo 里搜下 **[SCNModelResponseParser registerModelParser:[SCNModelParser class]];** 具体看下究竟。

- 文件下载

    ```objc
    SCNetworkRequest *get = [[SCNetworkRequest alloc]initWithURLString:kTestDownloadApi2 params:nil];
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
    ```

- 文件上传

    ```objc
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestUploadApi params:ps];
    
    SCNetworkFormFilePart *filePart = [SCNetworkFormFilePart new];
    filePart.fileURL = [[NSBundle mainBundle]pathForResource:@"node" ofType:@"jpg"];
    filePart.fileName = @"test.jpg";
    
    SCNetworkFormFilePart *filePart2 = [SCNetworkFormFilePart new];
    filePart2.fileURL = [[NSBundle mainBundle]pathForResource:@"node" ofType:@"txt"];
    filePart2.fileName = @"test.txt";
    
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
    ```

- 通过表单POST数据

    ```objc
    NSDictionary *ps = @{@"name":@"Matt Reach",@"k1":@"v1",@"k2":@"v2",@"date":[[NSDate new]description]};
    SCNetworkPostRequest *post = [[SCNetworkPostRequest alloc]initWithURLString:kTestUploadApi params:ps];
    post.parameterEncoding = SCNKParameterEncodingFormData;
    [post addCompletionHandler:^(SCNetworkRequest *request, id result, NSError *err) {
        
        if (completion) {
            completion(result,err);
        }
    }];
    
    [[SCNetworkService sharedService]startRequest:post];
    ```

## 链式编程

```
SCNJSONResponseParser *responseParser = [SCNJSONResponseParser parser];
///框架会检查接口返回的 code 是不是 0 ，如果不是 0 ，那么返回给你一个err，并且result是 nil;
responseParser.checkKeyPath = @"code";
responseParser.okValue = @"0";
    
///support chain
    
SCNetworkRequest *req = [[SCNetworkRequest alloc]init];
    
req.c_URL(@"http://debugly.cn/dist/json/test.json")
   .c_ResponseParser(responseParser);
   .c_CompletionHandler(^(SCNetworkRequest *request, id result, NSError *err) {
        
            if (completion) {
                completion(result);
            }
       });
[[SCNetworkService sharedService]sendRequest:req];
```


## 架构设计

- 综合参考了 MKNetwork2.0 和 AFNetwork 2.0 的设计，精简了他们的精华，去掉了冗余的设计，融入了自己的想法，将网络请求抽象为 Request 对象，并由 Service 管理，Service 为 Request 分配代理对象 --- 处理传输数据、请求结束，请求失败等事件，请求结束后通过改变 Rquest 的 state 属性，告知 Request 请求结束，然后根据配置的响应解析器，异步解析数据，结果可能是 data, string, json, model, image 等等；最终通过我们添加到 Request 对象上的 completionBlock 回调给调用层。

设计图:

<img src="http://debugly.cn/images/SCNetworkKit/SCNetworkKit.png">

## 采用注册的方式解耦和

功能强大的同时要顾及到扩展性，本框架支持很多扩展，以响应解析为例，你可以继续创建你想要的解析器；可以使用你喜欢的 JOSN 转 Model 框架来做解析；可以让网络库解析更多格式的图片；这些都是可以做到的，并且还很简单。

- 由于框架配备了支持 JSON 转 Model 的 SCNModelResponseParser 响应解析器，那么就不得不依赖于 JSON 转 Model 的框架，考虑到项目中很可能已经有了这样的框架，因此并没有将这块逻辑写死，而是采用注册的方式，来扩展 SCN 的能力！所以使用 Model 解析器之前必须注册 一个用于将 JOSN 转为 Model 的类，该类实现 SCNModelParserProtocol 协议！为了方便，最好是在APP启动后就注册，或者创建 Service 的时候创建，以免使用的时候还没注册，导致崩溃！

    ```objc
    @protocol SCNModelParserProtocol <NSObject>
    
    @required;
    + (id)fetchSubJSON:(id)json keyPath:(NSString *)keypath;
    + (id)JSON2Model:(id)json modelName:(NSString *)mName;
    
    @end
    
    @interface SCNModelResponseParser : SCNJSONResponseParser
    
    @property (nonatomic,copy) NSString *modelName;
    @property (nonatomic,copy) NSString *modelKeyPath;
    
    + (void)registerModelParser:(Class<SCNModelParserProtocol>)parser;
    
    @end
    
    ```

我在 demo 里面使用的是我的另外一个轮子：[SCJSONUtil](https://github.com/debugly/SCJSONUtil) ；具体实现可查看demo。


- 图片解析器默认支持 png、jpg 图片格式，当下 webp 格式由于体积更小，很多厂商开始使用，我的 SDK 里也用到了这个格式，因此我在 SDK 里注册了解析 webp 的解析类；

    ```objc
    @protocol SCNImageParserProtocol <NSObject>
    
    @required;
    + (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale;
    
    @end
    
    ///默认支持png 和 jpg；可通过注册的方式扩展！
    @interface SCNImageResponseParser : SCNHTTPResponseParser
    
    
    /**
     注册新的图片解析器和对应的类型
    
     @param parser 解析器
     @param mime 支持的类型
     */
    + (void)registerParser:(Class<SCNImageParserProtocol>)parser forMime:(NSString *)mime;
    
    @end
    
    ```

这种注册器的方式优雅地扩充了网络库的功能，就好比插件一样，插上就能用，只需要规格上符合我协议里规定的要求即可！反之，如果你不需要解析 webp， 你不需要 json 转 model 的话，你就没必要去插对应的模块！

如果没有注册器这么一个好的实践的话，要达到同样的扩展效果可能就很难了！如果你有别的点子请联系我。

## SCNetworkService

由上图可知，SCNetworkService 主要起到了发起网络请求，处理好 Request，task，delegate 对象的一一对应关系的作用！

- 为了方便使用，还提供了可用于整个 App 的共享 SCNetworkService 对象，用来发送普通的网络请求；当然你也可以为不同的业务创建不同的 Service；一个 Service 则对应了一个 NSURLSession 对象！

## SCNetworkRequest

NSURLSession 管理的网络请求结束后，会在 SCNetworkRequest 里处理响应数据，根据配置的 ResponseParser 去异步解析，最终在主线程里安全着陆；

- SCNetworkRequest 从 start 开始被 Service 持有，直到着陆后 Service 不再持有，因此上层可以不持有 SCNetworkRequest 对象！如果要拥有 SCNetworkRequest 对象的指针，一般使用 weak 即可；

- SCNetworkRequest 支持添加多个回调，回调顺序跟添加的顺序一样；
- 注意添加回调的时候，不要让 SCNetworkRequest 持有你的对象，否则 SCNetworkRequest 会一直持有，直到着陆；

## SCNetworkPostRequest

继承了 SCNetworkRequest，专门用于发送 POST 请求，支持四种编码方式:

- SCNKParameterEncodingURL : application/x-www-form-urlencoded;
- SCNKParameterEncodingJSON : application/json;
- SCNKParameterEncodingPlist : application/x-plist;
- SCNKParameterEncodingFormData : multipart/form-data;

只有使用 SCNKParameterEncodingFormData 方式的请求采用 HTTPBodyStream ！

## 版本

- 1.0.5 : 支持 stream HTTPBody，轻松搞定大文件上传
- 1.0.6 : 支持一次上传多个文件，配套 Node 上传文件服务器
- 1.0.7 : 修复直接使用二进制上传失败问题（重复计算长度，导致Content Length计算偏大）
- 1.0.8 : 支持 macOS 平台 (暂不支持图片解析)
- 1.0.9 :  整理目录，POST 请求可添加 Query 参数
- 1.0.10 : 修改默认UA格式
- 1.0.11 : 抽取解析过程，可完全自定义；支持 JSONUtil 的动态映射

## 完

如有问题，或者需要 SCNetworkKit 提供更强大的功能，请提 issue 给我，3q！
