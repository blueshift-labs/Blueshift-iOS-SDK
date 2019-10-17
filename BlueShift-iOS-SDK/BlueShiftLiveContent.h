//
//  BlueShiftLiveContent.h
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 13/01/17.
//  Copyright © 2017 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftLiveContent : NSObject

+ (void) fetchLiveContentByEmail:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;
+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;
+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

+ (void) fetchLiveContentByEmail:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;
+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;
+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;
+ (void) fetchInAppNotificationByDeviceID:(NSString *)lastMessageID andLastTimestamp:(NSString *)lastTimestamp success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

@end
