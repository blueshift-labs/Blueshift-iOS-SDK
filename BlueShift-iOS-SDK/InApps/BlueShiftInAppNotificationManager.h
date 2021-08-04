//
//  BlueShiftInAppNotificationManager.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <Foundation/Foundation.h>
#import "BlueShiftInAppNotification.h"
#import "BlueShiftNotificationViewController.h"
#import "BlueShiftInAppNotificationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftInAppNotificationManager : NSObject

@property (nonatomic, strong, readwrite) BlueShiftNotificationViewController * _Nullable currentNotificationController;
@property (nonatomic, weak) id<BlueShiftInAppNotificationDelegate> inAppNotificationDelegate;
@property (nonatomic, strong) NSNumber* inAppNotificationTimeInterval;
@property (nonatomic) NSString * _Nullable inAppNotificationDisplayOnPage;

- (void)load;
- (void)initializeInAppNotificationFromAPI:(NSMutableArray *)notificationArray handler:(void (^)(BOOL))handler;
- (void)fetchInAppNotificationsFromDataStore: (BlueShiftInAppTriggerMode) triggerMode;
- (void)fetchLastInAppMessageIDFromDB:(void (^)(BOOL, NSString *, NSString *))handler;
- (void)deleteExpireInAppNotificationFromDataStore;
- (void)markAsDisplayedForNotificationsViewedOnOtherDevice:(NSArray *)messageUUIDArray;

@end

NS_ASSUME_NONNULL_END
