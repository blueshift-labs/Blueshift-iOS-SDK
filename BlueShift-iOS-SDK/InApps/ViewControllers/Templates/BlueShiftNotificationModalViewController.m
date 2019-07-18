//
//  BlueShiftPromoNotificationViewController.m
//  BlueShift-iOS-SDK-BlueShiftBundle
//
//  Created by Noufal Subair on 16/07/19.
//

#import "BlueShiftNotificationModalViewController.h"
#import "../BlueShiftNotificationView.h"
#import "../BlueShiftNotificationWindow.h"

@interface BlueShiftNotificationModalViewController ()<UIGestureRecognizerDelegate>{
    UIView *notificationView;
}

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *okButton;

- (IBAction)onCancelButtonTapped:(id)sender;
- (IBAction)onOkayButtonTapped:(id)sender;

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;
@property(nonatomic, assign) CGFloat initialHorizontalCenter;
@property(nonatomic, assign) CGFloat initialTouchPositionX;
@property(nonatomic, assign) CGFloat originalCenter;

@end

@implementation BlueShiftNotificationModalViewController

- (void)loadView {
    [super loadView];
    notificationView= [[[NSBundle mainBundle] loadNibNamed:@"BlueshiftNotificationModal" owner:self options:nil] objectAtIndex:0];
    [self.view insertSubview:notificationView aboveSubview:self.view];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadNotification];
}

- (void)loadNotification {
    if (self.notification) {
        [self titleLabel].text = [self notification].title;
        [self subTitleLabel].text = [self notification].subTitle;
        [self descriptionLabel].text =[self notification].descriptionText;
    }
    
    CGRect frame = [self positionWebView];
    notificationView.frame = frame;
    if ([self.notification.dimensionType  isEqual: @"percentage"]) {
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    }
}

- (void)configureBackground {
    self.view.backgroundColor = [UIColor clearColor];
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

- (CGRect)positionWebView {
    CGSize size = CGSizeZero;
    if ([self.notification.dimensionType  isEqual: @"points"]) {
        // Ignore Constants.INAPP_X_PERCENT
        size.width = self.notification.width;
        size.height = self.notification.height;
    } else if([self.notification.dimensionType  isEqual: @"percentage"]) {
        size.width = (CGFloat) ceil([[UIScreen mainScreen] bounds].size.width * (self.notification.width / 100.0f));
        size.height = (CGFloat) ceil([[UIScreen mainScreen] bounds].size.height * (self.notification.height / 100.0f));
    }else {
        
    }
    
    CGRect frame = notificationView.frame;
    frame.size = size;
    notificationView.autoresizingMask = UIViewAutoresizingNone;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    NSString* position = self.notification.position;
    
    if([position  isEqual: INAPP_POSITION_TOP]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = 0.0f + 20.0f;
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
    } else if([position  isEqual: INAPP_POSITION_CENTER]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = (screenSize.height - size.height) / 2.0f;
    } else if([position  isEqual: INAPP_POSITION_BOTTOM]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = screenSize.height - size.height;
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleTopMargin;
    } else {
        
    }
    
    frame.origin.x = frame.origin.x < 0.0f ? 0.0f : frame.origin.x;
    frame.origin.y = frame.origin.y < 0.0f ? 0.0f : frame.origin.y;
    notificationView.frame = frame;
    _originalCenter = frame.origin.x + frame.size.width / 2.0f;
    
    return frame;
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
