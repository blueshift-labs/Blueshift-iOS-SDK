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
#import "../../../BlueShiftInAppNotificationDelegate.h"

@interface BlueShiftNotificationModalViewController ()<UIGestureRecognizerDelegate>{
    UIView *notificationView;
}

@property id<BlueShiftInAppNotificationDelegate> inAppNotificationDelegate;
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
    
    notificationView = [[UIView alloc] initWithFrame:CGRectZero];
    notificationView.layer.cornerRadius = 10.0;
    notificationView.clipsToBounds = YES;
    [self.view insertSubview:notificationView aboveSubview:self.view];
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

- (void)createNotificationView {
    CGRect frame = [self positionNotificationView: notificationView];
    notificationView.frame = frame;
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
        notificationView.autoresizingMask = notificationView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    }
}

- (void)onOkayButtonTapped:(UIButton *)customButton{
    [self closeButtonDidTapped];

    NSInteger position = customButton.tag;
    if (self.delegate && [self.delegate respondsToSelector:@selector(inAppActionDidTapped: fromViewController:)] && self.notification && self.notification.notificationContent && self.notification.notificationContent.actions && self.notification.notificationContent.actions[position]) {
        NSDictionary *buttonPayload = [[BlueShiftInAppNotificationButton alloc] convertObjectToDictionary: self.notification.notificationContent.actions[position]];
        [self.delegate inAppActionDidTapped : buttonPayload fromViewController:self];
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
            imageView = [self createImageView];
            yPadding = imageView.layer.frame.size.height + (2 * kInAppNotificationModalYPadding);
            [notificationView addSubview:imageView];
        }
        
        UILabel *iconLabel;
        if (self.notification.notificationContent.icon) {
            yPadding = yPadding > 0.0 ? yPadding : (2 * kInAppNotificationModalYPadding);
            iconLabel = [self createIconLabel: yPadding];
            yPadding = (2 * kInAppNotificationModalYPadding) + yPadding;
            [notificationView addSubview: iconLabel];
        }
        
        UILabel *titleLabel;
        if (self.notification.notificationContent.title) {
            yPadding = yPadding + iconLabel.layer.frame.size.height;
            titleLabel = [self createTitleLabel: yPadding];
            [notificationView addSubview: titleLabel];
        }
        
        UILabel *subTitleLabel;
        if (self.notification.notificationContent.subTitle) {
            yPadding = yPadding + iconLabel.layer.frame.size.height;
            subTitleLabel = [self createSubTitleLabel: yPadding];
            [notificationView addSubview: subTitleLabel];
        }
        
        UILabel *descriptionLabel;
        if (self.notification.notificationContent.message) {
            yPadding = titleLabel.layer.frame.size.height > 0
                ? (yPadding + titleLabel.layer.frame.size.height + 2 * kInAppNotificationModalYPadding)
                : (2 * kInAppNotificationModalYPadding);
            descriptionLabel = [self createDescriptionLabel:yPadding];
            [notificationView addSubview:descriptionLabel];
        }
        
        if (self.notification.contentStyle) {
            notificationView.backgroundColor = self.notification.contentStyle.messageBackgroundColor ? [self colorWithHexString: self.notification.contentStyle.messageBackgroundColor]
                : UIColor.whiteColor;
        }
        
        [self initializeButtonView];
    }
}

- (UIImageView *)createImageView {
    CGFloat xPosition = 0.0;
    CGFloat yPosition = 0.0;
    CGFloat imageViewWidth = notificationView.frame.size.width;
    CGFloat imageViewHeight = notificationView.frame.size.width / 2;
    CGRect cgRect = CGRectMake(xPosition, yPosition, imageViewWidth, imageViewHeight);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame: cgRect];
    
    if (self.notification.notificationContent.banner) {
     [self loadImageFromURL: imageView andImageURL: self.notification.notificationContent.banner];
    }
    
    //imageView.frame = cgRect;
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    
    return imageView;
}

- (UILabel *)createIconLabel:(CGFloat)yPosition {
    CGFloat xPosition = [self getCenterXPosition:notificationView childWidth: kInAppNotificationModalIconWidth];
    CGRect cgRect = CGRectMake(xPosition, yPosition, kInAppNotificationModalIconWidth, kInAppNotificationModalIconHeight);
        
    UILabel *label = [[UILabel alloc] initWithFrame:cgRect];
    [self applyIconToLabelView: label];
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [label setTextAlignment: NSTextAlignmentCenter];
        
    return label;
}

- (UILabel *)createTitleLabel:(CGFloat)yPosition {
    CGFloat titleLabelWidth = notificationView.frame.size.width;
    CGFloat titleLabelHeight = kInAppNotificationModalTitleHeight;
    CGRect cgRect = CGRectMake(1.0, yPosition, titleLabelWidth, titleLabelHeight);
    
    UILabel *titlelabel = [[UILabel alloc] initWithFrame: cgRect];
    CGFloat fontSize = 18.0;
    
    if (self.notification.contentStyle) {
        [self setLabelText: titlelabel andString:self.notification.notificationContent.title labelColor:self.notification.contentStyle.titleColor backgroundColor:self.notification.contentStyle.titleBackgroundColor];
        fontSize = self.notification.contentStyle.titleSize.floatValue > 0
        ? self.notification.contentStyle.titleSize.floatValue : 18.0;
    }

    [titlelabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size: fontSize]];
    titlelabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [titlelabel setTextAlignment: NSTextAlignmentCenter];
    
    return titlelabel;
}

- (UILabel *)createSubTitleLabel:(CGFloat)yPosition {
    CGFloat subTitleLabelWidth = notificationView.frame.size.width;
    
    UILabel *subTitleLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    [subTitleLabel setNumberOfLines: 0];
    [subTitleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:16]];
    
    if (self.notification.contentStyle) {
        [self setLabelText: subTitleLabel andString:self.notification.notificationContent.subTitle labelColor:self.notification.contentStyle.titleColor backgroundColor:self.notification.contentStyle.titleBackgroundColor];
    }
    
    CGFloat descriptionLabelHeight = [self getLabelHeight: subTitleLabel labelWidth: subTitleLabelWidth] + 10.0;
    CGRect cgRect = CGRectMake(1.0, yPosition, subTitleLabelWidth, descriptionLabelHeight);
    
    subTitleLabel.frame = cgRect;
    subTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [subTitleLabel setTextAlignment: NSTextAlignmentCenter];
    
    return subTitleLabel;
}

- (UILabel *)createDescriptionLabel:(CGFloat)yPosition {
    CGFloat descriptionLabelWidth = notificationView.frame.size.width - 20;
    CGFloat xPosition = [self getCenterXPosition: notificationView childWidth: descriptionLabelWidth];
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    [descriptionLabel setNumberOfLines: 0];
     CGFloat fontSize = 18.0;
    
    if (self.notification.contentStyle) {
        [self setLabelText: descriptionLabel andString:self.notification.notificationContent.message labelColor:self.notification.contentStyle.messageColor backgroundColor:self.notification.contentStyle.messageBackgroundColor];
        fontSize = self.notification.contentStyle.messageSize.floatValue > 0
        ? self.notification.contentStyle.messageSize.floatValue : 18.0;
    }
    
    [descriptionLabel setFont:[UIFont fontWithName:@"Helvetica" size: fontSize]];
    CGFloat descriptionLabelHeight = [self getLabelHeight: descriptionLabel labelWidth: descriptionLabelWidth];
    CGRect cgRect = CGRectMake(xPosition, yPosition, descriptionLabelWidth, descriptionLabelHeight);
    
    descriptionLabel.frame = cgRect;
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [descriptionLabel setTextAlignment: NSTextAlignmentCenter];
    
    return descriptionLabel;
}

- (void)initializeButtonView {
    if (self.notification && self.notification.notificationContent && self.notification.notificationContent.actions) {
        NSUInteger numberOfButtons = [self.notification.notificationContent.actions count];
        CGFloat xPadding = numberOfButtons == 1 ? 0.0 : 5.0;
        CGFloat yPadding = numberOfButtons == 1 ? 0.0 : 5.0;
    
        CGFloat buttonHeight = 40.0;
        CGFloat buttonWidth = [self getActionButtonWidth] ;
        
        CGFloat xPosition = numberOfButtons == 1 ? 0.0 :[self getActionButtonXPosition: notificationView childWidth: buttonWidth];
        CGFloat yPosition = notificationView.frame.size.height - buttonHeight - yPadding;
        
        for (int i = 0; i< [self.notification.notificationContent.actions count]; i++) {
            CGRect cgRect = CGRectMake(xPosition, yPosition , buttonWidth, buttonHeight);
            [self createActionButton: self.notification.notificationContent.actions[i] positionButton: cgRect objectPosition: &i];
            
             if (self.notification.contentStyle && self.notification.contentStyle.actionsOrientation .intValue > 0) {
                 yPosition = yPosition - buttonHeight - (2 * yPadding);
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
    button.layer.cornerRadius = [self.notification.notificationContent.actions count] == 1 ? 0.0 : 10.0;
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

- (CGFloat)getLabelHeight:(UILabel*)label labelWidth:(CGFloat)width {
    CGSize constraint = CGSizeMake(width, CGFLOAT_MAX);
    CGSize size;
    [label setNumberOfLines: 0];
    
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [label.text boundingRectWithSize:constraint
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName:label.font}
                                                  context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    
    return size.height;
}

- (CGFloat)getActionButtonWidth{
    NSUInteger numberOfButtons = [self.notification.notificationContent.actions count];
    CGFloat xPadding = numberOfButtons == 1 ? 0.0 : 5.0;
    
    return (self.notification.contentStyle && self.notification.contentStyle.actionsOrientation.intValue > 0)
    ? (notificationView.frame.size.width - ((numberOfButtons + 1) * xPadding))
    : (notificationView.frame.size.width - ((numberOfButtons + 1) * xPadding))/numberOfButtons;
}

- (CGFloat)getActionButtonXPosition:(UIView *)parentView childWidth:(CGFloat)width {
    return (self.notification.contentStyle && self.notification.contentStyle.actionsOrientation.intValue > 0)
    ? [self getCenterXPosition: parentView childWidth: width]
    : 5.0;
}

@end
