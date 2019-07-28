//
//  BlueShiftInAppNotificationManager.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotificationManager.h"
#import "ViewControllers/Templates/BlueShiftNotificationWebViewController.h"
#import "ViewControllers/Templates/BlueShiftNotificationModalViewController.h"
#import "ViewControllers/Templates/BlueShiftNotificationSlideBannerViewController.h"
#import "Models/InAppNotificationEntity.h"
#import "BlueShiftAppDelegate.h"
#import "BlueShiftInAppTriggerMode.h"

@interface BlueShiftInAppNotificationManager() <BlueShiftNotificationDelegate>

/* In-App message timer for handlin upcoming messages */
@property (nonatomic, strong, readwrite) NSTimer *inAppMsgTimer;

/* private object context */
@property (nonatomic, strong, readwrite) NSManagedObjectContext *privateObjectContext;

@end

@implementation BlueShiftInAppNotificationManager

// init
- (void)load {
    self.notificationControllerQueue = [NSMutableArray new];
}


- (void) addInAppNotificationToDataStore: (NSDictionary*)payload forApplicationState:(UIApplicationState)applicationState {
    
    /* creating a private context */
    if (nil == self.privateObjectContext) {
        self.privateObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    }
    
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
                [inAppNotificationEntity insert:payload inContext:self.privateObjectContext handler:^(BOOL status) {
                    if(status) {
                        printf("%f NotificationMgr: Insert Done. Loading from DB \n", [[NSDate date] timeIntervalSince1970]);
                        if (applicationState == UIApplicationStateActive) {
                            [self fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNow];
                        } else {
                            NSLog(@"NotificationMgr:: Saving in-app msg just saved in CoreDataApp. AppState = %d" , applicationState);
                        }
                    }
                }];
            }
        }
    }
}


- (void)removeInAppNotificationFromDB:(NSManagedObjectID *) entityItem {
    
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
    
    if (entityItem != nil) {
        
        NSManagedObjectContext *context = self.privateObjectContext;
        context.parentContext = masterContext;
        
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    NSManagedObject* pManagedObject =  [context objectWithID: entityItem];
          
                    @try {
                        [context deleteObject: pManagedObject];
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Caught exception %@", exception);
                    }
                    [context performBlock:^{
                        NSError *saveError = nil;
                        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                            [context save:&saveError];
                            
                            if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                                [masterContext performBlock:^{
                                    NSError *error = nil;
                                    [masterContext save:&error];
                                }];
                            }
                        }
                    }];
                }];
            } else {
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }
    }
}




- (void)fetchInAppNotificationsFromDataStore: (BlueShiftInAppTriggerMode) triggerMode  {
    [InAppNotificationEntity fetchAll: triggerMode withHandler:^(BOOL status, NSArray *results) {
        if(status) {
            for(int i = 0; i < [results count]; i++) {
                InAppNotificationEntity *entity = [results objectAtIndex:i];
                [self createNotificationFromDictionary: entity];
            }
        }
    }];
}

// Method to start In-App message loading timer
- (void)startInAppMessageLoadTimer {
    [NSTimer scheduledTimerWithTimeInterval:10
                                     target:self
                                   selector:@selector(handlePendingInAppMessage)
                                   userInfo:nil
                                    repeats:YES];
}

// handle In-App msg.
- (void) handlePendingInAppMessage {
    [self fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerUpComing];
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


- (void)createNotification:(BlueShiftInAppNotification*)notification {
    BlueShiftNotificationViewController *notificationController;
    NSString *errorString = nil;
    
    switch (notification.inAppType) {
        case BlueShiftInAppTypeHTML:
            printf("%f NotificationMgr:: Creating html notification View \n", [[NSDate date] timeIntervalSince1970]);
            notificationController = [[BlueShiftNotificationWebViewController alloc] initWithNotification:notification];
            break;
        case BlueShiftInAppTypeModal:
            notificationController = [[BlueShiftNotificationModalViewController alloc] initWithNotification:notification];
            break;
        case BlueShiftInAppModalWithImage:
            notificationController = [[BlueShiftNotificationModalViewController alloc] initWithNotification:notification];
            break;
        case BlueShiftNotificationSlideBanner:
            notificationController = [[BlueShiftNotificationSlideBannerViewController alloc] initWithNotification:notification];
            break;
        case BlueShiftNotificationOneButton:
           notificationController = [[BlueShiftNotificationModalViewController alloc] initWithNotification:notification];
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
    [self createNotification: inAppNotification];
}



// Notification Click Callbacks
-(void)inAppDidDismiss:(BlueShiftInAppNotification *)notification fromViewController:(BlueShiftNotificationViewController *)controller  {
    
    NSManagedObjectID* entityItem = controller.notification.objectID;
    
    self.currentNotificationController = nil;
    
    /* delete the app entity from core data */
    [self removeInAppNotificationFromDB: entityItem];
    
    /* scan queue for any pending notification. */
    //TODO:  check app foreground state before scanning.
    [self scanNotificationQueue];
}

// Notification render Callbacks
-(void)inAppDidShow:(BlueShiftInAppNotification *)notification fromViewController:(BlueShiftNotificationViewController *)controller {
}

@end
