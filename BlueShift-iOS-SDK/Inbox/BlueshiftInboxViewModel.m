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
    [BlueshiftInboxManager getCachedInboxMessagesWithHandler:^(BOOL status, NSMutableArray * _Nullable messages) {
        [self->_sectionInboxMessages removeAllObjects];
        if (status && messages) {
            [self->_sectionInboxMessages insertObject:[self getSectionedMessages:messages] atIndex:0];
        }
        success(YES);
    }];
}

- (NSMutableArray<BlueshiftInboxMessage*>*)getSectionedMessages:(NSMutableArray<BlueshiftInboxMessage*>*)messages {
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

- (NSIndexPath* _Nullable)getIndexPathForMessageId:(NSString*)messageId {
    if (_sectionInboxMessages && _sectionInboxMessages.count > 0) {
        for(int sectionCounter = 0; sectionCounter < _sectionInboxMessages.count; sectionCounter++) {
            NSUInteger row = [self->_sectionInboxMessages[sectionCounter] indexOfObjectPassingTest:^BOOL(BlueshiftInboxMessage*  _Nonnull obj, NSUInteger idx2, BOOL * _Nonnull stop) {
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

- (void)markMessageAsRead:(BlueshiftInboxMessage*)message {
    if (message.readStatus == NO) {
        [BlueshiftInboxManager markInboxMessageAsRead:message];
        message.readStatus = YES;
    }
}

- (NSData*)getCachedImageDataForURL:(NSString*)url {
    return [BlueShiftRequestOperationManager.sharedRequestOperationManager getCachedImageDataForURL:url];
}

- (void)downloadImageForMessage:(BlueshiftInboxMessage*)message {
    if (message.iconImageURL) {
        NSURL *url = [NSURL URLWithString:message.iconImageURL];
        [BlueShiftRequestOperationManager.sharedRequestOperationManager downloadImageForURL:url handler:^(BOOL status, NSData *data, NSError *error) {
            if (status && self->_viewDelegate) {
                NSIndexPath *indexPath = [self getIndexPathForMessageId:message.messageUUID];
                if (indexPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->_viewDelegate reloadTableViewCellForIndexPath:indexPath animated:NO];
                    });
                }
            }
        }];
    }
}

- (NSString*)getDefaultFormatDate:(NSDate*)createdAtDate {
    return [NSDateFormatter localizedStringFromDate:createdAtDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
}

@end
