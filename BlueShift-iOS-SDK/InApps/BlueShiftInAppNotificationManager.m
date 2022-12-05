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
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

@interface BlueShiftInAppNotificationManager() <BlueShiftNotificationDelegate>

@property (nonatomic, strong, readwrite) NSTimer *inAppMessageFetchTimer;

/* private object context */
@property (nonatomic, strong, readwrite) NSManagedObjectContext *privateObjectContext;

@end

@implementation BlueShiftInAppNotificationManager

#pragma mark - Set up
// init
- (void)load {
    
    [self startInAppMessageFetchTimer];

    /* register for app background / foreground notification */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onApplicationEnteringBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onApplicationEnteringForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
     [self deleteExpireInAppNotificationFromDataStore];
}

- (void)onApplicationEnteringBackground:(NSNotification *)notification {
    // stop the timer once app enters background.
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self stopInAppMessageFetchTimer];
    }
}

- (void)onApplicationEnteringForeground:(NSNotification *)notification {
    // start the timer once app enters foreground.
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO && [[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES) {
//        [self fetchNowAndUpcomingInAppMessageFromDB];
        [self startInAppMessageFetchTimer];
    }
}

- (void)startInAppMessageFetchTimer {
    if (self.inAppMessageFetchTimer == nil) {
        double timeInterval = (self.inAppNotificationTimeInterval > kMinimumInAppTimeInterval) ? self.inAppNotificationTimeInterval : kDefaultInAppTimeInterval;
        self.inAppMessageFetchTimer = [NSTimer scheduledTimerWithTimeInterval: timeInterval target:self selector:@selector(fetchNowAndUpcomingInAppMessageFromDB) userInfo:nil repeats: YES];
        [BlueshiftLog logInfo:@"Started InAppMessageFetchTimer with time interval in seconds -" withDetails:[NSNumber numberWithDouble: timeInterval] methodName:nil];
    }
}

// Method to stop time gap b/w loading inAppNotification timer
- (void)stopInAppMessageFetchTimer {
    if (self.inAppMessageFetchTimer != nil) {
        [self.inAppMessageFetchTimer invalidate];
        self.inAppMessageFetchTimer = nil;
        [BlueshiftLog logInfo:@"Stopped InAppMessageFetchTimer" withDetails:nil methodName:nil];
    }
}

- (void)fetchNowAndUpcomingInAppMessageFromDB {
    [self fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNowAndUpComing];
}

//Remove the in-apps on receciving `in_app_mark_as_open` silent push which
//are displayed on the other deivce for same user.
- (void)markAsDisplayedForNotificationsViewedOnOtherDevice:(NSArray *)messageUUIDArray {
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

#pragma mark - Insert, delete, update in-app notifications
- (void)initializeInAppNotificationFromAPI:(NSMutableArray *)notificationArray handler:(void (^)(BOOL))handler {
    @try {
        if (notificationArray && notificationArray.count > 0) {
            NSMutableArray *messageUUIDs = [NSMutableArray arrayWithCapacity:[notificationArray count]];
            [notificationArray enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
                [messageUUIDs addObject:[obj[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey]];
            }];
            
            [InAppNotificationEntity checkIfMessagesPresentForMessageUUIDs:messageUUIDs handler:^(BOOL status, NSDictionary * _Nonnull uuids) {
                for (int counter = 0; counter < notificationArray.count ; counter++) {
                    NSDictionary* inapp = [notificationArray objectAtIndex: counter];
                    double expiresAt = [inapp[kInAppNotificationDataKey][kInAppNotificationKey][kSilentNotificationTriggerEndTimeKey] doubleValue];
                    //Do not add duplicate messages in the db
                    if(![uuids valueForKey:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey]]) {
                        // Do not add expired in-app notifications to in-app DB.
                        if ([self checkInAppNotificationExpired:expiresAt] == NO) {
                            [self addInAppNotificationToDataStore: inapp];
                        } else {
                            [BlueshiftLog logInfo:@"Skipped adding expired in-app message to DB. MessageUUID -" withDetails:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                        }
                    } else {
                        [BlueshiftLog logInfo:@"Skipped adding duplicate in-app message to DB. MessageUUID -" withDetails:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                    }
                }
                handler(YES);
            }];
        }
    } @catch (NSException *exception) {
    }
}

- (void)addInboxNotifications:(NSMutableArray *)notificationArray handler:(void (^)(BOOL))handler {
    @try {
        if (notificationArray && notificationArray.count > 0) {
            NSMutableArray *messageUUIDs = [NSMutableArray arrayWithCapacity:[notificationArray count]];
            [notificationArray enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
                [messageUUIDs addObject:[obj[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey]];
            }];
            
            [InAppNotificationEntity checkIfMessagesPresentForMessageUUIDs:messageUUIDs handler:^(BOOL status, NSDictionary * _Nonnull uuids) {
                for (int counter = 0; counter < notificationArray.count ; counter++) {
                    NSDictionary* inapp = [notificationArray objectAtIndex: counter];
                    double expiresAt = [inapp[kInAppNotificationDataKey][kInAppNotificationKey][kSilentNotificationTriggerEndTimeKey] doubleValue];
                    //Do not add duplicate messages in the db
                    if(![uuids valueForKey:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey]]) {
                        // Do not add expired in-app notifications to in-app DB.
                        if ([self checkInAppNotificationExpired:expiresAt] == NO) {
                            [self addInAppNotificationToDataStore: inapp];
                        } else {
                            [BlueshiftLog logInfo:@"Skipped adding expired in-app message to DB. MessageUUID -" withDetails:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                        }
                    } else {
                        [BlueshiftLog logInfo:@"Skipped adding duplicate in-app message to DB. MessageUUID -" withDetails:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                    }
                }
                handler(YES);
            }];
        }
    } @catch (NSException *exception) {
    }
}

- (void)addInAppNotificationToDataStore:(NSDictionary *)payload {
    @try {
        NSManagedObjectContext *privateContext = [BlueShift sharedInstance].appDelegate.inboxManagedObjectContext;
        if (privateContext) {
            NSEntityDescription *entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:privateContext];
            if(entity) {
                InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext: privateContext];
                if(inAppNotificationEntity) {
                    [inAppNotificationEntity insert:payload handler:^(BOOL status) {
                        if(status) {
                            [[BlueShift sharedInstance] trackInAppNotificationDeliveredWithParameter: payload canBacthThisEvent: NO];
                            // invoke the inApp clicked callback method
                            if ([self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidDeliver:)]) {
                                [self.inAppNotificationDelegate inAppNotificationDidDeliver:payload];
                            }
                        }
                    }];
                }
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

/// Returns true if the In-App exists in the SDK database.
/// @param payload  In-App notification payload
/// @param handler completion handler
- (void)checkInAppNotificationExist:(NSDictionary *)payload handler:(void (^)(BOOL))handler{
    @try {
        NSString *messageUUID = [self getInAppMessageID: payload];
        if (messageUUID) {
//            [InAppNotificationEntity fetchNotificationByID:privateContext forNotificatioID: messageUUID request: fetchRequest handler:^(BOOL status, NSArray *result){
//                handler(status);
//            }];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

-(NSString * _Nullable)getInAppMessageID:(NSDictionary *)notificationPayload {
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
    
    return nil;
}

//TODO: need to modify this to delete only the expired notification
- (void)deleteExpireInAppNotificationFromDataStore {
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
                        if ([self getTimeDifference: notification.createdAt.doubleValue] > 30 || count > 40) {
                            [self deleteNotification: notification context: masterContext];
                            [BlueshiftLog logInfo:@"Deleted Displayed notification, messageId : " withDetails:notification.id methodName:nil];
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
                NSError *saveError = nil;
                if(context) {
                    [context save:&saveError];
                    if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                        [masterContext performBlock:^{
                            NSError *error = nil;
                            @try {
                                [masterContext save:&error];
                            }
                            @catch (NSException *exception) {
                                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                            }
                        }];
                    }
                }
            }
            @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
        }];
    }
}

- (BOOL)checkInAppNotificationExpired:(double)expiryTime {
    double currentTime =  [[NSDate date] timeIntervalSince1970];
    return currentTime > expiryTime;
}

- (double)getTimeDifference:(double)createdTime {
    double currentTime =  [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeDifference = currentTime - createdTime;
    return (timeDifference / (3600 * 24));
}



// TODO: can be removed, not used as used sort descriptor
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

- (void)removeInAppNotificationFromDB:(NSManagedObjectID *)objectId completionHandler:(void (^_Nonnull)(BOOL))handler {
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext * masterContext = appDelegate.managedObjectContext;
    
    if (objectId && masterContext) {
        if (nil == self.privateObjectContext) {
            self.privateObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        }
        
        NSManagedObjectContext *context = self.privateObjectContext;
        context.parentContext = masterContext;
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    NSManagedObject* pManagedObject =  [context objectWithID: objectId];
                    @try {
                        [context deleteObject: pManagedObject];
                        NSError *saveError = nil;
                        if(context) {
                            [context save:&saveError];
                            if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                                [masterContext performBlock:^{
                                    @try {
                                        NSError *error = nil;
                                        [masterContext save:&error];
                                        handler(YES);
                                    } @catch (NSException *exception) {
                                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                                        handler(NO);
                                    }
                                }];
                            } else {
                                handler(NO);
                            }
                        } else {
                            handler(NO);
                        }
                    }
                    @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        handler(NO);
                    }
                }];
            } else {
                handler(NO);
            }
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            handler(NO);
        }
    } else {
        handler(NO);
    }
}

- (void)updateInAppNotification:(NSDictionary *)notificationPayload {
    //    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    //    NSManagedObjectContext *masterContext;
    //    if (appDelegate) {
    //        @try {
    //            masterContext = appDelegate.managedObjectContext;
    //        }
    //        @catch (NSException *exception) {
    //            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    //        }
    //    }
    //    if(masterContext) {
    //        NSEntityDescription *entity;
    //        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    //        @try {
    //            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
    //            [fetchRequest setEntity:entity];
    //        }
    //        @catch (NSException *exception) {
    //            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    //        }
    //
    NSString *notificationID = [self getInAppMessageID: notificationPayload];
    if (notificationID !=nil && ![notificationID isEqualToString:@""]) {
        
        [InAppNotificationEntity markMessageAsRead:notificationID];
        //        [InAppNotificationEntity updateInAppNotificationStatus: masterContext forNotificatioID: notificationID request: fetchRequest notificationStatus:@"Displayed" andAppDelegate: appDelegate handler:^(BOOL status){
        //            if (status) {
        //                [BlueshiftLog logInfo:@"Marked in-app message in DB as Displayed, messageId : " withDetails:notificationID methodName:nil];
        //            }
        //        }];
    }
}

#pragma mark - Inbox


#pragma mark - Fetch in-app from the Datastore, filter and process it to display notification
- (void)fetchInAppNotificationsFromDataStore: (BlueShiftInAppTriggerMode) triggerMode  {
    if([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus]) {
        if ([self inAppNotificationDisplayOnPage]) {
            if (!self.currentNotificationController) {
                [InAppNotificationEntity fetchAllMessagesForTrigger:triggerMode andDisplayPage:[self inAppNotificationDisplayOnPage] withHandler:^(BOOL status, NSArray *results) {
                    if (status) {
                        NSArray *sortedArray = [self sortedInAppNotification: results];
                        NSArray* filteredResults = [self filterInAppNotificationResults: sortedArray];
                        if ([filteredResults count] > 0) {
                            InAppNotificationEntity *entity = [filteredResults objectAtIndex:0];
                            [BlueshiftLog logInfo:@"Fetched one in-app message from DB to display, message id - " withDetails:entity.id methodName:nil];
                            [self createNotificationFromDictionary: entity];
                        } else {
                            [BlueshiftLog logInfo:@"Skipping in-app display! Reason: No pending in-apps to display at this moment for current screen." withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
                        }
                    } else {
                        [BlueshiftLog logInfo:@"Skipping in-app display! Reason: No pending in-apps to display for current screen." withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
                    }
                }];
            } else {
                [BlueshiftLog logInfo:@"Skipping in-app fetch! Reason: In-progress or active in-app detected." withDetails:nil methodName:nil];
            }
        } else {
            [BlueshiftLog logInfo:@"Skipping in-app fetch! Reason: screen is not registered to receive in-apps." withDetails:nil methodName:nil];
        }
    } else {
        [BlueshiftLog logInfo:@"Skipping in-app fetch! Reason: In-App notifications are not enabled" withDetails:nil methodName:nil];
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

- (NSArray *) filterInAppNotificationResults: (NSArray*) results {
    
    /* get the current time (since 1970) */
    NSTimeInterval currentTime =  [[NSDate date] timeIntervalSince1970];
    NSMutableArray *upcomingFilteredResults = [[NSMutableArray alloc] init];
    NSMutableArray *nowFilteredResults = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < [results count]; i++)
    {
        InAppNotificationEntity *entity = [results objectAtIndex:i];
        if ([entity.triggerMode isEqualToString: @"now"]) {
            double endTime = [entity.endTime doubleValue];
            if (currentTime > endTime) {
                /* discard notification if its expired. */
                [self removeInAppNotificationFromDB: entity.objectID completionHandler:^(BOOL status) {
                    if (status) {
                        [BlueshiftLog logInfo:@"Deleted Expired pending notification, messageId : " withDetails:entity.id methodName:nil];
                    }
                }];
            } else {
                /* For 'Now' category msg show it if time is not expired */
                [nowFilteredResults addObject:entity];
            }
        } else if ([entity.triggerMode isEqualToString: @"upcoming"]) {
            double endTime = [entity.endTime doubleValue];
            double startTime = [entity.startTime doubleValue];
            
            if (currentTime > endTime) {
                /* discard notification if its expired. */
                [self removeInAppNotificationFromDB: entity.objectID completionHandler:^(BOOL status) {
                    if (status) {
                        [BlueshiftLog logInfo:@"Deleted Expired pending notification, messageId : " withDetails:entity.id methodName:nil];
                    }
                }];
            } else if (startTime > currentTime) {
                /* Wait for (startTime-currentTime) before IAM is shown */
                continue;
            } else {
                [upcomingFilteredResults addObject:entity];
            }
        }
    }
    NSArray *filteredResults = [nowFilteredResults arrayByAddingObjectsFromArray: upcomingFilteredResults];
    return filteredResults;
}

#pragma mark - Display in-app notification
- (void)createNotificationFromDictionary:(InAppNotificationEntity *) inAppEntity {
    BlueShiftInAppNotification *inAppNotification = [[BlueShiftInAppNotification alloc] initFromEntity:inAppEntity];
    [BlueshiftLog logInfo:@"Created in-app object from dictionary, message Id: " withDetails:inAppEntity.id methodName:nil];
    [self createInAppNotification: inAppNotification displayOnScreen:inAppEntity.displayOn];
}

- (void)createInAppNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentNotificationController != nil || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
            [BlueshiftLog logInfo:@"Active In-app notification detected or app is not running in active state, skipped displaying current in-app." withDetails:nil methodName:nil];
            return;
        }
        
        switch (notification.inAppType) {
            case BlueShiftInAppTypeHTML:
                [self processHTMLNotification:notification displayOnScreen:displayOnScreen];
                break;
                
            case BlueShiftInAppTypeModal:
                [self processModalNotification:notification displayOnScreen:displayOnScreen];
                break;
                
            case BlueShiftNotificationSlideBanner:
                [self processSlideInBannerNotification:notification displayOnScreen:displayOnScreen];
                break;
                
            case BlueShiftNotificationRating:
            {
                [self displayReviewController];
                [self removeInAppNotificationFromDB: notification.objectID completionHandler:^(BOOL status) {}];
                return;;
            }
                
            default:
            {
                NSString* errorString = [NSString stringWithFormat:@"Unhandled notification type: %lu", (unsigned long)notification.inAppType];
                [BlueshiftLog logError:nil withDescription:errorString methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
            break;
        }
    });
}

- (void)displayReviewController {
    if (@available(iOS 10.3, *)) {
        [SKStoreReviewController requestReview];
    }
}

-(void)processSlideInBannerNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    [BlueshiftLog logInfo:@"Creating HTML in-app notification to display on screen name" withDetails:displayOnScreen methodName:nil];
    BlueShiftNotificationViewController* notificationVC = [[BlueShiftNotificationSlideBannerViewController alloc] initWithNotification:notification];
    notificationVC.displayOnScreen = displayOnScreen;
    self.currentNotificationController = notificationVC;

    BOOL isSlideInIconImagePresent = [notificationVC isSlideInIconImagePresent:notification];
    BOOL isBackgroundImagePresent = [notificationVC isBackgroundImagePresentForNotification:notification];
    if (isSlideInIconImagePresent || isBackgroundImagePresent) {
        NSURL* iconImageURL = isSlideInIconImagePresent ? [NSURL URLWithString:notification.notificationContent.iconImage] : nil;
        NSURL* backgroundImageURL = isBackgroundImagePresent ? [NSURL URLWithString:notification.templateStyle.backgroundImage] : nil;
        dispatch_group_t serviceGroup = dispatch_group_create();
        dispatch_group_async(serviceGroup,BlueShift.sharedInstance.dispatch_get_blueshift_queue,^{
            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadImageForURL:iconImageURL handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];
            
            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadImageForURL:backgroundImageURL handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];
            
            dispatch_group_notify(serviceGroup,dispatch_get_main_queue(),^{
                [self presentInAppViewController:notificationVC forNotification:notification];
            });
        });
    } else {
        [self presentInAppViewController:notificationVC forNotification:notification];
    }
}

-(void)processModalNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    [BlueshiftLog logInfo:@"Creating Modal in-app notification to display on screen name" withDetails:displayOnScreen methodName:nil];
    BlueShiftNotificationViewController* notificationVC = [[BlueShiftNotificationModalViewController alloc] initWithNotification:notification];
    notificationVC.displayOnScreen = displayOnScreen;
    self.currentNotificationController = notificationVC;
    BOOL isBackgroundImagePresent = [notificationVC isBackgroundImagePresentForNotification:notification];
    BOOL isBannerImagePresent = [notificationVC isBannerImagePresentForNotification:notification];

    if (isBackgroundImagePresent || isBannerImagePresent) {
        NSURL* backgroundImageURL = isBackgroundImagePresent ? [NSURL URLWithString:notification.templateStyle.backgroundImage] : nil;
        NSURL* bannerImageURL = isBannerImagePresent ? [NSURL URLWithString:notification.notificationContent.banner] : nil;
        dispatch_group_t serviceGroup = dispatch_group_create();
        dispatch_group_async(serviceGroup,BlueShift.sharedInstance.dispatch_get_blueshift_queue,^{
            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadImageForURL:backgroundImageURL handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];

            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadImageForURL:bannerImageURL handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];
            
            dispatch_group_notify(serviceGroup,dispatch_get_main_queue(),^{
                [self presentInAppViewController:notificationVC forNotification:notification];
            });
        });
    } else {
        [self presentInAppViewController:notificationVC forNotification:notification];
    }
}

-(void)processHTMLNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    [BlueshiftLog logInfo:@"Creating HTML in-app notification to display on screen name" withDetails:displayOnScreen methodName:nil];
    BlueShiftNotificationViewController* notificationVC = [[BlueShiftNotificationWebViewController alloc] initWithNotification:notification];
    notificationVC.displayOnScreen = displayOnScreen;
    notificationVC.delegate = self;
    self.currentNotificationController = notificationVC;

    BlueShiftNotificationWebViewController *webViewController = (BlueShiftNotificationWebViewController*) notificationVC;
    [webViewController setupWebView];
}

// Present ViewController
- (void)presentInAppViewController:(BlueShiftNotificationViewController*)notificationController forNotification:(BlueShiftInAppNotification*)notification {
    void(^ presentInAppBlock)(void) = ^{
        @try {
            if (notificationController && (notificationController.notification.isFromInbox == YES || [self shouldDisplayInAppNotification:notificationController.displayOnScreen] == YES)) {
                [BlueshiftLog logInfo:@"Presenting in-app notification on the screen name" withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
                if(notificationController.delegate == nil) {
                    notificationController.delegate = self;
                }
                notificationController.inAppNotificationDelegate = self.inAppNotificationDelegate;
                if (notification && notification.templateStyle) {
                    [notificationController setTouchesPassThroughWindow: notification.templateStyle.enableBackgroundAction];
                }
                [notificationController show:YES];
            } else {
                self.currentNotificationController = nil;
                [BlueshiftLog logInfo:@"Skipped preseting in-app notification for screen - " withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
            }

        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            if (notificationController && notificationController.window == nil) {
                self.currentNotificationController = nil;
            }
        }
    };
    
    if ([NSThread isMainThread] == YES) {
        presentInAppBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            presentInAppBlock();
        });
    }
}


/// Check if the notification is eligible to display on the current screen.
/// @param displayOnScreen Name of screen where notification should be displayed
- (BOOL)shouldDisplayInAppNotification:(NSString*)displayOnScreen {
    if ([self inAppNotificationDisplayOnPage] == nil) {
        [BlueshiftLog logInfo:@"Current screen is not registered to receive in-app notification." withDetails:nil methodName:nil];
        return false;
    } else if ([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:displayOnScreen]) {
        if(![[self inAppNotificationDisplayOnPage] isEqualToString:displayOnScreen]) {
            [BlueshiftLog logInfo:@"Current screen name is different than in-app notification target screen name." withDetails:@{@"currentScreenName":self.inAppNotificationDisplayOnPage, @"inAppTargetScreenName":displayOnScreen} methodName:nil];
            return false;
        } else {
            return true;
        }
    }
    return true;
}

#pragma mark - In App events
// Notification Click Callbacks
-(void)inAppDidDismiss:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller  {
    self.currentNotificationController = nil;
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self startInAppMessageFetchTimer];
    }
}

-(void)inAppActionDidTapped:(NSDictionary *)notificationPayload withAction:(BlueshiftInAppActions)action  fromViewController:(BlueShiftNotificationViewController *)controller {
    if (action == BlueshiftInAppDismissAction) {
        [[BlueShift sharedInstance] trackInAppNotificationDismissWithParameter:notificationPayload canBacthThisEvent:NO];
    } else {
        [[BlueShift sharedInstance] trackInAppNotificationButtonTappedWithParameter:notificationPayload canBacthThisEvent:NO];
    }
    // invoke the inApp clicked callback method
    if ([self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidClick:)]) {
        [self.inAppNotificationDelegate inAppNotificationDidClick:notificationPayload];
    }
}   

// Notification render Callbacks
-(void)inAppDidShow:(NSDictionary *)notification fromViewController:(BlueShiftNotificationViewController *)controller {
    // Set opened by attribute for inbox
    NSMutableDictionary* mutableNotification = [notification mutableCopy];
    if (controller.notification.isFromInbox) {
        [mutableNotification setValue:kBSTrackingOpenedByUser forKey:kBSTrackingOpenedBy];
    } else {
        [mutableNotification setValue:kBSTrackingOpenedByPrefetch forKey:kBSTrackingOpenedBy];
    }
    [[BlueShift sharedInstance] trackInAppNotificationShowingWithParameter: mutableNotification canBacthThisEvent: NO];
    
    // invoke the inApp open callback method
    if ([self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidOpen:)]) {
        [self.inAppNotificationDelegate inAppNotificationDidOpen:notification];
    }
    [self updateInAppNotification: notification];
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self stopInAppMessageFetchTimer];
    }
}

@end
