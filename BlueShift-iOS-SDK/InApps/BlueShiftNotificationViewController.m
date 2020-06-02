//
//  BlueShiftNotificationViewController.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftNotificationViewController.h"
#import "BlueShiftNotificationWindow.h"
#import "BlueShiftNotificationView.h"
#import <CoreText/CoreText.h>
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftNotificationCloseButton.h"

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
    [self sendActionEventAnalytics: kInAppNotificationButtonTypeDismissKey];
    [self hide:YES];
}

- (void)loadNotificationView {
    self.view = [[BlueShiftNotificationView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
}

- (UIView *)createNotificationWindow{
    UIView *notificationView = [[UIView alloc] initWithFrame:CGRectZero];
    notificationView.clipsToBounds = YES;
    
    return notificationView;
}

- (void)createWindow {
    Class windowClass = self.canTouchesPassThroughWindow ? BlueShiftNotificationWindow.class : UIWindow.class;
    self.window = [[windowClass alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.window.alpha = 0;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.windowLevel = UIWindowLevelNormal;
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
    unsigned char r, g, b;
    const char *cStr = [str cStringUsingEncoding:NSASCIIStringEncoding];
    long x = strtol(cStr+1, NULL, 16);
    b =  x & 0xFF;
    g = (x >> 8) & 0xFF;
    r = (x >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

- (void)loadImageFromURL:(UIImageView *)imageView andImageURL:(NSString *)imageURL andWidth:(double)width andHeight:(double)height{
    NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:imageURL]];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
//    UIImage *image = [[UIImage alloc] initWithData:imageData];
    
    // resize image
    CGSize newSize = CGSizeMake(imageView.frame.size.width, imageView.frame.size.height);
    UIGraphicsBeginImageContext(newSize);// a CGSize that has the size you want
    CGFloat xPosition = (imageView.frame.size.width / 2) - (width / 2);
    CGFloat yPosition = (imageView.frame.size.height / 2) - (height / 2);
    [image drawInRect:CGRectMake(xPosition, yPosition, width, height)];
    
    //image is the original UIImage
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    imageView.image = newImage;
}

- (void)setBackgroundImageFromURL:(UIView *)notificationView {
    if (notificationView && self.notification.templateStyle && self.notification.templateStyle.backgroundImage &&
    ![self.notification.templateStyle.backgroundImage isEqualToString:@""]) {
        NSString *backgroundImageURL = self.notification.templateStyle.backgroundImage;
        NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: backgroundImageURL]];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        [notificationView setBackgroundColor: [UIColor colorWithPatternImage: image]];
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

- (void)createCloseButton:(CGRect)frame {
    BOOL showCloseButton = ((self.notification.inAppType == BlueShiftInAppTypeModal && self.notification.notificationContent.actions.count == 0) || self.notification.inAppType == BlueShiftInAppTypeHTML) ? YES : self.notification.templateStyle.enableCloseButton;
    if (self.notification.templateStyle && showCloseButton) {
        if ( self.notification.templateStyle.closeButton
            && self.notification.templateStyle.closeButton.text
            && ![self.notification.templateStyle.closeButton.text isEqualToString:@""]) {
            CGFloat xPosition = frame.origin.x + frame.size.width - KInAppNotificationModalCloseButtonWidth - 5;
            CGRect cgRect = CGRectMake(xPosition, frame.origin.y + 5, KInAppNotificationModalCloseButtonWidth, KInAppNotificationModalCloseButtonHeight);
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
            [_closeButton removeFromSuperview];
            CGFloat xPosition = frame.origin.x + frame.size.width - KInAppNotificationModalCloseButtonWidth;
            CGRect cgRect = CGRectMake(xPosition, frame.origin.y, KInAppNotificationModalCloseButtonWidth, KInAppNotificationModalCloseButtonHeight);
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

- (void)loadImageFromLocal:(UIImageView *)imageView imageFilePath:(NSString *)filePath {
    if (filePath) {
        imageView.image = [UIImage imageWithContentsOfFile: filePath];
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

- (void)handleActionButtonNavigation:(BlueShiftInAppNotificationButton *)buttonDetails {
    [self sendActionEventAnalytics: buttonDetails.text];
    
    if (buttonDetails && buttonDetails.buttonType) {
        if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(actionButtonDidTapped:)] && self.notification) {
            [self sendActionButtonTappedDelegate: buttonDetails];
        } else if ([buttonDetails.buttonType isEqualToString: kInAppNotificationButtonTypeDismissKey]) {
            [self closeButtonDidTapped];
        } else if ([buttonDetails.buttonType isEqualToString: kInAppNotificationButtonTypeShareKey]){
            if (buttonDetails.shareableText != nil && ![buttonDetails.shareableText isEqualToString:@""]) {
                [self shareData: buttonDetails.shareableText];
            } else{
                [self closeButtonDidTapped];
            }
        } else {
            if([BlueShift sharedInstance].appDelegate.oldDelegate && [[BlueShift sharedInstance].appDelegate.oldDelegate respondsToSelector:@selector(application:openURL:options:)]
                    && buttonDetails.iosLink && ![buttonDetails.iosLink isEqualToString:@""]) {
                NSURL *deepLinkURL = [NSURL URLWithString: buttonDetails.iosLink];
                if (@available(iOS 9.0, *)) {
                    [[BlueShift sharedInstance].appDelegate.oldDelegate application:[UIApplication sharedApplication] openURL: deepLinkURL options:@{}];
                }
            }
            
            [self closeButtonDidTapped];
        }
    }
}

- (void)sendActionButtonTappedDelegate:(BlueShiftInAppNotificationButton *)actionButton {
    NSMutableDictionary *actionPayload = [[NSMutableDictionary alloc] init];
    if (actionButton.buttonType && [actionButton.buttonType isEqualToString: kInAppNotificationButtonTypeShareKey]) {
        NSString *sharableLink = actionButton.shareableText ? actionButton.shareableText : @"";
        [actionPayload setObject: sharableLink forKey: kInAppNotificationModalSharableTextKey];
    } else {
        NSString *iosLink = actionButton.iosLink ? actionButton.iosLink : @"";
        [actionPayload setObject: iosLink forKey: kInAppNotificationModalPageKey];
    }

    NSString *buttonType = actionButton.buttonType ? actionButton.buttonType : @"";
    [actionPayload setObject: buttonType forKey: kInAppNotificationButtonTypeKey];
    [[self inAppNotificationDelegate] actionButtonDidTapped: actionPayload];
    [self closeButtonDidTapped];
}

- (void)sendActionEventAnalytics:(NSString *)elementType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inAppActionDidTapped: fromViewController:)]
        && self.notification) {
        NSMutableDictionary *notificationPayload = [self.notification.notificationPayload mutableCopy];
        [notificationPayload setObject: elementType forKey: kInAppNotificationModalElementsKey];
        [self.delegate inAppActionDidTapped : notificationPayload fromViewController:self];
    }
}

- (void)shareData:(NSString *)sharableData{
    UIActivityViewController* activityView = [[UIActivityViewController alloc] initWithActivityItems:@[sharableData] applicationActivities:nil];
    
    if (@available(iOS 8.0, *)) {
        activityView.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            if (completed){
                [self closeButtonDidTapped];
            }
        };
    }
    
    [self presentViewController:activityView animated:YES completion:nil];
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
    
        CGFloat iconFontSize = (fontSize !=nil && fontSize > 0)? fontSize.floatValue : 22.0;
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
        BOOL failedToRegisterFont = NO;
        if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            NSLog(@"Error: Cannot load Font Awesome");
            CFBridgingRelease(errorDescription);
            failedToRegisterFont = YES;
        }
        
        CFRelease(font);
        CFRelease(provider);
    }else {
        [self downloadFileFromURL: iconLabel];
    }
}

- (void)downloadFileFromURL:(UILabel *)iconLabel {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL  *url = [NSURL URLWithString: kInAppNotificationFontFileDownlaodURL];
        NSData *urlData = [NSData dataWithContentsOfURL:url];
        if (urlData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *fontFileName = [BlueShiftInAppNotificationHelper createFileNameFromURL: kInAppNotificationFontFileDownlaodURL];
                NSString *fontFilePath = [BlueShiftInAppNotificationHelper getLocalDirectory: fontFileName];
                [urlData writeToFile: fontFilePath  atomically:YES];
                [self applyIconToLabelView: iconLabel andFontIconSize: [NSNumber numberWithInt: 22]];
            });
        }
    });
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

@end
