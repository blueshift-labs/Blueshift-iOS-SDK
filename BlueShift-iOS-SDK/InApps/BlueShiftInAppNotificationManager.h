//
//  BlueShiftInAppNotificationManager.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <Foundation/Foundation.h>
#import "Models/BlueShiftInAppNotification.h"
#import "ViewControllers/BlueShiftNotificationViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftInAppNotificationManager : NSObject

@property (nonatomic, strong, readwrite) BlueShiftNotificationViewController * _Nullable currentNotificationController;
@property (nonatomic, strong, readwrite) NSMutableArray<BlueShiftNotificationViewController*> *notificationControllerQueue;

- (void) load;
- (void) addInAppNotificationToDataStore: (NSDictionary*)payload forApplicationState:(UIApplicationState)applicationState;

- (void) createNotificationFromDictionary:(NSDictionary *)dictionary;

- (void) startInAppMessageLoadTimer;

@end

NS_ASSUME_NONNULL_END
