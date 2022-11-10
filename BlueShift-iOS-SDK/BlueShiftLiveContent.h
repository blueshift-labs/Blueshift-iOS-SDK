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
///   - campaignName:name of the live content slot
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByEmail:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on customer id using the live content slot. SDK will use the customer id saved in the BlueshiftUserInfo class.
/// - Parameters:
///   - campaignName:name of the live content slot
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on device id using the live content slot.
/// - Parameters:
///   - campaignName:name of the live content slot
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on email id using the live content slot. SDK will use the email id saved in the BlueshiftUserInfo class.
/// - Parameters:
///   - campaignName:name of the live content slot
///   - context: Additional details
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByEmail:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on customer id using the live content slot.  SDK will use the customer id saved in the BlueshiftUserInfo class.
/// - Parameters:
///   - campaignName:name of the live content slot
///   - context: Additional details
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

/// Fetch live content based on device id using the live content slot.
/// - Parameters:
///   - campaignName:name of the live content slot
///   - context: Additional details
///   - success: success completion handler
///   - failure: failure completion handler
+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

@end
