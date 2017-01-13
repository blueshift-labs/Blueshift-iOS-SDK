//
//  BlueShiftLiveContent.h
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 13/01/17.
//  Copyright © 2017 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftLiveContent : NSObject

+ (void) fetchLiveContent:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;

@end
