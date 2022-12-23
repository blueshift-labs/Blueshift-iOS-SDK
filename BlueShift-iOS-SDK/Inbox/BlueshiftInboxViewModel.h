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

- (void)reloadTableViewCellForIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

@end

@interface BlueshiftInboxViewModel: NSObject

@property (weak) id<BlueshiftInboxViewDelegate> _Nullable viewDelegate;

@property NSMutableArray<NSMutableArray*>* sectionInboxMessages;

@property BOOL(^ _Nonnull messageFilter)(BlueshiftInboxMessage*);

@property (copy) NSComparisonResult(^ _Nonnull messageComparator)(BlueshiftInboxMessage*, BlueshiftInboxMessage*);

- (void)downloadImageForMessage:(BlueshiftInboxMessage*)message;

- (NSString*)getDefaultFormatDate:(NSDate*)createdAtDate;

- (NSData*)getCachedImageDataForURL:(NSString*)url;

- (void)reloadInboxMessagesWithHandler:(void (^_Nonnull)(BOOL))success;

- (BlueshiftInboxMessage * _Nullable)itemAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;

- (NSUInteger)numberOfSections;

- (void)markMessageAsRead:(BlueshiftInboxMessage*)message;


@end

NS_ASSUME_NONNULL_END
