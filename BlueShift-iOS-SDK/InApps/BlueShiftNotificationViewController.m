//
//  BlueShiftNotificationViewController.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftNotificationViewController.h"
#import "BlueShiftNotificationWindow.h"
#import "BlueShiftNotificationView.h"
#import <CoreText/CoreText.h>
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftNotificationCloseButton.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"
#import "BlueshiftWebBrowserViewController.h"

@interface BlueShiftNotificationViewController () {
    BlueShiftNotificationCloseButton *_closeButton;
}
@end

@implementation BlueShiftNotificationViewController

- (instancetype)initWithNotification:(BlueShiftInAppNotification *)notification {
    self = [super init];
    if (self) {
        notification.contentStyle = ([self isDarkThemeEnabled] && notification.contentStyleDark) ? notification.contentStyleDark : notification.contentStyle;
        notification.templateStyle = ([self isDarkThemeEnabled] && notification.templateStyleDark) ? notification.templateStyleDark : notification.templateStyle;
        _notification = notification;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidAppear:)]) {
        [[self inAppNotificationDelegate] inAppNotificationDidAppear:self.notification.notificationPayload];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidDisappear:)]) {
        [[self inAppNotificationDelegate] inAppNotificationDidDisappear:self.notification.notificationPayload];
    }
}

- (void)setTouchesPassThroughWindow:(BOOL) can {
    self.canTouchesPassThroughWindow = can;
}

- (void)closeButtonDidTapped {
    NSString *closeButtonIndex = [NSString stringWithFormat:@"%@%@",kInAppNotificationButtonIndex,kInAppNotificationButtonTypeCloseKey];
    NSDictionary *details = @{kNotificationClickElementKey:closeButtonIndex};
    [self sendActionEventAnalytics:details forActionType:BlueshiftInAppDismissAction];
    [self hide:YES];
}

- (void)loadNotificationView {
    CGSize windowSize = [BlueShiftInAppNotificationHelper getApplicationWindowSize:self.window];
    self.view = [[BlueShiftNotificationView alloc] initWithFrame:CGRectMake(0, 0, windowSize.width, windowSize.height)];
}

- (UIView *)createNotificationWindow{
    UIView *notificationView = [[UIView alloc] initWithFrame:CGRectZero];
    notificationView.clipsToBounds = YES;
    
    return notificationView;
}

- (UIWindow*)getKeyWindowBasedOnInAppOrigin {
    //If in-app is originated from inbox, then use scene from the inbox screen
    if (_notification && _notification.isFromInbox && _notification.inboxDelegate && [_notification.inboxDelegate respondsToSelector:@selector(getInboxWindowScene)]) {
        if (@available(iOS 13.0, *)) {
            UIWindowScene* windowScene = _notification.inboxDelegate.getInboxWindowScene;
            if (windowScene) {
                if (@available(iOS 15.0, *)) {
                    return _notification.inboxDelegate.getInboxWindowScene.keyWindow;
                } else {
                    for (UIWindow *window in _notification.inboxDelegate.getInboxWindowScene.windows) {
                        if (window && window.isKeyWindow) {
                            return window;
                        }
                    }
                }
            }
        }
    }
    //If its normal in-app, use the key window
    return [BlueShiftInAppNotificationHelper getApplicationKeyWindow];
}


- (void)createWindow {
    self.window = nil;
    Class windowClass = self.canTouchesPassThroughWindow ? BlueShiftNotificationWindow.class : UIWindow.class;
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = [self getKeyWindowBasedOnInAppOrigin].windowScene;
        if (windowScene) {
            self.window = [[windowClass alloc] initWithWindowScene: windowScene];
        }
    }
    if (self.window == nil) {
        self.window = [[windowClass alloc] init];
    }
    self.window.frame = [self getKeyWindowBasedOnInAppOrigin].frame;
    self.window.alpha = 0;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.windowLevel = UIWindowLevelNormal;
}

- (void)createWindowAndPresent {
    [self createWindow];
    self.window.rootViewController = self;
    [self.window setHidden:NO];
}

-(void)show:(BOOL)animated {
    NSAssert(false, @"Override in sub-class");
}

-(void)hide:(BOOL)animated {
    NSAssert(false, @"Override in sub-class");
}

- (void)configureBackground {
    self.view.backgroundColor = [UIColor clearColor];
}

- (UIColor *)colorWithHexString:(NSString *)str {
    if (str) {
        unsigned char r, g, b;
        const char *cStr = [str cStringUsingEncoding:NSASCIIStringEncoding];
        long x = strtol(cStr+1, NULL, 16);
        b =  x & 0xFF;
        g = (x >> 8) & 0xFF;
        r = (x >> 16) & 0xFF;
        return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
    } else {
        return [UIColor clearColor];
    }
}


/// Download and load image in imageView
/// @param imageURL Image url to download the image
/// @param imageView  assign the downloaded image to imageView
- (void)loadImageFromURL:(NSString *)imageURL forImageView:(UIImageView *)imageView {
    UIImage *image = [[UIImage alloc] initWithData:[BlueShiftRequestOperationManager.sharedRequestOperationManager getCachedImageDataForURL:imageURL]];
    imageView.image = image;
}

- (void)setBackgroundImageFromURL:(UIView *)notificationView {
    if (notificationView && [self isBackgroundImagePresentForNotification:self.notification]) {
        NSString *backgroundImageURL = self.notification.templateStyle.backgroundImage;
        UIImage *image = [[UIImage alloc] initWithData:[BlueShiftRequestOperationManager.sharedRequestOperationManager getCachedImageDataForURL:backgroundImageURL]];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = notificationView.bounds;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [notificationView addSubview:imageView];
    }
}

- (void)setBackgroundColor:(UIView *)notificationView {
    UIColor *backgroundColor = UIColor.whiteColor;
    if(self.notification.templateStyle && self.notification.templateStyle.backgroundColor && ![self.notification.templateStyle.backgroundColor isEqualToString:@""]){
        backgroundColor = [self colorWithHexString:self.notification.templateStyle.backgroundColor];
    }
    notificationView.backgroundColor = backgroundColor;
}

- (void)setBackgroundRadius:(UIView *)notificationView {
    CGFloat backgroundRadius = 0.0;
    if (self.notification.templateStyle && self.notification.templateStyle.backgroundRadius
        && self.notification.templateStyle.backgroundRadius.floatValue > 0) {
        backgroundRadius = self.notification.templateStyle.backgroundRadius.floatValue;
    }
    notificationView.layer.cornerRadius = backgroundRadius;
}

- (void)setBackgroundDim {
    CGFloat backgroundDimAmount = 0.5;
    if (self.notification.templateStyle && self.notification.templateStyle.backgroundDimAmount
        && self.notification.templateStyle.backgroundDimAmount.floatValue > 0) {
        backgroundDimAmount = self.notification.templateStyle.backgroundDimAmount.floatValue;
    }
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: backgroundDimAmount];
}

- (BOOL)checkDefaultCloseButtonStatusForInApp {
    if((self.notification.inAppType == BlueShiftInAppTypeModal && self.notification.notificationContent.actions.count == 0) || self.notification.inAppType == BlueShiftInAppTypeHTML) {
        return YES;
    }
    return NO;
}

- (BOOL)shouldShowCloseButton {
    if (self.notification.templateStyle.enableCloseButton != nil) {
        return [self.notification.templateStyle.enableCloseButton boolValue];
    }
    return [self checkDefaultCloseButtonStatusForInApp];
}

- (void)createCloseButton:(CGRect)frame {
    BOOL showCloseButton = [self shouldShowCloseButton];
    CGFloat margin = 5;
    if (self.notification.templateStyle && showCloseButton) {
        if ( self.notification.templateStyle.closeButton
            && self.notification.templateStyle.closeButton.text
            && ![self.notification.templateStyle.closeButton.text isEqualToString:@""]) {
            CGFloat xPosition = frame.origin.x + frame.size.width - KInAppNotificationModalCloseButtonWidth - margin;
            CGRect cgRect = CGRectMake(xPosition, frame.origin.y + margin, KInAppNotificationModalCloseButtonWidth, KInAppNotificationModalCloseButtonHeight);
            UIButton *closeButtonLabel = [[UIButton alloc] initWithFrame:cgRect];
            BlueShiftInAppNotificationButton *closeButton = self.notification.templateStyle.closeButton;
            CGFloat closeButtonFontSize = (closeButton && closeButton.textSize && closeButton.textSize.floatValue > 0)
                ? closeButton.textSize.floatValue: 22;
            
            [self applyIconToLabelView:closeButtonLabel.titleLabel andFontIconSize:[NSNumber numberWithFloat:closeButtonFontSize]];
            
            CGFloat closeButtonRadius = 0.5 * closeButtonLabel.bounds.size.width;
            if (closeButton) {
                [self setButton: closeButtonLabel andString: closeButton.text
                textColor: closeButton.textColor backgroundColor: closeButton.backgroundColor];
                
                closeButtonRadius = (closeButton.backgroundRadius && closeButton.backgroundRadius.floatValue > 0) ?
                closeButton.backgroundRadius.floatValue : closeButtonRadius;
            }

            closeButtonLabel.layer.cornerRadius = closeButtonRadius;
            [closeButtonLabel addTarget:self action:@selector(closeButtonDidTapped) forControlEvents:UIControlEventTouchUpInside];
            
            closeButtonLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
            [closeButtonLabel.titleLabel setTextAlignment: NSTextAlignmentCenter];
            [self.view addSubview: closeButtonLabel];
        } else {
            CGFloat xPosition = frame.origin.x + frame.size.width - KInAppNotificationModalCloseButtonWidth - margin;
            CGRect cgRect = CGRectMake(xPosition, frame.origin.y + margin, KInAppNotificationModalCloseButtonWidth, KInAppNotificationModalCloseButtonHeight);
            _closeButton = [BlueShiftNotificationCloseButton new];
            [_closeButton addTarget:self action:@selector(closeButtonDidTapped) forControlEvents:UIControlEventTouchUpInside];
            _closeButton.frame = cgRect;
            _closeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
            [self.view addSubview:_closeButton];
        }
    }
}

- (void)setButton:(UIButton *)button andString:(NSString *)value
        textColor:(NSString *)textColorCode
  backgroundColor:(NSString *)backgroundColorCode {
    if (value != (id)[NSNull null] && value.length > 0 ) {
        [button setTitle : value forState:UIControlStateNormal];
        
        if (textColorCode != (id)[NSNull null] && textColorCode.length > 0) {
            [button setTitleColor:[self colorWithHexString:textColorCode] forState:UIControlStateNormal];
        }
        if (backgroundColorCode != (id)[NSNull null] && backgroundColorCode.length > 0) {
            [button setBackgroundColor:[self colorWithHexString:backgroundColorCode]];
        }
    }
}

- (void)setLabelText:(UILabel *)label andString:(NSString *)value
          labelColor:(NSString *)labelColorCode
     backgroundColor:(NSString *)backgroundColorCode {
    if (value != (id)[NSNull null] && value.length > 0 ) {
        label.hidden = NO;
        label.text = value;
        
        if (labelColorCode != (id)[NSNull null] && labelColorCode.length > 0) {
            label.textColor = [self colorWithHexString:labelColorCode];
        }
        
        if (backgroundColorCode != (id)[NSNull null] && backgroundColorCode.length > 0) {
            label.backgroundColor = [self colorWithHexString:backgroundColorCode];
        }
    } else {
        label.hidden = YES;
    }
}

- (void)handleInAppButtonAction:(BlueShiftInAppNotificationButton *)buttonDetails {
    @try {
        NSMutableDictionary *details = [[NSMutableDictionary alloc]init];
        NSString *encodedURLString = [BlueShiftInAppNotificationHelper getEncodedURLString:buttonDetails.iosLink];
        if (encodedURLString) {
            [details setValue:encodedURLString forKey:kNotificationURLElementKey];
        }
        if (buttonDetails.buttonIndex) {
            [details setValue:buttonDetails.buttonIndex forKey:kNotificationClickElementKey];
        }
        //send tracking events and handle special deep links
        [self processInAppActionForDeepLink:buttonDetails.iosLink details:details];
        
        //handle deep link to share with app or open in browser
        NSDictionary *inAppOptions = [self getInAppOpenURLOptions:buttonDetails];
        [self handleInAppNotificationDeepLink:buttonDetails.iosLink options:inAppOptions];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (void)handleInAppNotificationDeepLink:(NSString*)deepLink options:(NSDictionary*)options {
    NSURL *deepLinkURL = [NSURL URLWithString:deepLink];
    BOOL success = NO;
    if ([BlueShiftInAppNotificationHelper isValidWebURL:deepLinkURL]) {
        success = [BlueShift.sharedInstance.appDelegate openDeepLinkInWebViewBrowser:deepLinkURL showOpenInBrowserButton: self.notification.showOpenInBrowserButton];
    } else {
        success = [BlueShift.sharedInstance.appDelegate openCustomSchemeDeepLinks:deepLinkURL];
    }
    if (!success) {
        [self shareDeepLinkToApp:deepLink options:options];
    }
    
    [self hide:YES];
}

- (void)shareDeepLinkToApp:(NSString* _Nullable)deepLink options:(NSDictionary*)options {
    if([deepLink isEqualToString:kInAppNotificationDismissDeepLinkURL] ||
       [deepLink isEqualToString:kInAppNotificationReqPNPermissionDeepLinkURL] ||
       [BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:deepLink] == NO) {
        // Placeholder
        // Do not send the deep links with type dismiss or ask-pn-permission or nil or empty to openURL:options:
        // This case is already handled in the [self processInAppActionForDeepLink:]
    } else if (_notification && _notification.isFromInbox == YES && [self.notification.inboxDelegate respondsToSelector:@selector(isInboxNotificationActionTappedImplementedByHostApp)] && [self.notification.inboxDelegate isInboxNotificationActionTappedImplementedByHostApp] == YES) {
        // Handle the Deep link of in-apps originated from inbox and have implemented the callback method
        // `inboxNotificationActionTappedWithDeepLink:inboxViewController:options:`
        [_notification.inboxDelegate inboxInAppNotificationActionTappedWithDeepLink:deepLink options:options];
    } else if (_notification && _notification.isFromInbox == NO && self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(actionButtonDidTapped:)]) {
        // Handle the deep link if in-app is not originated from inbox and host app has implemented the callback method
        // `actionButtonDidTapped`
        [self sendActionButtonTappedDelegate:deepLink options:options];
    } else if([BlueShift sharedInstance].appDelegate.mainAppDelegate &&
              [[BlueShift sharedInstance].appDelegate.mainAppDelegate respondsToSelector:@selector(application:openURL:options:)]) {
        // Default callback mecanism
        if (@available(iOS 9.0, *)) {
            NSURL *deepLinkURL = [NSURL URLWithString: deepLink];
            if (deepLinkURL) {
                [[BlueShift sharedInstance].appDelegate.mainAppDelegate application:[UIApplication sharedApplication] openURL:deepLinkURL options:options];
                [BlueshiftLog logInfo:[NSString stringWithFormat:@"%@ %@",@"Delivered in-app notification deeplink to AppDelegate openURL method, Deep link - ", deepLinkURL] withDetails:options methodName:nil];
            }
        }
    }
}

- (void)processInAppActionForDeepLink:(NSString* _Nullable)deepLink details:(NSDictionary*)details {
    if (deepLink == nil || [deepLink isEqualToString:@""] || [deepLink isEqualToString:kInAppNotificationDismissDeepLinkURL]) {
        [self sendActionEventAnalytics:details forActionType:BlueshiftInAppDismissAction];
    } else if ([deepLink isEqualToString:kInAppNotificationReqPNPermissionDeepLinkURL]) {
        [self handleRequestPushPermissionDeepLink];
        [self sendActionEventAnalytics:details forActionType:BlueshiftAskPNPermission];
    } else {
        [self sendActionEventAnalytics:details forActionType:BlueshiftInAppClickAction];
    }
}

- (NSDictionary *)getInAppOpenURLOptions:(BlueShiftInAppNotificationButton * _Nullable)inAppbutton {
    NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithDictionary:@{openURLOptionsSource:openURLOptionsBlueshift}];
    @try {
        if (_notification) {
            NSString *inAppType = @"";
            switch (_notification.inAppType) {
                case BlueShiftInAppTypeModal:
                    inAppType = openURLOptionsModal;
                    break;
                case BlueShiftNotificationSlideBanner:
                    inAppType = openURLOptionsSlideIn;
                    break;
                case BlueShiftInAppTypeHTML:
                    inAppType = openURLOptionsHTML;
                    break;
                default:
                    inAppType = @"";
                    break;
            }
            [options setValue:inAppType forKey:openURLOptionsInAppType];
        }
        if (inAppbutton) {
            if ([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:inAppbutton.buttonIndex]) {
                [options setValue:inAppbutton.buttonIndex forKey:openURLOptionsButtonIndex];
            }
            if([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:inAppbutton.text]) {
                [options setValue:inAppbutton.text forKey:openURLOptionsButtonText];
            }
        }
        if (_notification.isFromInbox) {
            [options setValue:openURLOptionsInbox forKey:openURLOptionsChannel];
        } else {
            [options setValue:openURLOptionsInApp forKey:openURLOptionsChannel];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
    return options;
}

- (void)sendActionButtonTappedDelegate:(NSString*)deepLink options:(NSDictionary*)options {
    NSMutableDictionary *actionPayload = [[NSMutableDictionary alloc] initWithDictionary:options];
    [actionPayload setObject: deepLink forKey: kInAppNotificationModalPageKey];

    [actionPayload setObject: kInAppNotificationButtonTypeOpenKey forKey: kInAppNotificationButtonTypeKey];
    [[self inAppNotificationDelegate] actionButtonDidTapped: actionPayload];
    [BlueshiftLog logInfo:@"Delivered in-app notification deeplink to the actionButtonDidTapped delegate method" withDetails:actionPayload methodName:nil];
}

- (void)sendActionEventAnalytics:(NSDictionary *)details forActionType:(BlueshiftInAppActions)action {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inAppActionDidTapped:withAction:fromViewController:)]
        && self.notification) {
        NSMutableDictionary *notificationPayload = [self.notification.notificationPayload mutableCopy];
        if (details) {
            [notificationPayload addEntriesFromDictionary: details];
        }
        [self.delegate inAppActionDidTapped:notificationPayload withAction:action fromViewController:self];
    }
    [BlueshiftLog logInfo:[NSString stringWithFormat:@"Sending tracking analytics for the %@ action of the in-app notification",action == 1 ? @"dismiss" : @"click"] withDetails:nil methodName:nil];
}

- (void)handleRequestPushPermissionDeepLink {
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if ([settings authorizationStatus] == UNAuthorizationStatusDenied) {
                [self showEnablePushFromSettingsAlert];
            } else if ([settings authorizationStatus] == UNAuthorizationStatusNotDetermined) {
                [[BlueShift sharedInstance].appDelegate registerForNotification];
            }
        }];
    }
}

- (void)showEnablePushFromSettingsAlert {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIWindow * __block window = nil;
        // Cache the registered in-app screen name, and unregister screen to not show any in-apps
        // till enable push alert is displayed.
        NSString * inAppScreenName = [BlueShift.sharedInstance getRegisteredForInAppScreenName];
        [BlueShift.sharedInstance unregisterForInAppMessage];
        if (@available(iOS 13.0, *)) {
            window = [[UIWindow alloc] initWithWindowScene:[BlueShiftInAppNotificationHelper getApplicationKeyWindow].windowScene];
        } else {
            window = [[UIWindow alloc] initWithFrame:[BlueShiftInAppNotificationHelper getApplicationKeyWindow].bounds];
        }
        
        window.rootViewController = [UIViewController new];
        window.windowLevel = UIWindowLevelAlert;
        // Get localized strings if availble
        NSString *title = NSLocalizedString(kBSGoToSettingTitleLocalizedKey, @"");
        NSString *text = NSLocalizedString(kBSGoToSettingTextLocalizedKey, @"");
        NSString *okayLabel = NSLocalizedString(kBSGoToSettingOkayButtonLocalizedKey, @"");
        NSString *cancelLabel = NSLocalizedString(kBSGoToSettingCancelButtonLocalizedKey, @"");

        // If Localized strings are not set, use SDK default text
        title = [title isEqualToString: kBSGoToSettingTitleLocalizedKey] ? kBSGoToSettingDefaultTitle : title;
        text = [text isEqualToString: kBSGoToSettingTextLocalizedKey] ? kBSGoToSettingDefaultText : text;
        okayLabel = [okayLabel isEqualToString: kBSGoToSettingOkayButtonLocalizedKey] ? kBSGoToSettingDefaultOkayButton : okayLabel;
        cancelLabel = [cancelLabel isEqualToString:kBSGoToSettingCancelButtonLocalizedKey] ? kBSGoToSettingDefaultCancelButton : cancelLabel;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:okayLabel style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* url = [[NSURL alloc] initWithString: UIApplicationOpenSettingsURLString];
                if (url && [UIApplication.sharedApplication canOpenURL:url]) {
                    if (@available(iOS 10.0, *)) {
                        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
                            if (success) {
                                [BlueshiftLog logInfo:@"Opened url successfully for enable push notifications." withDetails:url methodName:nil];
                            } else {
                                [BlueshiftLog logInfo:@"Failed to open url for enable push notifications." withDetails:url methodName:nil];
                            }
                        }];
                    } else {
                        [UIApplication.sharedApplication openURL:url];
                    }
                }
                // Register for in-apps using cached screen name
                [BlueShift.sharedInstance registerForInAppMessage:inAppScreenName];
            });
            window.hidden = YES;
            window = nil;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:cancelLabel style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            window.hidden = YES;
            window = nil;
            // Register for in-apps using cached screen name
            [BlueShift.sharedInstance registerForInAppMessage:inAppScreenName];
        }]];
        
        [window makeKeyAndVisible];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

- (CGFloat)getLabelHeight:(UILabel*)label labelWidth:(CGFloat)width {
    CGSize constraint = CGSizeMake(width, CGFLOAT_MAX);
    CGSize size;
    [label setNumberOfLines: 0];
    
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [label.text boundingRectWithSize:constraint
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName:label.font}
                                                  context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    
    return size.height;
}

- (void)applyIconToLabelView:(UILabel *)iconLabelView andFontIconSize:(NSNumber *)fontSize {
    if (iconLabelView && [fontSize floatValue] > 0) {
        if ([UIFont fontWithName:kInAppNotificationModalFontAwesomeNameKey size:30] == nil) {
            [self createFontFile: iconLabelView];
        }
    
        CGFloat iconFontSize = (fontSize && fontSize.floatValue > 0)? fontSize.floatValue : 22.0;
        iconLabelView.font = [UIFont fontWithName: kInAppNotificationModalFontAwesomeNameKey size: iconFontSize];
        iconLabelView.layer.masksToBounds = YES;
    }
}

- (void)createFontFile:(UILabel *)iconLabel {
    NSString *fontFileName = [BlueShiftInAppNotificationHelper createFileNameFromURL: kInAppNotificationFontFileDownlaodURL];
    
    if ([BlueShiftInAppNotificationHelper hasFileExist: fontFileName]) {
        NSString *fontFilePath = [BlueShiftInAppNotificationHelper getLocalDirectory: fontFileName];
        NSData *fontData = [NSData dataWithContentsOfFile: fontFilePath];
        CFErrorRef error;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(( CFDataRef)fontData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            [BlueshiftLog logError:nil withDescription:@"Failed to load FontAwesome" methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            CFBridgingRelease(errorDescription);
        }
        
        CFRelease(font);
        CFRelease(provider);
    } else {
        [BlueShiftInAppNotificationHelper downloadFontAwesomeFile:^{
            [self applyIconToLabelView: iconLabel andFontIconSize: [NSNumber numberWithInt: 22]];
        }];
    }
}

- (int)getTextAlignement:(NSString *)alignmentString {
    if (alignmentString && ![alignmentString isEqualToString:@""]) {
        if ([alignmentString isEqualToString: kInAppNotificationModalLayoutMarginLeftKey] ||
            [alignmentString isEqualToString: kInAppNotificationModalGravityStartKey])
            return NSTextAlignmentLeft;
        else if([alignmentString isEqualToString: kInAppNotificationModalGravityEndKey] ||
                  [alignmentString isEqualToString: kInAppNotificationModalLayoutMarginRightKey])
            return NSTextAlignmentRight;
        else
            return NSTextAlignmentCenter;
        
    }
    
    return NSTextAlignmentCenter;
}

- (BOOL)isValidString:(NSString *)data {
    return (data && data.length > 0);
}

- (BOOL)isDarkThemeEnabled {
    if (@available(iOS 13.0, *)) {
        return self.traitCollection.userInterfaceStyle == 2;
    }

    return NO;
}

- (BOOL)isBackgroundImagePresentForNotification:(BlueShiftInAppNotification*)notification {
    return (notification && notification.templateStyle && [BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:notification.templateStyle.backgroundImage]);
}

- (BOOL)isBannerImagePresentForNotification:(BlueShiftInAppNotification*)notification {
    return (notification && notification.notificationContent && [BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:notification.notificationContent.banner]);
}

- (BOOL)isSlideInIconImagePresent:(BlueShiftInAppNotification*)notification {
    return (notification && notification.notificationContent && [BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:notification.notificationContent.iconImage]);
}

@end
