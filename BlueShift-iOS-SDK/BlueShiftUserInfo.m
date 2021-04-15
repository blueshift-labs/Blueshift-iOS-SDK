//
//  BlueShiftUserInfo.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftUserInfo.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

static BlueShiftUserInfo *_sharedUserInfo = nil;

@implementation BlueShiftUserInfo {
    BOOL isCustomerIdNotSetInfoDisplayed;
    BOOL isEmailIdNotSetInfoDisplayed;
}

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

- (NSMutableDictionary *)convertToDictionary {
    NSMutableDictionary *sharedUserInfoMutableDictionary = [NSMutableDictionary dictionary];
    @try {
        if (self.email) {
            [sharedUserInfoMutableDictionary setValue:self.email forKey:kEmail];
        } else {
            if (!isEmailIdNotSetInfoDisplayed) {
                [BlueshiftLog logInfo:@"EmailId is not set for BlueShiftUserInfo. Please set email id." withDetails:nil methodName:nil];
                isEmailIdNotSetInfoDisplayed = YES;
            }
        }
        if (self.retailerCustomerID) {
            [sharedUserInfoMutableDictionary setValue:self.retailerCustomerID forKey:kBSUserCustomerId];
        } else {
            if (!isCustomerIdNotSetInfoDisplayed) {
                [BlueshiftLog logInfo:@"Retails customer ID is not set for BlueShiftUserInfo. Please set customer Id" withDetails:nil methodName:nil];
                isCustomerIdNotSetInfoDisplayed = YES;
            }
        }
        
        [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserName value:self.name];
        [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserFirstName value:self.firstName];
        [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserLastName value:self.lastName];
        [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserGender value:self.gender];
        if (self.joinedAt) {
            NSNumber *joinedAtTimeStamp = [NSNumber numberWithDouble:[self.joinedAt timeIntervalSinceReferenceDate]];
            [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserJoinedAt value:joinedAtTimeStamp];
        }
        [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserFacebookId value:self.facebookID];
        [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserEducation value:self.education];
        [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserUnsubscribedPush value:[NSNumber numberWithBool:self.unsubscribed]];
        [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserAdditionalInfo value:self.additionalUserInfo];
        if (self.dateOfBirth) {
            NSNumber *dateOfBirthTimeStamp = [NSNumber numberWithDouble:[self.dateOfBirth timeIntervalSinceReferenceDate]];
            [BlueshiftEventAnalyticsHelper addToDictionary:sharedUserInfoMutableDictionary key:kBSUserDOB value:dateOfBirthTimeStamp];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
    return [sharedUserInfoMutableDictionary mutableCopy];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *savedData = [self convertToDictionary];
    if (self.extras) {
        [savedData addEntriesFromDictionary:self.extras];
    }
    return savedData;
}

- (NSDictionary *)toDictionaryToSaveData {
    NSMutableDictionary *savedData = [self convertToDictionary];
    [BlueshiftEventAnalyticsHelper addToDictionary:savedData key:kBSUserExtras value:self.extras];
    return savedData;
}

- (void)save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDictionary = [self toDictionaryToSaveData];
    [defaults setValue:userInfoDictionary forKey:ksavedBlueShiftUserInfoDictionary];
    if ([defaults synchronize]==YES) {
        _sharedUserInfo = nil;
        _sharedUserInfo = [BlueShiftUserInfo currentUserInfo];
    }
}

+ (void)removeCurrentUserInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([BlueShiftUserInfo isCurrentUserInfoSavedInUserDefaults]==YES) {
        [defaults removeObjectForKey:ksavedBlueShiftUserInfoDictionary];
        if ([defaults synchronize]==YES) {
            _sharedUserInfo = nil;
            _sharedUserInfo = [[BlueShiftUserInfo alloc] init];
        }
    }
}

+ (BOOL)isCurrentUserInfoSavedInUserDefaults {
    BOOL status = NO;
    if ([BlueShiftUserInfo currentUserInfo]) {
        status = YES;
    }
    return status;
}

+ (BlueShiftUserInfo *)currentUserInfo {
    if (_sharedUserInfo==nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *currentUserInfoDictionary = (NSDictionary *)[defaults objectForKey:ksavedBlueShiftUserInfoDictionary];
        _sharedUserInfo = [BlueShiftUserInfo parseUserInfoDictionary:currentUserInfoDictionary];
    }
    
    return _sharedUserInfo;
}

+ (BlueShiftUserInfo *)parseUserInfoDictionary:(NSDictionary *)currentUserInfoDictionary {
    BlueShiftUserInfo *blueShiftUserInfo = nil;
    if (currentUserInfoDictionary) {
        blueShiftUserInfo = [[BlueShiftUserInfo alloc] init];
        blueShiftUserInfo.email = [currentUserInfoDictionary objectForKey:kEmail];
        blueShiftUserInfo.retailerCustomerID = [currentUserInfoDictionary objectForKey:kBSUserCustomerId];
        blueShiftUserInfo.name = [currentUserInfoDictionary objectForKey:kBSUserName];
        blueShiftUserInfo.firstName = [currentUserInfoDictionary objectForKey:kBSUserFirstName];
        blueShiftUserInfo.lastName = [currentUserInfoDictionary objectForKey:kBSUserLastName];
        blueShiftUserInfo.education = [currentUserInfoDictionary objectForKey:kBSUserEducation];
        blueShiftUserInfo.facebookID = [currentUserInfoDictionary objectForKey:kBSUserFacebookId];
        blueShiftUserInfo.gender = [currentUserInfoDictionary objectForKey:kBSUserGender];
        if([currentUserInfoDictionary objectForKey:kBSUserUnsubscribedPush]) {
            blueShiftUserInfo.unsubscribed = [[currentUserInfoDictionary objectForKey:kBSUserUnsubscribedPush] boolValue];
        }
        NSTimeInterval joinedAtTimeStamp = [[currentUserInfoDictionary objectForKey:kBSUserJoinedAt] doubleValue];
        
        if (joinedAtTimeStamp) {
            blueShiftUserInfo.joinedAt = [NSDate dateWithTimeIntervalSinceReferenceDate:joinedAtTimeStamp];
        }
        
        NSTimeInterval dateOfBirthTimeStamp = [[currentUserInfoDictionary objectForKey:kBSUserDOB]doubleValue];
        
        if (dateOfBirthTimeStamp) {
            blueShiftUserInfo.dateOfBirth = [NSDate dateWithTimeIntervalSinceReferenceDate:dateOfBirthTimeStamp];
        }
        blueShiftUserInfo.extras = [currentUserInfoDictionary objectForKey:kBSUserExtras];
        blueShiftUserInfo.additionalUserInfo = [currentUserInfoDictionary objectForKey:kBSUserAdditionalInfo];
    }
    return blueShiftUserInfo;
}


@end
