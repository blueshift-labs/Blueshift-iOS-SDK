//
//  BlueshiftWebBrowserViewController.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 28/08/23.
//
#import <WebKit/WebKit.h>

#import "BlueshiftWebBrowserViewController.h"

@interface BlueshiftWebBrowserViewController ()<WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property UIBarButtonItem *reloadButton;
@property UIBarButtonItem *openInBrowserButton;
@property NSString* registerForInAppScreenName;
@end

@implementation BlueshiftWebBrowserViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _showOpenInBrowserButton = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavigationButtons];
    [self setupWebView];
    [self setupProgressView];
    [self activateConstraints];
    
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
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
    _reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadButtonTapped)];
    if (@available(iOS 13.0, *)) {
        _openInBrowserButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"safari"] style:UIBarButtonItemStylePlain target:self action:@selector(openInBrowser)];
    } else {
        _openInBrowserButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openInBrowser)];
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
            appearance.titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.grayColor};
            self.navigationController.navigationBar.standardAppearance = appearance;
            self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        NSDictionary *titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor grayColor]
        };
        [self.navigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
        [self.navigationController.navigationBar setTranslucent:NO];
    }
}

- (void)setupWebView {
    WKWebViewConfiguration *wkConfig = [[WKWebViewConfiguration alloc] init];
    wkConfig.allowsInlineMediaPlayback = YES;
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:wkConfig];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.navigationDelegate = self;
    _webView.allowsBackForwardNavigationGestures = true;
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_webView];
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setupProgressView {
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.progressView];
}

- (void)activateConstraints {
    if (@available(iOS 11.0, *)) {
        [NSLayoutConstraint activateConstraints:@[
            // WebView constraints
            [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            
            // ProgressView constraints
            [self.progressView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [self.progressView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.progressView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.progressView.heightAnchor constraintEqualToConstant:2.0]
        ]];
    } else {
        CGFloat top = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
        [NSLayoutConstraint activateConstraints:@[
            // WebView constraints
            [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:top],
            [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            
            // ProgressView constraints
            [self.progressView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:top],
            [self.progressView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.progressView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.progressView.heightAnchor constraintEqualToConstant:2.0]
        ]];
    }
}

- (void)openInBrowser {
    [UIApplication.sharedApplication openURL:_webView.URL];
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
    self.navigationItem.title = webView.title;
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
