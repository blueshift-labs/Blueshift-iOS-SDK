//
//  BlueShiftInAppNotificationManager.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <Foundation/Foundation.h>
#import "Models/BlueShiftInAppNotification.h"
#import "ViewControllers/BlueShiftNotificationViewController.h"
#import "../BlueShiftInAppNotificationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftInAppNotificationManager : NSObject

@property (nonatomic, strong, readwrite) BlueShiftNotificationViewController * _Nullable currentNotificationController;
@property (nonatomic, strong, readwrite) NSMutableArray<BlueShiftNotificationViewController*> *notificationControllerQueue;
@property (nonatomic, weak) id<BlueShiftInAppNotificationDelegate> inAppNotificationDelegate;

- (void)load;
- (void)pushInAppNotificationToDB:(NSDictionary*)payload;
- (void)createNotificationFromDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
