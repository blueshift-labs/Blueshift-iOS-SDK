//
//  BlueShiftAlertView.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftAlertView.h"

@implementation BlueShiftAlertView

+ (instancetype)alertViewWithPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary andDelegate:(id)delegate {
    // Get a alertView instance for a particular type of push Notification Dictionary ...
    // Differentiation is done on the basis of the category of the push payload dictionary ...
    
    BlueShiftAlertView *blueShiftAlertView = nil;
    //NSDictionary *pushAlertDictionary = [[pushDetailsDictionary objectForKey:@"aps"] objectForKey:@"alert"];
    NSDictionary *pushAlertDictionary = [pushDetailsDictionary objectForKey:@"aps"];
    NSString *pushCategory = [[pushDetailsDictionary objectForKey:@"aps"] objectForKey:@"category"];
    //NSString *pushMessage = [pushAlertDictionary objectForKey:@"body"];
    NSString *pushMessage = [pushAlertDictionary objectForKey:@"alert"];
    
    if ([pushCategory isEqualToString:kNotificationCategoryBuyIdentifier]) {
        blueShiftAlertView = [[BlueShiftAlertView alloc] initWithTitle:@"Notification Alert" message:pushMessage delegate:delegate cancelButtonTitle:@"Dismiss" otherButtonTitles:@"View",@"Buy", nil];
        blueShiftAlertView.alertViewContext = BlueShiftAlertViewContextNotificationCategoryBuy;
    } else if ([pushCategory isEqualToString:kNotificationCategoryViewCartIdentifier]) {
        blueShiftAlertView = [[BlueShiftAlertView alloc] initWithTitle:@"Notification Alert" message:pushMessage delegate:delegate cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Open Cart", nil];
        blueShiftAlertView.alertViewContext = BlueShiftAlertViewContextNotificationCategoryCart;
    } else if ([pushCategory isEqualToString:kNotificationCategoryOfferIdentifier]) {
        blueShiftAlertView = [[BlueShiftAlertView alloc] initWithTitle:@"Notification Alert" message:pushMessage delegate:delegate cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Show", nil];
        blueShiftAlertView.alertViewContext = BlueShiftAlertViewContextNotificationCategoryOffer;
    } else {
        blueShiftAlertView = [[BlueShiftAlertView alloc] initWithTitle:@"Notification Alert" message:pushMessage delegate:delegate cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    }
    
    return blueShiftAlertView;
}


@end
