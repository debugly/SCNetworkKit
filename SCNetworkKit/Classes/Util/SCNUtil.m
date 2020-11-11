//
//  SCNUtil.h
//  SCNetWorkKit
//
//  Created by Matt Reach on 2020/8/18.
//  Copyright © 2020年 debugly.cn. All rights reserved.
//
#import "SCNUtil.h"
#import <sys/sysctl.h>
#import "NSString+SCAddtions.h"

NSString *const SCNErrorDomain = @"com.debugly.SCNetWorkKit";

NSError * SCNError(NSInteger code,id info)
{
    if(!info){
        info = @"未知错误";
    }
    NSDictionary *infoDic = nil;
    if(![info isKindOfClass:[NSDictionary class]]){
        infoDic = @{NSLocalizedDescriptionKey:info};
    }else{
        infoDic = info;
    }
    return [[NSError alloc] initWithDomain:SCNErrorDomain code:code userInfo:infoDic];
}


@implementation SCNUtil

/*
 SCNetworkRequest默认UA格式如下:
 %E6%90%9C%E7%8B%90%E8%A7%86%E9%A2%91/1 SCNDemo/1.0.8 (iPhone; iOS 11.4; Scale/2.00)
 %E6%90%9C%E7%8B%90%E5%BD%B1%E9%9F%B3/1 SCNMacDemo/1.0.8 (MacBookPro11,5; Mac OS X 10.14.5)
 https://stackoverflow.com/questions/36379347/does-nsurlsession-send-user-agent-automatically
 
 不指定时，系统默认的 UA格式如下:
 SCNDemo/1 CFNetwork/901.1 Darwin/18.2.0
 %E6%90%9C%E7%8B%90%E5%BD%B1%E9%9F%B3/17141 CFNetwork/975.0.3 Darwin/18.2.0 (x86_64)
 */
#if TARGET_OS_OSX
+ (NSString *)deviceModel
{
    NSString *model = nil;
    
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    
    error = sysctlbyname("hw.model", NULL, &length, NULL, 0);
    if (error == 0) {
        char *cpuModel = (char *)malloc(sizeof(char) * length);
        if (cpuModel != NULL) {
            error = sysctlbyname("hw.model", cpuModel, &length, NULL, 0);
            if (error == 0) {
                model = @(cpuModel);
            }
            free(cpuModel);
        }
    }
    
    return model;
}
#endif

+ (NSString *) defaultUA
{
    static NSString *ua;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
        NSDictionary *localizedInfoDic = [[NSBundle mainBundle] localizedInfoDictionary];
        [infoDic setValuesForKeysWithDictionary:localizedInfoDic];
        
        NSString *bundleName = infoDic[(__bridge NSString *)kCFBundleExecutableKey];
        if (!bundleName) {
            bundleName = infoDic[(__bridge NSString *)kCFBundleIdentifierKey];
        }
        NSString *displayName = infoDic[@"CFBundleDisplayName"];
        if (!displayName) {
            displayName = bundleName;
        }
        ///有可能是中文，必须编码！
        displayName = [displayName sc_urlEncodedString];
        NSString *vk = (__bridge NSString *) kCFBundleVersionKey;
        NSString *buildNum = infoDic[vk];
        NSString *shortVersion = infoDic[@"CFBundleShortVersionString"];
        if (!shortVersion) {
            shortVersion = buildNum;
        }
        
#if TARGET_OS_IPHONE
        ua = [NSString stringWithFormat:@"%@/%@ %@/%@ (%@; iOS %@; Scale/%0.2f)",displayName, buildNum, bundleName, shortVersion, [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
        NSOperatingSystemVersion sysVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
        NSString *osv = [NSString stringWithFormat:@"%ld.%ld.%ld",sysVersion.majorVersion,sysVersion.minorVersion,sysVersion.patchVersion];
        
        ua = [NSString stringWithFormat:@"%@/%@ %@/%@ (%@; Mac OS X %@)", displayName, buildNum, bundleName, shortVersion, [self deviceModel],osv];
#endif
    });
    return ua;
}

@end
