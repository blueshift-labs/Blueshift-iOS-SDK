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
#import "BlueShiftDeepLink.h"
#import "BlueShiftPushParamDelegate.h"
#import <CoreData/CoreData.h>
#import "BlueShiftTrackEvents.h"
#import "BlueshiftEventAnalyticsHelper.h"
#import "BlueshiftUniversalLinksDelegate.h"

@interface BlueShiftAppDelegate : NSObject<UIApplicationDelegate>

@property NSDictionary * _Nullable userInfo;
@property NSDictionary * _Nullable pushAlertDictionary;
@property NSObject<UIApplicationDelegate> * _Nonnull mainAppDelegate;
@property NSObject<UNUserNotificationCenterDelegate> * _Nonnull userNotificationDelegate API_AVAILABLE(ios(10.0));
@property (nonatomic, weak) id<BlueShiftPushDelegate> _Nullable blueShiftPushDelegate;
@property (nonatomic, weak) id<BlueShiftPushParamDelegate> _Nullable blueShiftPushParamDelegate;
@property (nonatomic, weak) id<BlueshiftUniversalLinksDelegate> _Nullable blueshiftUniversalLinksDelegate;

@property BlueShiftDeepLink * _Nullable deepLinkToProductPage;
@property BlueShiftDeepLink * _Nullable deepLinkToCartPage;
@property BlueShiftDeepLink * _Nullable deepLinkToOfferPage;
@property BlueShiftDeepLink * _Nullable deepLinkToCustomPage;
- (NSURL *_Nullable)applicationDocumentsDirectory;

/// initialise core data objects
- (void)initializeCoreData;
- (NSManagedObjectContext * _Nullable)managedObjectContext;
- (NSManagedObjectContext * _Nullable)realEventManagedObjectContext;
- (NSManagedObjectContext * _Nullable)batchEventManagedObjectContext;

/// Calling this method will register for push notifications. It will show a push permission dialog to the user.
- (void)registerForNotification;
- (void)registerForSilentPushNotification;

- (BOOL)handleRemoteNotificationOnLaunchWithLaunchOptions:(NSDictionary *_Nullable)launchOptions;
- (NSString *_Nullable)hexadecimalStringFromData:(NSData *_Nullable)data;

/// Share the device token with the SDK by calling this method inside `didRegisterForRemoteNotificationsWithDeviceToken` method.
- (void)registerForRemoteNotification:(NSData *_Nullable)deviceToken;
- (void)failedToRegisterForRemoteNotificationWithError:(NSError *_Nonnull)error;

/// Call this method inside `application:didReceiveRemoteNotification` method of appDelegate. SDK will process the received push notification
/// to perform required tasks.
- (void)handleRemoteNotification:(NSDictionary *_Nonnull)userInfo forApplication:(UIApplication *_Nonnull)application fetchCompletionHandler:(void (^_Nonnull)(UIBackgroundFetchResult result))handler;

- (void)application:(UIApplication *_Nonnull)application handleRemoteNotification:(NSDictionary *_Nonnull)userInfo;
- (void)application:(UIApplication *_Nonnull)application handleLocalNotification:(nonnull UNNotificationRequest *)notification API_AVAILABLE(ios(10.0));
- (void)handleRemoteNotification:(NSDictionary *_Nonnull)userInfo;
- (void)handleActionWithIdentifier: (NSString *_Nonnull)identifier forRemoteNotification:(NSDictionary *_Nonnull)notification completionHandler: (void (^_Nonnull)(void)) completionHandler;

- (void)appDidEnterBackground:(UIApplication *_Nonnull)application DEPRECATED_MSG_ATTRIBUTE("SDK now automatically detects if app enters background, this method will be removed in upcoming releases.");
- (void)appDidBecomeActive:(UIApplication *_Nonnull)application DEPRECATED_MSG_ATTRIBUTE("SDK now automatically detects if app becomes active, this method will be removed in upcoming releases.");

- (void)handleBlueshiftUniversalLinksForActivity:(NSUserActivity *_Nonnull)activity API_AVAILABLE(ios(8.0));
- (void)handleBlueshiftUniversalLinksForURL:(NSURL *_Nonnull)url  API_AVAILABLE(ios(8.0));

/// Track `app_open` by manually calling this method from the host application
- (void)trackAppOpenWithParameters:(NSDictionary *_Nullable)parameters;

/// SDK triggeres app_open event automatically when app is launched from killed state and is controlled by the enableAppOpenTrackEvent config flag.
/// @discussion The automatic app_open events can be throttled by setting time interval in secods to config.automaticAppOpenTimeInterval.
- (void)trackAppOpenOnAppLaunch:(NSDictionary *_Nullable)parameters;

// SceneDelegate lifecycle methods
- (void)sceneWillEnterForeground:(UIScene* _Nullable)scene API_AVAILABLE(ios(13.0)) DEPRECATED_MSG_ATTRIBUTE("SDK now automatically detects if app enters foreground, this method will be removed in upcoming releases.");
- (void)sceneDidEnterBackground:(UIScene* _Nullable)scene API_AVAILABLE(ios(13.0)) DEPRECATED_MSG_ATTRIBUTE("SDK now automatically detects if app enters background, this method will be removed in upcoming releases.");

/// Update current UNAuthorizationStatus in BlueshiftAppData on app launch and on app didBecomeActive
- (void)checkUNAuthorizationStatus;

/// Get last modified status of the push notification authorization.
/// Returns "YES" if authorization status is enabled, returns "NO" if it is disabled.
- (NSString*_Nullable)getLastModifiedUNAuthorizationStatus;

/// Get the clicked push notfiication button name and associated deep link url.
/// @param userInfo push notification payload
/// @param identifier action identifier
/// @return returns a dictionary with the values for deep link URL and the clicked button name. Use key `clk_url` to get the deep link URL and use `clk_elmt` to get button name from the dictionary.
- (NSDictionary* _Nullable)parseCustomActionPushNotification:(NSDictionary *_Nonnull)userInfo forActionIdentifier:(NSString *_Nonnull)identifier;

@end
#endif
