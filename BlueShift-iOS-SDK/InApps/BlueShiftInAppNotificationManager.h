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
@property (nonatomic) double inAppNotificationTimeInterval;

- (void) load;

- (void) createNotificationFromDictionary:(NSDictionary *)dictionary;
- (void) initializeInAppNotificationFromAPI:(NSMutableArray *)payload;
- (void) recuresiveAdding:(NSArray *)list item:(NSNumber *)item;
- (void)fetchInAppNotificationsFromDataStore: (BlueShiftInAppTriggerMode) triggerMode;

@end

NS_ASSUME_NONNULL_END
