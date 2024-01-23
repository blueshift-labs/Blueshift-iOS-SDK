//
//  BlueshiftWebViewBrowserDelegate.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 27/10/23.
//

#ifndef BlueshiftWebViewBrowserDelegate_h
#define BlueshiftWebViewBrowserDelegate_h

@protocol BlueshiftWebViewBrowserDelegate <NSObject>
@optional
/// Set custom tint color for the SDK's webview browser screen. This browser will be opened when open in web links are sent from the push/in-app notifications.
@property UIColor* blueshiftWebViewBrowserTintColor;

/// Set custom title color for the SDK's webview browser screen. This browser will be opened when open in web links are sent from the push/in-app notifications.
@property UIColor* blueshiftWebViewBrowserTitleColor;

/// Set custom navigation bar background color for the SDK's webview browser screen. This browser will be opened when open in web links are sent from the push/in-app notifications.
@property UIColor* blueshiftWebViewBrowserNavBarColor;

/// Set custom progress view color for the SDK's webview browser. This browser will be opened when open in web links are sent from the push/in-app notifications.
@property UIColor* blueshiftWebViewBrowserProgressViewColor;
@end

#endif /* BlueshiftWebViewBrowserDelegate_h */
