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
#import "BlueShiftAlertView.h"

@interface BlueShiftAppDelegate : NSObject<UIApplicationDelegate, CLLocationManagerDelegate, BlueShiftAlertControllerDelegate>

@property NSDictionary * _Nullable userInfo;
@property NSDictionary * _Nullable pushAlertDictionary;

@property NSObject<UIApplicationDelegate> * _Nonnull oldDelegate;
@property (nonatomic, weak) id<BlueShiftPushDelegate> _Nullable blueShiftPushDelegate;
@property (nonatomic, weak) id<BlueShiftPushParamDelegate> _Nullable blueShiftPushParamDelegate;

@property BlueShiftDeepLink * _Nullable deepLinkToProductPage;
@property BlueShiftDeepLink * _Nullable deepLinkToCartPage;
@property BlueShiftDeepLink * _Nullable deepLinkToOfferPage;
@property BlueShiftDeepLink * _Nullable deepLinkToCustomPage;

@property (readonly, strong, nonatomic) NSManagedObjectContext * _Nullable managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext * _Nullable realEventManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext * _Nullable batchEventManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel * _Nullable managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator * _Nullable persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *_Nullable)applicationDocumentsDirectory;

- (void) registerForNotification;
- (BOOL) handleRemoteNotificationOnLaunchWithLaunchOptions:(NSDictionary *_Nullable)launchOptions;
- (void)registerLocationService;

- (void) registerForRemoteNotification:(NSData *_Nullable)deviceToken;
- (void) failedToRegisterForRemoteNotificationWithError:(NSError *_Nonnull)error;
- (void) handleRemoteNotification:(NSDictionary *_Nonnull)userInfo forApplication:(UIApplication *_Nonnull)application fetchCompletionHandler:(void (^_Nonnull)(UIBackgroundFetchResult result))handler;
- (void) application:(UIApplication *_Nonnull)application handleRemoteNotification:(NSDictionary *_Nonnull)userInfo;
- (void)application:(UIApplication *_Nonnull)application handleLocalNotification:(nonnull UILocalNotification *)notification;
- (void)handleActionWithIdentifier: (NSString *_Nonnull)identifier forRemoteNotification:(NSDictionary *_Nonnull)notification completionHandler: (void (^_Nonnull)()) completionHandler;

- (void)appDidEnterBackground:(UIApplication *_Nonnull)application;
- (void)appDidBecomeActive:(UIApplication *_Nonnull)application;

@end
#endif
