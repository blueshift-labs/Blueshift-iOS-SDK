//
//  BlueShiftInAppNotificationManager.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <StoreKit/StoreKit.h>
#import "BlueShiftInAppNotificationManager.h"
#import "ViewControllers/Templates/BlueShiftNotificationWebViewController.h"
#import "ViewControllers/Templates/BlueShiftNotificationModalViewController.h"
#import "ViewControllers/Templates/BlueShiftNotificationSlideBannerViewController.h"
#import "Models/InAppNotificationEntity.h"
#import "BlueShiftAppDelegate.h"
#import "Models/BlueShiftInAppTriggerMode.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "../BlueShift.h"

#define THRESHOLD_FOR_UPCOMING_IAM  (30*60)         // 30 min set for time-being.

@interface BlueShiftInAppNotificationManager() <BlueShiftNotificationDelegate>

/* In-App message timer for handlin upcoming messages */
@property (nonatomic, strong, readwrite) NSTimer *inAppMsgTimer;

/* Timer for set gap b/w two in app notificaation*/
@property (nonatomic, strong, readwrite) NSTimer *inAppScanQueueTimer;

/* private object context */
@property (nonatomic, strong, readwrite) NSManagedObjectContext *privateObjectContext;

@end

@implementation BlueShiftInAppNotificationManager

// init
- (void)load {
    self.notificationControllerQueue = [NSMutableArray new];
    
    /* create timer for upcoming events */
    [self startInAppMessageLoadTimer];
    
    /* show any now messages if saved earlier */
    [self fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNow];
    
    
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
    [self stopInAppScanQueueTimer];
}

- (void) OnApplicationEnteringForeground:(NSNotification *)notification {
    /* start the timer once app enters foreground */
    
    [self startInAppMessageLoadTimer];
    
    /* show any now messages if saved earlier */
    [self fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNow];
    
}

- (void) initializeInAppNotificationFromAPI:(NSMutableArray *)notificationArray {
    NSNumber *item = [NSNumber numberWithInt:0];
    [self recuresiveAdding:notificationArray item:item];
    [self deleteExpireInAppNotificationFromDataStore];
}

- (void)recuresiveAdding:(NSArray *)list item:(NSNumber *)item {
    [self addInAppNotificationToDataStore:[list objectAtIndex:[item integerValue]] handler:^(BOOL status) {
        if(status) {
            NSNumber *nextItem = [NSNumber numberWithLong:[item longValue] + 1];
            if ([nextItem integerValue] < [list count]) {
                [self recuresiveAdding:list item:nextItem];
            } else {
                [self fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNow];
            }
        }
    }];
}

- (void)checkInAppNotificationExist:(NSDictionary *)payload handler:(void (^)(BOOL))handler{
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
    
    if (masterContext != nil) {
        NSEntityDescription *entity;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        @try {
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
            [fetchRequest setEntity:entity];
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }
        
        if(entity != nil && fetchRequest.entity != nil) {
            InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] init];
            if ([payload objectForKey: kInAppNotificationModalMessageUDIDKey]) {
                NSString *notificationID = (NSString *)[payload objectForKey: kInAppNotificationModalMessageUDIDKey];
                [inAppNotificationEntity fetchNotificationByID:masterContext forNotificatioID: notificationID request: fetchRequest handler:^(BOOL status, NSArray *result){
                    if (status) {
                        handler(NO);
                    } else {
                        handler(YES);
                    }
                }];
            }
        }
    }
}

- (double)checkInAppNotificationExpired:(double)createdTime {
    double currentTime =  [[NSDate date] timeIntervalSince1970] * 1000;
    NSDate *createdDate = [self convertMillisecondToDate: createdTime];
    NSDate *currentDate = [self convertMillisecondToDate:currentTime];
    
    NSTimeInterval timeDifference = [currentDate timeIntervalSinceDate: createdDate];
    return (timeDifference / 3600 * 24);
}

- (NSDate *)convertMillisecondToDate:(double)milliseonds {
    return [NSDate dateWithTimeIntervalSince1970:(milliseonds / 1000.0)];
}

- (void) addInAppNotificationToDataStore: (NSDictionary*)payload handler:(void (^)(BOOL))handler{
    [self checkInAppNotificationExist: payload handler:^(BOOL status){
        if (status) {
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
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                @try {
                    entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
                    [fetchRequest setEntity:entity];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught exception %@", exception);
                }
                if(entity != nil && fetchRequest.entity != nil) {
                    InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext: masterContext];
                    
                    if(inAppNotificationEntity != nil) {
                        [inAppNotificationEntity insert:payload usingPrivateContext:self.privateObjectContext andMainContext: masterContext handler:^(BOOL status) {
                            
                            if(status) {
                                [[BlueShift sharedInstance] trackInAppNotificationDeliveredWithParameter: payload canBacthThisEvent: YES];
                                handler(YES);
                            }
                        }];
                    }
                }
            }
        }
    }];
}

- (void) deleteExpireInAppNotificationFromDataStore {
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
    
    if (masterContext != nil) {
        NSEntityDescription *entity;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        @try {
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
            [fetchRequest setEntity:entity];
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }
        
        if(entity != nil && fetchRequest.entity != nil) {
            InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] init];
            [inAppNotificationEntity fetchInAppNotificationByStatus: masterContext forNotificatioID: @"Displayed" request: fetchRequest handler:^(BOOL status , NSArray *results){
                if (status && results != nil && [results count] > 0) {
                    for(int i = 0; i < results.count; i++) {
                        InAppNotificationEntity *notification = [results objectAtIndex:i];
                        double timeDifferenceInDay = [self checkInAppNotificationExpired: [notification.createdAt doubleValue]];
                        if (timeDifferenceInDay > 30) {
                            if (nil == self.privateObjectContext) {
                                self.privateObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                            }
                            
                            NSManagedObjectContext *context = self.privateObjectContext;
                            context.parentContext = masterContext;
                            
                            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                [context performBlock:^{
                                    NSManagedObject* pManagedObject =  [context objectWithID: notification.objectID];
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
                            }
                        }
                    }
                }
            }];
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
        
        /* creating a private context */
        if (nil == self.privateObjectContext) {
            self.privateObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        }
        
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
    
    [InAppNotificationEntity fetchAll:triggerMode context:masterContext withHandler:^(BOOL status, NSArray *results) {
        if (status) {
            NSArray* filteredResults = [self filterInAppNotificationResults:results withTriggerMode:triggerMode];
            
            for(int i = 0; i < [filteredResults count]; i++) {
                InAppNotificationEntity *entity = [filteredResults objectAtIndex:i];
                [self createNotificationFromDictionary: entity];
            }
        }
    }];
}

- (void)updateInAppNotification:(NSDictionary *)notificationPayload {
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
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        @try {
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
            [fetchRequest setEntity:entity];
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }
        
        InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] init];
        if(inAppNotificationEntity != nil) {
            if ([notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey]) {
                NSString *notificationID = (NSString *)[notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey];
                [inAppNotificationEntity updateInAppNotificationStatus: masterContext forNotificatioID: notificationID request: fetchRequest notificationStatus:@"Displayed" andAppDelegate: appDelegate handler:^(BOOL status){
                    if (status) {
                        [self startInAppScanQueueTimer];
                        [self stopInAppMessageLoadTimer];
                    }
                }];
            }
        }
    }
}


- (NSArray *) filterInAppNotificationResults: (NSArray*) results withTriggerMode:(BlueShiftInAppTriggerMode) triggerMode {
    
    /* get the current time (since 1970) */
    NSTimeInterval currentTime =  [[NSDate date] timeIntervalSince1970];
    NSArray *outResults = nil;
    
    if (BlueShiftInAppTriggerUpComing == triggerMode)
    {
        NSMutableArray* filteredResults = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < [results count]; i++)
        {
            InAppNotificationEntity *entity = [results objectAtIndex:i];
            
            double endTime = [entity.endTime doubleValue];
            double startTime = [entity.startTime doubleValue];
            
            if (currentTime - THRESHOLD_FOR_UPCOMING_IAM > endTime) {
                /* discard notification if its expired. */
    
                [self removeInAppNotificationFromDB: entity.objectID];
                
            } else if (startTime > currentTime) {
                /* Wait for (startTime-currentTime) before IAM is shown */
                
            } else {
                [filteredResults addObject:entity];
            }
        }
        outResults = [NSArray arrayWithArray: filteredResults];
        
    } else if (BlueShiftInAppTriggerNow == triggerMode) {
        
        NSMutableArray* filteredResults = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < [results count]; i++)
        {
            InAppNotificationEntity *entity = [results objectAtIndex:i];
            
            double endTime = [entity.endTime doubleValue];
            double startTime = [entity.startTime doubleValue];
            
            if (currentTime - THRESHOLD_FOR_UPCOMING_IAM > endTime) {
                /* discard notification if its expired. */
                
                [self removeInAppNotificationFromDB: entity.objectID];
            } else {
                /* For 'Now' category msg show it if time is not expired */
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
        self.inAppMsgTimer = [NSTimer scheduledTimerWithTimeInterval: 10
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

// Method to start time gap b/w loading inAppNotification timer
- (void)startInAppScanQueueTimer {
    if (self.inAppScanQueueTimer == nil) {
        self.inAppScanQueueTimer = [NSTimer scheduledTimerWithTimeInterval:[self inAppNotificationTimeInterval]
                                target:self
                                selector:@selector(scanNotificationQueue)
                                userInfo:nil
                                repeats: NO];
    }
}

// Method to stop time gap b/w loading inAppNotification timer
- (void) stopInAppScanQueueTimer {
    if (self.inAppScanQueueTimer != nil) {
        [self.inAppScanQueueTimer invalidate];
        self.inAppScanQueueTimer = nil;
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
        [self stopInAppScanQueueTimer];
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
        case BlueShiftNotificationRating:
            [self displayReviewController];
            
            /* delete this notification from coreData */
            [self removeInAppNotificationFromDB: notification.objectID];
            return;
            
            
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

- (void)displayReviewController {
    if (@available(iOS 10.3, *)) {
        [SKStoreReviewController requestReview];
    }
}

- (void)createNotificationFromDictionary:(InAppNotificationEntity *) inAppEntity {
    
    BlueShiftInAppNotification *inAppNotification = [[BlueShiftInAppNotification alloc] initFromEntity:inAppEntity];
    [self createNotification: inAppNotification];
}



// Notification Click Callbacks
-(void)inAppDidDismiss:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller   {
    
    [[BlueShift sharedInstance] trackInAppNotificationDismissWithParameter:notificationPayload canBacthThisEvent:YES];
    
   // NSManagedObjectID* entityItem = controller.notification.objectID;
    
    self.currentNotificationController = nil;
    
    /* update the app entity from core data */
    [self updateInAppNotification: notificationPayload];
}

-(void)inAppActionDidTapped:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller {

    [[BlueShift sharedInstance] trackInAppNotificationButtonTappedWithParameter:NULL canBacthThisEvent: YES];
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(actionButtonDidTapped:)]) {
        [[self inAppNotificationDelegate] actionButtonDidTapped: notificationPayload];
        
    }
}

// Notification render Callbacks
-(void)inAppDidShow:(NSDictionary *)notification fromViewController:(BlueShiftNotificationViewController *)controller {
    [[BlueShift sharedInstance] trackInAppNotificationShowingWithParameter: notification canBacthThisEvent: YES];
    
    [self stopInAppMessageLoadTimer];
}

@end
