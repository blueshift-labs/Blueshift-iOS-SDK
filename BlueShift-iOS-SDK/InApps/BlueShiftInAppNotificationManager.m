//
//  BlueShiftInAppNotificationManager.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <StoreKit/StoreKit.h>
#import "BlueShiftInAppNotificationManager.h"
#import "BlueShiftNotificationWebViewController.h"
#import "BlueShiftNotificationModalViewController.h"
#import "BlueShiftNotificationSlideBannerViewController.h"
#import "InAppNotificationEntity.h"
#import "BlueShiftAppDelegate.h"
#import "BlueShiftInAppTriggerMode.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShift.h"
#import "../BlueshiftLog.h"

#define THRESHOLD_FOR_UPCOMING_IAM  (30*60)         // 30 min set for time-being.

@interface BlueShiftInAppNotificationManager() <BlueShiftNotificationDelegate>

/* In-App message timer for handlin upcoming messages */
@property (nonatomic, strong, readwrite) NSTimer *inAppMsgTimer;

/* Timer for set gap b/w two in app notificaation*/
@property (nonatomic, strong, readwrite) NSTimer *inAppScanQueueTimer;

@property (nonatomic, strong, readwrite) NSTimer *inAppMessageFetchTimer;

/* private object context */
@property (nonatomic, strong, readwrite) NSManagedObjectContext *privateObjectContext;

@end

@implementation BlueShiftInAppNotificationManager

// init
- (void)load {
    
    [self startInAppMessageFetchTimer];

    /* register for app background / foreground notification */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnApplicationEnteringBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(OnApplicationEnteringForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
     [self deleteExpireInAppNotificationFromDataStore];
}

- (void) OnApplicationEnteringBackground:(NSNotification *)notification {
    /* stop the timer once app enters background */
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self stopInAppMessageFetchTimer];
    }
}

- (void) OnApplicationEnteringForeground:(NSNotification *)notification {
    /* start the timer once app enters foreground */
    
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self fetchNowAndUpcomingInAppMessageFromDB];
        [self startInAppMessageFetchTimer];
        [self deleteExpireInAppNotificationFromDataStore];
    }
}

- (void) initializeInAppNotificationFromAPI:(NSMutableArray *)notificationArray handler:(void (^)(BOOL))handler {
    if (notificationArray !=nil && notificationArray.count > 0) {
        for (int i = 0; i < notificationArray.count ; i++) {
            [self addInAppNotificationToDataStore: [notificationArray objectAtIndex: i]];
        }
        
        handler(YES);
    } else {
        handler(YES);
    }
}

//Remove the in-apps on receciving `in_app_mark_as_open` silent push which
//are displayed on the other deivce for same user.
-(void)markAsDisplayedForNotificationsViewedOnOtherDevice:(NSArray *)messageUUIDArray {
    if (messageUUIDArray != nil && messageUUIDArray.count > 0) {
        for (int count = 0; count< messageUUIDArray.count; count++) {
            NSString *messageUUID = [messageUUIDArray objectAtIndex:count];
            if (messageUUID != nil && ![messageUUID isEqualToString:@""]) {
                NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:messageUUID, kInAppNotificationModalMessageUDIDKey,nil];
                [self updateInAppNotification:dictionary];
            }
        }
    }
}

- (void)checkInAppNotificationExist:(NSDictionary *)payload handler:(void (^)(BOOL))handler{
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    if (appDelegate) {
        @try {
            masterContext = appDelegate.managedObjectContext;
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
        
        if(entity != nil && fetchRequest.entity != nil) {
            NSString *notificationID = [self getInAppMessageID: payload];
            if (notificationID !=nil && ![notificationID isEqualToString:@""]) {
                [InAppNotificationEntity fetchNotificationByID:masterContext forNotificatioID: notificationID request: fetchRequest handler:^(BOOL status, NSArray *result){
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

-(NSString *)getInAppMessageID:(NSDictionary *)notificationPayload {
    if ([notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey]) {
        return (NSString *)[notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey];
    } else {
        if([notificationPayload objectForKey:kInAppNotificationDataKey]) {
            notificationPayload = [notificationPayload objectForKey:kInAppNotificationDataKey];
            if ([notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey]) {
                return (NSString *)[notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey];
            }
        }
    }
    
    return @"";
}

- (double)checkInAppNotificationExpired:(double)createdTime {
    double currentTime =  [[NSDate date] timeIntervalSince1970];
    NSDate *createdDate = [self convertMillisecondToDate: createdTime];
    NSDate *currentDate = [self convertMillisecondToDate:currentTime];
    
    NSTimeInterval timeDifference = [currentDate timeIntervalSinceDate: createdDate];
    return (timeDifference / (3600 * 24));
}

- (NSDate *)convertMillisecondToDate:(double)seconds {
    return [NSDate dateWithTimeIntervalSince1970:seconds];
}

- (void) addInAppNotificationToDataStore: (NSDictionary *) payload {
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
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
                if(entity != nil && fetchRequest.entity != nil) {
                    InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext: masterContext];
                    
                    if(inAppNotificationEntity != nil) {
                        [inAppNotificationEntity insert:payload usingPrivateContext:self.privateObjectContext andMainContext: masterContext handler:^(BOOL status) {
                            if(status) {
                                [[BlueShift sharedInstance] trackInAppNotificationDeliveredWithParameter: payload canBacthThisEvent: NO];
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
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
    
    if (masterContext != nil) {
        NSEntityDescription *entity;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSInteger count;
        @try {
            NSError *error;
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
            [fetchRequest setEntity:entity];
            count = [masterContext countForFetchRequest: fetchRequest error:&error];
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
        
        if(entity != nil && fetchRequest.entity != nil) {
            [InAppNotificationEntity fetchInAppNotificationByStatus: masterContext forNotificatioID: @"Displayed" request: fetchRequest handler:^(BOOL status , NSArray *results){
                if (status && results != nil && [results count] > 0) {
                    for(int i = 0; i < results.count; i++) {
                        InAppNotificationEntity *notification = [results objectAtIndex:i];
                        double timeDifferenceInDay = [self checkInAppNotificationExpired: [notification.createdAt doubleValue]];
                        if (timeDifferenceInDay > 30 || count > 40) {
                            [self deleteNotification: notification context: masterContext];
                            [BlueshiftLog logInfo:@"Deleted Expired notification, messageId : " withDetails:notification.id methodName:nil];
                        }
                    }
                }
            }];
        }
    }
}

- (void)deleteNotification:(InAppNotificationEntity *)notification context:(NSManagedObjectContext *)masterContext{
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
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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

- (void)fetchLastInAppMessageIDFromDB:(void (^)(BOOL, NSString *, NSString *))handler {
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    if (appDelegate) {
        @try {
            masterContext = appDelegate.managedObjectContext;
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
    
    if (masterContext != nil) {
        NSEntityDescription *entity;
        NSError *error;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        @try {
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
            [fetchRequest setEntity:entity];
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
        
        if(entity != nil && fetchRequest.entity != nil) {
            NSArray *results = [masterContext executeFetchRequest: fetchRequest error:&error];
            NSArray *sortedList = [self sortedInAppMessageWithDate: results];
            if (sortedList != nil && [sortedList count] > 0 && sortedList[[sortedList count] - 1]) {
                InAppNotificationEntity *notification = results[[sortedList count] -1];
                handler(YES, notification.id, notification.timestamp);
            } else {
                handler(YES, @"", @"");
            }
        }
    }
}

- (NSArray *)sortedInAppMessageWithDate:(NSArray *)messageList {
    if (messageList != nil && messageList.count > 0) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat: kInAppNotificationModalTimestampDateFormat];
        NSArray *sortedArray = [messageList sortedArrayUsingComparator:^NSComparisonResult(InAppNotificationEntity *message1, InAppNotificationEntity *message2) {
            NSDate *d1 = [dateFormatter dateFromString: message1.timestamp];
            NSDate *d2 = [dateFormatter dateFromString: message2.timestamp];
            return [d1 compare: d2];
        }];
        
        return sortedArray;
    }
    
    return [[NSArray alloc] init];
}

- (void)removeInAppNotificationFromDB:(NSManagedObjectID *) entityItem {
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    
    if (appDelegate) {
        @try {
            masterContext = appDelegate.managedObjectContext;
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
}


- (void)fetchInAppNotificationsFromDataStore: (BlueShiftInAppTriggerMode) triggerMode  {
    if([self inAppNotificationDisplayOnPage] && self.currentNotificationController == nil) {
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        NSManagedObjectContext *masterContext;
        if (appDelegate) {
            @try {
                masterContext = appDelegate.managedObjectContext;
            }
            @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
        }
        [InAppNotificationEntity fetchAll:triggerMode forDisplayPage: [self inAppNotificationDisplayOnPage] context:masterContext withHandler:^(BOOL status, NSArray *results) {
            if (status) {
                NSArray *sortedArray = [self sortedInAppNotification: results];
                NSArray* filteredResults = [self filterInAppNotificationResults: sortedArray];
                if ([filteredResults count] > 0) {
                    InAppNotificationEntity *entity = [filteredResults objectAtIndex:0];
                    [self createNotificationFromDictionary: entity];
                }
            }
        }];
    }
}

- (NSArray *)sortedInAppNotification:(NSArray *)inAppNotificationArray {
    NSArray *sortedArrayList = [[NSArray alloc] init];
    
    if (inAppNotificationArray != nil && [inAppNotificationArray count] > 0) {
        NSArray *reversedArray = [[[inAppNotificationArray reverseObjectEnumerator] allObjects] mutableCopy];
        NSArray *displayOnArray = [[NSArray alloc] init];
        NSArray *displayOnEmptyArray = [[NSArray alloc] init];
        
        for (int i = 0;  i< [reversedArray count];  i++) {
            InAppNotificationEntity *entity = [reversedArray objectAtIndex: i];
            NSString *displayOn = entity.displayOn;
            if (displayOn && ![displayOn isEqualToString: @""]) {
                displayOnArray = [displayOnArray arrayByAddingObject: entity];
            } else if (displayOn == nil || [displayOn isEqualToString:@""]){
                displayOnEmptyArray = [displayOnEmptyArray arrayByAddingObject: entity];
            }
        }
        
        sortedArrayList = [displayOnArray arrayByAddingObjectsFromArray: displayOnEmptyArray];
    }
    
    return sortedArrayList;
}

- (void)updateInAppNotification:(NSDictionary *)notificationPayload {
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    if (appDelegate) {
        @try {
            masterContext = appDelegate.managedObjectContext;
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
        
        NSString *notificationID = [self getInAppMessageID: notificationPayload];
        if (notificationID !=nil && ![notificationID isEqualToString:@""]) {
        [InAppNotificationEntity updateInAppNotificationStatus: masterContext forNotificatioID: notificationID request: fetchRequest notificationStatus:@"Displayed" andAppDelegate: appDelegate handler:^(BOOL status){
            [BlueshiftLog logInfo:@"Marked in-app message in DB as Displayed, messageId : " withDetails:notificationID methodName:nil];
        }];
        }
    }
}


- (NSArray *) filterInAppNotificationResults: (NSArray*) results {
    
    /* get the current time (since 1970) */
    NSTimeInterval currentTime =  [[NSDate date] timeIntervalSince1970];
    NSArray *filteredResults = [[NSArray alloc] init];
    NSMutableArray *upcomingFilteredResults = [[NSMutableArray alloc] init];
    NSMutableArray *nowFilteredResults = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < [results count]; i++)
    {
        InAppNotificationEntity *entity = [results objectAtIndex:i];
        if ([entity.triggerMode isEqualToString: @"now"]) {
            double endTime = [entity.endTime doubleValue];
            if (currentTime - THRESHOLD_FOR_UPCOMING_IAM > endTime) {
                /* discard notification if its expired. */
                [self removeInAppNotificationFromDB: entity.objectID];
                [BlueshiftLog logInfo:@"Deleted Expired notification, messageId : " withDetails:entity.id methodName:nil];
            } else {
                /* For 'Now' category msg show it if time is not expired */
                [nowFilteredResults addObject:entity];
            }
        } else if ([entity.triggerMode isEqualToString: @"upcoming"]) {
            double endTime = [entity.endTime doubleValue];
            double startTime = [entity.startTime doubleValue];
            
            if ((currentTime - THRESHOLD_FOR_UPCOMING_IAM) > endTime) {
                /* discard notification if its expired. */
                [self removeInAppNotificationFromDB: entity.objectID];
                [BlueshiftLog logInfo:@"Deleted Expired notification, messageId : " withDetails:entity.id methodName:nil];
            } else if (startTime > currentTime) {
                /* Wait for (startTime-currentTime) before IAM is shown */
                continue;
            } else {
                [upcomingFilteredResults addObject:entity];
            }
        }
    }
    filteredResults = [nowFilteredResults arrayByAddingObjectsFromArray: upcomingFilteredResults];
    return filteredResults;
}

- (void)startInAppMessageFetchTimer {
    if (self.inAppMessageFetchTimer == nil) {
        self.inAppMessageFetchTimer = [NSTimer scheduledTimerWithTimeInterval: [self inAppNotificationTimeInterval]
                                                                    target:self
                                                                  selector:@selector(fetchNowAndUpcomingInAppMessageFromDB)
                                                                  userInfo:nil
                                                                   repeats: NO];
        [BlueshiftLog logInfo:@"Started InAppMessageFetchTimer" withDetails:nil methodName:nil];
    }
}

// Method to stop time gap b/w loading inAppNotification timer
- (void) stopInAppMessageFetchTimer {
    if (self.inAppMessageFetchTimer != nil) {
        [self.inAppMessageFetchTimer invalidate];
        self.inAppMessageFetchTimer = nil;
        [BlueshiftLog logInfo:@"Stopped InAppMessageFetchTimer" withDetails:nil methodName:nil];
    }
}

- (void)fetchNowAndUpcomingInAppMessageFromDB {
    [self fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNowAndUpComing];
}

// Present ViewController
- (void)presentInAppNotification:(BlueShiftNotificationViewController*)notificationController {
    if ([self inAppNotificationDisplayOnPage] && self.currentNotificationController == nil) {
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
        notificationController.inAppNotificationDelegate = self.inAppNotificationDelegate;
        [notificationController setTouchesPassThroughWindow: notification.templateStyle.enableBackgroundAction];
        [self presentInAppNotification:notificationController];
    }
    if (errorString) {
        [BlueshiftLog logError:nil withDescription:errorString methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (void)displayReviewController {
    if (@available(iOS 10.3, *)) {
        [SKStoreReviewController requestReview];
    }
}

- (void)createNotificationFromDictionary:(InAppNotificationEntity *) inAppEntity {
    BlueShiftInAppNotification *inAppNotification = [[BlueShiftInAppNotification alloc] initFromEntity:inAppEntity];
    [BlueshiftLog logInfo:@"Created in-app message to display, message Id: " withDetails:inAppEntity.id methodName:nil];
    [self createNotification: inAppNotification];
}

// Notification Click Callbacks
-(void)inAppDidDismiss:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller  {
    self.currentNotificationController = nil;
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self startInAppMessageFetchTimer];
    }
}

-(void)inAppActionDidTapped:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller {
    [[BlueShift sharedInstance] trackInAppNotificationButtonTappedWithParameter: notificationPayload canBacthThisEvent: NO];
}   

// Notification render Callbacks
-(void)inAppDidShow:(NSDictionary *)notification fromViewController:(BlueShiftNotificationViewController *)controller {
    [[BlueShift sharedInstance] trackInAppNotificationShowingWithParameter: notification canBacthThisEvent: NO];
    [self updateInAppNotification: notification];
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self stopInAppMessageFetchTimer];
    }
}

@end
