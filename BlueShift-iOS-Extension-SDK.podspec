Pod::Spec.new do |s|
  s.name         = "BlueShift-iOS-Extension-SDK"
  s.version      = "2.1.16"
  s.summary      = "iOS SDK for push notification content extension and service extension for integrating media and carousel push notifications"

  s.description  = <<-DESC
                   A longer description of BlueShift-iOS-SDK in Markdown format.
                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/blueshift-labs/Blueshift-iOS-SDK"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author             = { "Blueshift" => "success@getblueshift.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/blueshift-labs/BlueShift-iOS-SDK.git", :tag => "2.1.16" }
  s.source_files  = "BlueShift-iOS-Extension-SDK", "BlueShift-iOS-Extension-SDK/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.resources = "BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel,otf}"
  #s.resource_bundle = { :BlueShiftBundle => 'BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel,otf}' }
  s.public_header_files = "BlueShift-iOS-Extension-SDK/**/*.h"

end
