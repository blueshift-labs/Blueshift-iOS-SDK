//
//  BlueShiftNotificationSlideBannerViewController.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 23/07/19.
//

#import "BlueShiftNotificationSlideBannerViewController.h"
#import "../BlueShiftNotificationView.h"
#import "../BlueShiftNotificationWindow.h"

@interface BlueShiftNotificationSlideBannerViewController ()<UIGestureRecognizerDelegate> {
    UIView *slideBannerView;
}

@property (strong, nonatomic) IBOutlet UIView *slideBannerPopupView;
@property (strong, nonatomic) IBOutlet UILabel *iconLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *okayButton;

- (IBAction)onOkayButtonTapped:(id)sender;

@end

@implementation BlueShiftNotificationSlideBannerViewController

- (void)loadView {
    [super loadView];
    slideBannerView = [self loadNotificationView];
    [self.view insertSubview:slideBannerView aboveSubview:self.view];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTouchesPassThroughWindow: TRUE];
    [self configureBackground];
    [self loadNotification];
}

- (void)loadNotification{
    if (self.notification) {
        if (self.notification.notificationContent && self.notification.contentStyle) {
                [self setLabelText:[self descriptionLabel] andString:self.notification.notificationContent.message labelColor:self.notification.contentStyle.messageColor backgroundColor:self.notification.contentStyle.messageBackgroundColor];
            
//            [self setLabelText:[self iconLabel] andString:self.notification.notificationContent.icon labelColor:self.notification.contentStyle.iconColor backgroundColor:self.notification.contentStyle.iconBackgroundColor];
//
//                if (self.notification.contentStyle.iconSize != (id)[NSNull null] && self.notification.contentStyle.iconSize > 0) {
//                    CGFloat iconFontSize = [self.notification.contentStyle.iconSize doubleValue];
//                    [[self iconLabel] setFont:[UIFont fontWithName:@"../../Fonts/Font -Awesome-Solid.otf" size: iconFontSize]];
//                }
//
//                if (self.notification.contentStyle.iconBackgroundRadius != (id)[NSNull null] && self.notification.contentStyle.iconBackgroundRadius > 0) {
//                    CGFloat iconRadius = [self.notification.contentStyle.iconBackgroundRadius doubleValue];
//                    [self iconLabel].layer.cornerRadius = iconRadius;
//                }
            
                [self applyIconToLabelView:[self iconLabel]];
            
                if (self.notification.templateStyle && self.notification.templateStyle.backgroundColor) {
                        [self slideBannerPopupView].backgroundColor = [self colorWithHexString: self.notification.templateStyle.backgroundColor];
                }
            }
    }
    
    CGRect frame = [self positionNotificationView: [self slideBannerPopupView]];
    slideBannerView.frame = frame;
    if ([self.notification.dimensionType  isEqual: @"percentage"]) 
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
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
        [UIView animateWithDuration:0.7f animations:^{
            self.window.alpha = 2.0;
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
        [UIView animateWithDuration:0.7f animations:^{
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

- (IBAction)onOkayButtonTapped:(id)sender {
    [self closeButtonDidTapped];
}
@end
