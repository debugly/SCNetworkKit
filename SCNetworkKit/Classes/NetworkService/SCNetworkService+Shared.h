//
//  SCNetworkService+Shared.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2017/2/28.
//  Copyright © 2017年 debugly.cn. All rights reserved.
//

/*
 
 是否应该使用这个单利？有哪些坑？
 ----------------------------
 笔者建议为业务层网络请求分成不同的类别；不同的类别使用不同的 SCNetworkService 对象管理！
 举例说明，假设你为业务层用到的 API 抽取了接口层，那么接口层有必要单独使用一个 SCNetworkService 对象；
 然后所有的图片请求应该也是走统一出口的，也有必要单独使用一个 SCNetworkService 对象；
 可能你还有上传，下载的功能；那么应当为他们提供单独的 SCNetworkService 对象；
 至于将这个单利对象用在哪个模块层面完全由使用者决定（也可以忽略这个单利）！
 
 为什么要为不同业务层提供独立的 SCNetworkService ？
 ----------------------------
 因为 SCNetworkKit 底层是基于 NSURLSession 的，NSURLSession 对象对于同一主机的最大连接数是有限制的！具体跟创建 Session 是的 config.HTTPMaximumConnectionsPerHost 有关系；这个值在 Wifi 情况下默认是 6 ！
 当业务层所有模块的接口都对应一个主机时，碰巧的是你使用了单一的 SCNetworkService 对象管理了所有请求时，那么你的App就会出现严重的问题：
 1、你的下载任务并发数不可能大于 6 ！
 2、当你的下载任务等于 6 时，可能你的其他业务请求不回来接口数据，抓包查看发现请求压根没发出去；除非下载任务完成或断开！
 3、当很多图片需要加载时，“接口被阻塞，请求不到用户评论数据”（臆想的需求）
 ......
 
 开发者应该做出一个合理的权衡，一定不要整个 App 共享一个 SCNetworkService 对象，虽然笔者提供了单利，这并不意味着笔者提倡这么做。当然也没有必要每个请求都创建一个 SCNetworkService 对象，这样会使 NSURLSession 的优势丧失，浪费系统资源。
 
 ----------------------------
 
 */
#import "SCNetworkService.h"

@interface SCNetworkService (Shared)

/// 获取单例
+ (instancetype)sharedService;

@end
