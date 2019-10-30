//
//  BlueShiftNotificationWebViewController.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import <WebKit/WebKit.h>
#import "BlueShiftNotificationWebViewController.h"
#import "BlueShiftNotificationCloseButton.h"
#import "BlueShiftNotificationView.h"
#import "BlueShiftNotificationWindow.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftInAppNotificationDelegate.h"

#define INAPP_CLOSE_BUTTON_WIDTH 40

API_AVAILABLE(ios(8.0))
@interface BlueShiftNotificationWebViewController ()<WKNavigationDelegate, UIGestureRecognizerDelegate> {
    WKWebView *webView;
    BlueShiftNotificationCloseButton *_closeButton;
}

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;
@property(nonatomic, assign) CGFloat initialHorizontalCenter;
@property(nonatomic, assign) CGFloat initialTouchPositionX;
@property(nonatomic, assign) CGFloat originalCenter;
@property id<BlueShiftInAppNotificationDelegate> inAppNotificationDelegate;

@end

@implementation BlueShiftNotificationWebViewController

- (void)loadView {
    if (self.canTouchesPassThroughWindow) {
        [self loadNotificationView];
    } else {
        [super loadView];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBackground];
    [self presentWebViewNotification];
}

- (void)configureBackground {
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)presentWebViewNotification{
    if (@available(iOS 8.0, *)) {
        WKWebView *webView = [self createWebView];
        [self setWebViewDelegate:webView];
        [self addWebViewAsSubView:webView];
        [self loadWebView];
    }
}

- (WKWebView *)createWebView  API_AVAILABLE(ios(8.0)){
    WKWebViewConfiguration *wkConfig = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:wkConfig];
    webView.scrollView.showsHorizontalScrollIndicator = NO;
    webView.scrollView.showsVerticalScrollIndicator = NO;
    webView.scrollView.scrollEnabled = NO;
    webView.backgroundColor = [UIColor whiteColor];
    webView.opaque = NO;
    webView.tag = 188293;
    webView.clipsToBounds = TRUE;
    webView.layer.cornerRadius = 10.0;
    
    return webView;
}

- (void)setWebViewDelegate:(WKWebView *)webView  API_AVAILABLE(ios(8.0)){
    webView.navigationDelegate = self;
}

- (void)addWebViewAsSubView:(WKWebView *)webView  API_AVAILABLE(ios(8.0)){
    [self.view addSubview:webView];
}

- (void)loadFromURL {
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.notification.notificationContent.url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0]];
    webView.navigationDelegate = nil;
}

- (void)loadFromHTML {
    [webView loadHTMLString:[kInAppNotificationModalHTMLHeaderKey stringByAppendingString: self.notification.notificationContent.content] baseURL:nil];
}

- (CGRect)positionWebView{
    float width = (self.notification.templateStyle && self.notification.templateStyle.width > 0) ? self.notification.templateStyle.width : self.notification.width;
    float height = (self.notification.templateStyle && self.notification.templateStyle.height > 0) ? self.notification.templateStyle.height : self.notification.height;
    
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
        // Ignore Constants.INAPP_X_PERCENT
        size.width = width;
        size.height = height;
    } else if([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
        CGFloat itemHeight = (CGFloat) ceil([[UIScreen mainScreen] bounds].size.height * (height / 100.0f));
        CGFloat itemWidth =  (CGFloat) ceil([[UIScreen mainScreen] bounds].size.width * (width / 100.0f));
        
        if (width == 100) {
            itemWidth = itemWidth - (leftMargin + rightMargin);
        }
        
        if (height == 100) {
            itemHeight = itemHeight - (topMargin + bottomMargin);
        }
        
        size.width = itemWidth;
        size.height = itemHeight;
    }else {
        
    }
    
    // prevent webview content insets for Cover
    if (@available(iOS 11.0, *)) {
        if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey] && height == 100.0) {
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    
    CGRect frame = webView.frame;
    frame.size = size;
    webView.autoresizingMask = UIViewAutoresizingNone;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    NSString* position = (self.notification.templateStyle && self.notification.templateStyle.position) ? self.notification.templateStyle.position : self.notification.position;
    
    int extra = (int) (self.notification.showCloseButton ? (INAPP_CLOSE_BUTTON_WIDTH / 2.0f) : 0.0f);
    
    if([position  isEqual: kInAppNotificationModalPositionTopKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = 0.0f + extra + 20.0f;
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
    } else if([position  isEqual:  kInAppNotificationModalPositionCenterKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        double yPosition = (screenSize.height - size.height) / 2.0f;
        if (height == 100) {
            yPosition = yPosition + topMargin;
        }
        frame.origin.y = yPosition;
    } else if([position  isEqual: kInAppNotificationModalPositionBottomKey]) {
        frame.origin.x = (screenSize.width - size.width) / 2.0f;
        frame.origin.y = screenSize.height - size.height;
        webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleTopMargin;
    } else {
        
    }
    
    frame.origin.x = frame.origin.x < 0.0f ? 0.0f : frame.origin.x;
    frame.origin.y = frame.origin.y < 0.0f ? 0.0f : frame.origin.y;
    webView.frame = frame;
    _originalCenter = frame.origin.x + frame.size.width / 2.0f;
    
    return frame;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler API_AVAILABLE(ios(8.0)){
    
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        [self sendActionEventAnalytics: url.absoluteString];
        
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"Opened url");
                }
            }];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)configureWebViewBackground {
    self.view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
}

- (void)createCloseButton:(CGRect) frame {
    if (self.notification.showCloseButton) {
        _closeButton = [BlueShiftNotificationCloseButton new];
        [_closeButton addTarget:self action:@selector(closeButtonDidTapped) forControlEvents:UIControlEventTouchUpInside];
        int extra = (int) (self.notification.showCloseButton ? (INAPP_CLOSE_BUTTON_WIDTH) : 0.0f);
        _closeButton.frame = CGRectMake(frame.origin.x + frame.size.width - extra + 5, frame.origin.y - 5, INAPP_CLOSE_BUTTON_WIDTH, INAPP_CLOSE_BUTTON_WIDTH);
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:_closeButton];
    }
}

- (void)loadWebView {
    if (self.notification.notificationContent.url) {
        [self loadFromURL];
    } else{
        printf("%f WebViewController:: loading html from data \n", [[NSDate date] timeIntervalSince1970]);
        [self loadFromHTML];
    }
    
    CGRect frame = [self positionWebView];
    [self configureWebViewBackground];
    [self createCloseButton:frame];
    if ([self.notification.dimensionType  isEqual: kInAppNotificationModalResolutionPercntageKey]) {
      webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleWidth;
      webView.autoresizingMask = webView.autoresizingMask | UIViewAutoresizingFlexibleHeight;
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

-(void)hideFromWindow:(BOOL)animated {
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    if (!self.notification.notificationContent.content) return;
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}


@end
