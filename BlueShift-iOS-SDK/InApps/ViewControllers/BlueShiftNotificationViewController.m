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
#import "../BlueShiftInAppNotificationConstant.h"

@interface BlueShiftNotificationViewController ()

@property(nonatomic, assign) CGFloat initialHorizontalCenter;
@property(nonatomic, assign) CGFloat initialTouchPositionX;
@property(nonatomic, assign) CGFloat originalCenter;

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

- (CGRect)positionNotificationView:(UIView *)notificationView {
    float width = (self.notification.templateStyle && self.notification.templateStyle.width > 0) ? self.notification.templateStyle.width : self.notification.width;
    float height = (self.notification.templateStyle && self.notification.templateStyle.height > 0) ? self.notification.templateStyle.height : self.notification.height;
    
    float topMargin = 0.0;
    float bottomMargin = 0.0;
    float leftMargin = 0.0;
    float rightMargin = 0.0;
    if (self.notification.templateStyle && self.notification.templateStyle.margin) {
        if (self.notification.templateStyle.margin.top > 0) {
            topMargin = self.notification.templateStyle.margin.top;
        }
        if (self.notification.templateStyle.margin.bottom > 0) {
            bottomMargin = self.notification.templateStyle.margin.bottom;
        }
        if (self.notification.templateStyle.margin.left > 0) {
            leftMargin = self.notification.templateStyle.margin.left;
        }
        if (self.notification.templateStyle.margin.right > 0) {
            rightMargin = self.notification.templateStyle.margin.right;
        }
    }
    
    CGSize size = CGSizeZero;
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPointsKey]) {
        // Ignore Constants.INAPP_X_PERCENT
        size.width = width;
        size.height = height;
    } else if([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        CGFloat itemHeight = (CGFloat) ceil([[UIScreen mainScreen] bounds].size.height * (height / 100.0f));
        CGFloat itemWidth =  (CGFloat) ceil([[UIScreen mainScreen] bounds].size.width * (width / 100.0f));
        
        if (self.notification.inAppType == BlueShiftNotificationSlideBanner && itemHeight < 80.0) {
            itemHeight = 80.0;
        }
        
        if (width == 100) {
            itemWidth = itemWidth - (leftMargin + rightMargin);
        }
        
        if (height == 100) {
            itemHeight = itemHeight - (topMargin + bottomMargin);
        }
        
        size.width = itemWidth;
        size.height = itemHeight;
        
    }else {
        
    }
    
    CGRect frame = notificationView.frame;
    frame.size = size;
    notificationView.autoresizingMask = UIViewAutoresizingNone;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    NSString* position = (self.notification.templateStyle && self.notification.templateStyle.position) ? self.notification.templateStyle.position : self.notification.position;
    
    if([position  isEqual: kInAppNotificationModalPositionTopKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = 0.0f + topMargin;
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
    } else if([position  isEqual: kInAppNotificationModalPositionCenterKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = (screenSize.height - size.height) / 2.0f;
    } else if([position  isEqual: kInAppNotificationModalPositionBottomKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = screenSize.height - (size.height + bottomMargin);
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleTopMargin;
    } else {
        
    }
    
    frame.origin.x = frame.origin.x < 0.0f ? 0.0f : frame.origin.x;
    frame.origin.y = frame.origin.y < 0.0f ? 0.0f : frame.origin.y;
    notificationView.frame = frame;
    _originalCenter = frame.origin.x + frame.size.width / 2.0f;
    
    return frame;
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
    if (buttonDetails && buttonDetails.buttonType) {
        if ([buttonDetails.buttonType isEqualToString: kInAppNotificationButtonTypeDismissKey]) {
            [self closeButtonDidTapped];
        } else if ([buttonDetails.buttonType isEqualToString: kInAppNotificationButtonTypeShareKey]){
            [self shareData: buttonDetails.sharableText ? buttonDetails.sharableText :@""];
            
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(inAppActionDidTapped: fromViewController:)]) {
                NSDictionary *buttonPayload = [[BlueShiftInAppNotificationButton alloc] convertObjectToDictionary: buttonDetails];
                [self.delegate inAppActionDidTapped : buttonPayload fromViewController:self];
            }
            
            [self closeButtonDidTapped];
        }
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

- (void)applyIconToLabelView:(UILabel *)iconLabelView {
    if (self.notification.notificationContent.icon) {
        if ([UIFont fontWithName:kInAppNotificationModalFontAwesomeNameKey size:30] == nil) {
            [self createFontFile: iconLabelView];
        }
    
        CGFloat iconFontSize = 22.0;
        if (self.notification.contentStyle && self.notification.contentStyle.iconSize) {
            iconFontSize = self.notification.contentStyle.iconSize.floatValue > 0
            ? self.notification.contentStyle.iconSize.floatValue : 22.0;
            
        }
        iconLabelView.font = [UIFont fontWithName: kInAppNotificationModalFontAwesomeNameKey size: iconFontSize];
    
        [self setLabelText: iconLabelView andString: self.notification.notificationContent.icon labelColor:self.notification.contentStyle.iconColor backgroundColor:self.notification.contentStyle.iconBackgroundColor];
    
        iconLabelView.layer.cornerRadius = 10;
        iconLabelView.layer.masksToBounds = YES;
    }
}

- (void)createFontFile:(UILabel *)iconLabel {
    if ([self hasFileExist: [self getLocalDirectory: kInAppNotificationModalFontWithExtensionKey]]) {
        NSData *fontData = [NSData dataWithContentsOfFile: [self getLocalDirectory :kInAppNotificationModalFontWithExtensionKey]];
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
        NSString *urlToDownload = @"https://firebasestorage.googleapis.com/v0/b/cargonex-6251f.appspot.com/o/FontAwesome.otf?alt=media&token=da8d5411-04dd-47a3-a4a8-be76603ca117";
        NSURL  *url = [NSURL URLWithString:urlToDownload];
        NSData *urlData = [NSData dataWithContentsOfURL:url];
        if (urlData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [urlData writeToFile: [self getLocalDirectory: kInAppNotificationModalFontWithExtensionKey] atomically:YES];
                [self applyIconToLabelView: iconLabel];
            });
        }
    });
}

- (NSString *)getLocalDirectory:(NSString *)fileName {
    NSString* tempPath = NSTemporaryDirectory();
    return [tempPath stringByAppendingPathComponent: fileName];
}

- (BOOL)hasFileExist:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath: filePath];
}

- (void)deleteFileFromLocal:(NSString *)fileName{
    NSString *filePath = [self getLocalDirectory: fileName];
    if ([self hasFileExist: filePath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
}

- (NSString *)createFileNameFromURL:(NSString *)imageURL{
    NSString *fileName = [[imageURL lastPathComponent] stringByDeletingPathExtension];
    NSURL *url = [NSURL URLWithString: imageURL];
    NSString *extension = [url pathExtension];
    fileName = [fileName stringByAppendingString:@"."];
    return [fileName stringByAppendingString: extension];
}

@end
