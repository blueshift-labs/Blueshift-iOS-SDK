Pod::Spec.new do |s|
  s.name                  = "BlueShift-iOS-Extension-SDK"
  s.version               = "2.2.0"
  s.summary               = "iOS SDK for Push Notification Service Extension and Content Extension to support image and carousel image push notifications"
  s.homepage              = "https://github.com/blueshift-labs/Blueshift-iOS-SDK"
  s.license               = { :type => "MIT", :file => "LICENSE.md" }
  s.author                = { "Blueshift" => "success@getblueshift.com" }
  s.platform              = :ios, "10.0"
  s.source                = { :git => "https://github.com/blueshift-labs/BlueShift-iOS-SDK.git", :tag => s.version.to_s }
  s.source_files          = "BlueShift-iOS-Extension-SDK", "BlueShift-iOS-Extension-SDK/**/*.{h,m}"
  s.public_header_files   = "BlueShift-iOS-Extension-SDK/**/*.h"
  s.requires_arc          = true
end
