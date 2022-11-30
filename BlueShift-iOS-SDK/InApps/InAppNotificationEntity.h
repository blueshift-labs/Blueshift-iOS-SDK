//
//  InAppNotificationEntity.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 12/07/19.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BlueShiftInAppTriggerMode.h"
#import "BlueShiftAppDelegate.h"
#import "BlueShiftInAppNotificationHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface InAppNotificationEntity : NSManagedObject

@property (nonatomic, retain) NSString *id;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *priority;
@property (nonatomic, retain) NSString *triggerMode;
@property (nonatomic, retain) NSString *eventName;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *displayOn;
@property (nonatomic, retain) NSString *timestamp;
@property (nonatomic, retain) NSString *availability;

@property (nonatomic, retain) NSNumber *startTime;
@property (nonatomic, retain) NSNumber *endTime;
@property (nonatomic, retain) NSNumber *createdAt;

@property (nonatomic, retain) NSData *payload;

@property (nonatomic) BOOL readStatus;


- (void) insert:(NSDictionary *)dictionary usingPrivateContext: (NSManagedObjectContext*)privateContext
 andMainContext: (NSManagedObjectContext*)masterContext handler:(void (^)(BOOL))handler;

+ (void)fetchAll:(BlueShiftInAppTriggerMode)triggerMode forDisplayPage:(NSString *)displayOn context:(NSManagedObjectContext *)masterContext  withHandler:(void (^)(BOOL, NSArray *))handler;

+ (void)fetchNotificationByID :(NSManagedObjectContext *)context forNotificatioID: (NSString *) notificationID request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler;

+ (void)updateInAppNotificationStatus:(NSManagedObjectContext *)context forNotificatioID: (NSString *) notificationID request: (NSFetchRequest*)fetchRequest notificationStatus:(NSString *)status andAppDelegate:(BlueShiftAppDelegate *)appdelegate handler:(void (^)(BOOL))handler;

+ (void)fetchInAppNotificationByStatus :(NSManagedObjectContext *)context forNotificatioID: (NSString *) status request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler;

/// Erase all the In app notifications records from the SDK database.
+ (void)eraseEntityData;

+ (void)markNotificationAsRead:(BlueshiftInboxMessage *)message;

NS_ASSUME_NONNULL_END

@end
