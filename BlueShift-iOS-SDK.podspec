Pod::Spec.new do |s|
  s.name                    = "BlueShift-iOS-SDK"
  s.version                 = "2.6.1"
  s.summary                 = "iOS SDK for integrating Rich Push & In App Notifications, Universal Links and Analytics"
  s.homepage                = "https://github.com/blueshift-labs/Blueshift-iOS-SDK"
  s.license                 = { :type => "MIT", :file => "LICENSE.md" }
  s.author                  = { "Blueshift" => "success@getblueshift.com" }
  s.requires_arc            = true
  s.source                  = { :git => "https://github.com/blueshift-labs/BlueShift-iOS-SDK.git", :tag => s.version.to_s }
  s.documentation_url       = "https://developer.blueshift.com/docs/about-the-blueshift-ios-sdk"
  s.ios.deployment_target   = "9.0"
  s.swift_version           = "5.0"
  
  # Default subspec - Core SDK (Objective-C only)
  s.default_subspecs        = "Core"
  
  # Core subspec - Original Objective-C SDK
  s.subspec "Core" do |core|
    core.ios.source_files        = "BlueShift-iOS-SDK/**/*.{h,m}"
    core.ios.public_header_files = "BlueShift-iOS-SDK/**/*.h"
    core.ios.resource_bundles    = {"BlueShift-iOS-SDK_BlueShift_iOS_SDK" =>  ["BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel,png,xib,xcprivacy}"] }
    core.ios.exclude_files       = "BlueShift-iOS-SDK/include/**/*.{h,m}", "BlueShift-iOS-SDK/SwiftUI/**/*"
    core.ios.framework           = "CoreData"
  end
  
  # SwiftUI subspec - Optional SwiftUI support for in-app notifications
  s.subspec "SwiftUI" do |swiftui|
    swiftui.ios.deployment_target = "13.0"
    swiftui.dependency "BlueShift-iOS-SDK/Core"
    swiftui.ios.source_files      = "BlueShift-iOS-SDK/SwiftUI/**/*.{swift,h}"
    swiftui.ios.public_header_files = "BlueShift-iOS-SDK/SwiftUI/**/*.h"
    swiftui.ios.framework         = "SwiftUI", "WebKit"
  end
end
