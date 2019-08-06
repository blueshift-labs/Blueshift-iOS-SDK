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
#import "BlueShiftInAppNotificationConstant.h"

#define THRESHOLD_FOR_UPCOMING_IAM  (30*60)         // 30 min set for time-being.

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
    
    /* create timer for upcoming events */
    [self startInAppMessageLoadTimer];
    
    /* register for app background / foreground notification */
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnApplicationEnteringBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnApplicationEnteringForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    
}

- (void) OnApplicationEnteringBackground:(NSNotification *)notification {
    /* stop the timer once app enters background */
    
    [self stopInAppMessageLoadTimer];
}

- (void) OnApplicationEnteringForeground:(NSNotification *)notification {
    /* start the timer once app enters foreground */
    
    [self startInAppMessageLoadTimer];
    
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
                        if (applicationState == UIApplicationStateActive ||
                            applicationState == UIApplicationStateInactive) {
                            [self fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNow];
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
        
        if (status) {
            NSArray* filteredResults = [self filterInAppNotificationResults:results withTriggerMode:triggerMode];
            
            for(int i = 0; i < [filteredResults count]; i++) {
                InAppNotificationEntity *entity = [filteredResults objectAtIndex:i];
                [self createNotificationFromDictionary: entity];
            }
        }
    }];
}


- (NSArray *) filterInAppNotificationResults: (NSArray*) results withTriggerMode:(BlueShiftInAppTriggerMode) triggerMode {
    
    /* get the current time (since 1970) */
    NSTimeInterval currentTime =  [[NSDate date] timeIntervalSince1970];
    
    NSArray *outResults = nil;
    
    if (BlueShiftInAppTriggerUpComing == triggerMode)
    {
        NSMutableArray* filteredResults = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < [results count]; i++) {
            InAppNotificationEntity *entity = [results objectAtIndex:i];
            
            
            double endTime = [entity.endTime doubleValue];
            double startTime = [entity.startTime doubleValue];
            
            if (currentTime - THRESHOLD_FOR_UPCOMING_IAM > endTime) {
                /* discard notification if its expired. */
    
                //TODO: remove from db
                
                printf("\nUpcoming:: Discarded Current time of IAM = %f endTime = %f", currentTime, endTime);
                
            } else if (startTime > currentTime) {
                /* Wait for (startTime-currentTime) before IAM is shown */
                
                printf("\nUpcoming:: Wait further Current time of IAM = %f startTime = %f", currentTime, startTime);
                
            } else {
                
                printf("\nUpcoming:: Display Current time of IAM = %f startTime = %f", currentTime, startTime);
                
                [filteredResults addObject:entity];
            }
        }
        outResults = [NSArray arrayWithArray: filteredResults];
    } else {
        outResults = results;
    }
    return outResults;
}



// Method to start In-App message loading timer
- (void)startInAppMessageLoadTimer {
    if (nil == self.inAppMsgTimer) {
        self.inAppMsgTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                          target:self
                                                        selector:@selector(handlePendingInAppMessage)
                                                        userInfo:nil
                                                         repeats:YES];
    }
}

// Method to stop In-App message loading timer
- (void) stopInAppMessageLoadTimer {
    if (nil != self.inAppMsgTimer) {
        [self.inAppMsgTimer invalidate];
        self.inAppMsgTimer = nil;
    }
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
            notificationController = [[BlueShiftNotificationWebViewController alloc] initWithNotification:notification];
            break;
        case BlueShiftInAppTypeModal:
            notificationController = [[BlueShiftNotificationModalViewController alloc] initWithNotification:notification];
            break;
        case BlueShiftNotificationSlideBanner:
            notificationController = [[BlueShiftNotificationSlideBannerViewController alloc] initWithNotification:notification];
            break;
            
        default:
            errorString = [NSString stringWithFormat:@"Unhandled notification type: %lu", (unsigned long)notification.inAppType];
            break;
    }
    if (notificationController) {
        notificationController.delegate = self;
        [notificationController setTouchesPassThroughWindow: notification.templateStyle.enableBackgroundAction];
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
-(void)inAppDidDismiss:(BlueShiftInAppNotification *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller  {
    
    NSManagedObjectID* entityItem = controller.notification.objectID;
    
    self.currentNotificationController = nil;
    
    /* delete the app entity from core data */
    [self removeInAppNotificationFromDB: entityItem];
    
    /* scan queue for any pending notification. */
    //TODO:  check app foreground state before scanning.
    [self scanNotificationQueue];
 //   [[self inAppNotificationDelegate] dismissButtonDidTapped: notificationPayload];
}

-(void)inAppActionDidTapped:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller {
   if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(actionButtonDidTapped:)]) {
        [[self inAppNotificationDelegate] actionButtonDidTapped: notificationPayload];
    }
}

// Notification render Callbacks
-(void)inAppDidShow:(BlueShiftInAppNotification *)notification fromViewController:(BlueShiftNotificationViewController *)controller {
}

@end
