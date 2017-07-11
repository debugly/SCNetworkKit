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

- 综合参考了 MKNetwork2.0 和 AFNetwork 2.0 的设计，精简了他们的精华，去掉了冗余的设计，将网络请求抽象为 Request 对象，并由 Service 管理，Service 为 Request 分配代理对象 --- 处理传输数据、请求结束，请求失败等事件，请求结束后通过改变 Rquest 的 state 属性，告知 Request 请求结束，然后根据配置的响应解析器，异步解析数据，结果可能是 data, string, json, model, image 等等；最终通过我们添加到 Request 对象上的 completionBlock 回调给调用层。

设计图:

<img src="/asset/SCNetworkKit.png">

- 为了方便，提供了可用于整个 App 的共享 Service 对象发送请求；当然你也可以为不同的业务创建不同的网路请求 Service；一个 Service 则对应了一个 NSURLSession 对象！
