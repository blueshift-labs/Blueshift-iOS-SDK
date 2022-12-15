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
#import "BlueshiftInboxManager.h"
#import "BlueshiftLog.h"


@interface BlueshiftInboxViewModel()
@property NSDateFormatter* utcDateFormatter;

@end


@implementation BlueshiftInboxViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _sectionInboxMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)reloadInboxMessagesWithHandler:(void (^_Nonnull)(BOOL))success {
    [BlueshiftInboxManager getInboxMessagesWithHandler:^(BOOL status, NSMutableArray * _Nullable messages) {
        if (status && messages) {
            [self->_sectionInboxMessages insertObject:[self filterAndSortMessages:messages] atIndex:0];
        } else {
            [self->_sectionInboxMessages removeAllObjects];
        }
        success(YES);
    }];
}

- (NSMutableArray<BlueshiftInboxMessage*>*)filterAndSortMessages:(NSMutableArray<BlueshiftInboxMessage*>*)messages {
    return [[self sortMessages:[self filterMessages:messages]] mutableCopy];
}

- (NSMutableArray<BlueshiftInboxMessage*>*)filterMessages:(NSMutableArray<BlueshiftInboxMessage*>*)messages {
    if (_messageFilter) {
        NSArray *filteredMessages = [messages filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return self->_messageFilter(object);
        }]];
        return [filteredMessages mutableCopy];
    } else {
        return messages;
    }
}

- (NSMutableArray<BlueshiftInboxMessage*>*)sortMessages:(NSMutableArray<BlueshiftInboxMessage*>*)messages {
    if (self.messageComparator) {
       NSArray* sortedMessages = [messages sortedArrayUsingComparator:self.messageComparator];
        return  [sortedMessages mutableCopy];
    }
    return messages;
}

- (BlueshiftInboxMessage * _Nullable)itemAtIndexPath:(NSIndexPath *)indexPath {
    @try {
        if(_sectionInboxMessages) {
            return [[_sectionInboxMessages objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        } else {
            return nil;
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
    return nil;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section {
    @try {
        return _sectionInboxMessages ? [_sectionInboxMessages objectAtIndex:section].count : 0;
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
    return 0;
}

- (NSUInteger)numberOfSections {
    return _sectionInboxMessages ?_sectionInboxMessages.count : 0;
}

- (void)markMessageAsRead:(BlueshiftInboxMessage*)message {
    if (message.readStatus == NO) {
        [BlueshiftInboxManager markInboxMessageAsRead:message];
        message.readStatus = YES;
    }
}

- (void)downloadImageForURLString:(NSString*)urlString completionHandler:(void (^)(NSData* _Nullable))handler {
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

@end
