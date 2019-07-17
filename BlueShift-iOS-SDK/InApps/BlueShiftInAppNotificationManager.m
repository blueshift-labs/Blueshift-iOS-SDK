//
//  BlueShiftInAppNotificationManager.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotificationManager.h"
#import "ViewControllers/Templates/BlueShiftNotificationWebViewController.h"
#import "ViewControllers/Templates/BlueShiftPromoNotificationViewController.h"
#import "Models/InAppNotificationEntity.h"
#import "BlueShiftAppDelegate.h"

@interface BlueShiftInAppNotificationManager() <BlueShiftNotificationDelegate>
@end

@implementation BlueShiftInAppNotificationManager

// init
- (void)load {
    self.notificationControllerQueue = [NSMutableArray new];
}

- (void)pushInAppNotificationToDB:(NSDictionary*)payload {
    @synchronized(self) {
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        NSManagedObjectContext *masterContext;
        if (appDelegate) {
            @try {
                masterContext = appDelegate.managedObjectContext;
            }
            @catch (NSException *exception) {
                NSLog(@"Caught exception %@", exception);
            }
        }
        if(masterContext) {
            NSEntityDescription *entity;
            @try {
                entity = [NSEntityDescription entityForName:@"InAppNotificationEntity" inManagedObjectContext:masterContext];
            }
            @catch (NSException *exception) {
                NSLog(@"Caught exception %@", exception);
            }
            if(entity != nil) {
                
                NSManagedObjectContext *context = appDelegate.managedObjectContext;
                
                InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
                if(inAppNotificationEntity != nil) {
                    printf("%f NotificationMgr: Inserting the payload \n", [[NSDate date] timeIntervalSince1970]);
                    [inAppNotificationEntity insert:payload handler:^(BOOL status) {
                        if(status) {
                            printf("%f NotificationMgr: Insert Done. Loading from DB \n", [[NSDate date] timeIntervalSince1970]);
                            [self fetchInAppNotificationsFromDB];
                        }
                    }];
                }
            }
        }
    }
}

- (void)fetchInAppNotificationsFromDB {
    [InAppNotificationEntity fetchAll:^(BOOL status, NSArray *results) {
        if(status) {
            for(int i = 0; i < [results count]; i++) {
                InAppNotificationEntity *entity = [results objectAtIndex:i];
                [self createNotificationFromDictionary: entity];
            }
        }
    }];
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
            printf("%f NotificationMgr:: Creating html notification View \n", [[NSDate date] timeIntervalSince1970]);
            notificationController = [[BlueShiftNotificationWebViewController alloc] initWithNotification:notification];
            break;
        case BlueShiftInAppTypeModal:
            notificationController = [[BlueShiftPromoNotificationViewController alloc] initWithNotification:notification];
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

- (void)createNotificationFromDictionary:(InAppNotificationEntity *) inAppEntity {
    
    BlueShiftInAppNotification *inAppNotification = [[BlueShiftInAppNotification alloc] initFromEntity:inAppEntity];
    
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
