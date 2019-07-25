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

@interface BlueShiftNotificationModalViewController ()<UIGestureRecognizerDelegate>{
    UIView *notificationView;
}

@property (strong, nonatomic) IBOutlet BlueShiftNotificationView *notificationModalView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *okButton;
@property (strong, nonatomic) IBOutlet UIImageView *titleBackgroundView;

- (IBAction)onCancelButtonTapped:(id)sender;
- (IBAction)onOkayButtonTapped:(id)sender;

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;

@end

@implementation BlueShiftNotificationModalViewController

- (void)loadView {
    [super loadView];
    notificationView = [self loadNotificationView];
    [self.view insertSubview:notificationView aboveSubview:self.view];
    //self.view.frame = CGRectMake(0, 0, 300, 3000);
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
            
            if (self.notification.dismiss) {
                [self setButton:[self cancelButton] andString:self.notification.dismiss.text
                    textColor:self.notification.dismiss.textColor backgroundColor:self.notification.dismiss.backgroundColor];
            }
            if (self.notification.appOpen) {
                [self setButton:[self okButton] andString:self.notification.appOpen.text
                    textColor:self.notification.appOpen.textColor backgroundColor:self.notification.appOpen.backgroundColor];
            }
            
            if (self.notification.contentStyle
                && self.notification.contentStyle.titleBackgroundColor != (id)[NSNull null] && self.notification.contentStyle.titleBackgroundColor.length > 0) {
                [self loadImageFromURL:[self titleBackgroundView] andImageURL:self.notification.contentStyle.titleBackgroundColor];
            }
            
            if (self.notification.contentStyle.titleSize != (id)[NSNull null] && self.notification.contentStyle.titleSize > 0) {
                    //CGFloat titleFontSize = [self.notification.contentStyle.titleSize doubleValue];
                    //[[self titleLabel] setFont:[UIFont fontWithName:@"System-Heavy" size:titleFontSize]];
            }
            
            if (self.notification.contentStyle.messageSize != (id)[NSNull null] && self.notification.contentStyle.messageSize > 0) {
                    //CGFloat messageFontSize = [self.notification.contentStyle.messageSize doubleValue];
                    //[[self descriptionLabel] setFont:[UIFont fontWithName:@"System" size:messageFontSize]];
            }
        }
    }
    
    CGRect frame = [self positionNotificationView:notificationView];
    notificationView.frame = frame;
    if ([self.notification.dimensionType  isEqual: @"percentage"]) {
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    }
}

- (IBAction)onCancelButtonTapped:(id)sender {
    [self closeButtonDidTapped];
}

- (IBAction)onOkayButtonTapped:(id)sender {
    [self closeButtonDidTapped];
}

- (void)showFromWindow:(BOOL)animated {
    if (!self.notification) return;
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
