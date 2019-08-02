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

- (void)actionButtonDidTapped:(NSDictionary *)payloadDictionary;
- (void)dismissButtonDidTapped:(NSDictionary *)payloadDictionary;
- (void)inAppNotificationWillAppear;
- (void)inAppNotificationDidAppear;
- (void)inAppNotificationWillDisAppear;
- (void)inAppNotificationDidDisAppear;

@end


#endif /* BlueShiftInAppNotificationDelegate_h */
