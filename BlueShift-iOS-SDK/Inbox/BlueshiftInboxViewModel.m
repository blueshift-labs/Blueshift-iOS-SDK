//
//  BlueshiftInboxViewModel.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 18/11/22.
//

#import "BlueshiftInboxViewModel.h"
#import "BlueShift.h"
#import "BlueshiftConstants.h"
#import "InAppNotificationEntity.h"
#import "BlueshiftAppDelegate.h"
#import "BlueShiftRequestOperationManager.h"

@interface BlueshiftInboxViewModel()
@property NSDateFormatter* utcDateFormatter;

@end


@implementation BlueshiftInboxViewModel

- (void)reloadInboxMessagesInOrder:(NSComparisonResult)sortOrder handler:(void (^_Nonnull)(BOOL))success {
    if (!_inboxMessages) {
        _inboxMessages = [[NSMutableArray alloc] init];
    }
    NSManagedObjectContext *context = [BlueShift sharedInstance].appDelegate.managedObjectContext;
    if(context) {
        [InAppNotificationEntity fetchAll:BlueShiftInAppTriggerModeInbox forDisplayPage: @"" context:context withHandler:^(BOOL status, NSArray *results) {
            if (status) {
                [self->_inboxMessages removeAllObjects];
                NSArray* orderedResults;
                if ([results count] > 0) {
                    if (sortOrder == NSOrderedDescending) {
                        orderedResults = results;
                    } else {
                        orderedResults = [[results reverseObjectEnumerator] allObjects];
                    }
                    for (InAppNotificationEntity *inApp in orderedResults) {
                        NSDictionary *payloadDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:inApp.payload];
                        NSDictionary* inboxDict = payloadDictionary[@"data"][@"inbox"];
                        NSString* title = [inboxDict valueForKey:@"title"];
                        NSString* detail = [inboxDict valueForKey:@"details"];
                        NSString* icon = [inboxDict valueForKey:@"icon"];
                        
                        BlueshiftInboxMessage *msg = [[BlueshiftInboxMessage alloc] initMessageId:inApp.id objectId:inApp.objectID inAppType:inApp.type readStatus:inApp.readStatus title:title detail:detail date:[self getLocalDateFromUTCDate:inApp.timestamp] iconURL:icon messagePayload:payloadDictionary];
                        [self->_inboxMessages addObject:msg];
                    }
                } else {
                    self->_inboxMessages = [@[] mutableCopy];
                }
                success(YES);
            } else {
                success(NO);
            }
        }];
    }
}

- (BlueshiftInboxMessage * _Nullable)itemAtIndexPath:(NSIndexPath *)indexPath {
    if(_inboxMessages && _inboxMessages.count > indexPath.row && indexPath.row >= 0){
        return [_inboxMessages objectAtIndex:indexPath.row];
    } else {
        return nil;
    }
}
- (NSUInteger)numberOfItems {
    return _inboxMessages ? _inboxMessages.count : 0;
}
- (NSUInteger)numberOfSections {
    return 1;
}

- (void)markMessageAsRead:(BlueshiftInboxMessage*)message {
    if (message.readStatus == NO) {
        [BlueShift.sharedInstance markInboxMessageAsRead:message];
        message.readStatus = YES;
    }
}

- (void)downloadImageForURLString:(NSString*)urlString completionHandler:(void (^_Nonnull)(NSData* _Nullable))handler {
    if (urlString) {
        NSURL *url = [NSURL URLWithString:urlString];
        [BlueShiftRequestOperationManager.sharedRequestOperationManager downloadImageForURL:url handler:^(BOOL status, NSData *data, NSError *error) {
            if (status) {
                handler(data);
            } else {
                handler(nil);
            }
        }];
    } else {
        handler(nil);
    }
}

- (NSString*)getDefaultFormatDate:(NSDate*)createdAtDate {
    return [self sometimeAgoStringFromStringDate:createdAtDate];
}

- (NSDate*)getLocalDateFromUTCDate:(NSString*)createdAtDateString {
    NSDateFormatter *dateFormatter = [self getUTCDateFormatter];
    NSDate* utcDate = [dateFormatter dateFromString:createdAtDateString];
    return utcDate;
}

// TODO: check for the different regional calendar types
- (NSString*)sometimeAgoStringFromStringDate:(NSDate*)createdAtDate {
    if (createdAtDate) {
        NSCalendar *calendar = [[NSCalendar currentCalendar] initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
        [calendar setTimeZone:[NSTimeZone systemTimeZone]];
        [calendar setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
        
        NSDateComponents *components = [calendar components:(NSCalendarUnitDay |NSCalendarUnitWeekOfMonth | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:createdAtDate toDate:[NSDate date] options:0];
        NSDateComponentsFormatter* timeFormatter = [[NSDateComponentsFormatter alloc] init];
        timeFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        
        if(components.year > 0) {
            timeFormatter.allowedUnits = NSCalendarUnitYear;
        } else if(components.month > 0) {
            timeFormatter.allowedUnits = NSCalendarUnitMonth;
        } else if(components.weekOfMonth > 0) {
            timeFormatter.allowedUnits = NSCalendarUnitWeekOfMonth;
        } else if(components.day > 0) {
            timeFormatter.allowedUnits = NSCalendarUnitDay;
        } else if(components.hour > 0) {
            timeFormatter.allowedUnits = NSCalendarUnitHour;
        } else if(components.minute > 0) {
            timeFormatter.allowedUnits = NSCalendarUnitMinute;
        } else if(components.second > 0) {
            timeFormatter.allowedUnits = NSCalendarUnitSecond;
        }
        
        NSString* timeString = [timeFormatter stringFromDateComponents:components];
        return [NSString stringWithFormat:@"%@ ago",timeString];
    }
    return nil;
}

-(NSDateFormatter*)getUTCDateFormatter {
    if (_utcDateFormatter) {
        return _utcDateFormatter;
    } else {
        _utcDateFormatter = [[NSDateFormatter alloc] init];
        [_utcDateFormatter setDateFormat:kDefaultDateFormat];
        [_utcDateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601]];
        [_utcDateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
        [_utcDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        return _utcDateFormatter;
    }
}

@end
