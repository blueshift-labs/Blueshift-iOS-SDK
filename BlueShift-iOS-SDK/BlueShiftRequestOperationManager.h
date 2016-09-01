//
//  BlueShiftRequestOperationManager.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import "BlueShiftAppDelegate.h"
#import <CoreData/CoreData.h>
#import "HttpRequestOperationEntity.h"
#import "BlueShiftHTTPMethod.h"
#import "NSNumber+BlueShiftHelpers.h"
#import "BlueShiftStatusCodes.h"

@interface BlueShiftRequestOperationManager : AFHTTPRequestOperationManager



// Method to get the shared instance for BlueShiftOperationManager ...

+ (BlueShiftRequestOperationManager *)sharedRequestOperationManager;



// Method to add Basic authentication request Header ...

- (void)addBasicAuthenticationRequestHeaderForUsername:(NSString *)username andPassword:(NSString *)password;

@end
