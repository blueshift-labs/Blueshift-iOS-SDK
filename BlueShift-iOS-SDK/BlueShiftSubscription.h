//
//  BlueShiftSubscription.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueShiftSubscriptionState.h"

@interface BlueShiftSubscription : NSObject


@property BlueShiftSubscriptionState subscriptionState;
@property NSString *cycleType;
@property NSInteger cycleLength;
@property NSString *subscriptionType;
@property float price;
@property NSTimeInterval startDate;


- (id)initWithSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate;

- (NSDictionary *)toDictionary;
+ (BlueShiftSubscription *)currentSubscription;
- (void)save;
+ (void)removeCurrentSubscription;



@end
