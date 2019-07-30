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
@property (strong, nonatomic) IBOutlet UIView *notificationModalView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *okButton;
@property (strong, nonatomic) IBOutlet UILabel *iconLabel;

- (IBAction)onCancelButtonTapped:(id)sender;
- (IBAction)onOkayButtonTapped:(id)sender;

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;

@end

@implementation BlueShiftNotificationModalViewController

- (void)loadView {
    if (self.notification && self.notification.templateStyle && self.notification.templateStyle.enableBackgroundAction == TRUE) {
        [self loadNotificationView];
    } else {
        [super loadView];
    }
    
    notificationView = [self fetchNotificationView];
    [self.view insertSubview:notificationView aboveSubview:self.view];
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
            
            [self initializeButtonView];
            [self applyIconToLabelView: [self iconLabel]];
        }
    }
    
    CGRect frame = [self positionNotificationView: [self notificationModalView]];
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

- (void)initializeButtonView{
    if (self.notification) {
        if (self.notification.appOpen && self.notification.dismiss) {
            [self setButton:[self cancelButton] andString:self.notification.dismiss.text
                  textColor:self.notification.dismiss.textColor backgroundColor:self.notification.dismiss.backgroundColor];
            
            [self setButton:[self okButton] andString:self.notification.appOpen.text
                  textColor:self.notification.appOpen.textColor backgroundColor:self.notification.appOpen.backgroundColor];
        } else if (self.notification.share && self.notification.dismiss){
            [self setButton:[self cancelButton] andString:self.notification.dismiss.text
                  textColor:self.notification.dismiss.textColor backgroundColor:self.notification.dismiss.backgroundColor];
            
            [self setButton:[self okButton] andString:self.notification.share.text
                  textColor:self.notification.share.textColor backgroundColor:self.notification.share.backgroundColor];
        } else if (self.notification.share && self.notification.appOpen){
            [self setButton:[self cancelButton] andString:self.notification.appOpen.text
                  textColor:self.notification.appOpen.textColor backgroundColor:self.notification.appOpen.backgroundColor];
            
            [self setButton:[self okButton] andString:self.notification.share.text
                  textColor:self.notification.share.textColor backgroundColor:self.notification.share.backgroundColor];
        } else {
            [self setButton:[self cancelButton] andString:self.notification.dismiss.text
                  textColor:self.notification.dismiss.textColor backgroundColor:self.notification.dismiss.backgroundColor];
        }
    }
}

@end
