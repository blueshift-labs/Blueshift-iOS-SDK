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

@interface BlueshiftInboxViewModel: NSObject

/// Get sectioned messages to display inside the tableview.
/// This can be used as data source for the inbox tableview.
@property NSMutableArray<NSMutableArray*>* sectionInboxMessages;

/// Assgin the message filter to filter our the messages based on your usecase  to filter the `sectionInboxMessages` list.
@property BOOL(^ _Nonnull messageFilter)(BlueshiftInboxMessage*);

/// Assign comparator based on your usecase to sort the `sectionInboxMessages` list.
@property (copy) NSComparisonResult(^ _Nonnull messageComparator)(BlueshiftInboxMessage*, BlueshiftInboxMessage*);

/// Get SDK default device locale based date in string format.
///   - Parameter createdAtDate: pass the `NSDate` to the function
///   - Returns  formatted date as`NSString`
- (NSString*)getDefaultFormatDate:(NSDate*)createdAtDate;

/// Calling this method, SDK will fetch all valid messages from the inbox db from the local and update the `sectionInboxMessages`.
/// Use `sectionInboxMessages` as your datasource to your tableview. On the succes callback, you can just refresh the tableview.
/// - Parameter success: callback telling you the reload is complete.
- (void)reloadInboxMessagesWithHandler:(void (^_Nonnull)(BOOL))success;

/// Get item at the given indexpath. SDK will parse the indexpath to get the selected item from the `sectionInboxMessages`.
/// - Parameter indexPath: indexPath of the selected row of tableview.
/// - Returns `BlueshiftInboxMessage` for the given indexPath
- (BlueshiftInboxMessage * _Nullable)itemAtIndexPath:(NSIndexPath *)indexPath;

/// Calling this method will return the number of items in section by looking at `sectionInboxMessages` and given `section` value.
/// - Parameter section: section to get the number of items for.
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;


/// Returns the number of sections by looking at the `sectionInboxMessages`.
- (NSUInteger)numberOfSections;

@end

NS_ASSUME_NONNULL_END
