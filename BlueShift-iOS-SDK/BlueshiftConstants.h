//
//  BlueshiftConstants.h
//  Pods
//
//  Created by Ketan Shikhare on 12/10/20.
//

#ifndef BlueshiftConstants_h
#define BlueshiftConstants_h


//Device Data
#define kLatitude                               @"latitude"
#define kLongitude                              @"longitude"
#define kDeviceIDFA                             @"device_idfa"
#define kNetworkCarrier                         @"network_carrier"
#define kOSName                                 @"os_name"
#define kDeviceManufacturer                     @"device_manufacturer"
#define kDeviceIDFV                             @"device_idfv"
#define kIDFADefaultValue                       @"00000000-0000-0000-0000-000000000000"
#define kDeviceToken                            @"device_token"
#define kDeviceType                             @"device_type"
#define kDeviceID                               @"device_id"
#define kApple                                  @"apple"
#define kiOS                                    @"iOS"

//App Data
#define kEnablePush                             @"enable_push"
#define kEnableInApp                            @"enable_inapp"
#define kBundleIdentifier                       @"bundle_identifier"
#define kBuildNumber                            @"build_number"
#define kAppVersion                             @"app_version"
#define kAppName                                @"app_name"
#define kCFBundleShortVersionString             @"CFBundleShortVersionString"

//UserDefaults
#define kBlueshiftDeviceIdSourceUUID            @"BlueshiftDeviceIdSourceUUID"
#define kBlueshiftUNAuthorizationStatus         @"BlueshiftUNAuthorizationStatus"
#define kBlueshiftDeviceToken                   @"BlueshiftDeviceToken"
#define kBlueshiftEnablePush                    @"BlueshiftEnablePush"

//Bool
#define kYES                                    @"YES"
#define kNO                                     @"NO"

//OpenURL options keys and values
#define openURLOptionsSource                    @"source"
#define openURLOptionsBlueshift                 @"Blueshift"
#define openURLOptionsChannel                   @"channel"
#define openURLOptionsInApp                     @"inApp"
#define openURLOptionsPush                      @"push"
#define openURLOptionsModal                     @"modal"
#define openURLOptionsSlideIn                   @"slideInBanner"
#define openURLOptionsHTML                      @"HTML"
#define openURLOptionsInAppType                 @"inAppType"
#define openURLOptionsButtonIndex               @"clickedButtonIndex"
#define openURLOptionsButtonText                @"clickedButtonText"

#endif /* BlueshiftConstants_h */
