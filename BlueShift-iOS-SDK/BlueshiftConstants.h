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
#define kBrowserPlatform                        @"browser_platform"

//App Data
#define kEnablePush                             @"enable_push"
#define kEnableInApp                            @"enable_inapp"
#define kBundleIdentifier                       @"bundle_identifier"
#define kBuildNumber                            @"build_number"
#define kAppVersion                             @"app_version"
#define kAppName                                @"app_name"
#define kCFBundleShortVersionString             @"CFBundleShortVersionString"

//Fetch InApp API params
#define kEmail                                  @"email"
#define kAPIKey                                 @"api_key"
#define kLastTimestamp                          @"last_timestamp"

//UserDefaults
#define kBlueshiftDeviceIdSourceUUID            @"BlueshiftDeviceIdSourceUUID"
#define kBlueshiftUNAuthorizationStatus         @"BlueshiftUNAuthorizationStatus"
#define kBlueshiftDeviceToken                   @"BlueshiftDeviceToken"
#define kBlueshiftEnablePush                    @"BlueshiftEnablePush"
#define kBlueshiftLastAppOpenTimestamp          @"BlueshiftLastAppOpenTimestamp"
#define kBlueshiftEnableTracking                @"BlueshiftEnableTracking"
#define kBlueshiftEnableInApp                   @"BlueshiftEnableInApp"
#define ksavedBlueShiftUserInfoDictionary       @"savedBlueShiftUserInfoDictionary"

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
#define openURLOptionsPushUserInfo              @"userInfo"

//Core data entities
#define kHttpRequestOperationEntity             @"HttpRequestOperationEntity"
#define kBatchEventEntity                       @"BatchEventEntity"

//URLSession constants
#define kURLSessionLocation                     @"location"

//UserInfo constants
#define kBSUserCustomerId                       @"customer_id"
#define kBSUserName                             @"name"
#define kBSUserFirstName                        @"firstname"
#define kBSUserLastName                         @"lastname"
#define kBSUserGender                           @"gender"
#define kBSUserJoinedAt                         @"joined_at"
#define kBSUserFacebookId                       @"facebook_id"
#define kBSUserEducation                        @"education"
#define kBSUserUnsubscribedPush                 @"unsubscribed_push"
#define kBSUserDOB                              @"date_of_birth"
#define kBSUserAdditionalInfo                   @"additional_user_info"
#define kBSUserExtras                           @"extras"
            
//Tracking constants
#define kBSClick                                @"click"
#define kBSDelivered                            @"delivered"
#define kBSOpen                                 @"open"
#define kBSDismiss                              @"dismiss"

//Serial queue
#define BLUESHIFT_SERIAL_QUEUE                  "com.blueshift.sdk"

#endif /* BlueshiftConstants_h */
