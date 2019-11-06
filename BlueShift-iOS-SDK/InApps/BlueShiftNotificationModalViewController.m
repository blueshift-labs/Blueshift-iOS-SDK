//
//  BlueShiftPromoNotificationViewController.m
//  BlueShift-iOS-SDK-BlueShiftBundle
//
//  Created by Noufal Subair on 16/07/19.
//

#import "BlueShiftNotificationModalViewController.h"
#import "BlueShiftNotificationView.h"
#import "BlueShiftNotificationWindow.h"
#import "BlueShiftInAppNotificationHelper.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftInAppNotificationDelegate.h"
#import "BlueShiftInAppNotificationHelper.h"

@interface BlueShiftNotificationModalViewController ()<UIGestureRecognizerDelegate>{
    UIView *notificationView;
}

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;
@property(nonatomic, assign) CGFloat initialHorizontalCenter;
@property(nonatomic, assign) CGFloat initialTouchPositionX;
@property(nonatomic, assign) CGFloat originalCenter;

- (void)onOkayButtonTapped:(UIButton *)customButton;

@end

@implementation BlueShiftNotificationModalViewController

- (void)loadView {
    if (self.canTouchesPassThroughWindow) {
        [self loadNotificationView];
    } else {
        [super loadView];
    }
    
    notificationView = [self createNotificationWindow];
    [self.view insertSubview:notificationView aboveSubview:self.view];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBackground];
    [self createNotificationView];
    [self initializeNotificationView];
}

- (void)createNotificationView {
    CGRect frame = [self positionNotificationView];
    notificationView.frame = frame;
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    }
}

- (void)onOkayButtonTapped:(UIButton *)customButton{
    NSInteger position = customButton.tag;
    if (self.notification && self.notification.notificationContent && self.notification.notificationContent.actions && self.notification.notificationContent.actions[position]) {
        [self handleActionButtonNavigation: self.notification.notificationContent.actions[position]];
    }
}

- (void)showFromWindow:(BOOL)animated {
    if (!self.notification) return;
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationWillAppear)]) {
        [[self inAppNotificationDelegate] inAppNotificationWillAppear];
    }
    
    [self createWindow];
    void (^completionBlock)(void) = ^ {
        if (self.delegate && [self.delegate respondsToSelector:@selector(inAppDidShow:fromViewController:)]) {
            [self.delegate inAppDidShow: self.notification.notificationPayload fromViewController:self];
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 1.0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } else {
        self.window.alpha = 1.0;
        completionBlock();
    }
}

- (void)hideFromWindow:(BOOL)animated {
    void (^completionBlock)(void) = ^ {
        if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationWillDisappear)]) {
            [[self inAppNotificationDelegate] inAppNotificationWillDisappear];
        }
        
        [self.window setHidden:YES];
        [self.window removeFromSuperview];
        self.window = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(inAppDidDismiss:fromViewController:)]) {
            [self.delegate inAppDidDismiss:self.notification.notificationPayload fromViewController:self];
        }
        
        if (self.notification.notificationContent.banner) {
            NSString *fileName = [BlueShiftInAppNotificationHelper createFileNameFromURL: self.notification.notificationContent.banner];
            if (fileName && [BlueShiftInAppNotificationHelper hasFileExist: fileName]) {
                [BlueShiftInAppNotificationHelper deleteFileFromLocal: fileName];
                NSLog(@"Image file deleted");
            }
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
    else {
        completionBlock();
    }
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

- (void)initializeNotificationView{
    if (self.notification && self.notification.notificationContent) {
        CGFloat yPadding = 0.0;
        
        UIImageView *imageView;
        if (self.notification.notificationContent.banner) {
            BlueShiftInAppLayoutMargin *bannerImagePadding = [self fetchNotificationBannerImagePadding];
            yPadding = (bannerImagePadding && bannerImagePadding.top > 0) ? bannerImagePadding.top : 0.0;
            imageView = [self createImageView];
            
            CGFloat bannerBottomPadding = (bannerImagePadding && bannerImagePadding.bottom > 0) ? bannerImagePadding.bottom : 0.0;
            yPadding = yPadding + imageView.layer.frame.size.height + bannerBottomPadding;
        }
        
        UILabel *iconLabel;
        if (self.notification.notificationContent.icon) {
            BlueShiftInAppLayoutMargin *iconPadding = [self fetchNotificationIconPadding];
            CGFloat iconTopPadding = (iconPadding && iconPadding.top > 0) ? iconPadding.top : 0.0;
            CGFloat iconBottomPadding = (iconPadding && iconPadding.bottom > 0) ? iconPadding.bottom : 0.0;
            
            yPadding = yPadding + iconTopPadding;
            iconLabel = [self createIconLabel: yPadding];
            yPadding = yPadding + iconBottomPadding + iconLabel.frame.size.height;
        }
        
        UILabel *titleLabel;
        if (self.notification.notificationContent.title) {
            BlueShiftInAppLayoutMargin *titlePadding = [self fetchNotificationTitlePadding];
            CGFloat titleTopPadding = (titlePadding && titlePadding.top > 0) ? titlePadding.top : 0.0 ;
            CGFloat titleBottomPadding = (titlePadding && titlePadding.bottom > 0)? titlePadding.bottom : 0.0;
            
            yPadding = yPadding + titleTopPadding;
            titleLabel = [self createTitleLabel: yPadding];
            yPadding = yPadding + titleLabel.frame.size.height + titleBottomPadding;
        }
        
        UILabel *subTitleLabel;
        if (self.notification.notificationContent.subTitle) {
            BlueShiftInAppLayoutMargin *subTitlePadding = [self fetchNotificationSubTitlePadding];
            CGFloat subTitleTopPadding = (subTitlePadding && subTitlePadding.top > 0) ? subTitlePadding.top : 0.0;
            CGFloat subTitleBottomPadding = (subTitlePadding && subTitlePadding.bottom > 0) ? subTitlePadding.bottom : 0.0;
            
            yPadding = yPadding + subTitleTopPadding;
            subTitleLabel = [self createSubTitleLabel: yPadding];
            yPadding = yPadding + subTitleLabel.frame.size.height + subTitleBottomPadding;
        }
        
        UILabel *descriptionLabel;
        if (self.notification.notificationContent.message) {
            BlueShiftInAppLayoutMargin *messagePadding = [self fetchNotificationMessagePadding];
            CGFloat messageTopPadding = (messagePadding && messagePadding.top > 0) ? messagePadding.top : 0.0;
            CGFloat messageBottomPadding = (messagePadding && messagePadding.bottom > 0) ? messagePadding.bottom : 0.0;
            
            yPadding = yPadding + messageTopPadding;
            descriptionLabel = [self createDescriptionLabel:yPadding];
            yPadding = yPadding + descriptionLabel.frame.size.height + messageBottomPadding;
        }
        
        if (self.notification.contentStyle) {
            notificationView.backgroundColor = self.notification.contentStyle.messageBackgroundColor ? [self colorWithHexString: self.notification.contentStyle.messageBackgroundColor]
                : UIColor.whiteColor;
        }
        
        if (self.notification.templateStyle == nil || self.notification.templateStyle.height <= 0) {
            CGRect frame = notificationView.frame;
            frame.size.height = yPadding + [self calculateTotalButtonHeight];
            notificationView.frame = frame;
            
            [self createNotificationView];
        }
        
        [notificationView addSubview:imageView];
        [notificationView addSubview: iconLabel];
        [notificationView addSubview: titleLabel];
        [notificationView addSubview: subTitleLabel];
        [notificationView addSubview:descriptionLabel];
        [self initializeButtonView];
    }
}

- (UIImageView *)createImageView {
    BlueShiftInAppLayoutMargin *bannerImagePadding = [self fetchNotificationBannerImagePadding];
    CGFloat rightPadding = (bannerImagePadding && bannerImagePadding.right > 0) ? bannerImagePadding.right : 0.0;
    CGFloat xPosition = (bannerImagePadding && bannerImagePadding.left > 0) ? bannerImagePadding.left : 0.0;
    CGFloat yPosition = (bannerImagePadding && bannerImagePadding.top > 0) ? bannerImagePadding.top : 0.0;
    
    CGFloat imageViewWidth = notificationView.frame.size.width - (xPosition + rightPadding);
    CGFloat imageViewHeight = notificationView.frame.size.width / 2;
    CGRect cgRect = CGRectMake(xPosition, yPosition, imageViewWidth, imageViewHeight);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame: cgRect];
    if (self.notification.notificationContent.banner) {
        NSString *fileName = [BlueShiftInAppNotificationHelper createFileNameFromURL: self.notification.notificationContent.banner];
        if (fileName && [BlueShiftInAppNotificationHelper hasFileExist: fileName]) {
            NSString *filePath = [BlueShiftInAppNotificationHelper getLocalDirectory: fileName];
            [self loadImageFromLocal:imageView imageFilePath: filePath];
        } else{
            [self loadImageFromURL: imageView andImageURL: self.notification.notificationContent.banner];
        }
    }
    
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    
    return imageView;
}

- (UILabel *)createIconLabel:(CGFloat)yPosition {
    CGFloat xPosition = [self getCenterXPosition:notificationView childWidth: kInAppNotificationModalIconWidth];
    CGRect cgRect = CGRectMake(xPosition, yPosition, kInAppNotificationModalIconWidth, kInAppNotificationModalIconHeight);
        
    UILabel *label = [[UILabel alloc] initWithFrame:cgRect];
    
    CGFloat iconFontSize = 22;
    if (self.notification.contentStyle && self.notification.contentStyle.iconSize) {
        iconFontSize = self.notification.contentStyle.iconSize.floatValue > 0
        ? self.notification.contentStyle.iconSize.floatValue : 22;
    }
    
    [self applyIconToLabelView:label andFontIconSize:[NSNumber numberWithFloat:iconFontSize]];
    
    [self setLabelText: label andString: self.notification.notificationContent.icon labelColor:self.notification.contentStyle.iconColor backgroundColor:self.notification.contentStyle.iconBackgroundColor];
    
    CGFloat iconRadius = 0.0;
    if (self.notification.contentStyle && self.notification.contentStyle.iconBackgroundRadius) {
        iconFontSize = self.notification.contentStyle.iconBackgroundRadius.floatValue;
    }
    
    label.layer.cornerRadius = iconRadius;
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [label setTextAlignment: NSTextAlignmentCenter];
        
    return label;
}

- (UILabel *)createTitleLabel:(CGFloat)yPosition {
    BlueShiftInAppLayoutMargin *titlePadding = [self fetchNotificationTitlePadding];
    CGFloat titleLeftPadding = (titlePadding && titlePadding.left > 0) ? titlePadding.left : 0.0;
    CGFloat titleRightPadding = (titlePadding && titlePadding.right > 0)? titlePadding.right : 0.0;
    
    CGFloat titleLabelWidth = notificationView.frame.size.width - (titleLeftPadding + titleRightPadding);
    CGFloat titleLabelHeight = kInAppNotificationModalTitleHeight;
    CGRect cgRect = CGRectMake(titleLeftPadding, yPosition, titleLabelWidth, titleLabelHeight);
    
    UILabel *titlelabel = [[UILabel alloc] initWithFrame: cgRect];
    CGFloat fontSize = 18.0;
    
    if (self.notification.contentStyle) {
        [self setLabelText: titlelabel andString:self.notification.notificationContent.title labelColor:self.notification.contentStyle.titleColor backgroundColor:self.notification.contentStyle.titleBackgroundColor];
        fontSize = self.notification.contentStyle.titleSize.floatValue > 0
        ? self.notification.contentStyle.titleSize.floatValue : 18.0;
    }

    [titlelabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size: fontSize]];
    titlelabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    int textAlignment = (self.notification.contentStyle && self.notification.contentStyle.titleGravity) ? [self getTextAlignement: self.notification.contentStyle.titleGravity] : NSTextAlignmentCenter;
    [titlelabel setTextAlignment: textAlignment];
    
    return titlelabel;
}

- (UILabel *)createSubTitleLabel:(CGFloat)yPosition {
    BlueShiftInAppLayoutMargin *subTitlePadding = [self fetchNotificationSubTitlePadding];
    CGFloat subTitleLeftPadding = (subTitlePadding && subTitlePadding.left > 0) ? subTitlePadding.left : 0.0;
    CGFloat subTitleRightPadding = (subTitlePadding && subTitlePadding.right > 0)? subTitlePadding.right : 0.0;
    
    CGFloat subTitleLabelWidth = notificationView.frame.size.width - (subTitleLeftPadding + subTitleRightPadding);
    UILabel *subTitleLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    [subTitleLabel setNumberOfLines: 0];
    [subTitleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:16]];
    
    if (self.notification.contentStyle) {
        [self setLabelText: subTitleLabel andString:self.notification.notificationContent.subTitle labelColor:self.notification.contentStyle.titleColor backgroundColor:self.notification.contentStyle.titleBackgroundColor];
    }
    
    CGFloat descriptionLabelHeight = [self getLabelHeight: subTitleLabel labelWidth: subTitleLabelWidth] + 10.0;
    CGRect cgRect = CGRectMake(subTitleLeftPadding, yPosition, subTitleLabelWidth, descriptionLabelHeight);
    
    subTitleLabel.frame = cgRect;
    subTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    int textAlignment = (self.notification.contentStyle && self.notification.contentStyle.titleGravity) ? [self getTextAlignement: self.notification.contentStyle.titleGravity] : NSTextAlignmentCenter;
    [subTitleLabel setTextAlignment: textAlignment];
    
    return subTitleLabel;
}

- (UILabel *)createDescriptionLabel:(CGFloat)yPosition {
    BlueShiftInAppLayoutMargin *messagePadding = [self fetchNotificationMessagePadding];
    CGFloat messageLeftPadding = (messagePadding && messagePadding.left > 0) ? messagePadding.left : 0.0;
    CGFloat messageRightPadding = (messagePadding && messagePadding.right > 0)? messagePadding.right : 0.0;
    
    CGFloat descriptionLabelWidth = notificationView.frame.size.width - (messageLeftPadding + messageRightPadding);
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    [descriptionLabel setNumberOfLines: 0];
     CGFloat fontSize = 14.0;
    
    if (self.notification.contentStyle) {
        [self setLabelText: descriptionLabel andString:self.notification.notificationContent.message labelColor:self.notification.contentStyle.messageColor backgroundColor:self.notification.contentStyle.messageBackgroundColor];
        fontSize = self.notification.contentStyle.messageSize.floatValue > 0
        ? self.notification.contentStyle.messageSize.floatValue : 14.0;
    }
    
    [descriptionLabel setFont:[UIFont fontWithName:@"Helvetica" size: fontSize]];
    CGFloat descriptionLabelHeight = [self getLabelHeight: descriptionLabel labelWidth: descriptionLabelWidth];
    CGRect cgRect = CGRectMake(messageLeftPadding, yPosition, descriptionLabelWidth, descriptionLabelHeight);
    
    descriptionLabel.frame = cgRect;
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    int textAlignment = (self.notification.contentStyle && self.notification.contentStyle.messageGravity) ? [self getTextAlignement: self.notification.contentStyle.messageGravity] : NSTextAlignmentCenter;
    [descriptionLabel setTextAlignment: textAlignment];
    
    return descriptionLabel;
}

- (void)initializeButtonView {
    if (self.notification && self.notification.notificationContent && self.notification.notificationContent.actions &&
        self.notification.notificationContent.actions.count > 0) {
        
        CGFloat xPadding = 0.0;
        CGFloat yPadding = 0.0;
        if (self.notification.contentStyle != nil && self.notification.contentStyle.actionsPadding != nil) {
            if (self.notification.contentStyle.actionsPadding.left > 0) {
                xPadding = self.notification.contentStyle.actionsPadding.left;
            }
            
            if (self.notification.contentStyle.actionsPadding.bottom > 0) {
                yPadding = self.notification.contentStyle.actionsPadding.bottom;
            }
        }
    
        CGFloat buttonHeight = 40.0;
        CGFloat buttonWidth = [self getActionButtonWidth:xPadding] ;
        
        CGFloat xPosition = [self getActionButtonXPosition: notificationView childWidth: buttonWidth andXPadding: xPadding];
        CGFloat yPosition = notificationView.frame.size.height - buttonHeight - yPadding;
        
        for (int i = 0; i< [self.notification.notificationContent.actions count]; i++) {
            CGRect cgRect = CGRectMake(xPosition, yPosition , buttonWidth, buttonHeight);
            [self createActionButton: self.notification.notificationContent.actions[i] positionButton: cgRect objectPosition: &i];
            
             if (self.notification.contentStyle && self.notification.contentStyle.actionsOrientation .intValue > 0) {
                 yPosition = yPosition - buttonHeight - yPadding;
             } else {
                 xPosition =  xPosition + buttonWidth + xPadding;
             }
        }
    }
}

- (void)createActionButton:(BlueShiftInAppNotificationButton *)buttonDetails positionButton:(CGRect)positionValue objectPosition:(int *)position{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self
               action:@selector(onOkayButtonTapped:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTag: *position];
    [self setButton: button andString: buttonDetails.text
          textColor: buttonDetails.textColor backgroundColor: buttonDetails.backgroundColor];
    
    CGFloat buttonRadius = (buttonDetails.backgroundRadius !=nil && buttonDetails.backgroundRadius > 0) ?
    [buttonDetails.backgroundRadius floatValue] : 0.0;
    
    button.layer.cornerRadius = buttonRadius;
    button.frame = positionValue;
    button.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [notificationView addSubview:button];
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

- (CGFloat)getCenterXPosition:(UIView *)parentView childWidth:(CGFloat)width {
    CGFloat xPadding = width / 2.0;
    
    return ((parentView.frame.size.width / 2) - xPadding);
}

- (CGFloat)getActionButtonWidth:(CGFloat)xPadding{
    NSUInteger numberOfButtons = [self.notification.notificationContent.actions count];
    
    return (self.notification.contentStyle && self.notification.contentStyle.actionsOrientation.intValue > 0)
    ? (notificationView.frame.size.width - ((numberOfButtons + 1) * xPadding))
    : (notificationView.frame.size.width - ((numberOfButtons + 1) * xPadding)) /numberOfButtons;
}

- (CGFloat)getActionButtonXPosition:(UIView *)parentView childWidth:(CGFloat)width andXPadding:(CGFloat)xPadding{
    return (self.notification.contentStyle && self.notification.contentStyle.actionsOrientation.intValue > 0)
    ? [self getCenterXPosition: parentView childWidth: width]
    : xPadding;
}

- (CGRect)positionNotificationView {
    float width = (self.notification.templateStyle && self.notification.templateStyle.width > 0) ? self.notification.templateStyle.width : self.notification.width;
    float height = (self.notification.templateStyle && self.notification.templateStyle.height > 0) ? self.notification.templateStyle.height :[BlueShiftInAppNotificationHelper convertHeightToPercentage: notificationView];
    
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    float topMargin = statusBarFrame.size.height;
    float bottomMargin = 0.0;
    float leftMargin = 0.0;
    float rightMargin = 0.0;
    if (self.notification.templateStyle && self.notification.templateStyle.margin) {
        if (self.notification.templateStyle.margin.top > 0) {
            topMargin = topMargin + self.notification.templateStyle.margin.top;
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
        size.width = width;
        size.height = height;
    } else if([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        CGFloat itemHeight = (CGFloat) ceil([[UIScreen mainScreen] bounds].size.height * (height / 100.0f));
        CGFloat itemWidth =  (CGFloat) ceil([[UIScreen mainScreen] bounds].size.width * (width / 100.0f));
        
        if (height == 100) {
            itemHeight = itemHeight - (topMargin + bottomMargin);
        }
        
        if (width == 100) {
            itemWidth = itemWidth - (leftMargin + rightMargin);
        }
        
        size.width = itemWidth;
        size.height = itemHeight;
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
    }
    
    frame.origin.x = frame.origin.x < 0.0f ? 0.0f : frame.origin.x;
    frame.origin.y = frame.origin.y < 0.0f ? 0.0f : frame.origin.y;
    notificationView.frame = frame;
    _originalCenter = frame.origin.x + frame.size.width / 2.0f;
    
    return frame;
}

- (CGFloat)calculateTotalButtonHeight {
    if (self.notification.notificationContent.actions != nil && self.notification.notificationContent.actions.count > 0) {
    
        CGFloat bottomPadding = 0;
        CGFloat topPadding = 0.0;
        CGFloat buttonCount = [self.notification.notificationContent.actions count];
        
        if (self.notification.contentStyle != nil && self.notification.contentStyle.actionsPadding != nil) {
            if (self.notification.contentStyle.actionsPadding.bottom > 0)
                bottomPadding = self.notification.contentStyle.actionsPadding.bottom;
            
            if (self.notification.contentStyle.actionsPadding.top > 0) {
                topPadding = self.notification.contentStyle.actionsPadding.top;
            }
        }
        
        if (self.notification.contentStyle != nil && self.notification.contentStyle.actionsOrientation != nil && self.notification.contentStyle.actionsOrientation.intValue > 0) {
                return ((buttonCount * 40) + (buttonCount * bottomPadding)) + topPadding;
        } else {
            return (bottomPadding + 40) + topPadding;
        }
    }
    
    return 0;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationBannerImagePadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.bannerPadding)
    ? self.notification.contentStyle.bannerPadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationIconPadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.iconPadding)
       ? self.notification.contentStyle.iconPadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationTitlePadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.titlePadding)
       ? self.notification.contentStyle.titlePadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationMessagePadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.messagePadding)
       ? self.notification.contentStyle.messagePadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationSubTitlePadding {
     return (self.notification && self.notification.contentStyle && self.notification.contentStyle.subTitlePadding)
          ? self.notification.contentStyle.subTitlePadding : NULL;
}

@end
