//
//  BlueshiftLog.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 29/07/20.
//  Copyright © 2020 Blueshift. All rights reserved.
//

#import "BlueshiftLog.h"
#import "BlueShift.h"
#import "BlueShiftTrackEvents.h"
#import "BlueshiftConstants.h"

@implementation BlueshiftLog

+ (void)logError:(NSError*) error withDescription:(NSString*)description methodName:(NSString*)method {
    NSString* log = @"[Blueshift] Error : ";
    @try {
        if (description) {
            log = [NSString stringWithFormat:@"%@%@",log,description];
        }
        if (method) {
            log = [NSString stringWithFormat:@"%@\nMethod name: %@",log,method];
        }
        if (error) {
            log = [NSString stringWithFormat:@"%@\n%@",log,error];
        }
        NSLog(@"%@", log);
    } @catch (NSException *exception) {
        NSLog(@"Failed to log error %@",exception);
    }
}

+ (void)logException:(NSException*) exception withDescription:(NSString*)description  methodName:(NSString*)method {
    NSString* log = @"[Blueshift] Exception : ";
    @try {
        if (description) {
            log = [NSString stringWithFormat:@"%@%@",log,description];
        }
        if (method) {
            log = [NSString stringWithFormat:@"%@\nMethod name: %@",log,method];
        }
        if (exception) {
            log = [NSString stringWithFormat:@"%@\n%@",log,exception];
        }
        NSLog(@"%@", log);
        [self trackSDKCrashAnalyticsError:exception];
    } @catch (NSException *exception) {
        NSLog(@"Failed to log exception %@",exception);
    }
}

+ (void)logInfo:(NSString*)info withDetails: (id) details methodName:(NSString*)method{
    if ([[BlueShift sharedInstance] config].debug) {
        NSString* log = @"[Blueshift] info : ";
        @try {
            if (info) {
                log = [NSString stringWithFormat:@"%@%@",log,info];
            }
            if (method) {
                log = [NSString stringWithFormat:@"%@\nMethod name: %@ ",log,method];
            }
            if (details) {
                log = [NSString stringWithFormat:@"%@\n%@",log,details];
            }
            NSLog(@"%@", log);
        } @catch (NSException *exception) {
            NSLog(@"Failed to log info %@",exception);
        }
    }
}

+ (void)logAPICallInfo:(NSString*)info withDetails: (NSDictionary*) details statusCode:(NSInteger)statusCode {
    if ([[BlueShift sharedInstance] config].debug) {
        NSString* log = @"[Blueshift] API call info : ";
        @try {
        if (info) {
            log = [NSString stringWithFormat:@"%@%@",log,info];
        }
        if (statusCode!=0) {
            log = [NSString stringWithFormat:@"%@\nStatus code:%ld",log,(long)statusCode];
        }
        if (details) {
            if([details objectForKey:@"a"]) {
                log = [NSString stringWithFormat:@"%@\nEVENT-%@ ",log, [details objectForKey:@"a"]];
            } else if([details objectForKey:kEventGeneric]) {
                log = [NSString stringWithFormat:@"%@\nEVENT-%@ ",log, [details objectForKey:kEventGeneric]];
            }
            log = [NSString stringWithFormat:@"%@\n%@",log,details];
        }
        NSLog(@"%@", log);
        } @catch (NSException *exception) {
            NSLog(@"Failed to log API call info %@",exception);
        }
    }
}

+ (void)trackSDKCrashAnalyticsError:(NSException *)exception {
    if ([BlueShift sharedInstance].config.enableSDKCrashAnalytics == YES) {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        if (exception.reason) {
            [errorDetails setObject:exception.reason forKey:kSDKCrashAnalyticsCause];
        }
        if (exception.callStackSymbols) {
            [errorDetails setObject: [exception callStackSymbols] forKey:kSDKCrashAnalyticsStackTrace];
        }
        if (exception.name) {
            [errorDetails setObject:exception.name forKey:kSDKCrashAnalyticsExceptionName];
        }
        if (exception.userInfo) {
            [errorDetails setObject:exception.userInfo forKey:kSDKCrashAnalyticsExceptionInfo];
        }
        [[BlueShift sharedInstance] trackEventForEventName:kSDKCrashAnalyticsEventName andParameters:errorDetails canBatchThisEvent:YES];
    }
}

@end
