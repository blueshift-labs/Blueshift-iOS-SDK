//
//  BlueShiftLiveContent.h
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 13/01/17.
//  Copyright © 2017 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftLiveContent : NSObject

/// Fetch live content based on email id using the live content slot. SDK will use the email id saved in the BlueshiftUserInfo class.
/// - Parameters:
///   - slotName:name of the live content slot
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByEmail:(NSString *)slotName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on customer id using the live content slot. SDK will use the customer id saved in the BlueshiftUserInfo class.
/// - Parameters:
///   - slotName:name of the live content slot
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByCustomerID:(NSString *)slotName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on device id using the live content slot.
/// - Parameters:
///   - slotName:name of the live content slot
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByDeviceID:(NSString *)slotName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on email id using the live content slot. SDK will use the email id saved in the BlueshiftUserInfo class.
/// - Parameters:
///   - slotName:name of the live content slot
///   - context: Additional details
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByEmail:(NSString *)slotName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on customer id using the live content slot.  SDK will use the customer id saved in the BlueshiftUserInfo class.
/// - Parameters:
///   - slotName:name of the live content slot
///   - context: Additional details
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByCustomerID:(NSString *)slotName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on device id using the live content slot.
/// - Parameters:
///   - slotName:name of the live content slot
///   - context: Additional details
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByDeviceID:(NSString *)slotName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

@end
