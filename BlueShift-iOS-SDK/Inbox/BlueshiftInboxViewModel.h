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

- (void)reloadInboxMessagesInOrder:(NSComparisonResult)sortOrder handler:(void (^_Nonnull)(BOOL))success;

- (BlueshiftInboxMessage * _Nullable)itemAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)numberOfItems;

- (NSUInteger)numberOfSections;


@end

@interface BlueshiftInboxViewModel: NSObject <BlueshiftInboxViewDelegate>

@property NSArray* titleArray;

@property NSMutableArray* inboxMessages;
@property NSString* _Nullable blueshiftInboxDateFormat;

- (void)downloadImageForURLString:(NSString*)urlString completionHandler:(void (^_Nonnull)(NSData* _Nullable))success;

- (NSString*)getDefaultFormatDate:(NSDate*)createdAtDate;

@end

NS_ASSUME_NONNULL_END
