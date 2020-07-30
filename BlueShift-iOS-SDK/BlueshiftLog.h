//
//  BlueshiftLog.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 29/07/20.
//  Copyright © 2020 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueshiftLog : NSObject

+ (void)logError:(NSError*) error withDescription:(NSString*)description methodName:(NSString*)method;
+ (void)logException:(NSException*) exception withDescription:(NSString*)description methodName:(NSString*)method;
+ (void)logInfo:(NSString*)info withDetails: (id) details methodName:(NSString*)method;
+(void)logAPICallInfo:(NSString*)info withDetails: (NSDictionary*) details statusCode:(NSInteger)statusCode;

@end
