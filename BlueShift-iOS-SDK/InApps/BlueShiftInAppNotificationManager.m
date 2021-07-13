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
        [self fetchNowAndUpcomingInAppMessageFromDB];
        [self startInAppMessageFetchTimer];
        [self deleteExpireInAppNotificationFromDataStore];
    }
}

- (void)startInAppMessageFetchTimer {
    if (self.inAppMessageFetchTimer == nil) {
        self.inAppMessageFetchTimer = [NSTimer scheduledTimerWithTimeInterval: [self inAppNotificationTimeInterval]
                                                                    target:self
                                                                  selector:@selector(fetchNowAndUpcomingInAppMessageFromDB)
                                                                  userInfo:nil
                                                                   repeats: YES];
        [BlueshiftLog logInfo:@"Started InAppMessageFetchTimer" withDetails:nil methodName:nil];
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
    if (notificationArray !=nil && notificationArray.count > 0) {
        for (int i = 0; i < notificationArray.count ; i++) {
            [self addInAppNotificationToDataStore: [notificationArray objectAtIndex: i]];
        }
    }
    handler(YES);
}

- (void) addInAppNotificationToDataStore: (NSDictionary *) payload {
    [self checkInAppNotificationExist: payload handler:^(BOOL status){
        if (status == NO) {
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
                @try {
                    entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
                }
                @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
                if(entity != nil) {
                    InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext: masterContext];
                    
                    if(inAppNotificationEntity != nil) {
                        [inAppNotificationEntity insert:payload usingPrivateContext:self.privateObjectContext andMainContext: masterContext handler:^(BOOL status) {
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
        }
    }];
}

/// Returns true if the In-App exists in the SDK database.
/// @param payload  In-App notification payload
/// @param handler completion handler
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
                        handler(status);
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
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        @try {
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:masterContext];
            [fetchRequest setEntity:entity];
            if(entity != nil && fetchRequest.entity != nil) {
                [masterContext performBlock:^{
                    @try {
                        NSError *error;
                        NSArray *results = [masterContext executeFetchRequest: fetchRequest error:&error];
                        NSArray *sortedList = [self sortedInAppMessageWithDate: results];
                        if (sortedList != nil && [sortedList count] > 0 && sortedList[[sortedList count] - 1]) {
                            InAppNotificationEntity *notification = results[[sortedList count] -1];
                            handler(YES, notification.id, notification.timestamp);
                        } else {
                            handler(NO, @"", @"");
                        }
                    } @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        handler(NO, @"", @"");
                    }
                }];
            } else {
                handler(NO, @"", @"");
            }
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            handler(NO, @"", @"");
        }
    } else {
        handler(NO, @"", @"");
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
                        NSError *saveError = nil;
                        if(context) {
                            [context save:&saveError];
                            if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                                [masterContext performBlock:^{
                                    @try {
                                        NSError *error = nil;
                                        [masterContext save:&error];
                                    } @catch (NSException *exception) {
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
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
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
            if (status) {
                [BlueshiftLog logInfo:@"Marked in-app message in DB as Displayed, messageId : " withDetails:notificationID methodName:nil];
            }
        }];
        }
    }
}

#pragma mark - Fetch in-app from the Datastore, filter and process it to display notification
- (void)fetchInAppNotificationsFromDataStore: (BlueShiftInAppTriggerMode) triggerMode  {
    
    if([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] && [self inAppNotificationDisplayOnPage] && self.currentNotificationController == nil) {
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
        if(masterContext == nil) {
            return;
        }
        [InAppNotificationEntity fetchAll:triggerMode forDisplayPage: [self inAppNotificationDisplayOnPage] context:masterContext withHandler:^(BOOL status, NSArray *results) {
            if (status) {
                NSArray *sortedArray = [self sortedInAppNotification: results];
                NSArray* filteredResults = [self filterInAppNotificationResults: sortedArray];
                if ([filteredResults count] > 0) {
                    InAppNotificationEntity *entity = [filteredResults objectAtIndex:0];
                    [BlueshiftLog logInfo:@"Fetched one in-app message from DB to display message id - " withDetails:entity.id methodName:nil];
                    [self createNotificationFromDictionary: entity];
                } else {
                    [BlueshiftLog logInfo:@"There are no pending in-apps to display at this moment for page." withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
                }
            } else {
                [BlueshiftLog logInfo:@"There are no pending in-apps to display for page." withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
            }
        }];
    } else {
        [BlueshiftLog logInfo:@"In-app fetch from DB skipped due to one of the below reasons." withDetails:@" 1. In-App notifications are not enabled, 2. Screen is not registered to receive in-apps. 3. Active or in-progress In-app notification detected." methodName:nil];
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
                [self removeInAppNotificationFromDB: entity.objectID];
                [BlueshiftLog logInfo:@"Deleted Expired notification, messageId : " withDetails:entity.id methodName:nil];
            } else {
                /* For 'Now' category msg show it if time is not expired */
                [nowFilteredResults addObject:entity];
            }
        } else if ([entity.triggerMode isEqualToString: @"upcoming"]) {
            double endTime = [entity.endTime doubleValue];
            double startTime = [entity.startTime doubleValue];
            
            if (currentTime > endTime) {
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
        if (self.currentNotificationController != nil) {
            [BlueshiftLog logInfo:@"Active In-app notification detected, skipped displaying current in-app." withDetails:nil methodName:nil];
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
                [self removeInAppNotificationFromDB: notification.objectID];
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if(isSlideInIconImagePresent) {
                [notificationVC loadAndCacheImageForURLString:notification.notificationContent.iconImage];
            }
            if (isBackgroundImagePresent) {
                [notificationVC loadAndCacheImageForURLString:notification.templateStyle.backgroundImage];
            }
            [self presentInAppViewController:notificationVC forNotification:notification];
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (isBackgroundImagePresent) {
                [notificationVC loadAndCacheImageForURLString:notification.templateStyle.backgroundImage];
            }
            if (isBannerImagePresent) {
                [notificationVC loadAndCacheImageForURLString:notification.notificationContent.banner];
            }
            [self presentInAppViewController:notificationVC forNotification:notification];
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
            if (notificationController && [self shouldDisplayInAppNotification:notificationController.displayOnScreen] == YES) {
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
                [BlueshiftLog logInfo:@"Skipped preseting in-app notification as screen is not registered to receive in-app notification or current screen is different than in-app notification display on screen." withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
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
        return false;
    } else if ([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:displayOnScreen]) {
        if(![[self inAppNotificationDisplayOnPage] isEqualToString:displayOnScreen]) {
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
    [[BlueShift sharedInstance].inAppImageDataCache removeAllObjects];
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self startInAppMessageFetchTimer];
    }
}

-(void)inAppActionDidTapped:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller {
    [[BlueShift sharedInstance] trackInAppNotificationButtonTappedWithParameter: notificationPayload canBacthThisEvent: NO];
    // invoke the inApp clicked callback method
    if ([self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidClick:)]) {
        [self.inAppNotificationDelegate inAppNotificationDidClick:notificationPayload];
    }
}   

// Notification render Callbacks
-(void)inAppDidShow:(NSDictionary *)notification fromViewController:(BlueShiftNotificationViewController *)controller {
    [[BlueShift sharedInstance] trackInAppNotificationShowingWithParameter: notification canBacthThisEvent: NO];
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
