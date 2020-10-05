//
//  BlueShiftInAppNotificationDelegate.h
//  Pods
//
//  Created by Noufal Subair on 01/08/19.
//

#ifndef BlueShiftInAppNotificationDelegate_h
#define BlueShiftInAppNotificationDelegate_h

#import <Foundation/Foundation.h>

@protocol BlueShiftInAppNotificationDelegate <NSObject>

@optional

- (void)actionButtonDidTapped:(NSDictionary *)notificationDictionary;
- (void)inAppNotificationWillAppear:(NSDictionary *)notificationDictionary;
- (void)inAppNotificationDidAppear:(NSDictionary *)notificationDictionary;
- (void)inAppNotificationWillDisappear:(NSDictionary *)notificationDictionary;
- (void)inAppNotificationDidDisappear:(NSDictionary *)notificationDictionary;
- (void)inAppNotificationDidStartLoading:(UIView *)view;
- (void)inAppNotificationDidFinishLoading;

@end


#endif /* BlueShiftInAppNotificationDelegate_h */
