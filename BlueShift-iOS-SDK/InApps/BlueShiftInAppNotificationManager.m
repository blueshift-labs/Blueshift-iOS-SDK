//
//  BlueShiftInAppNotificationManager.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotificationManager.h"
#import "ViewControllers/Templates/BlueShiftNotificationWebViewController.h"

@interface BlueShiftInAppNotificationManager() <BlueShiftNotificationDelegate>
@end

@implementation BlueShiftInAppNotificationManager

// init
- (void)load {
    self.notificationControllerQueue = [NSMutableArray new];
}

- (void)pushInAppNotificationToDB:(NSDictionary*)payload {
    
}

- (void)fetchInAppNotificationsFromDB {
    
}

// trigger queued notifications
- (void)scanNotificationQueue {
    if (self.notificationControllerQueue && [self.notificationControllerQueue count] > 0) {
        BlueShiftNotificationViewController *notificationController = [self.notificationControllerQueue objectAtIndex:0];
        [self.notificationControllerQueue removeObjectAtIndex:0];
        [self presentInAppNotification:notificationController];
    }
}

// Present ViewController
- (void)presentInAppNotification:(BlueShiftNotificationViewController*)notificationController {
    if (self.currentNotificationController) {
        // if we are currently displaying a notification, queue this notification for later display
        [self.notificationControllerQueue addObject:notificationController];
        return;
    } else {
        // no current notification so display
        self.currentNotificationController = notificationController;
        [notificationController show:YES];
    }
}

// Remove current notification and Schedule next
- (void)inAppNotificationDidDismiss:(BlueShiftNotificationViewController*)notificationController {
    if (self.currentNotificationController && self.currentNotificationController == notificationController) {
        self.currentNotificationController= nil;
        [self scanNotificationQueue];
    }
}

- (void)createNotification:(BlueShiftInAppNotification*)notification {
    BlueShiftNotificationViewController *notificationController;
    NSString *errorString = nil;
    
    switch (notification.inAppType) {
        case BlueShiftInAppTypeHTML:
            notificationController = [[BlueShiftNotificationWebViewController alloc] initWithNotification:notification];
            break;
        default:
            errorString = [NSString stringWithFormat:@"Unhandled notification type: %lu", (unsigned long)notification.inAppType];
            break;
    }
    if (notificationController) {
        notificationController.delegate = self;
        [notificationController setTouchesPassThroughWindow:YES];
        [self presentInAppNotification:notificationController];
    }
    if (errorString) {
    }

}

- (void)createNotificationFromDictionary:(NSDictionary *)dictionary {
    BlueShiftInAppNotification *inAppNotification = [[BlueShiftInAppNotification alloc] initFromDictionary:dictionary];
    [inAppNotification configureFromDictionary:dictionary];
    
    [self createNotification:inAppNotification];
}

// Notification Click Callbacks
-(void)inAppDidDismiss:(BlueShiftInAppNotification *)notification fromViewController:(BlueShiftNotificationViewController *)controller  {
    [self inAppNotificationDidDismiss:controller];
    [self scanNotificationQueue];
}

// Notification render Callbacks
-(void)inAppDidShow:(BlueShiftInAppNotification *)notification fromViewController:(BlueShiftNotificationViewController *)controller {
}

@end
