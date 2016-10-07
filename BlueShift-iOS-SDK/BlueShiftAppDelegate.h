//
//  BlueShiftAppDelegate.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#ifndef BlueShift_iOS_SDK_BlueShiftAppDelegate_h
#define BlueShift_iOS_SDK_BlueShiftAppDelegate_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BlueShift.h"
#import "BlueShiftPushDelegate.h"
#import "BlueShiftDeepLink.h"
#import "BlueShiftPushParamDelegate.h"
#import <CoreData/CoreData.h>
#import "BlueShiftTrackEvents.h"


@interface BlueShiftAppDelegate : NSObject<UIApplicationDelegate, UIAlertViewDelegate, CLLocationManagerDelegate>

@property NSDictionary *userInfo;
@property NSDictionary *pushAlertDictionary;

@property NSObject<UIApplicationDelegate> *oldDelegate;
@property (nonatomic, retain) id<BlueShiftPushDelegate> blueShiftPushDelegate;
@property (nonatomic, retain) id<BlueShiftPushParamDelegate> blueShiftPushParamDelegate;

@property BlueShiftDeepLink *deepLinkToProductPage;
@property BlueShiftDeepLink *deepLinkToCartPage;
@property BlueShiftDeepLink *deepLinkToOfferPage;
@property BlueShiftDeepLink *deepLinkToCustomPage;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (void) registerForNotification;
- (BOOL) handleRemoteNotificationOnLaunchWithLaunchOptions:(NSDictionary *)launchOptions;
- (void)registerLocationService;

- (void) registerForRemoteNotification:(NSData *)deviceToken;
- (void) failedToRegisterForRemoteNotificationWithError:(NSError *)error;
- (void) handleRemoteNotification:(NSDictionary *)userInfo forApplication:(UIApplication *)application fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler;
- (void) application:(UIApplication *)application handleRemoteNotification:(NSDictionary *)userInfo;
- (void)application:(UIApplication *)application handleLocalNotification:(nonnull UILocalNotification *)notification;
- (void)handleActionWithIdentifier: (NSString *)identifier forRemoteNotification:(NSDictionary *)notification completionHandler: (void (^)()) completionHandler;

- (void)appDidEnterBackground:(UIApplication *)application;
- (void)appDidBecomeActive:(UIApplication *)application;

@end
#endif
