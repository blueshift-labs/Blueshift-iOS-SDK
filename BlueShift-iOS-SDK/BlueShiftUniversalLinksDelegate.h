//
//  BlueShiftUniversalLinksDelegate.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan on 19/05/20.
//  Copyright © 2020 Bullfinch Software. All rights reserved.
//

@protocol BlueShiftUniversalLinksDelegate <NSObject>

@optional
- (void) didReceiveBlueshiftAttributionData: (NSURL *)url;
- (void) didFailedToReceiveBlueshiftAttributionData: (NSError *)error;

@end

