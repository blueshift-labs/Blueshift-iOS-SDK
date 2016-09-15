//
//  BlueShiftSubscription.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftSubscription.h"

static BlueShiftSubscription *_currentSubscription = nil;

@implementation BlueShiftSubscription

- (id)initWithSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate{
    
    self = [super init];
    
    if (self) {
        self.subscriptionState = subscriptionState;
        self.cycleType = cycleType;
        self.cycleLength = cycleLength;
        self.subscriptionType = subscriptionType;
        self.price = price;
        self.startDate = startDate;
    }
    
    return self;
}


- (NSDictionary *)toDictionary {
    NSMutableDictionary *subscriptionMutableDictionary = [NSMutableDictionary dictionary];
    if (self.subscriptionState) {
        [subscriptionMutableDictionary setObject:[NSNumber numberWithInt:self.subscriptionState] forKey:@"subscription_state"];
    }
    
    if (self.cycleType) {
        [subscriptionMutableDictionary setObject:self.cycleType forKey:@"subscription_period_type"];
    }
    
    if (self.cycleLength) {
        [subscriptionMutableDictionary setObject:[NSNumber numberWithInteger:self.cycleLength] forKey:@"subscription_period_length"];
    }
    
    if (self.subscriptionType) {
        [subscriptionMutableDictionary setObject:self.subscriptionType forKey:@"subscription_plan_type"];
    }
    
    if (self.price) {
        [subscriptionMutableDictionary setObject:[NSNumber numberWithFloat:self.price] forKey:@"subscription_amount"];
    }
    
    if (self.startDate) {
        [subscriptionMutableDictionary setObject:[NSNumber numberWithDouble:self.startDate] forKey:@"subscription_start_date"];
    }
    
    
    return [subscriptionMutableDictionary copy];
}

- (void)save
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *subscriptionDictionary = [self toDictionary];
    [defaults setObject:subscriptionDictionary forKey:@"savedBlueShiftSubscriptionDictionary"];
    if ([defaults synchronize]==YES) {
        _currentSubscription = nil;
        _currentSubscription = [BlueShiftSubscription currentSubscription];
    }
}

+ (void)removeCurrentSubscription
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([BlueShiftSubscription isCurrentSubscriptionSavedInUserDefaults]==YES) {
        [defaults removeObjectForKey:@"savedBlueShiftSubscriptionDictionary"];
        if ([defaults synchronize]==YES) {
            _currentSubscription = nil;
        }
    }
}

+ (BOOL)isCurrentSubscriptionSavedInUserDefaults
{
    BOOL status = NO;
    if ([BlueShiftSubscription currentSubscription]) {
        status = YES;
    }
    return status;
}

+ (BlueShiftSubscription *)currentSubscription
{
    if (_currentSubscription==nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *currentUserInfoDictionary = (NSDictionary *)[defaults objectForKey:@"savedBlueShiftSubscriptionDictionary"];
        _currentSubscription = [BlueShiftSubscription parseUserInfoDictionary:currentUserInfoDictionary];
    }
    
    return _currentSubscription;
}


+ (BlueShiftSubscription *)parseUserInfoDictionary:(NSDictionary *)currentSubscriptionDictionary
{
    BlueShiftSubscription *blueShiftSubscription = nil;
    if (currentSubscriptionDictionary) {
        blueShiftSubscription = [[BlueShiftSubscription alloc] init];
        blueShiftSubscription.cycleType = [currentSubscriptionDictionary objectForKey:@"subscription_period_type"];
        blueShiftSubscription.cycleLength = [[currentSubscriptionDictionary objectForKey:@"subscription_period_length"] integerValue];
        blueShiftSubscription.subscriptionType = [currentSubscriptionDictionary objectForKey:@"subscription_plan_type"];
        blueShiftSubscription.price = [[currentSubscriptionDictionary objectForKey:@"subscription_amount"] integerValue];
        
        blueShiftSubscription.startDate = [[currentSubscriptionDictionary objectForKey:@"subscription_start_date"] integerValue];
    }
    return blueShiftSubscription;
}



@end
