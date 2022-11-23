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

@end


@implementation BlueshiftInboxViewModel
- (instancetype)init {
    self = [super init];
    if (self) {
        _blueshiftInboxDateFormatType = BlueshiftInboxDateFormatTypeSomeTimeAgo;
        _titleArray = @[@[@"Iron Man",
                          @"Jon Favreau[27] Mark Fergus & Hawk Ostby and Art Marcum & Matt Holloway[27][28] Avi Arad and Kevin Feige",
                          @"https://picsum.photos/id/1/200/200"],
                        @[@"The Incredible Hulk",
                          @"Louis Leterrier[29] Zak Penn[30]  Avi Arad, Gale Anne Hurd and Kevin Feige",
                          @"https://picsum.photos/id/2/200/200"],
                        @[@"Iron Man 2",
                          @"Jon Favreau[31] Justin Theroux[32]  Kevin Feige",
                          @"https://picsum.photos/id/3/200/200"],
                        @[@"Thor",
                          @"Kenneth Branagh[33] Ashley Edward Miller & Zack Stentz and Don Payne[34]",
                          @"https://picsum.photos/id/4/200/200"],
                        @[@"Captain America: The First Avenger",
                          @"Joe Johnston[35]  Christopher Markus & Stephen McFeely[36]",
                          @"https://picsum.photos/id/5/200/200"],
                        @[@"Marvel's The Avengers",
                          @"Joss Whedon[37]",
                          @"https://picsum.photos/id/6/200/200"],
                        @[@"Iron Man 3",
                          @"Shane Black[38] Drew Pearce and Shane Black[38][39] Kevin Feige",
                          @"https://picsum.photos/id/7/200/200"],
                        @[@"Thor: The Dark World",
                          @"Alan Taylor[40] Christopher L. Yost and Christopher Markus & Stephen McFeely[41]",
                          @"https://picsum.photos/id/8/200/200"],
                        @[@"Captain America: The Winter Soldier",
                          @"Anthony and Joe Russo[42] Christopher Markus & Stephen McFeely[43]",
                          @"https://picsum.photos/id/9/200/200"],
                        @[@"Guardians of the Galaxy",
                          @"James Gunn[44]  James Gunn and Nicole Perlman[45]",
                          @"https://picsum.photos/id/10/200/200"],
                        @[@"Avengers: Age of Ultron",
                          @"Joss Whedon[46]",
                          @"https://picsum.photos/id/11/200/200"],
                        @[@"Ant-Man",
                          @"Peyton Reed[47] Edgar Wright & Joe Cornish and Adam McKay & Paul Rudd[48]",
                          @"https://picsum.photos/id/12/200/200"],
                        @[@"Captain America: Civil War",
                          @"Anthony and Joe Russo[49] Christopher Markus & Stephen McFeely[49]  Kevin Feige",
                          @"https://picsum.photos/id/13/200/200"],
                        @[@"Doctor Strange",
                          @"Scott Derrickson[50]  Jon Spaihts and Scott Derrickson & C. Robert Cargill[51]",
                          @"https://picsum.photos/id/14/200/200"],
                        @[@"Guardians of the Galaxy Vol. 2",
                          @"James Gunn[45]",
                          @"https://picsum.photos/id/15/200/200"],
                        @[@"Spider-Man: Homecoming",
                          @"Jon Watts[52] Jonathan Goldstein & John Francis Daley",
                          @"https://picsum.photos/id/16/200/200"],
                        @[@"Thor: Ragnarok",
                          @"Taika Waititi[54] Eric Pearson and Craig Kyle & Christopher L. Yost[55][56] Kevin @Feige",
                          @"https://picsum.photos/id/17/200/200"],
                        @[@"Black Panther",
                          @"Ryan Coogler[57]  Ryan Coogler & Joe Robert Cole[58][59]",
                          @"https://picsum.photos/id/18/200/200"],
                        @[@"Avengers: Infinity War",
                          @"Anthony and Joe Russo[60] Christopher Markus & Stephen McFeely[61]",
                          @"https://picsum.photos/id/19/200/200"],
                        @[@"Ant-Man and the Wasp",
                          @"Peyton Reed[62] Chris McKenna & Erik Sommers and Paul Rudd & Andrew Barrer & Gabriel @Ferrari[63] Kevin Feige and Stephen Broussard",
                          @"https://picsum.photos/id/20/200/200"],
                        @[@"Captain Marvel",
                          @"Anna Boden & Ryan Fleck[64] Anna Boden & Ryan Fleck & Geneva Robertson-Dworet[65] Kevin @Feige",
                          @"https://picsum.photos/id/21/200/200"],
                        @[@"Avengers: Endgame",
                          @"Anthony and Joe Russo[60] Christopher Markus & Stephen McFeely[61]",
                          @"https://picsum.photos/id/22/200/200"],
                        @[@"Spider-Man: Far From Home",
                          @"Jon Watts[66] Chris McKenna & Erik Sommers[67]  Kevin Feige",
                          @"https://picsum.photos/id/23/200/200"],];
    }
    return self;
}

- (void)reloadInboxMessages:(void (^_Nonnull)(BOOL))success {
    if (!_inboxMessages) {
        _inboxMessages = [[NSMutableArray alloc] init];
    }
    NSManagedObjectContext *context = [BlueShift sharedInstance].appDelegate.managedObjectContext;
    if(context) {
        [InAppNotificationEntity fetchAll:BlueShiftInAppNoTriggerEvent forDisplayPage: @"" context:context withHandler:^(BOOL status, NSArray *results) {
            if (status) {
                [self->_inboxMessages removeAllObjects];
                if ([results count] > 0) {
                    NSArray* orderedResults = [[results reverseObjectEnumerator] allObjects];
                    for (InAppNotificationEntity *inApp in orderedResults) {
                        NSDictionary *payloadDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:inApp.payload];
                        //                        NSDictionary* inboxDict = payloadDictionary[@"data"][@"inapp"][@"inbox"];
                        int randomNumber = arc4random() % 22;
                        BlueshiftInboxMessage *msg = [[BlueshiftInboxMessage alloc] initMessageId:inApp.id objectId:inApp.objectID inAppType:inApp.type readStatus:NO title:self->_titleArray[randomNumber][0] detail:self->_titleArray[randomNumber][1] date:inApp.timestamp iconURL:self->_titleArray[randomNumber][2] message:payloadDictionary];
                        [self->_inboxMessages addObject:msg];
                    }
                } else {
                    self->_inboxMessages = [@[] mutableCopy];
                }
                success(YES);
            }
            success(NO);
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

- (NSString*)getFormattedDateForDate:(NSString*)createdAtDateString {
    if (_blueshiftInboxDateFormatType == BlueshiftInboxDateFormatTypeFormatString) {
        NSDateFormatter *dateFormatter = [self getUTCDateFormatter];

        NSDate *date = [dateFormatter dateFromString:createdAtDateString];
        if(_blueshiftInboxDateFormat) {
            [dateFormatter setDateFormat:_blueshiftInboxDateFormat];
        }
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        return [dateFormatter stringFromDate:date];
    } else {
        return [self sometimeAgoStringFromStringDate:createdAtDateString];
    }
}

// TODO: check for the different regional calendar types
- (NSString*)sometimeAgoStringFromStringDate:(NSString*)createdAtDateString {
    NSDateFormatter *dateFormatter = [self getUTCDateFormatter];
    
    NSDate *createdAtDate = [dateFormatter dateFromString:createdAtDateString];
    NSCalendar *calendar = [[NSCalendar currentCalendar] initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
    [calendar setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
//    [calendar setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    
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

-(NSDateFormatter*)getUTCDateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDefaultDateFormat];
    [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601]];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    return dateFormatter;
}


@end
