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

@interface BlueshiftInboxViewModel()
@property NSDateFormatter* utcDateFormatter;

@end


@implementation BlueshiftInboxViewModel

- (void)reloadInboxMessagesInOrder:(NSComparisonResult)sortOrder handler:(void (^_Nonnull)(BOOL))success {
    if (!_inboxMessages) {
        _inboxMessages = [[NSMutableArray alloc] init];
    }
    
    [BlueshiftInboxManager getInboxMessages:sortOrder handler:^(BOOL status, NSMutableArray * _Nullable messages) {
        if (status) {
            self->_inboxMessages = messages;
        } else {
            [self->_inboxMessages removeAllObjects];
        }
        success(YES);
    }];
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
        [BlueshiftInboxManager markInboxMessageAsRead:message];
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
