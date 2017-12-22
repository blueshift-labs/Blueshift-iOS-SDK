//
//  BlueShiftPushAnalytics.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/10/17.
//

#import <Foundation/Foundation.h>

@interface BlueShiftPushAnalytics : NSObject

+ (void)sendPushAnalytics:(NSString *)type withParams:(NSDictionary *)userInfo;

@end
