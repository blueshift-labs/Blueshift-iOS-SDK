//
//  BlueShiftAlertView.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftAlertView.h"

@implementation BlueShiftAlertView

- (UIAlertController *)alertViewWithPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    
    NSDictionary *pushAlertDictionary = [pushDetailsDictionary objectForKey:@"aps"];
    NSString *pushCategory = [[pushDetailsDictionary objectForKey:@"aps"] objectForKey:@"category"];
    NSString *pushMessage = [pushAlertDictionary objectForKey:@"alert"];
    UIAlertController *blueShiftAlertController = [UIAlertController alertControllerWithTitle:kAlertTitle message:pushMessage preferredStyle:UIAlertControllerStyleAlert];
    if ([pushCategory isEqualToString:kNotificationCategoryBuyIdentifier]) {
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:kDismissButton style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *viewAction = [UIAlertAction actionWithTitle:kViewButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.alertControllerDelegate handleAlertActionButtonForCategoryBuyWithActionName:action.title];
        }];
        UIAlertAction *buyAction = [UIAlertAction actionWithTitle:kBuyButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.alertControllerDelegate handleAlertActionButtonForCategoryBuyWithActionName:action.title];
        }];
        [blueShiftAlertController addAction:dismissAction];
        [blueShiftAlertController addAction:buyAction];
        [blueShiftAlertController addAction:viewAction];
    } else if ([pushCategory isEqualToString:kNotificationCategoryViewCartIdentifier]) {
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:kDismissButton style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *openAction = [UIAlertAction actionWithTitle:kOpenButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.alertControllerDelegate handleAlertActionButtonForCategoryCartWithActionName:action.title];
        }];
        [blueShiftAlertController addAction:dismissAction];
        [blueShiftAlertController addAction:openAction];
    } else if ([pushCategory isEqualToString:kNotificationCategoryOfferIdentifier]) {
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:kDismissButton style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *showAction = [UIAlertAction actionWithTitle:kShowButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.alertControllerDelegate handleAlertActionButtonForCategoryPromotionWithActionName:action.title];
        }];
        [blueShiftAlertController addAction:dismissAction];
        [blueShiftAlertController addAction:showAction];
    } else if ([pushCategory isEqualToString:kNotificationTwoButtonAlertIdentifier]) {
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:kDismissButton style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *showAction = [UIAlertAction actionWithTitle:kShowButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.alertControllerDelegate handleAlertActionButtonForCategoryTwoButtonAlertWithActionName:action.title];
        }];
        [blueShiftAlertController addAction:dismissAction];
        [blueShiftAlertController addAction:showAction];
    } else if ([pushCategory isEqualToString:kNotificationOneButtonAlertIdentifier]) {
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:kDismissButton style:UIAlertActionStyleCancel handler:nil];
        [blueShiftAlertController addAction:dismissAction];
    } else {
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:kDismissButton style:UIAlertActionStyleDefault handler:nil];
        [blueShiftAlertController addAction:dismissAction];
    }
    return blueShiftAlertController;
}


@end
