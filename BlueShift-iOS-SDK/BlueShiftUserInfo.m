//
//  BlueShiftUserInfo.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftUserInfo.h"

static BlueShiftUserInfo *_sharedUserInfo = nil;

@implementation BlueShiftUserInfo

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedUserInfo = [BlueShiftUserInfo currentUserInfo];
        if (_sharedUserInfo==nil) {
            _sharedUserInfo = [[BlueShiftUserInfo alloc] init];
        }
    });
    return _sharedUserInfo;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *sharedUserInfoMutableDictionary = [NSMutableDictionary dictionary];
    
    if (self.email) {
        [sharedUserInfoMutableDictionary setObject:self.email forKey:@"email"];
    } else {
        NSLog(@"\n\n BlueShiftWarning: Email not set for BlueShiftUserInfo \n");
    }
    
    if (self.name) {
        [sharedUserInfoMutableDictionary setObject:self.name forKey:@"name"];
    }
    
    if (self.retailerCustomerID) {
        [sharedUserInfoMutableDictionary setObject:self.retailerCustomerID forKey:@"customer_id"];
    } else {
        NSLog(@"\n\n BlueShiftWarning: Retailer Customer ID not set for BlueShiftUserInfo \n");
    }
    
    if (self.firstName) {
        [sharedUserInfoMutableDictionary setObject:self.firstName forKey:@"firstname"];
    }
    
    if (self.lastName) {
        [sharedUserInfoMutableDictionary setObject:self.lastName forKey:@"lastname"];
    }
    
    if  (self.gender) {
        [sharedUserInfoMutableDictionary setObject:self.gender forKey:@"gender"];
    }
    
    if (self.joinedAt) {
        NSNumber *joinedAtTimeStamp = [NSNumber numberWithDouble:[self.joinedAt timeIntervalSinceReferenceDate]];
        [sharedUserInfoMutableDictionary setObject:joinedAtTimeStamp forKey:@"joined_at"];
    }
    
    if (self.facebookID) {
        [sharedUserInfoMutableDictionary setObject:self.facebookID forKey:@"facebook_id"];
    }
    
    if (self.education) {
        [sharedUserInfoMutableDictionary setObject:self.education forKey:@"education"];
    }
    
    if (self.unsubscribed) {
        [sharedUserInfoMutableDictionary setObject:[NSNumber numberWithBool:self.unsubscribed] forKey:@"unsubscribed"];
    }
    
    if (self.additionalUserInfo) {
        [sharedUserInfoMutableDictionary setObject:self.additionalUserInfo forKey:@"additional_user_info"];
    }
    
    if (self.dateOfBirth) {
        NSNumber *dateOfBirthTimeStamp = [NSNumber numberWithDouble:[self.dateOfBirth timeIntervalSinceReferenceDate]];
        [sharedUserInfoMutableDictionary setObject:dateOfBirthTimeStamp forKey:@"date_of_birth"];
    }
    
    return [sharedUserInfoMutableDictionary copy];
}


- (void)save
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDictionary = [self toDictionary];
    [defaults setObject:userInfoDictionary forKey:@"savedBlueShiftUserInfoDictionary"];
    if ([defaults synchronize]==YES) {
        _sharedUserInfo = nil;
        _sharedUserInfo = [BlueShiftUserInfo currentUserInfo];
    }
}

+ (void)removeCurrentUserInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([BlueShiftUserInfo isCurrentUserInfoSavedInUserDefaults]==YES) {
        [defaults removeObjectForKey:@"savedBlueShiftUserInfoDictionary"];
        if ([defaults synchronize]==YES) {
            _sharedUserInfo = nil;
            _sharedUserInfo = [[BlueShiftUserInfo alloc] init];
        }
    }
}

+ (BOOL)isCurrentUserInfoSavedInUserDefaults
{
    BOOL status = NO;
    if ([BlueShiftUserInfo currentUserInfo]) {
        status = YES;
    }
    return status;
}

+ (BlueShiftUserInfo *)currentUserInfo
{
    if (_sharedUserInfo==nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *currentUserInfoDictionary = (NSDictionary *)[defaults objectForKey:@"savedBlueShiftUserInfoDictionary"];
        _sharedUserInfo = [BlueShiftUserInfo parseUserInfoDictionary:currentUserInfoDictionary];
    }
    
    return _sharedUserInfo;
}

+ (BlueShiftUserInfo *)parseUserInfoDictionary:(NSDictionary *)currentUserInfoDictionary
{
    BlueShiftUserInfo *blueShiftUserInfo = nil;
    if (currentUserInfoDictionary) {
        blueShiftUserInfo = [[BlueShiftUserInfo alloc] init];
        blueShiftUserInfo.email = [currentUserInfoDictionary objectForKey:@"email"];
        blueShiftUserInfo.name = [currentUserInfoDictionary objectForKey:@"name"];
        blueShiftUserInfo.firstName = [currentUserInfoDictionary objectForKey:@"firstname"];
        blueShiftUserInfo.lastName = [currentUserInfoDictionary objectForKey:@"lastname"];
        blueShiftUserInfo.education = [currentUserInfoDictionary objectForKey:@"education"];
        blueShiftUserInfo.facebookID = [currentUserInfoDictionary objectForKey:@"facebook_id"];
        blueShiftUserInfo.gender = [currentUserInfoDictionary objectForKey:@"gender"];
        if([currentUserInfoDictionary objectForKey:@"unsubscribed"] && [[currentUserInfoDictionary objectForKey:@"unsubscribed"] boolValue]) {
            blueShiftUserInfo.unsubscribed = [[currentUserInfoDictionary objectForKey:@"unsubscribed"] boolValue];
        }
        NSTimeInterval joinedAtTimeStamp = [[currentUserInfoDictionary objectForKey:@"joined_at"] doubleValue];
        
        if (joinedAtTimeStamp) {
            blueShiftUserInfo.joinedAt = [NSDate dateWithTimeIntervalSinceReferenceDate:joinedAtTimeStamp];
        }
        
        NSTimeInterval dateOfBirthTimeStamp = [[currentUserInfoDictionary objectForKey:@"date_of_birth"]doubleValue];
        
        if (dateOfBirthTimeStamp) {
            blueShiftUserInfo.dateOfBirth = [NSDate dateWithTimeIntervalSinceReferenceDate:dateOfBirthTimeStamp];
        }
        
        blueShiftUserInfo.additionalUserInfo = [currentUserInfoDictionary objectForKey:@"additional_user_info"];
        blueShiftUserInfo.retailerCustomerID = [currentUserInfoDictionary objectForKey:@"customer_id"];
    }
    return blueShiftUserInfo;
}


@end
