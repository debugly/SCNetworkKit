# SCNetworkKit

SCNetworkKit is a simple but powerful iOS network framework based on NSURLSession and NSURLSessionConfiguration, written by Objective-C, Support iOS 7+ ;

# 为什么创建这个轮子 ？

因为我在做 SDK，而不是 App;我要确保提供出去的 SDK 不对外产生依赖，以防由于依赖的环境问题影响到了SDK的功能！因此我需要一个稳定的网络请求框架，能够为 SDK 提供可靠的网络服务！

# 特性

- 简单；你可以很方法的发出一个网络请求；然后框架会根据配置的解析器，异步解析响应数据，把结果回调给你；
- 异步解析响应数据；网络框架提供了共享的异步解析队列，在解析响应数据时不会卡住主线程，解析完毕后将结果通过 block 回调给使用者；
- 回调完全 block 化；所有的回调均采用了 block 回调的形式完成；
- 支持一般的网络请求，也支持文件下载；

# 架构设计

- 综合参考了 MKNetwork2.0 和 AFNetwork 2.0 的设计，精简了他们的精华，去掉了冗余的设计，融入了自己的想法，将网络请求抽象为 Request 对象，并由 Service 管理，Service 为 Request 分配代理对象 --- 处理传输数据、请求结束，请求失败等事件，请求结束后通过改变 Rquest 的 state 属性，告知 Request 请求结束，然后根据配置的响应解析器，异步解析数据，结果可能是 data, string, json, model, image 等等；最终通过我们添加到 Request 对象上的 completionBlock 回调给调用层。

设计图:

<img src="http://debugly.cn/images/SCNetworkKit/SCNetworkKit.png">

# 采用注册的方式解耦和

功能强大的同时要顾及到扩展性，本框架支持很多扩展，以响应解析为例，你可以继续创建你想要的解析器；可以使用你喜欢的 JOSN 转 Model 框架来做解析；可以让网络库解析更多格式的图片；这些都是可以做到的，并且还很简单。

- 由于框架配备了支持 JSON 转 Model 的 SCNModelResponseParser 响应解析器，那么就不得不依赖于 JSON 转 Model 的框架，考虑到项目中很可能已经有了这样的框架，因此并没有将这块逻辑写死，而是采用注册的方式，来扩展 SCN 的能力！所以使用 Model 解析器之前必须注册 一个用于将 JOSN 转为 Model 的类，该类实现 SCNModelParserProtocol 协议！为了方便，最好是在APP启动后就注册，或者创建 Service 的时候创建，以免使用的时候还没注册，导致崩溃！

```
@protocol SCNModelParserProtocol <NSObject>

@required;
+ (id)fetchSubJSON:(id)json keyPath:(NSString *)keypath;
+ (id)JSON2Model:(id)json modelName:(NSString *)mName;
+ (id)JSON2StringValueJSON:(id)json;

@end

@interface SCNModelResponseParser : SCNJSONResponseParser

@property (nonatomic,copy) NSString *modelName;
@property (nonatomic,copy) NSString *modelKeyPath;

+ (void)registerModelParser:(Class<SCNModelParserProtocol>)parser;

@end

```

我在 demo 里面使用的是我的另外一个轮子：[SCJSONUtil](https://github.com/debugly/SCJSONUtil) ；具体实现可查看demo。


- 图片解析器默认支持 png、jpg 图片格式，当下 webp 格式由于体积更小，很多厂商开始使用，我的 SDK 里也用到了这个格式，因此我在 SDK 里注册了解析 webp 的解析类；

```
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

-----------------------------------------

如有问题，或者需要 SCNetworkKit 提供更强大的功能，请提 issue 给我，3q！