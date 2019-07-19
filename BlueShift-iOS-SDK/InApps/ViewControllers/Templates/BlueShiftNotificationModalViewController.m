//
//  BlueShiftPromoNotificationViewController.m
//  BlueShift-iOS-SDK-BlueShiftBundle
//
//  Created by Noufal Subair on 16/07/19.
//

#import "BlueShiftNotificationModalViewController.h"
#import "../BlueShiftNotificationView.h"
#import "../BlueShiftNotificationWindow.h"
#import "../BlueshiftUIColor.h"

@interface BlueShiftNotificationModalViewController ()<UIGestureRecognizerDelegate>{
    UIView *notificationView;
}

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *okButton;

- (IBAction)onCancelButtonTapped:(id)sender;
- (IBAction)onOkayButtonTapped:(id)sender;

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;

@end

@implementation BlueShiftNotificationModalViewController

- (void)loadView {
    [super loadView];
    notificationView= [[[NSBundle mainBundle] loadNibNamed:@"BlueshiftNotificationModal" owner:self options:nil] objectAtIndex:0];
    [self.view insertSubview:notificationView aboveSubview:self.view];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBackground];
    [self loadNotification];
}

- (void)loadNotification {
    if (self.notification) {
        if (self.notification.content && self.notification.contentStyle) {
            [self setLabelText:[self titleLabel] andString:self.notification.content.title labelColor:self.notification.contentStyle.titleColor backgroundColor:self.notification.contentStyle.titleBackgroundColor];
            
            [self setLabelText:[self descriptionLabel] andString:self.notification.content.message labelColor:self.notification.contentStyle.messageColor backgroundColor:self.notification.contentStyle.messageBackgroundColor];
            
            if (self.notification.dismiss) {
                [self setButton:[self cancelButton] andString:self.notification.dismiss.title
                    textColor:self.notification.dismiss.textColor backgroundColor:self.notification.dismiss.backgroundColor];
            }
            if (self.notification.appOpen) {
                [self setButton:[self okButton] andString:self.notification.appOpen.title
                    textColor:self.notification.appOpen.textColor backgroundColor:self.notification.appOpen.backgroundColor];
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

- (void)setLabelText:(UILabel *)label andString:(NSString *)value
          labelColor:(NSString *)labelColorCode
     backgroundColor:(NSString *)backgroundColorCode{
    if (value != (id)[NSNull null] || value.length > 0 ) {
        label.hidden = NO;
        label.text = value;
        label.textColor = [self colorWithHexString:labelColorCode];
        label.backgroundColor = [self colorWithHexString:backgroundColorCode];
    }else {
        label.hidden = YES;
    }
}

- (void)setButton:(UIButton *)button andString:(NSString *)value
        textColor:(NSString *)textColorCode
        backgroundColor:(NSString *)backgroundColorCode {
     if (value != (id)[NSNull null] || value.length > 0 ) {
         [button setTitle : value forState:UIControlStateNormal];
         [button setTitleColor:[self colorWithHexString:textColorCode] forState:UIControlStateNormal];
         [button setBackgroundColor:[self colorWithHexString:backgroundColorCode]];
     }
}

@end
