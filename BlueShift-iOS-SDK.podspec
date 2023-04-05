Pod::Spec.new do |s|
  s.name                    = "BlueShift-iOS-SDK"
  s.version                 = "2.3.1"
  s.summary                 = "iOS SDK for integrating Rich Push & In App Notifications, Universal Links and Analytics"
  s.homepage                = "https://github.com/blueshift-labs/Blueshift-iOS-SDK"
  s.license                 = { :type => "MIT", :file => "LICENSE.md" }
  s.author                  = { "Blueshift" => "success@getblueshift.com" }
  s.requires_arc            = true
  s.source                  = { :git => "https://github.com/blueshift-labs/BlueShift-iOS-SDK.git", :tag => s.version.to_s }
  s.documentation_url       = "https://developer.blueshift.com/docs/about-the-blueshift-ios-sdk"
  s.ios.deployment_target   = "9.0"
  s.ios.source_files        = "BlueShift-iOS-SDK/**/*.{h,m}"
  s.ios.public_header_files = "BlueShift-iOS-SDK/**/*.h"
  s.ios.resources           = "BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel,png}"
  s.ios.exclude_files       = "BlueShift-iOS-SDK/include/**/*.{h,m}"
  s.ios.framework           = "CoreData"
end
