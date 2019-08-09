//
//  BlueShiftNotificationSlideBannerViewController.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 23/07/19.
//

#import "BlueShiftNotificationSlideBannerViewController.h"
#import "../BlueShiftNotificationView.h"
#import "../BlueShiftNotificationWindow.h"
#import "../../BlueShiftInAppNotificationConstant.h"

@interface BlueShiftNotificationSlideBannerViewController ()<UIGestureRecognizerDelegate> {
    UIView *slideBannerView;
}

@property (strong, nonatomic) IBOutlet UIView *slideBannerPopupView;
@property (strong, nonatomic) IBOutlet UILabel *iconLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *okayButton;
@property id<BlueShiftInAppNotificationDelegate> inAppNotificationDelegate;

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
    [self presentAnimationView];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self initializeNotificationView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBackground];
    [self createNotificationView];
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

- (void)createNotificationView{
    CGRect frame = [self positionNotificationView: slideBannerView];
    slideBannerView.frame = frame;
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) 
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
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
        CGFloat xPadding = 2 * kInAppNotificationModalYPadding;
        
        UILabel *iconLabel;
        if (self.notification.notificationContent.icon) {
            iconLabel = [self createIconLabel: xPadding];
            xPadding = (2 * xPadding) + iconLabel.layer.frame.size.width;
            [slideBannerView addSubview: iconLabel];
        }
        
        UIButton *actionButton;
        if (self.notification.notificationContent.actions && self.notification.notificationContent.actions[0]) {
            actionButton = [self createActionButton];
            [slideBannerView addSubview: actionButton];
        }
        
        UILabel *descriptionLabel;
        if (self.notification.notificationContent.message) {
            CGFloat descriptionLabelWidth = slideBannerView.frame.size.width - (xPadding + actionButton.frame.size.width + kInAppNotificationModalYPadding);
            descriptionLabel = [self createDescriptionLabel:xPadding andLabelWidth:descriptionLabelWidth];
            [slideBannerView addSubview: descriptionLabel];
        }
        
        if (self.notification.templateStyle) {
            slideBannerView.backgroundColor = self.notification.templateStyle.backgroundColor ? [self colorWithHexString: self.notification.templateStyle.backgroundColor]
            : UIColor.blueColor;
        }
    }
}

- (UILabel *)createIconLabel:(CGFloat)xPosition {
    CGFloat yPosition = [self getCenterYPosition: kInAppNotificationModalIconHeight];
    CGRect cgRect = CGRectMake(xPosition, yPosition, kInAppNotificationModalIconWidth, kInAppNotificationModalIconHeight);
    
    UILabel *label = [[UILabel alloc] initWithFrame:cgRect];
    [self applyIconToLabelView: label];
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

- (UIButton *)createActionButton {
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionButton addTarget:self
               action:@selector(onOkayButtonTapped:)
     forControlEvents:UIControlEventTouchUpInside];
    [actionButton setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    
    CGFloat yPosition = [self getCenterYPosition: kInAppNotificationSlideBannerActionButtonHeight];
    CGFloat xPosition = slideBannerView.frame.size.width - kInAppNotificationSlideBannerActionButtonWidth;
    CGRect cgrect = CGRectMake(xPosition, yPosition, kInAppNotificationSlideBannerActionButtonWidth, kInAppNotificationSlideBannerActionButtonHeight);
    actionButton.frame = cgrect;
    actionButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    return actionButton;
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
    if (self.notification && self.notification.notificationContent && self.notification.notificationContent.actions && self.notification.notificationContent.actions[0]) {
        [self handleActionButtonNavigation: self.notification.notificationContent.actions[0]];
    }
}
@end
