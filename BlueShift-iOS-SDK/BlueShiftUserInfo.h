//
//  BlueShiftUserInfo.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "BlueShift.h"

@interface BlueShiftUserInfo : NSObject

/// Set user email id.
/// Make sure you call BlueShiftUserInfo.sharedInstance()?.save() after setting/modifying any property of user info.
@property (nonatomic, strong) NSString* _Nullable email;

/// Set user customer id.
/// Make sure you call BlueShiftUserInfo.sharedInstance()?.save() after setting/modifying any property of user info.
@property (nonatomic, strong) NSString* _Nullable retailerCustomerID;

@property (nonatomic, strong) NSString* _Nullable name;
@property (nonatomic, strong) NSString* _Nullable firstName;
@property (nonatomic, strong) NSString* _Nullable lastName;

@property (nonatomic, strong) NSDate* _Nullable dateOfBirth;
@property (nonatomic, strong) NSString* _Nullable gender;
@property (nonatomic, strong) NSString* _Nullable education;

@property (nonatomic, strong) NSDate* _Nullable joinedAt;

@property (nonatomic, strong) NSString* _Nullable facebookID;

/// Unsubscribe from the push notifications.
/// Set this flag to true if you want to stop receiving push notifications for that user.
@property NSNumber* _Nullable  unsubscribed;

/// The data stored in the additionalUserInfo will be populated on server with `additional_user_info__` prefix to every key name.
/// If key is stored as `profession`, then server will popluate it as `additional_user_info__profession` in the events.
/// Make sure you call BlueShiftUserInfo.sharedInstance()?.save() after setting/modifying the user info.
@property NSMutableDictionary* _Nullable additionalUserInfo DEPRECATED_MSG_ATTRIBUTE("This property is deprecated,use extras proprety instead to save additional information.");

/// The data stored in the extras will be sent to server as it is as part of every event.
/// If key is stored as `profession`, then server will populate it as `profession` in the events.
/// Make sure you call BlueShiftUserInfo.sharedInstance()?.save() after setting/modifying the user info.
@property NSMutableDictionary* _Nullable extras;

/// Call save method after making any change in the BlueshiftUserInfo data to store the data.
- (void)save;

/// Use this method to erase the stored data.
+ (void)removeCurrentUserInfo;

+ (instancetype _Nullable) sharedInstance;

/// Returns saved User info as dictionary of key value pairs
- (NSDictionary *_Nonnull)toDictionary;

@end

