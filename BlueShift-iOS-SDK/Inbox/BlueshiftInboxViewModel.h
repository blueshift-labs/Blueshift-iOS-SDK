//
//  BlueshiftInboxViewModel.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 18/11/22.
//

#import <Foundation/Foundation.h>
#import "BlueshiftInboxMessage.h"
#import "BlueshiftInboxTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BlueshiftInboxViewDelegate <NSObject>

@optional

@property NSMutableArray* inboxMessages;

- (void)reloadInboxMessagesWithHandler:(void (^_Nonnull)(BOOL))success;

- (BlueshiftInboxMessage * _Nullable)itemAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;

- (NSUInteger)numberOfSections;

- (void)markMessageAsRead:(BlueshiftInboxMessage*)message;

@end

@interface BlueshiftInboxViewModel: NSObject <BlueshiftInboxViewDelegate>

@property NSArray* titleArray;

@property NSMutableArray<NSMutableArray*>* sectionInboxMessages;
@property NSString* _Nullable blueshiftInboxDateFormat;
@property BOOL(^ _Nullable messageFilter)(BlueshiftInboxMessage*);
@property (copy) NSComparisonResult(^ _Nullable messageComparator)(BlueshiftInboxMessage*, BlueshiftInboxMessage*);

- (void)downloadImageForURLString:(NSString*)urlString completionHandler:(void (^)(NSData* _Nullable))success;

- (NSString*)getDefaultFormatDate:(NSDate*)createdAtDate;

@end

NS_ASSUME_NONNULL_END
