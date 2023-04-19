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

@implementation BlueshiftInboxViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _sectionInboxMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)reloadInboxMessagesWithHandler:(void (^_Nonnull)(BOOL))success {
    __weak __typeof(self)weakSelf = self;
    [BlueshiftInboxManager getCachedInboxMessagesWithHandler:^(BOOL status, NSMutableArray * _Nullable messages) {
        [weakSelf.sectionInboxMessages removeAllObjects];
        if (status && messages) {
            [weakSelf.sectionInboxMessages insertObject:[self getSectionedMessages:messages] atIndex:0];
        }
        success(YES);
    }];
}

- (NSMutableArray<BlueshiftInboxMessage*>*)getSectionedMessages:(NSMutableArray<BlueshiftInboxMessage*>*)messages {
    return [[self sortMessages:[self filterMessages:messages]] mutableCopy];
}

- (NSMutableArray<BlueshiftInboxMessage*>*)filterMessages:(NSMutableArray<BlueshiftInboxMessage*>*)messages {
    if (_messageFilter) {
        __weak __typeof(self)weakSelf = self;
        NSArray *filteredMessages = [messages filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return weakSelf.messageFilter(object);
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

- (NSIndexPath* _Nullable)getIndexPathForMessageId:(NSString*)messageId {
    if (_sectionInboxMessages && _sectionInboxMessages.count > 0) {
        for(int sectionCounter = 0; sectionCounter < _sectionInboxMessages.count; sectionCounter++) {
            NSUInteger row = [_sectionInboxMessages[sectionCounter] indexOfObjectPassingTest:^BOOL(BlueshiftInboxMessage*  _Nonnull obj, NSUInteger idx2, BOOL * _Nonnull stop) {
                return [obj.messageUUID isEqualToString:messageId];
            }];
            if (row != NSNotFound) {
                return [NSIndexPath indexPathForRow:row inSection:sectionCounter];
            }
        }
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
    return _sectionInboxMessages ?_sectionInboxMessages.count : 1;
}

- (NSString*)getDefaultFormatDate:(NSDate*)createdAtDate {
    return [NSDateFormatter localizedStringFromDate:createdAtDate dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
}

@end
