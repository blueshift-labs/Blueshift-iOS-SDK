//
//  BlueShiftNotificationSlideBannerViewController.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 23/07/19.
//

#import "BlueShiftNotificationSlideBannerViewController.h"
#import "BlueShiftNotificationView.h"
#import "BlueShiftNotificationWindow.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftInAppNotificationDelegate.h"
#import "BlueShiftInAppNotificationConstant.h"

@interface BlueShiftNotificationSlideBannerViewController ()<UIGestureRecognizerDelegate> {
    UIView *slideBannerView;
}

@property(nonatomic, assign) CGFloat initialHorizontalCenter;
@property(nonatomic, assign) CGFloat initialTouchPositionX;
@property(nonatomic, assign) CGFloat originalCenter;

- (IBAction)onOkayButtonTapped:(id)sender;

@end

@implementation BlueShiftNotificationSlideBannerViewController

- (void)loadView {
   if (self.canTouchesPassThroughWindow) {
        [self loadNotificationView];
    } else {
        [super loadView];
    }
    
    slideBannerView = [self createNotificationWindow];
    [self enableSingleTap];
    [self presentAnimationView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBackground];
    [self createNotificationView];
    [self initializeNotificationView];
}

- (void)enableSingleTap {
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(onOkayButtonTapped:)];
    [slideBannerView addGestureRecognizer:singleFingerTap];
}

- (void)presentAnimationView {
    CATransition *transition = [CATransition animation];
    transition.duration = 1.0;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [slideBannerView.layer addAnimation:transition forKey:nil];
    
    [self.view insertSubview:slideBannerView aboveSubview:self.view];
}

- (void)createNotificationView {
    CGRect frame = [self positionNotificationView];
    slideBannerView.frame = frame;
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
        
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
            [self.delegate inAppDidShow:self.notification.notificationPayload fromViewController:self];
        }
    };
    if (animated) {
        self.window.alpha = 2.0;
        completionBlock();
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
    };
    
    if (animated) {
        [UIView animateWithDuration:1.5 animations:^{
         self.view.frame = CGRectMake(2 * self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
            self.window.alpha = 0;
     } completion:^(BOOL finished) {
            completionBlock();        }];
    }
    else {
        completionBlock();
    }
}

- (void)initializeNotificationView {
    if (self.notification && self.notification.notificationContent) {
        CGFloat xPadding = 0.0;
        
        UILabel *iconLabel;
        BlueShiftInAppLayoutMargin *iconPadding = [self fetchNotificationIconPadding];
        if (self.notification.notificationContent.icon) {
            xPadding = (iconPadding && iconPadding.left > 0) ? iconPadding.left : 1.0;
            CGFloat iconRightPadding = (iconPadding && iconPadding.right > 0) ? iconPadding.right : 0.0;
            
            iconLabel = [self createIconLabel: xPadding];
            [slideBannerView addSubview: iconLabel];
            
            xPadding = xPadding + iconLabel.frame.size.width + iconRightPadding;
        }
        
        UILabel *actionButtonLabel;
        if (self.notification.notificationContent.secondarIcon) {
            actionButtonLabel = [self createActionButtonLabel];
            [slideBannerView addSubview: actionButtonLabel];
        }
        
        UILabel *descriptionLabel;
        BlueShiftInAppLayoutMargin *messagePadding = [self fetchNotificationMessagePadding];
        if (self.notification.notificationContent.message) {
            BlueShiftInAppLayoutMargin *actionButtonPadding = [self fetchNotificationActionButtonPadding];
            CGFloat actionButtonRightPadding = (actionButtonPadding && actionButtonPadding.right > 0) ? actionButtonPadding.right : 0.0;
            CGFloat actionButtonLeftPadding = (actionButtonPadding && actionButtonPadding.left > 0) ? actionButtonPadding.left : 0.0;
            CGFloat actionButtonPosition = actionButtonLabel.frame.size.width + actionButtonLeftPadding + actionButtonRightPadding;
            
            CGFloat messageLeftPadding = (messagePadding && messagePadding.left > 0) ? messagePadding.left :0.0;
            CGFloat messageRightPadding = (messagePadding && messagePadding.right > 0) ? messagePadding.right : 0.0;
    
            CGFloat descriptionLabelWidth = slideBannerView.frame.size.width - (xPadding + messageLeftPadding + messageRightPadding + actionButtonPosition);
            xPadding = xPadding + messageLeftPadding;
            descriptionLabel = [self createDescriptionLabel:xPadding andLabelWidth:descriptionLabelWidth];
            [slideBannerView addSubview: descriptionLabel];
        }
        
        if (self.notification.templateStyle) {
            slideBannerView.backgroundColor = self.notification.templateStyle.backgroundColor ? [self colorWithHexString: self.notification.templateStyle.backgroundColor]
            : UIColor.blueColor;
        }
        
        if (self.notification.templateStyle == nil || self.notification.templateStyle.height <= 0) {
            CGFloat messageTopPadding = (messagePadding && messagePadding.top > 0) ? messagePadding.top :0.0;
            CGFloat messageBottomPadding = (messagePadding && messagePadding.bottom > 0) ? messagePadding.right : 0.0;
            CGFloat descriptionLabelHeight = [self getLabelHeight: descriptionLabel labelWidth: descriptionLabel.frame.size.width] + (messageTopPadding + messageBottomPadding);
            
            if (descriptionLabelHeight < 50) {
                CGFloat iconTopPadding = (iconPadding && iconPadding.top > 0) ? iconPadding.top : 0.0;
                CGFloat iconBottomPadding = (iconPadding && iconPadding.bottom > 0) ? iconPadding.bottom : 0.0;
                descriptionLabelHeight = 50 + iconTopPadding + iconBottomPadding;
            }
            
            CGRect frame = slideBannerView.frame;
            frame.size.height = descriptionLabelHeight;
            slideBannerView.frame = frame;
            
            [self createNotificationView];
        }
    }
}

- (UILabel *)createIconLabel:(CGFloat)xPosition {
    CGFloat yPosition = [self getCenterYPosition: kInAppNotificationModalIconHeight];
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
        iconRadius = self.notification.contentStyle.iconBackgroundRadius.floatValue;
    }
       
    label.layer.cornerRadius = iconRadius;
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [label setTextAlignment: NSTextAlignmentCenter];
    
    return label;
}

- (UILabel *)createDescriptionLabel:(CGFloat)xPosition andLabelWidth:(CGFloat)labelWidth{
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    [descriptionLabel setNumberOfLines: 0];
    CGFloat fontSize = 14.0;
    
    if (self.notification.contentStyle) {
        [self setLabelText: descriptionLabel andString:self.notification.notificationContent.message labelColor:self.notification.contentStyle.messageColor backgroundColor:self.notification.contentStyle.messageBackgroundColor];
        fontSize = self.notification.contentStyle.messageSize.floatValue > 0
        ? self.notification.contentStyle.messageSize.floatValue : 18.0;
    }
    
    [descriptionLabel setFont:[UIFont fontWithName:@"Helvetica" size: fontSize]];
    CGFloat descriptionLabelHeight = [self getLabelHeight: descriptionLabel labelWidth: labelWidth];
    CGFloat yPosition = [self getCenterYPosition: descriptionLabelHeight];
    
    CGRect cgRect = CGRectMake(xPosition, yPosition, labelWidth, descriptionLabelHeight);
    
    descriptionLabel.frame = cgRect;
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [descriptionLabel setTextAlignment: NSTextAlignmentLeft];
    
    return descriptionLabel;
}

- (UILabel *)createActionButtonLabel {
    BlueShiftInAppLayoutMargin *actionButtonPadding = [self fetchNotificationActionButtonPadding];
    CGFloat rightPadding = (actionButtonPadding && actionButtonPadding.right > 0) ? actionButtonPadding.right : 0.0;
    
    CGFloat yPosition = [self getCenterYPosition: kInAppNotificationSlideBannerActionButtonHeight];
    CGFloat xPosition = slideBannerView.frame.size.width - (kInAppNotificationSlideBannerActionButtonWidth + rightPadding);
    CGRect cgrect = CGRectMake(xPosition, yPosition, kInAppNotificationSlideBannerActionButtonWidth, kInAppNotificationSlideBannerActionButtonHeight);
    
    UILabel *actionButtonlabel = [[UILabel alloc] initWithFrame:cgrect];
    
    CGFloat iconFontSize = 22;
    if (self.notification.contentStyle && self.notification.contentStyle.secondaryIconSize) {
        iconFontSize = self.notification.contentStyle.secondaryIconSize.floatValue > 0
        ? self.notification.contentStyle.secondaryIconSize.floatValue : 22;
    }
    
    [self applyIconToLabelView: actionButtonlabel andFontIconSize:[NSNumber numberWithFloat:iconFontSize]];
    
    [self setLabelText: actionButtonlabel andString: self.notification.notificationContent.secondarIcon labelColor:self.notification.contentStyle.secondaryIconColor backgroundColor:self.notification.contentStyle.secondaryIconBackgroundColor];
    
    CGFloat iconRadius = 0.0;
    if (self.notification.contentStyle && self.notification.contentStyle.secondaryIconBackgroundRadius) {
        iconRadius = self.notification.contentStyle.secondaryIconBackgroundRadius.floatValue;
    }
       
    actionButtonlabel.layer.cornerRadius = iconRadius;
    actionButtonlabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [actionButtonlabel setTextAlignment: NSTextAlignmentCenter];
    
    return actionButtonlabel;
}

- (CGFloat)getCenterYPosition:(CGFloat)height {
    CGFloat yPadding = height / 2.0;
    
    return ((slideBannerView.frame.size.height / 2) - yPadding);
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

- (IBAction)onOkayButtonTapped:(id)sender {
    if (self.notification && self.notification.notificationContent && self.notification.notificationContent.actions &&
        self.notification.notificationContent.actions.count > 0 &&
        self.notification.notificationContent.actions[0]) {
        [self handleActionButtonNavigation: self.notification.notificationContent.actions[0]];
    } else {
        [self closeButtonDidTapped];
    }
}

- (CGRect)positionNotificationView {
    float width = (self.notification.templateStyle && self.notification.templateStyle.width > 0) ? self.notification.templateStyle.width : self.notification.width;
    float height = (self.notification.templateStyle && self.notification.templateStyle.height > 0) ? self.notification.templateStyle.height : [BlueShiftInAppNotificationHelper convertHeightToPercentage :slideBannerView];
    
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
        
        if (width == 100) {
            itemWidth = itemWidth - (leftMargin + rightMargin);
        }
        
        size.width = itemWidth;
        size.height = itemHeight;
    }
    
    CGRect frame = slideBannerView.frame;
    frame.size = size;
    slideBannerView.autoresizingMask = UIViewAutoresizingNone;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    NSString* position = (self.notification.templateStyle && self.notification.templateStyle.position) ? self.notification.templateStyle.position : self.notification.position;
    
    if([position  isEqual: kInAppNotificationModalPositionTopKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = 0.0f + topMargin;
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
    } else if([position  isEqual: kInAppNotificationModalPositionCenterKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = (screenSize.height - size.height) / 2.0f;
    } else if([position  isEqual: kInAppNotificationModalPositionBottomKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = screenSize.height - (size.height + bottomMargin);
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleTopMargin;
    }
    
    frame.origin.x = frame.origin.x < 0.0f ? 0.0f : frame.origin.x;
    frame.origin.y = frame.origin.y < 0.0f ? 0.0f : frame.origin.y;
    slideBannerView.frame = frame;
    _originalCenter = frame.origin.x + frame.size.width / 2.0f;
    
    return frame;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationIconPadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.iconPadding)
       ? self.notification.contentStyle.iconPadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationMessagePadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.messagePadding)
       ? self.notification.contentStyle.messagePadding : NULL;
}

- (BlueShiftInAppLayoutMargin *)fetchNotificationActionButtonPadding {
    return (self.notification && self.notification.contentStyle && self.notification.contentStyle.actionsPadding) ? self.notification.contentStyle.actionsPadding : NULL;
}

@end
