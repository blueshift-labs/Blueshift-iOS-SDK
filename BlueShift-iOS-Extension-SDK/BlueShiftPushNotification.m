//
//  BlueShiftPushNotification.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//


#import "BlueShiftPushNotification.h"
#import "BlueshiftExtensionConstants.h"

API_AVAILABLE(ios(10.0))
static BlueShiftPushNotification *_sharedInstance = nil;

@implementation BlueShiftPushNotification

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (BOOL)isBlueShiftPushNotification:(UNNotificationRequest *)request {
    if([request.content.userInfo objectForKey:kNotificationMediaImageURL] || [request.content.userInfo objectForKey:kNotificationMediaGIFURL] || [request.content.userInfo objectForKey:kNotificationMediaAudioURL] || [request.content.userInfo objectForKey:kNotificationMediaVideoURL] || [request.content.userInfo objectForKey:kNotificationCarouselElements] || [request.content.userInfo objectForKey:kNotificationMessageUDIDKey]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)hasBlueShiftAttachments {
    if([BlueShiftPushNotification sharedInstance].attachments && [BlueShiftPushNotification sharedInstance].attachments.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request {
    if ([request.content.categoryIdentifier isEqualToString: kNotificationCarouselIdentifier] || [request.content.categoryIdentifier isEqualToString: kNotificationCarouselAnimationIdentifier]) {
        return [self carouselAttachmentsDownload:request];
    } else {
        [self addNotificationCategory:request];
        return [self mediaAttachmentDownlaod:request];
    }
}

- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request andAppGroupID:(NSString * _Nullable)appGroupID {
    return [self integratePushNotificationWithMediaAttachementsForRequest:request];
}

- (NSArray *)carouselAttachmentsDownload:(UNNotificationRequest *)request {
    NSArray *images = [request.content.userInfo objectForKey:kNotificationCarouselElements];
    NSMutableArray *attachments = [[NSMutableArray alloc]init];
    self.attachments = attachments;
    [images enumerateObjectsUsingBlock:
     ^(NSDictionary *image, NSUInteger index, BOOL *stop)
     {
         NSURL *imageURL = [NSURL URLWithString:[image objectForKey:kNotificationMediaImageURL]];
         NSData *imageData = nil;
         if(imageURL != nil && imageURL.absoluteString.length != 0) {
             imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
             if(imageData) {
                 NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                 NSString  *documentsDirectory = [paths objectAtIndex:0];
                 
                 NSString *attachmentName = [NSString stringWithFormat:@"image_%lu.jpg", (unsigned long)index];
                 NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
                 NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
                 NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
                 [imageData writeToFile:filePathToWrite atomically:YES];
                 
                 NSError *error;
                 UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error];
                 if (error) {
                     NSLog(@"[Blueshift] Failed to create carousel image attachment %@", error);
                 }
                 if(attachment != nil) {
                     [attachments addObject:attachment];
                     self.attachments = attachments;
                 }
             }
         }
     }];
    return attachments;
}

- (NSArray *)mediaAttachmentDownlaod:(UNNotificationRequest *)request {
    NSURL *imageURL = [NSURL URLWithString:[request.content.userInfo objectForKey:kNotificationMediaImageURL]];
    NSURL *videoURL = [NSURL URLWithString:[request.content.userInfo objectForKey:kNotificationMediaVideoURL]];
    NSURL *audioURL = [NSURL URLWithString:[request.content.userInfo objectForKey:kNotificationMediaAudioURL]];
    NSURL *gifURL   = [NSURL URLWithString:[request.content.userInfo objectForKey:kNotificationMediaGIFURL]];
    
    NSData *imageData = nil;
    NSData *videoData = nil;
    NSData *audioData = nil;
    NSData *gifData   = nil;
    
    NSMutableArray *attachments = [[NSMutableArray alloc]init];
    
    if(imageURL != nil) {
        imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
        if(imageData) {
            NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *attachmentName = [NSString stringWithFormat:kNotificationMediaImageName];
            NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
            NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
            NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
            [imageData writeToFile:filePathToWrite atomically:YES];
            
            NSError *error;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error];
            if (error) {
                NSLog(@"[Blueshift] Failed to create image attachment %@", error);
            }
            if(attachment != nil) {
                [attachments addObject:attachment];
            }
        }
    }
    if(videoURL != nil) {
        videoData = [[NSData alloc] initWithContentsOfURL: videoURL];
        if(videoData) {
            NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *attachmentName = [NSString stringWithFormat:kNotificationMediaVideoName];
            NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
            NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
            NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
            [videoData writeToFile:filePathToWrite atomically:YES];
            
            NSError *error;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error];
            if (error) {
                NSLog(@"[Blueshift] Failed to create video attachment %@", error);
            }
            if(attachment != nil) {
                [attachments addObject:attachment];
            }
        }
    }
    if(gifURL != nil) {
        gifData = [[NSData alloc] initWithContentsOfURL: gifURL];
        if(gifData) {
            NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *attachmentName = [NSString stringWithFormat:kNotificationMediaGIFName];
            NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
            NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
            NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
            [gifData writeToFile:filePathToWrite atomically:YES];
            
            NSError *error;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error];
            if (error) {
                NSLog(@"[Blueshift] Failed to create gif image attachment %@", error);
            }
            if(attachment != nil) {
                [attachments addObject:attachment];
            }
        }
    }
    if(audioURL != nil) {
        audioData = [[NSData alloc] initWithContentsOfURL: audioURL];
        if(audioData) {
            NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *attachmentName = [NSString stringWithFormat:kNotificationMediaAudioName];
            NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
            NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
            NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
            [audioData writeToFile:filePathToWrite atomically:YES];
            
            NSError *error;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error];
            if (error) {
                NSLog(@"[Blueshift] Failed to create audio attachment %@", error);
            }
            if(attachment != nil) {
                [attachments addObject:attachment];
            }
        }
    }
    self.attachments = attachments;
    return attachments;
}

- (void)addNotificationCategory:(UNNotificationRequest *)request{
    @try {
        NSDictionary* userInfo = request.content.userInfo;
        NSDictionary* aps = userInfo[kNotificationAPS];
        NSString* pushCategory = aps[kNotificationCategory];
        NSString* forceReplaceCategory = userInfo[kNotificationForceReplaceCategory];
        NSArray* actionsArray = userInfo[kNotificationActions];
        
        if(actionsArray && actionsArray.count > 0 && pushCategory) {
            __block bool isCategoryRegistrationComplteted = NO;
            NSMutableArray<UNNotificationAction *>* notificationActions = [self getNotificationActions:actionsArray];
            if (notificationActions.count > 0) {
                UNNotificationCategory* category = [UNNotificationCategory categoryWithIdentifier:pushCategory actions:notificationActions intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
                [[UNUserNotificationCenter currentNotificationCenter] getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull existingCategories) {
                    NSMutableSet<UNNotificationCategory *> * updatedCategories = [existingCategories mutableCopy];
                    // Add category if it is not present in the UNUserNotificationCenter
                    if([self isCatgoryExists:category.identifier inSet:updatedCategories] == NO) {
                        [updatedCategories addObject:category];
                        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:updatedCategories];
                    } else if(forceReplaceCategory && [forceReplaceCategory boolValue] == YES) {
                        // Remove old category with same id(if present) in order to replace it.
                        [self removeDuplicateCategory:category.identifier fromSet:updatedCategories];
                        [updatedCategories addObject:category];
                        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:updatedCategories];
                    }
                    // set the flag to true to exit the thread sleep loop.
                    isCategoryRegistrationComplteted = YES;
                }];
                int counter = 0;
                // Sleep thread till the category registration finishes or counter reaches to 20 (2 seconds)
                while (isCategoryRegistrationComplteted == NO && counter < kThreadSleepIterations) {
                    counter++;
                    [NSThread sleepForTimeInterval:kThreadSleepTimeInterval];
                }
            }
        }
    } @catch (NSException *exception) {
    }
}

- (NSMutableArray*)getNotificationActions:(NSArray*)actions {
    NSMutableArray<UNNotificationAction *>* notificationActions = [NSMutableArray new];
    @try {
        if (actions && actions.count > 0) {
            // Support maximum 5 action items
            NSInteger actionsCount = (actions.count > kNotificationMaxSupportedActions) ? kNotificationMaxSupportedActions : actions.count;
            for(int counter = 0; counter < actionsCount; counter++) {
                NSDictionary* actionItem = actions[counter];
                UNNotificationActionOptions actionOption = UNNotificationActionOptionForeground;
                NSString* actionType = actionItem[kNotificationActionType];
                if (actionType && ![actionType isEqualToString:kNotificationActionTypeOpen]) {
                    if([actionType isEqualToString:kNotificationActionTypeDestructive])
                        actionOption = UNNotificationActionOptionDestructive;
                    else if([actionType isEqualToString: kNotificationActionTypeAuthenticationRequired])
                        actionOption = UNNotificationActionOptionAuthenticationRequired;
                    else if([actionType isEqualToString:kNotificationActionTypeNone])
                        actionOption = UNNotificationActionOptionNone;
                }
                if (actionItem[kNotificationActionTitle]) {
                    // create unique action identifier if identifier field is missing in payload
                    NSString* actionIdentifier = actionItem[kNotificationActionIdentifier] ? actionItem[kNotificationActionIdentifier] : [NSString stringWithFormat:@"%@_%i",kNotificationDefaultActionIdentifier,counter];
                    UNNotificationAction* action = [UNNotificationAction actionWithIdentifier:actionIdentifier title:actionItem[kNotificationActionTitle] options:actionOption];
                    [notificationActions addObject:action];
                }
            }
        }
    } @catch (NSException *exception) {
    }
    return notificationActions;
}

// Remove duplicate categories from the set using category identifier
- (void)removeDuplicateCategory:(NSString*)categoryIdentifier fromSet:(NSMutableSet*)categories {
    @try {
        NSArray* categoriesArray = [categories allObjects];
        for(UNNotificationCategory* categoryItem in categoriesArray) {
            if ([categoryItem.identifier isEqualToString:categoryIdentifier]) {
                [categories removeObject:categoryItem];
            }
        }
    } @catch (NSException *exception) {
    }
}

- (BOOL)isCatgoryExists:(NSString*)categoryIdentifier inSet:(NSSet*)categories{
    NSArray* categoriesArray = [categories allObjects];
    for(UNNotificationCategory* categoryItem in categoriesArray) {
        if ([categoryItem.identifier isEqualToString:categoryIdentifier]) {
            return YES;
        }
    }
    return NO;
}

- (NSNumber* _Nullable)getUpdatedBadgeNumberForRequest:(UNNotificationRequest *)request {
    if ([self isAutoUpdateBadgePushNotification:request]) {
        __block NSNumber* badgeCount;
        [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
            badgeCount = [NSNumber numberWithUnsignedInteger: notifications.count];
        }];
        int counter = 0;
        // Sleep thread till the it gets count of notificaitons or counter reaches to 20 (2 seconds)
        while (!badgeCount && counter < kThreadSleepIterations) {
            counter++;
            [NSThread sleepForTimeInterval:kThreadSleepTimeInterval];
        }
        // Increment the number by one to include current notification
        if (badgeCount) {
            return [NSNumber numberWithInt: badgeCount.intValue + 1];
        } else {
            return [NSNumber numberWithInt: 1];
        }
    }
    return nil;
}

- (BOOL)isAutoUpdateBadgePushNotification:(UNNotificationRequest *)request {
    if([[request.content.userInfo objectForKey:kAutoUpdateBadge] boolValue] == YES) {
        return YES;
    }
    return NO;
}

@end
