//
//  BlueShiftSubscription.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 11/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
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
