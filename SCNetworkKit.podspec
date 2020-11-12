#
#  Be sure to run `pod spec lint SCNetworkKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "SCNetworkKit"
  s.version      = "1.0.21"
  s.summary      = "SCNetworkKit is a simple but powerful iOS and OS X networking framework."
  s.description  = <<-DESC
                  SCNetworkKit is a simple but powerful iOS and OS X networking framework,based on NSURLSession and NSURLSessionConfiguration, written by Objective-C, Support iOS 7+ ;
                   DESC
  s.homepage     = "http://debugly.cn/SCNetworkKit/"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "qianlongxu" => "qianlongxu@gmai.com" }
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.10"
  s.source       = { :git => "https://github.com/debugly/SCNetworkKit.git", :tag => "#{s.version}" }
  s.source_files  = "SCNetworkKit/Classes/**/*.{h,m}"
  s.public_header_files = "SCNetworkKit/Classes/SCNetworkKit.h", "SCNetworkKit/Classes/Util/NSDictionary+SCAddtions.h", "SCNetworkKit/Classes/Util/NSString+SCAddtions.h", "SCNetworkKit/Classes/NetworkService/SCNetworkService*.h", "SCNetworkKit/Classes/Request/SCNetworkRequest.h", "SCNetworkKit/Classes/Request/SCNetworkRequest+Chain.h", "SCNetworkKit/Classes/ResponseParser/*.h"
  s.requires_arc = true
end
