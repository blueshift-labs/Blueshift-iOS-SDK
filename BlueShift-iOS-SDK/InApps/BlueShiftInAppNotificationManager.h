//
//  BlueShiftInAppNotificationManager.h
//  BlueShift-iOS-SDK
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
@property double inAppNotificationTimeInterval;
@property (nonatomic) NSString * _Nullable inAppNotificationDisplayOnPage;

- (void)load;

- (void)fetchAndShowInAppNotification;

- (void)stopInAppMessageFetchTimer;

- (void)createInAppNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen;

@end

NS_ASSUME_NONNULL_END
