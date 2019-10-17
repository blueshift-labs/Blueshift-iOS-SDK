Pod::Spec.new do |s|
  s.name         = "BlueShift-iOS-SDK"
  s.version      = "2.0.0"
  s.summary      = "iOS SDK for integrating push notification and analytics"

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
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/blueshift-labs/BlueShift-iOS-SDK.git", :tag => "2.0.0" }
  s.exclude_files = "Classes/Exclude"
  s.subspec 'Core' do |ss|
    ss.source_files  = "BlueShift-iOS-SDK/**/*.{h,m}"
    ss.public_header_files = "BlueShift-iOS-SDK/**/*.h"
    ss.exclude_files = "Classes/Exclude"
    ss.resources = "BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel,png}"
    ss.resource_bundle = { :BlueShiftBundle => 'BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel,png}' }

  end

  s.subspec 'AppExtension' do |ss|
    ss.source_files  = "BlueShift-iOS-Extension-SDK", "BlueShift-iOS-Extension-SDK/**/*.{h,m}"
    ss.exclude_files = "Classes/Exclude"
    ss.public_header_files = "BlueShift-iOS-Extension-SDK/**/*.h"
  end

  s.default_subspecs = 'Core'
  s.framework  = "CoreData"
  s.requires_arc = true
end
