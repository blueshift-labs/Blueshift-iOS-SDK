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
/// This callback method will be called when user performs an action on the in-app notification.
/// You will receive the in-app notification deep link in the notificationDictionary as ios_link attribute.
/// @param notificationDictionary in-app action/click details
/// @warning Implementing this method will override the default behaviour of delivering deep-link to the OpenUrl method of the appDelegate and instead deep link will be delivered in this method.
- (void)actionButtonDidTapped:(NSDictionary *)notificationDictionary;

- (void)inAppNotificationWillAppear:(NSDictionary *)notificationDictionary;
- (void)inAppNotificationDidAppear:(NSDictionary *)notificationDictionary;
- (void)inAppNotificationWillDisappear:(NSDictionary *)notificationDictionary;
- (void)inAppNotificationDidDisappear:(NSDictionary *)notificationDictionary;

/// This is a SDK hook/callback for the in-app notification delivered event.
/// @param payload in-app notification payload
/// @discussion SDK invokes this callback method when it receives an in-app notification.
- (void)inAppNotificationDidDeliver:(NSDictionary *)payload;

/// This is a SDK hook/callback for the in-app notification open event.
/// @param payload in-app notification payload
/// @discussion SDK invokes this callback method when it displays an in-app notification.
- (void)inAppNotificationDidOpen:(NSDictionary *)payload;

/// This is a SDK hook/callback for the in-app notification click event.
/// @param payload in-app notification payload
/// @discussion SDK invokes this callback method when user clicks/taps on an in-app notification button/action.
- (void)inAppNotificationDidClick:(NSDictionary *)payload;

@end


#endif /* BlueShiftInAppNotificationDelegate_h */
