//
//  BlueshiftLog.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 29/07/20.
//  Copyright © 2020 Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueshiftLog : NSObject


/// Log error. The errors will be printed irrespective of the debug flag set in the SDK configuration.
/// @param error error object
/// @param description additional details on the error
/// @param method method name where error occured
+ (void)logError:(NSError*) error withDescription:(NSString*)description methodName:(NSString*)method;


/// Log exception. The exceptions will be printed irrespective of the debug flag set in the SDK configuration.
/// @param exception exception object
/// @param description additional details on the error
/// @param method method name where exception occured
+ (void)logException:(NSException*) exception withDescription:(NSString*)description methodName:(NSString*)method;


/// Log info. This log will be only printed when debug flag is set to true in the SDK configuration.
/// @param info information on the log
/// @param details additional details on the log.
/// @param method name of the method
+ (void)logInfo:(NSString*)info withDetails: (id) details methodName:(NSString*)method;


/// Log API call details. This log will be only printed when debug flag is set to true in the SDK configuration.
/// @param info information on the API call
/// @param details additional details on the API call
/// @param statusCode status code for the API call. Send status code as 0 if it is not applicable.
+ (void)logAPICallInfo:(NSString*)info withDetails: (NSDictionary*) details statusCode:(NSInteger)statusCode;

@end
