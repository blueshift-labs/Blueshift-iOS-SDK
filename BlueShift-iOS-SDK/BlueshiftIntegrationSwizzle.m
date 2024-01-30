//
//  BlueshiftIntegrationSwizzle.m
//  Blueshift
//
//  Created by Ketan Shikhare on 17/01/22.
//  Copyright Blueshift 2022. All rights reserved.


#import "BlueshiftIntegrationSwizzle.h"
#import "BlueShift.h"
#import <objc/runtime.h>
#import <UserNotifications/UserNotifications.h>
#import "BlueshiftConstants.h"

@implementation NSObject (BlueshiftIntegrationSwizzle)

+ (void)swizzleHostAppDelegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        id uiApplicationDelegate = [UIApplication sharedApplication].delegate;
        
        if ([uiApplicationDelegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
            SEL originalSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
            SEL swizzledSelector = @selector(blueshift_swizzled_application:didRegisterForRemoteNotificationsWithDeviceToken:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        } else {
            SEL originalSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
            SEL swizzledSelector = @selector(blueshift_swizzled_no_application:didRegisterForRemoteNotificationsWithDeviceToken:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        }
        
        if ([uiApplicationDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
            SEL originalSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
            SEL swizzledSelector = @selector(blueshift_swizzled_application:didFailToRegisterForRemoteNotificationsWithError:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        } else {
            SEL originalSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
            SEL swizzledSelector = @selector(blueshift_swizzled_no_application:didFailToRegisterForRemoteNotificationsWithError:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        }
        
        if ([uiApplicationDelegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
            SEL originalSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
            SEL swizzledSelector = @selector(blueshift_swizzled_application:didReceiveRemoteNotification:fetchCompletionHandler:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        } else {
            SEL originalSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
            SEL swizzledSelector = @selector(blueshift_swizzled_no_application:didReceiveRemoteNotification:fetchCompletionHandler:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        }
        
        if ([uiApplicationDelegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) {
            SEL originalSelector = @selector(application:didReceiveRemoteNotification:);
            SEL swizzledSelector = @selector(blueshift_swizzled_application:didReceiveRemoteNotification:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        } else {
            SEL originalSelector = @selector(application:didReceiveRemoteNotification:);
            SEL swizzledSelector = @selector(blueshift_swizzled_no_application:didReceiveRemoteNotification:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        }
        
        if ([uiApplicationDelegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
            SEL originalSelector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
            SEL swizzledSelector = @selector(blueshift_swizzled_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        } else {
            SEL originalSelector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
            SEL swizzledSelector = @selector(blueshift_swizzled_no_userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        }

        if ([uiApplicationDelegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)]) {
            SEL originalSelector = @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:);
            SEL swizzledSelector = @selector(blueshift_swizzled_userNotificationCenter:willPresentNotification:withCompletionHandler:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        } else {
            SEL originalSelector = @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:);
            SEL swizzledSelector = @selector(blueshift_swizzled_no_userNotificationCenter:willPresentNotification:withCompletionHandler:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        }
                
        
        if ([uiApplicationDelegate respondsToSelector:@selector(application:continueUserActivity:restorationHandler:)]) {
            SEL originalSelector = @selector(application:continueUserActivity:restorationHandler:);
            SEL swizzledSelector = @selector(blueshift_swizzled_application:continueUserActivity:restorationHandler:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        } else {
            SEL originalSelector = @selector(application:continueUserActivity:restorationHandler:);
            SEL swizzledSelector = @selector(blueshift_swizzled_no_application:continueUserActivity:restorationHandler:);
            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
        }
        
//        if (![uiApplicationDelegate respondsToSelector:@selector(didStartLinkProcessing)]) {
//            SEL originalSelector = @selector(didStartLinkProcessing);
//            SEL swizzledSelector = @selector(blueshift_swizzled_didStartLinkProcessing);
//            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
//        }
//
//        if (![uiApplicationDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
//            SEL originalSelector = @selector(didCompleteLinkProcessing:);
//            SEL swizzledSelector = @selector(blueshift_swizzled_didCompleteLinkProcessing:);
//            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
//        }
//
//        if (![uiApplicationDelegate respondsToSelector:@selector(didFailLinkProcessingWithError:url:)]) {
//            SEL originalSelector = @selector(didFailLinkProcessingWithError:url:);
//            SEL swizzledSelector = @selector(blueshift_swizzled_didFailLinkProcessingWithError:url:);
//            [self swizzleMethodWithClass:class originalSelector:originalSelector andSwizzledSelector:swizzledSelector];
//        }
    });
}

+ (void)swizzleMethodWithClass:(Class)class originalSelector:(SEL)originalSelector andSwizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL isSuccess = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (isSuccess) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

#pragma mark - Device token methods
- (void)blueshift_swizzled_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSData* cachedDeviceToken = [deviceToken copy];
    [self blueshift_swizzled_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    [[BlueShift sharedInstance].appDelegate registerForRemoteNotification:cachedDeviceToken];
}

- (void)blueshift_swizzled_no_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[BlueShift sharedInstance].appDelegate registerForRemoteNotification:deviceToken];
}

- (void)blueshift_swizzled_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error{
    [self blueshift_swizzled_application:application didFailToRegisterForRemoteNotificationsWithError:error];
    
    [[BlueShift sharedInstance].appDelegate failedToRegisterForRemoteNotificationWithError:error];
}

- (void)blueshift_swizzled_no_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
    [[BlueShift sharedInstance].appDelegate failedToRegisterForRemoteNotificationWithError:error];
}

#pragma mark - Remote Notification methods
- (void)blueshift_swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSDictionary *cachedUserInfo = [userInfo copy];
    [self blueshift_swizzled_application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];

    if([[BlueShift sharedInstance]isBlueshiftPushNotification:cachedUserInfo] == YES) {
        [[BlueShift sharedInstance].appDelegate handleRemoteNotification:userInfo forApplication:application fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
    }
}

- (void)blueshift_swizzled_no_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if([[BlueShift sharedInstance]isBlueshiftPushNotification:userInfo] == YES) {
        [[BlueShift sharedInstance].appDelegate handleRemoteNotification:userInfo forApplication:application fetchCompletionHandler:completionHandler];
    }
}

- (void)blueshift_swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSDictionary *cachedUserInfo = [userInfo copy];
    [self blueshift_swizzled_application:application didReceiveRemoteNotification:userInfo];
    
    if([[BlueShift sharedInstance]isBlueshiftPushNotification:cachedUserInfo] == YES) {
        [[BlueShift sharedInstance].appDelegate application:application handleRemoteNotification:userInfo];
    }
}

- (void)blueshift_swizzled_no_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[BlueShift sharedInstance].appDelegate application:application handleRemoteNotification:userInfo];
}

#pragma mark - User Notification methods
- (void)blueshift_swizzled_userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    UNNotificationResponse * cachedResponse = [response copy];
    [self blueshift_swizzled_userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];

    if([[BlueShift sharedInstance]isBlueshiftPushNotification:cachedResponse.notification.request.content.userInfo] == YES) {
        [[BlueShift sharedInstance].userNotificationDelegate userNotificationCenter:center didReceiveNotificationResponse:cachedResponse withCompletionHandler:^{}];
    }
}

- (void)blueshift_swizzled_no_userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)){
    if([[BlueShift sharedInstance]isBlueshiftPushNotification:response.notification.request.content.userInfo] == YES) {
        [[BlueShift sharedInstance].userNotificationDelegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    }
}

- (void)blueshift_swizzled_userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)){
    UNNotification * cachedNotification = [notification copy];
    [self blueshift_swizzled_userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];

    if([[BlueShift sharedInstance]isBlueshiftPushNotification:cachedNotification.request.content.userInfo] == YES) {
        [[BlueShift sharedInstance].userNotificationDelegate userNotificationCenter:center willPresentNotification:cachedNotification withCompletionHandler:^(UNNotificationPresentationOptions options) {}];
    }
}

- (void)blueshift_swizzled_no_userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)){
    if([[BlueShift sharedInstance]isBlueshiftPushNotification:notification.request.content.userInfo] == YES) {
        [[BlueShift sharedInstance].userNotificationDelegate userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
    }
}

#pragma mark - Universal links methods
- (void)blueshift_swizzled_application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    NSURL *url = [userActivity.webpageURL copy];
    [self blueshift_swizzled_application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    
    if([[BlueShift sharedInstance] isBlueshiftUniversalLinkURL:userActivity.webpageURL] == YES) {
        [[BlueShift sharedInstance].appDelegate handleBlueshiftUniversalLinksForURL:url];
    }
}

- (void)blueshift_swizzled_no_application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if([[BlueShift sharedInstance] isBlueshiftUniversalLinkURL:userActivity.webpageURL] == YES) {
        [[BlueShift sharedInstance].appDelegate handleBlueshiftUniversalLinksForURL:userActivity.webpageURL];
    }
}

@end
