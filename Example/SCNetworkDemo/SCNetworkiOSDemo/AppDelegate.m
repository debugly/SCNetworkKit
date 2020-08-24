//
//  AppDelegate.m
//  SCNetworkiOSDemo
//
//  Created by Matt Reach on 2020/8/24.
//

#import "AppDelegate.h"
#import "SCNJson2ModelParser.h"
#import <SCNetworkKit/SCNModelResponseParser.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //如果你不需要网络请求框架，帮你搞定 JSON 转 Model 的，那么你就需要下面的注册！
    {
        ///通过注册的方式，让 SCJSONUtil 和 网络库解耦合;如果你的工程里有其他解析框架，只需修改 SCNModelParser 里的几个方法即可！
        
        ///使用网络请求之前注册好！
        [SCNModelResponseParser registerModelParser:[SCNJson2ModelParser class]];
    }
    

    return YES;
}

@end
