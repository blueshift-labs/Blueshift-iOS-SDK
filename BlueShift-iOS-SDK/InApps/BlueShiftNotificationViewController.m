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
#import "BlueShiftInAppNotificationDelegate.h"

@interface BlueShiftNotificationViewController ()

@property id<BlueShiftInAppNotificationDelegate> inAppNotificationDelegate;

@end

@implementation BlueShiftNotificationViewController

- (instancetype)initWithNotification:(BlueShiftInAppNotification *)notification {
    self = [super init];
    if (self) {
        _notification = notification;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidAppear)]) {
        [[self inAppNotificationDelegate] inAppNotificationDidAppear];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidDisappear)]) {
         [[self inAppNotificationDelegate] inAppNotificationDidDisappear];
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
    notificationView.layer.cornerRadius = 10.0;
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

- (void)loadImageFromURL:(UIImageView *)imageView andImageURL:(NSString *)imageURL{
    NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:imageURL]];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    
    // resize image
    CGSize newSize = CGSizeMake(imageView.layer.frame.size.width, imageView.layer.frame.size.width);
    UIGraphicsBeginImageContext(newSize);// a CGSize that has the size you want
    [image drawInRect:CGRectMake(0.0, 0.0, newSize.width, newSize.height)];
    
    //image is the original UIImage
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    imageView.image = newImage;
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
    }else {
        label.hidden = YES;
    }
}

- (void)handleActionButtonNavigation:(BlueShiftInAppNotificationButton *)buttonDetails {
    [self sendActionEventAnalytics: buttonDetails.text];
    if (buttonDetails && buttonDetails.buttonType) {
        if ([buttonDetails.buttonType isEqualToString: kInAppNotificationButtonTypeDismissKey]) {
            [self closeButtonDidTapped];
        } else if ([buttonDetails.buttonType isEqualToString: kInAppNotificationButtonTypeShareKey]){
            if (buttonDetails.sharableText != nil && ![buttonDetails.sharableText isEqualToString:@""]) {
                [self shareData: buttonDetails.sharableText];
            } else{
                [self closeButtonDidTapped];
            }
        } else {
            if (buttonDetails.iosLink && ![buttonDetails.iosLink isEqualToString:@""]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString: buttonDetails.iosLink]];
            }
            
            [self closeButtonDidTapped];
        }
    }
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
    if (self.notification.notificationContent.icon) {
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

@end
