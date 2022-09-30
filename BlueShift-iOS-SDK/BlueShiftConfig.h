//
//  BlueShiftConfig.h
//  BlueShiftiOSSDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import "BlueShiftUserInfo.h"
#import "BlueShiftPushDelegate.h"
#import "BlueShiftInAppNotificationDelegate.h"
#import "BlueshiftUniversalLinksDelegate.h"
#import "BlueshiftDeviceIdSource.h"

typedef NS_ENUM (NSUInteger,BlueshiftRegion) {
    BlueshiftRegionUS,
    BlueshiftRegionEU
};

typedef NS_ENUM (NSUInteger,BlueshiftFilesLocation) {
    BlueshiftFilesLocationDocumentDirectory,
    BlueshiftFilesLocationLibraryDirectory
};

typedef NS_ENUM (NSUInteger,CarouselGoToAppBehaviour) {
    CarouselGoToAppBehaviourOpenAppWithoutDeepLink,
    CarouselGoToAppBehaviourOpenAppWithLastDisplayedImageDeepLink
};

@class BlueShiftInAppNotificationDelegate;

@interface BlueShiftConfig : NSObject

/// The SDK uses API key to connect to Blueshift platform and send data SDK collects from the app to Blueshift platform.
/// This is a mandatory field and you can get the API key from the Blueshift Account setting.
@property NSString * _Nonnull apiKey;

/// iOS SDK v2.2.3 onwards, you can set the Region to the SDK config.
/// Blueshift platform supports two regions, US and EU. Set the Blueshift region to SDK based on your Blueshift account region.
/// If you do not set the region explicitly to the config, the SDK will use US region as the default region.
@property BlueshiftRegion region;

/// SDK uses the launchOptions to track if the app is launched from push notification, if yes, then SDK sends the push click event and delivers the associated deep link url to the app.
/// It is highly recommended to set the launchOptions to the SDK.
@property NSDictionary * _Nonnull applicationLaunchOptions;

/// Set this property to false in order to stop SDK from registering for silent(background) push notifications.
/// @discussion SDK registers for silent push notifications in order to receive the in-app notifications when user has not asked for push permission
/// or has denied the push permission or turned off push notifications manually from the app setting.
/// @note By default this property is set to true.
@property BOOL enableSilentPushNotification;

/// Set this property to false in order to delay the push permission dialog.
/// @discussion When enablePushNotification is set to true during the SDK initialisation, the SDK will register for push notifications immediately after SDK initialisation and it will show user push notification permission dialogue.
/// @discussion If you want to delay showing push permission dialog, set this property to false and register for push notification explicitly from your app using SDK as below.
/// @code
/// BlueShift.sharedInstance()?.appDelegate?.registerForNotification()
/// @endcode
/// @note By default this property is set to true.
@property BOOL enablePushNotification;

@property BOOL enableLocationAccess DEPRECATED_MSG_ATTRIBUTE("From SDK v2.1.7, SDK has stopped tracking the location automatically. The app needs to set the updated location to the Blueshift SDK. This property will be removed in upcoming SDK versions.");

/// From SDK v2.1.13, the automatic app_open tracking will be disabled by default. In order to track the app_open set this flag to true.
/// @discussion You can set the time interval for automatic app_open events using config.automaticAppOpenTimeInterval to throttle them. Default value for automaticAppOpenTimeInterval is once in 24 hours.
/// @note Default value for enableAppOpenTrackEvent is set to false.
@property BOOL enableAppOpenTrackEvent;

/// Set `enableInAppNotification` property to true to enable in-app notifications. By default in-app notifications are disabled.
@property BOOL enableInAppNotification;

/// Set the `InAppManualTriggerEnabled` property to true, to stop the SDK from displaying in-app messages automatically.
/// @note You can display the in-app messages manually by calling below SDK method and it will only show one in-app.
/// @code
/// BlueShift.sharedInstance()?.displayInAppNotification()
/// @endcode
@property BOOL inAppManualTriggerEnabled;

/// By default `inAppBackgroundFetchEnabled` property is set as true.
/// When this feature is enabled, the SDK fetches the latest in-app messages in background, stores it locally to display when needed. If you don't want the SDK to fetch in-app automatically, set this property to false.
@property BOOL inAppBackgroundFetchEnabled;

/// From iOS SDK v2.1.7, it prints the logs when this property is set to true. It is recommended to set this property to true only for debug purpose.
/// @discussion The SDK logs are divided into 4 categories:
/// Errors, Exceptions, Info, API call info.
/// Errors and Exceptions are printed by default, while to see Info and API logs, you will need to set this property to true.
@property BOOL debug;

/// Set custom push notification categories. The SDK will merge the given categories with default SDK categories and register them to UNUserNotificationCenter while registering for push notifications
@property NSSet<UNNotificationCategory *> * _Nullable customCategories API_AVAILABLE(ios(10.0));

/// Set custom push notification authorization options. The SDK will override the default SDK authorization options with given options while registering for push notifications
@property UNAuthorizationOptions customAuthorizationOptions API_AVAILABLE(ios(10.0));

/// It is mandatory to set this property if you are using the Carousel push notifications.
/// The click tracking and push deep links for the carousel push notification will not work correctly if you do not set it.
@property NSString * _Nullable appGroupID;

/// Set this propery to true if the app has SceneDelegate configuration enabled.
/// @note Default value is set to false.
@property BOOL isSceneDelegateConfiguration API_AVAILABLE(ios(13.0)) DEPRECATED_MSG_ATTRIBUTE("From SDK v2.2.5, SDK will not use this property, instead it will check for scene delegate configuration dynamically if needed.");

/// Set this property to false to stop the SDK from collectiong IDFA.
/// @discussion With enableIDFACollection set as true, SDK will not ask user the device IDFA permission, but if the host app has asked for IDFA permission, and user has accepted it, then SDK collects it and sends to server.
/// @note Default value is set to true.
@property BOOL enableIDFACollection DEPRECATED_MSG_ATTRIBUTE("From iOS SDK v2.1.17, SDK has stopped automatic IDFA tracking. The app needs to set the IDFA value to the Blueshift SDK. This property will be removed in upcoming SDK versions.");

/// Custom device id provision for DeviceIDSourceCUSTOM
@property NSString * _Nullable customDeviceId;

/// Set this value in seconds in order to throttle the automatic app_open events getting fired from the SDK.
/// @discussion Setting this value will make sure that only one app_open event will get fired during given time interval.
/// @note Default value is set to 24Hours(60*60*24 seconds), and it will fire an app_open event once in a day.
/// To fire it every time on app launch set the value to 0
@property double automaticAppOpenTimeInterval;

/// The SDK uses this delegate while registering for the remote notifications and iOS gives callback to the implemented userNotification delegate methods when push notification action/event happens.
/// If you skip setting this delegate, SDK will create its own delegate and use it while registering for remote notifications.
/// All the userNotification push notification action/event will then go to SDK's delegate.
@property NSObject<UNUserNotificationCenterDelegate> * _Nullable userNotificationDelegate API_AVAILABLE(ios(10.0));

/// SDK provides callbacks for the push notification click event. Create a class which implements protocol `BlueShiftPushDelegate` to get the callback.
/// Set the object of the Class to this property as delegate during the SDK initialization.
@property id<BlueShiftPushDelegate> _Nullable blueShiftPushDelegate;

/// SDK provides callbacks for the in-app notification click, open, deliver events. Create a class which implements protocol `BlueShiftInAppNotificationDelegate` to get the callback.
/// Set the object of the Class as delegate to this property during the SDK initialization.
@property id<BlueShiftInAppNotificationDelegate> _Nullable inAppNotificationDelegate;

/// Set this property if you want to use the Universal links from the Blueshift.
/// implement the BlueshiftUniversalLinksDelegate protocol and then assign the delegate to this property.
@property id<BlueshiftUniversalLinksDelegate> _Nullable blueshiftUniversalLinksDelegate;

/// By default, the time-interval between two in-app messages (the interval when a message is dismissed and the next message appears while staying on same screen) is 60 seconds.
/// Set this property in seconds to modify the time interval.
@property(nonatomic) double BlueshiftInAppNotificationTimeInterval;

/// SDK creates core data files by default in the app's Document directory. If your app supports sharing the Documents directory or Documents browser, then you can change this location to Library directory, so that the SDK files won't show up in the app's Document directory.
/// Set this attribute to `.LibraryDirectory` if you dont want to use the Documents directory as SDK core data files location.
/// @note If you want to stop using the Documents directory, SDK takes care of moving existing core data files(if present) from Documents directory to Library directory.
/// @warning Shifting from Library directory to Document directory is not a recommended.
/// If you want to stop using the Library directory and start using the Documents directory, SDK does not take care of moving the files from Library directory to Documents directory.
@property BlueshiftFilesLocation sdkCoreDataFilesLocation;

/// By default, SDK sets IDFV as the deviceIdSource.
/// SDK provides IDFV, idfvBundleID, UUID and customDeviceId options as different device id sources.
/// @note If you have multiple apps under one Blueshift account, then we recommend setting it to the idfvBundleID or UUID option.
@property (nonatomic, assign) BlueshiftDeviceIdSource blueshiftDeviceIdSource;

/// This property defines the behaviour of the `Go to App` button of the Carousel push notification.
/// With value `CarouselGoToAppBehaviourOpenAppWithoutDeepLink`, it will just open the app without any deep link. This is default option if not set.
/// With value `CarouselGoToAppBehaviourOpenAppWithLastDisplayedImageDeepLink`, it will open app and share the deep link of the last displayed image on the Carousel push notification.
@property (nonatomic, assign) CarouselGoToAppBehaviour carouselPushNotifcationGoToAppBehaviour;

- (BOOL)validateConfigDetails;

- (NSString* _Nullable)getConfigStringToLog;

+ (BlueShiftConfig * _Nonnull)config;

@end
