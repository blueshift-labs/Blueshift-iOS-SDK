//
//  BlueshiftUniversalLinksDelegate.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan on 19/05/20.
//  Copyright ©2020 Blueshift. All rights reserved.
//

@protocol BlueshiftUniversalLinksDelegate <NSObject>

@optional

///This method receives the callback when the SDK processes the Blueshift deep link successfully.
///@param url This url you can use for deep linking.
- (void) didCompleteLinkProcessing: (NSURL *_Nullable)url;

/// This method receives the callback if the SDK fails to process the Blueshift deep link.
/// @param error The error details about why SDK failed to process the link.
/// @param url The URL which SDK failed to process.
- (void) didFailLinkProcessingWithError: (NSError *_Nullable)error url:(NSURL *_Nullable)url;

/// This method receives a callback that states that the SDK has started processing the Blueshift deep link.
/// You can use this method to show the activity indicator on screen.
- (void) didStartLinkProcessing;

@end

