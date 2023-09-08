//
//  BlueShiftAppDelegate.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#ifndef BlueShift_iOS_SDK_BlueShiftAppDelegate_h
#define BlueShift_iOS_SDK_BlueShiftAppDelegate_h

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>
#import "BlueShift.h"
#import "BlueShiftPushDelegate.h"
#import "BlueShiftPushParamDelegate.h"
#import <CoreData/CoreData.h>
#import "BlueShiftTrackEvents.h"
#import "BlueshiftEventAnalyticsHelper.h"
#import "BlueshiftUniversalLinksDelegate.h"

@interface BlueShiftAppDelegate : NSObject<UIApplicationDelegate>

@property NSDictionary * _Nullable userInfo DEPRECATED_MSG_ATTRIBUTE("This property will be removed in upcoming releases");
@property NSDictionary * _Nullable pushAlertDictionary DEPRECATED_MSG_ATTRIBUTE("This property will be removed in upcoming releases");
@property NSObject<UIApplicationDelegate> * _Nonnull mainAppDelegate;
@property NSObject<UNUserNotificationCenterDelegate> * _Nonnull userNotificationDelegate API_AVAILABLE(ios(10.0));
@property (nonatomic, weak) id<BlueShiftPushDelegate> _Nullable blueShiftPushDelegate;
@property (nonatomic, weak) id<BlueShiftPushParamDelegate> _Nullable blueShiftPushParamDelegate DEPRECATED_MSG_ATTRIBUTE("Use BlueShiftPushDelegate to get the push notification callbacks.");
@property (nonatomic, weak) id<BlueshiftUniversalLinksDelegate> _Nullable blueshiftUniversalLinksDelegate;

- (NSURL *_Nullable)applicationDocumentsDirectory;

/// initialise core data objects
- (void)initializeCoreData;

- (NSManagedObjectContext * _Nullable)eventsMOContext;
- (NSManagedObjectContext* _Nullable)inboxMOContext;

/// Calling this method will register for push notifications. It will show a push permission dialog to the user.
/// It is highly recommended to register for push notifications using the SDK method.
/// SDK takes care of registering the categories for carousel and custom action button push notifications.
- (void)registerForNotification;

/// SDK registers for silent push notfications automatically if the push permission is delayed or denied.
- (void)registerForSilentPushNotification;

- (NSString *_Nullable)hexadecimalStringFromData:(NSData *_Nullable)data;

/// Share the device token with the SDK by calling this method inside `didRegisterForRemoteNotificationsWithDeviceToken` method.
/// - Parameter deviceToken: received device token
- (void)registerForRemoteNotification:(NSData *_Nullable)deviceToken;

- (void)failedToRegisterForRemoteNotificationWithError:(NSError *_Nonnull)error;

/// Call this method inside `application: didReceiveRemoteNotification:` method of appDelegate. SDK will process the received push notification
/// to perform required tasks.
- (void)application:(UIApplication *_Nonnull)application handleRemoteNotification:(NSDictionary *_Nonnull)userInfo;

- (void)application:(UIApplication *_Nonnull)application handleLocalNotification:(nonnull UNNotificationRequest *)notification API_AVAILABLE(ios(10.0)) DEPRECATED_MSG_ATTRIBUTE("Handle the notifications using the UNUserNotificationCenter.");

/// Call this method inside `application:didReceiveRemoteNotification:fetchCompletionHandler` method of appDelegate. SDK will process the received push notification
/// to perform required tasks.
- (void)handleRemoteNotification:(NSDictionary *_Nonnull)userInfo forApplication:(UIApplication *_Nonnull)application fetchCompletionHandler:(void (^_Nonnull)(UIBackgroundFetchResult result))handler;

/// Handles the push notification payload when the app is in killed state and lauched using push notification
- (BOOL)handleRemoteNotificationOnLaunchWithLaunchOptions:(NSDictionary *_Nullable)launchOptions;

- (void)handleRemoteNotification:(NSDictionary *_Nonnull)userInfo;

- (void)handleActionWithIdentifier: (NSString *_Nonnull)identifier forRemoteNotification:(NSDictionary *_Nonnull)notification completionHandler: (void (^_Nonnull)(void)) completionHandler;

/// This method is to process the universal link received by the app. The SDK will process the deep link to perform a click
/// and share the original link to the app using the `BlueshiftUniversalLinksDelegate` delegate methods.
/// Call this method inside `application: continue userActivity: restorationHandler:` method of appDelegate class.
/// @param activity userActivity object
- (void)handleBlueshiftUniversalLinksForActivity:(NSUserActivity *_Nonnull)activity API_AVAILABLE(ios(8.0));

/// This method is to process the universal link received by the app. The SDK will process the deep link to perform a click
/// and share the original link to the app using the `BlueshiftUniversalLinksDelegate` delegate methods.
/// Call this method inside `application: continue userActivity: restorationHandler:` method of appDelegate class.
/// @param url received universal link url
- (void)handleBlueshiftUniversalLinksForURL:(NSURL *_Nonnull)url  API_AVAILABLE(ios(8.0));

/// Track `app_open` by manually calling this method from the host application
- (void)trackAppOpenWithParameters:(NSDictionary *_Nullable)parameters;

/// SDK triggeres app_open event automatically when app is launched from killed state and is controlled by the enableAppOpenTrackEvent config flag.
/// @discussion The automatic app_open events can be throttled by setting time interval in secods to config.automaticAppOpenTimeInterval.
- (void)trackAppOpenOnAppLaunch:(NSDictionary *_Nullable)parameters;

/// SDK tracks the push authorization status automatically by calling this method at the time of SDK initialisation and updates Blueshift server.
- (void)checkUNAuthorizationStatus;

/// Get last modified status of the push notification authorization.
/// Returns "YES" if authorization status is enabled, returns "NO" if it is disabled.
- (NSString*_Nullable)getLastModifiedUNAuthorizationStatus;

/// Get the clicked push notfiication button name and associated deep link url.
/// @param userInfo push notification payload
/// @param identifier action identifier
/// @return returns a dictionary with the values for deep link URL and the clicked button name. Use key `clk_url` to get the deep link URL and use `clk_elmt` to get button name from the dictionary.
- (NSDictionary* _Nullable)parseCustomActionPushNotification:(NSDictionary *_Nonnull)userInfo forActionIdentifier:(NSString *_Nonnull)identifier;

/// Call this method to open a web url in the SDKs internal webview browser screen.
- (BOOL)openDeepLinkInWebViewBrowser:(NSURL* _Nullable) deepLinkURL;

// SceneDelegate lifecycle methods
- (void)sceneWillEnterForeground:(UIScene* _Nullable)scene API_AVAILABLE(ios(13.0)) DEPRECATED_MSG_ATTRIBUTE("SDK now automatically detects if app enters foreground, this method will be removed in upcoming releases.");
- (void)sceneDidEnterBackground:(UIScene* _Nullable)scene API_AVAILABLE(ios(13.0)) DEPRECATED_MSG_ATTRIBUTE("SDK now automatically detects if app enters background, this method will be removed in upcoming releases.");
- (void)appDidEnterBackground:(UIApplication *_Nonnull)application DEPRECATED_MSG_ATTRIBUTE("SDK now automatically detects if app enters background, this method will be removed in upcoming releases.");
- (void)appDidBecomeActive:(UIApplication *_Nonnull)application DEPRECATED_MSG_ATTRIBUTE("SDK now automatically detects if app becomes active, this method will be removed in upcoming releases.");

@end
#endif
