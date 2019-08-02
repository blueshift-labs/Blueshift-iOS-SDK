#
#  Be sure to run `pod spec lint BlueShift-iOS-SDK.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "BlueShift-iOS-SDK"
  s.version      = "1.0.0"
  s.summary      = "iOS SDK for integrating push notification and analytics"

  s.description  = <<-DESC
                   A longer description of BlueShift-iOS-SDK in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/blueshift-labs/Blueshift-iOS-SDK"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  # s.license      = "MIT (example)"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "Blueshift" => "success@getblueshift.com" }
  # Or just: s.author    = "Shahas KP"
  # s.authors            = { "Shahas K P" => "shahas@bullfin.ch" }
  # s.social_media_url   = ""

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  s.platform     = :ios, "7.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/blueshift-labs/BlueShift-iOS-SDK.git", :tag => "1.0.0" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any h, m, mm, c & cpp files. For header
  #  files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  #s.source_files  = "BlueShift-iOS-SDK", "BlueShift-iOS-SDK/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"

  #s.public_header_files = "BlueShift-iOS-SDK/**/*.h"

  s.subspec 'Core' do |ss|
    ss.source_files  = "BlueShift-iOS-SDK/*.{h,m}"
    ss.public_header_files = "BlueShift-iOS-SDK/**/*.h"
    ss.exclude_files = "Classes/Exclude"
    ss.resources = "BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel,otf}"
    ss.resource_bundle = { :BlueShiftBundle => 'BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel,otf}' }

    ss.subspec 'InApps' do |ia|
      ia.source_files = "Blueshift-iOS-SDK/InApps/*.{h,m}"
      ia.public_header_files = "BlueShift-iOS-SDK/InApps/*.h"
      ia.exclude_files = "Classes/Exclude"
      ia.public_header_files = "Blueshift-iOS-SDK/InApps/*.h"

      ia.subspec 'Models' do |m|
        m.source_files = "Blueshift-iOS-SDK/InApps/Models/*.{h,m}"
        m.exclude_files = "Classes/Exclude"
        m.public_header_files = "Blueshift-iOS-SDK/InApps/Models/*.h"
      end

      ia.subspec 'Resources' do |r|
        r.source_files = "Blueshift-iOS-SDK/InApps/Resources/*.{h,m}"
        r.exclude_files = "Classes/Exclude"
        r.public_header_files = "Blueshift-iOS-SDK/InApps/Resources/*.h"
      end

      ia.subspec 'UI' do |ui|
        ui.source_files = "Blueshift-iOS-SDK/InApps/UI/*.{h,m}"
        ui.exclude_files = "Classes/Exclude"
        ui.public_header_files = "Blueshift-iOS-SDK/InApps/UI/*.h"
		    ui.subspec 'Images' do |is|
			   is.resources = 'Blueshift-iOS-SDK/InApps/Images/*.{png}'
			   is.resource_bundle = { :BlueShiftBundle => 'BlueShift-iOS-SDK/InApps/Images/*.{png}' }
		  end
		  ui.subspec 'IBFiles' do |ib|
			 ib.resources = "Blueshift-iOS-SDK/InApps/UI/IBFiles/*.{xib}"
			 ib.resource_bundle = { :BlueShiftBundle => 'BlueShift-iOS-SDK/InApps/UI/IBFiles/*.{xib}' }
		  end
    end

      ia.subspec 'ViewControllers' do |vc|
        vc.source_files = "Blueshift-iOS-SDK/InApps/ViewControllers/*.{h,m}"
        vc.exclude_files = "Classes/Exclude"
        vc.public_header_files = "Blueshift-iOS-SDK/InApps/ViewControllers/*.h"

        vc.subspec "Templates" do |t|
          t.source_files = "Blueshift-iOS-SDK/InApps/ViewControllers/Templates/*.{h,m}"
          t.exclude_files = "Classes/Exclude"
          t.public_header_files = "Blueshift-iOS-SDK/InApps/ViewControllers/Templates/*.h"
        end
      end
    end

  end

  s.subspec 'AppExtension' do |ss|
    ss.source_files  = "BlueShift-iOS-Extension-SDK", "BlueShift-iOS-Extension-SDK/**/*.{h,m}"
    ss.exclude_files = "Classes/Exclude"
    ss.public_header_files = "BlueShift-iOS-Extension-SDK/**/*.h"
  end

  s.default_subspecs = 'Core'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  #s.resources = "BlueShift-iOS-SDK/**/*.{xcdatamodeld,xcdatamodel}"
  
  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  s.framework  = "CoreData"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  #s.dependency
  # s.ios.resource_bundle = { 'Assets' => ['BlueShiftSDKDataModel.xcdatamodeld'] }
end
