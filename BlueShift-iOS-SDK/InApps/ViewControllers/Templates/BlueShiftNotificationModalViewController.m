//
//  BlueShiftPromoNotificationViewController.m
//  BlueShift-iOS-SDK-BlueShiftBundle
//
//  Created by Noufal Subair on 16/07/19.
//

#import "BlueShiftNotificationModalViewController.h"
#import "../BlueShiftNotificationView.h"
#import "../BlueShiftNotificationWindow.h"
#import "../../Models/BlueShiftInAppNotificationHelper.h"
#import "../../BlueShiftInAppNotificationConstant.h"

@interface BlueShiftNotificationModalViewController ()<UIGestureRecognizerDelegate>{
    UIView *notificationView;
}
@property (strong, nonatomic) IBOutlet UIView *notificationModalView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel *iconLabel;

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;

- (void)onOkayButtonTapped:(UIButton *)customButton;

@end

@implementation BlueShiftNotificationModalViewController

- (void)loadView {
    if (self.canTouchesPassThroughWindow) {
        [self loadNotificationView];
    } else {
        [super loadView];
    }
    
    notificationView = [self fetchNotificationView];
    [self.view insertSubview:notificationView aboveSubview:self.view];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self initializeButtonView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBackground];
    [self loadNotification];
}

- (void)loadNotification {
    if (self.notification) {
        if (self.notification.notificationContent && self.notification.contentStyle) {
            [self setLabelText:[self titleLabel] andString:self.notification.notificationContent.title labelColor:self.notification.contentStyle.titleColor backgroundColor:self.notification.contentStyle.titleBackgroundColor];
            
            [self setLabelText:[self descriptionLabel] andString:self.notification.notificationContent.message labelColor:self.notification.contentStyle.messageColor backgroundColor:self.notification.contentStyle.messageBackgroundColor];
            
            if (self.notification.contentStyle && self.notification.contentStyle.messageBackgroundColor) {
                [self notificationModalView].backgroundColor = [self colorWithHexString: self.notification.contentStyle.messageBackgroundColor];
            }
            
            if (self.notification.contentStyle.iconBackgroundRadius != (id)[NSNull null] && self.notification.contentStyle.iconBackgroundRadius > 0) {
                CGFloat iconRadius = [self.notification.contentStyle.iconBackgroundRadius doubleValue];
                [self iconLabel].layer.cornerRadius = iconRadius;
            }
        
            [self applyIconToLabelView: [self iconLabel]];
        }
    }
    
    CGRect frame = [self positionNotificationView: [self notificationModalView]];
    notificationView.frame = frame;
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    }
}


- (void)onOkayButtonTapped:(UIButton *)customButton{
    [self closeButtonDidTapped];
    if (self.delegate && [self.delegate respondsToSelector:@selector(inAppActionDidTapped: fromViewController:)] && self.notification && self.notification.actions && self.notification.actions[customButton.tag]) {
        NSInteger position = [customButton tag];
        [self.delegate inAppActionDidTapped : self.notification.actions[position].content fromViewController:self];
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
            [self.delegate inAppDidShow:self.notification fromViewController:self];
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
            [self.delegate inAppDidDismiss:self.notification fromViewController:self];
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

- (void)initializeButtonView{
    if (self.notification && self.notification.actions) {
        CGFloat xPadding = [self.notification.actions count] == 1 ? 0.0 : 5.0;
        CGFloat yPadding = [self.notification.actions count] == 1 ? 0.0 : 5.0;
        
        NSUInteger numberOfButtons = [self.notification.actions count];
        CGFloat buttonHeight = 40.0;
        CGFloat buttonWidth = (self.notificationModalView.frame.size.width - ((numberOfButtons + 1) * xPadding))/numberOfButtons;
        
        CGFloat xPosition = [self.notification.actions count] == 1 ? 0.0 : xPadding;
        CGFloat yPosition = self.notificationModalView.frame.size.height - buttonHeight - yPadding;
        
        for (int i = 0; i< [self.notification.actions count]; i++) {
            CGRect cgRect = CGRectMake(xPosition, yPosition , buttonWidth, buttonHeight);
            [self createActionButton: self.notification.actions[i] positionButton: cgRect objectPosition: &i];
            xPosition =  xPosition + buttonWidth + xPadding;
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
    button.layer.cornerRadius = [self.notification.actions count] == 1 ? 0.0 : 10.0;
    button.frame = positionValue;
    button.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.notificationModalView addSubview:button];
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

@end
