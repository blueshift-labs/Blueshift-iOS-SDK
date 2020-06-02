//
//  BlueshiftUniversalLinksDelegate.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan on 19/05/20.
//  Copyright ©2020 Blueshift. All rights reserved.
//

@protocol BlueshiftUniversalLinksDelegate <NSObject>

@optional
- (void) didCompleteLinkProcessing: (NSURL *_Nullable)url;
- (void) didFailLinkProcessingWithError: (NSError *_Nullable)error url:(NSURL *_Nullable)url;
- (void) didStartLinkProcessing;
@end

