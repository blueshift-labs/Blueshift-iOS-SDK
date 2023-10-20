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

/// This callback is only called for regular in-app notifications and not for the in-apps triggered from the inbox screen.
/// This callback method will be called when user performs an action on the in-app notification.
/// If deep link is available, you will receive the in-app notification deep link in the notificationDictionary as `ios_link` attribute.
/// @param notificationDictionary in-app action/click details. Use `channel`value to differenciate between the in-app and inbox clicks.
/// `channel` = `inbox` then click has come from inbox inapp display, while `channel`=`inApp` then it has come from regular in-app notification.
/// @warning Implementing this method will override the default behaviour of delivering deep-link to the OpenUrl method of the appDelegate and instead deep link will be delivered in this method.
- (void)actionButtonDidTapped:(NSDictionary *)notificationDictionary;

- (void)inAppNotificationWillAppear:(NSDictionary *)notificationDictionary DEPRECATED_MSG_ATTRIBUTE("This method is deprecated, and will be removed in a future SDK version.");

- (void)inAppNotificationDidAppear:(NSDictionary *)notificationDictionary DEPRECATED_MSG_ATTRIBUTE("This method is deprecated, and will be removed in a future SDK version.");

- (void)inAppNotificationWillDisappear:(NSDictionary *)notificationDictionary DEPRECATED_MSG_ATTRIBUTE("This method is deprecated, and will be removed in a future SDK version.");

- (void)inAppNotificationDidDisappear:(NSDictionary *)notificationDictionary DEPRECATED_MSG_ATTRIBUTE("This method is deprecated, and will be removed in a future SDK version.");

/// This is a SDK hook/callback for the in-app notification delivered event. This callback will be called for both regualar in-apps and in-apps triggered from inbox screen.
/// @param payload in-app notification payload
/// @discussion SDK invokes this callback method when it receives an in-app notification.
- (void)inAppNotificationDidDeliver:(NSDictionary *)payload;

/// This is a SDK hook/callback for the in-app notification open event. This callback will be called for both regualar in-apps and in-apps triggered from inbox screen.
/// @param payload in-app notification payload
/// @discussion SDK invokes this callback method when it displays an in-app notification.
- (void)inAppNotificationDidOpen:(NSDictionary *)payload;

/// This is a SDK hook/callback for the in-app notification click event. This callback will be called for both regualar in-apps and in-apps triggered from inbox screen.
/// @param payload in-app notification payload
/// @discussion SDK invokes this callback method when user clicks/taps on an in-app notification button/action.
- (void)inAppNotificationDidClick:(NSDictionary *)payload;

@end


#endif /* BlueShiftInAppNotificationDelegate_h */
