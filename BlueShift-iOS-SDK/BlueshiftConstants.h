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

// API params
#define kEmail                                  @"email"
#define kAPIKey                                 @"api_key"
#define kLastTimestamp                          @"last_timestamp"
#define kBSAuthorization                        @"Authorization"
#define kBSContentType                          @"Content-Type"
#define kBSApplicationJSON                      @"application/json"
#define kBSGETMethod                            @"GET"
#define kBSPOSTMethod                           @"POST"

//UserDefaults
#define kBlueshiftDidAskPushPermission          @"BlueshiftDidAskPushPermission"
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
#define openURLOptionsPushActionIdentifier      @"actionIdentifier"

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
#define kBSAction                               @"a"

//Serial queue
#define kBSSerialQueue                          "com.blueshift.coresdk"

//Core Data
#define kBSCoreDataDataModel                    @"BlueShiftSDKDataModel"
#define kBSSPMResourceBundlePath                @"/BlueShift-iOS-SDK_BlueShift_iOS_SDK.bundle"
#define kBSCoreDataMOMD                         @"momd"
#define kBSCoreDataSQLiteFileName               @"BlueShift-iOS-SDK.sqlite"
#define kBSFrameWorkPath                        @"Frameworks/BlueShift_iOS_SDK.framework"
#define kBSCreatedAt                            @"createdAt"

//NSNotificationCenter constant
#define kBSPushAuthorizationStatusDidChangeNotification @"BlueshiftPushAuthorizationStatusDidChangeNotification"
#define kBSStatus                               @"status"

//Default time interval for in-app notificaiton
#define kDefaultInAppTimeInterval               60
#define kMinimumInAppTimeInterval               5

// Push permission promt Localization keys
#define kBSGoToSettingTitleLocalizedKey         @"BLUESHIFT_GOTOSETTING_ALERT_TITLE"
#define kBSGoToSettingTextLocalizedKey          @"BLUESHIFT_GOTOSETTING_ALERT_TEXT"
#define kBSGoToSettingOkayButtonLocalizedKey    @"BLUESHIFT_GOTOSETTING_ALERT_OKAY_BUTTON"
#define kBSGoToSettingCancelButtonLocalizedKey  @"BLUESHIFT_GOTOSETTING_ALERT_CANCEL_BUTTON"

// Push permission promt default text
#define kBSGoToSettingDefaultTitle              @"Enable push notifications"
#define kBSGoToSettingDefaultText               @"You have disabled Push notifications for your app, please go to settings to enable it."
#define kBSGoToSettingDefaultOkayButton         @"Settings"
#define kBSGoToSettingDefaultCancelButton       @"Not Now"

#endif /* BlueshiftConstants_h */
