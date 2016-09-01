//
//  BlueShiftDeepLink.h
//  BlueShift-iOS-SDK
///
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BlueShiftPushParamDelegate.h"

typedef enum {
    BlueShiftDeepLinkRouteProductPage,
    BlueShiftDeepLinkRouteCartPage,
    BlueShiftDeepLinkRouteOfferPage
} BlueShiftDeepLinkRoute;



@interface BlueShiftDeepLink : NSObject

@property NSURL *pathURL;
@property BlueShiftDeepLinkRoute linkRoute;
@property (nonatomic, retain) id<BlueShiftPushParamDelegate> blueShiftPushParamDelegate;

- (id)initWithLinkRoute:(BlueShiftDeepLinkRoute)linkRoute andNSURL:(NSURL *)pathURL;
- (BOOL)performDeepLinking;
- (UIViewController *)lastViewController;
- (UIViewController *)firstViewController;


+ (void)mapDeepLink:(BlueShiftDeepLink *)deepLink toRoute:(BlueShiftDeepLinkRoute)linkRoute;
+ (BlueShiftDeepLink *)deepLinkForRoute:(BlueShiftDeepLinkRoute)linkRoute;

@end
