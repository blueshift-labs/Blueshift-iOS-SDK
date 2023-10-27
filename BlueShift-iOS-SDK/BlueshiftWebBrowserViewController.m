//
//  BlueshiftWebBrowserViewController.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 28/08/23.
//
#import <WebKit/WebKit.h>

#import "BlueshiftWebBrowserViewController.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

@interface BlueshiftWebBrowserViewController ()<WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property UIBarButtonItem *reloadButton;
@property UIBarButtonItem *openInBrowserButton;
@property NSString* registerForInAppScreenName;
@property UIColor* tintColor;
@property UIColor* titleColor;
@property UIColor* navBarColor;
@property UIColor* progressViewColor;
@end

@implementation BlueshiftWebBrowserViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _showOpenInBrowserButton = YES;
        _titleColor = UIColor.grayColor;
        BlueShiftConfig *config = BlueShift.sharedInstance.config;
        if (config.blueshiftWebViewBrowserDelegate) {
            if ([config.blueshiftWebViewBrowserDelegate respondsToSelector:(@selector(blueshiftWebViewBrowserTintColor))]) {
                _tintColor = config.blueshiftWebViewBrowserDelegate.blueshiftWebViewBrowserTintColor;
            }
            if ([config.blueshiftWebViewBrowserDelegate respondsToSelector:(@selector(blueshiftWebViewBrowserTitleColor))]) {
                _titleColor = config.blueshiftWebViewBrowserDelegate.blueshiftWebViewBrowserTitleColor;
            }
            if ([config.blueshiftWebViewBrowserDelegate respondsToSelector:(@selector(blueshiftWebViewBrowserNavBarColor))]) {
                _navBarColor = config.blueshiftWebViewBrowserDelegate.blueshiftWebViewBrowserNavBarColor;
            }
            if ([config.blueshiftWebViewBrowserDelegate respondsToSelector:(@selector(blueshiftWebViewBrowserProgressViewColor))]) {
                _progressViewColor = config.blueshiftWebViewBrowserDelegate.blueshiftWebViewBrowserProgressViewColor;
            }
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavigationButtons];
    [self setupWebView];
    [self setupProgressView];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:_url];
    [_webView loadRequest:request];
}

- (void)doneButtonTapped {
    [self hideFromWindow:YES];
}

- (void)reloadButtonTapped {
    [_webView reload];
}

- (void)setupNavigationButtons {
    NSString *doneText = NSLocalizedString(kBSDoneButtonLocalizedKey, @"") ;
    doneText = [doneText isEqualToString: kBSDoneButtonLocalizedKey] ? @"Done" : doneText;
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:doneText style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonTapped)];

    _reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadButtonTapped)];
    if (@available(iOS 13.0, *)) {
        _openInBrowserButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"safari"] style:UIBarButtonItemStylePlain target:self action:@selector(openInExternalBrowser)];
    } else {
        _openInBrowserButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openInExternalBrowser)];
    }
    
    if (_tintColor) {
        doneButton.tintColor = _tintColor;
        _openInBrowserButton.tintColor = _tintColor;
        _reloadButton.tintColor = _tintColor;
    }
    self.navigationItem.leftBarButtonItem = doneButton;
    if (_showOpenInBrowserButton) {
        self.navigationItem.rightBarButtonItems = @[_openInBrowserButton, _reloadButton];
    } else {
        self.navigationItem.rightBarButtonItem = _reloadButton;
    }
    if (@available(iOS 15, *)){
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        if (_navBarColor) {
            [appearance setBackgroundColor:_navBarColor];
        }
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName : _titleColor};
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        NSDictionary *titleTextAttributes = @{
            NSForegroundColorAttributeName: _titleColor
        };
        if (_navBarColor) {
            [self.navigationController.navigationBar setBarTintColor:_navBarColor];
        }
        [self.navigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
        [self.navigationController.navigationBar setTranslucent:NO];
        
    }
}

- (void)setupWebView {
    WKWebViewConfiguration *wkConfig = [[WKWebViewConfiguration alloc] init];
    wkConfig.allowsInlineMediaPlayback = YES;
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:wkConfig];
    _webView.navigationDelegate = self;
    _webView.allowsBackForwardNavigationGestures = true;
    [self.view addSubview:_webView];
    self.view = self.webView;
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setupProgressView {
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    if (_progressViewColor) {
        self.progressView.tintColor = _progressViewColor;
    }
    [self.view addSubview:self.progressView];
    [self activateConstraints];
}

- (void)activateConstraints {
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.topLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressView]|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:@{@"progressView" : self.progressView}]];
}

- (void)openInExternalBrowser {
    if (@available(iOS 10.0, *)) {
        NSURL *urlToOpen = _webView.URL;
        [UIApplication.sharedApplication openURL:urlToOpen options:@{} completionHandler:^(BOOL success) {
            if (success) {
                [BlueshiftLog logInfo:@"Opened url successfully in external browser." withDetails:urlToOpen methodName:nil];
            } else {
                [BlueshiftLog logInfo:@"Failed to open url in external browser." withDetails:urlToOpen methodName:nil];
            }
        }];
    } else {
        [UIApplication.sharedApplication openURL:_webView.URL];
    }
}

- (void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

-(void)hideFromWindow:(BOOL)animated {
    void (^completionBlock)(void) = ^ {
        [self.window setHidden:YES];
        [self.window removeFromSuperview];
        self.window = nil;
        [self resumeInAppNotificationDisplay];
    };
    
    [self dismissViewControllerAnimated:animated completion:^{
        if (animated) {
            [UIView animateWithDuration:0.25 animations:^{
                self.window.alpha = 0;
            } completion:^(BOOL finished) {
                completionBlock();
            }];
        } else {
            completionBlock();
        }
    }];
}


-(void)show:(BOOL)animated {
    [self pauseInAppNotificationDisplay];
    [self showFromWindow:animated];
}

- (void)showFromWindow:(BOOL)animated {
    [self createWindow];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
    self.window.rootViewController = navController;
    [self.window setHidden:NO];
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 1.0;
        }];
    } else {
        self.window.alpha = 1.0;
    }
}

- (void)pauseInAppNotificationDisplay {
    _registerForInAppScreenName = [BlueShift.sharedInstance getRegisteredForInAppScreenName];
    [BlueShift.sharedInstance unregisterForInAppMessage];
}

- (void)resumeInAppNotificationDisplay {
    if (_registerForInAppScreenName) {
        [BlueShift.sharedInstance registerForInAppMessage:_registerForInAppScreenName];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.progressView.hidden = NO;
    self.progressView.progress = 0;
    self.navigationItem.title = webView.URL.absoluteString;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.progressView.hidden = YES;
    self.navigationItem.title = [BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty: webView.title] ? webView.title : webView.URL.absoluteString;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.progressView.hidden = YES;
}

#pragma mark - Key-Value Observing (KVO)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat newProgress = [change[NSKeyValueChangeNewKey] floatValue];
        [self.progressView setProgress:newProgress animated:YES];
    }
}

@end
