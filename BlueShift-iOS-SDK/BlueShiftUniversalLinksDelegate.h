//
//  BlueShiftUniversalLinksDelegate.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan on 19/05/20.
//  Copyright © 2020 Blueshift. All rights reserved.
//

@protocol BlueShiftUniversalLinksDelegate <NSObject>

@optional
- (void) didReceiveBlueshiftAttributionData: (NSURL *_Nullable)url;
- (void) didFailedToReceiveBlueshiftAttributionData: (NSError *_Nullable)error;
- (void) didStartProcessingBlueshiftAttributionData;
@end

