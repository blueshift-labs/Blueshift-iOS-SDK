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

@property (strong, nonatomic) IBOutlet BlueShiftNotificationView *slideBannerPopUpView;
@property (strong, nonatomic) IBOutlet UILabel *iconLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation BlueShiftNotificationSlideBannerViewController

- (void)loadView {
    [super loadView];
    slideBannerView = [self loadNotificationView];
    [self.view insertSubview:slideBannerView aboveSubview:self.view];
    //self.view.frame = CGRectMake(0, 0, 300, 3000);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBackground];
    [self loadNotification];
}

- (void)loadNotification{
    if (self.notification) {
        [self setLabelText:[self descriptionLabel] andString:self.notification.notificationContent.message labelColor:self.notification.contentStyle.messageColor backgroundColor:self.notification.contentStyle.messageBackgroundColor];
    }
    
    CGRect frame = [self positionNotificationView:slideBannerView];
    slideBannerView.frame = frame;
    if ([self.notification.dimensionType  isEqual: @"percentage"]) {
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        slideBannerView.autoresizingMask = slideBannerView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    }
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

@end
