//
//  BlueshiftNotificationButton.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 19/07/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftNotificationButton : NSObject

@property (nonatomic, readwrite) BlueshiftNotificationButton *dismiss;
@property (nonatomic, readwrite) BlueshiftNotificationButton *appOpen;
@property (nonatomic, readwrite) BlueshiftNotificationButton *share;

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *textColor;
@property (nonatomic, copy, readwrite) NSString *backgroundColor;
@property (nonatomic, copy, readwrite) NSString *page;
@property (nonatomic, readwrite) BlueshiftNotificationButton *extra;
@property (nonatomic, copy, readwrite) NSString *productID;
@property (nonatomic, readwrite) BlueshiftNotificationButton *content;
@property (nonatomic, copy, readwrite) NSString *image;

- (instancetype)initFromDictionary: (NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
