//
//  BlueshiftInboxNavigationViewController.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 15/11/22.
//

#import "BlueshiftInboxNavigationViewController.h"

@interface BlueshiftInboxNavigationViewController ()
@property BlueshiftInboxViewController* inboxViewController;

@end

IB_DESIGNABLE
@implementation BlueshiftInboxNavigationViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        [self setUpInboxViewController];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setUpInboxViewController];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController: rootViewController];
    if (self) {
        [self setUpInboxViewController];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setUpInboxViewController];
    }
    return self;
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass {
    self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
    if (self) {
        [self setUpInboxViewController];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.viewControllers.count > 0 && self.viewControllers[0]) {
            if (weakSelf.showDoneButton) {
                UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonTapped)];
                self.viewControllers[0].navigationItem.rightBarButtonItem = doneButton;
            }
            self.viewControllers[0].navigationItem.title = self.title;
        }
    });
}

- (void)setCustomCellNibName:(NSString *)customCellNibName {
    if (_inboxViewController) {
        _inboxViewController.customCellNibName = customCellNibName;
    }
}

- (void)setInboxDelegateName:(NSString *)inboxDelegateName {
    if (_inboxViewController) {
        _inboxViewController.inboxDelegateName = inboxDelegateName;
    }
}

- (void)setUnreadBadgeColor:(UIColor *)unreadBadgeColor {
    if (_inboxViewController) {
        _inboxViewController.unreadBadgeColor = unreadBadgeColor;
    }
}

- (void)setRefreshControlColor:(UIColor *)refreshControlColor {
    if (_inboxViewController) {
        _inboxViewController.refreshControlColor = refreshControlColor;
    }
}

- (void)setEnableLargeTitle:(BOOL)enableLargeTitle {
    if (@available(iOS 11.0, *)) {
        self.navigationBar.prefersLargeTitles = YES;
    }
}

- (void)setShowActivityIndicator:(BOOL)showActivityIndicator {
    if (_inboxViewController) {
        _inboxViewController.showActivityIndicator = showActivityIndicator;
    }
}

- (void)setActivityIndicatorColor:(UIColor *)activityIndicatorColor {
    if (_inboxViewController) {
        _inboxViewController.activityIndicatorColor = activityIndicatorColor;
    }
}

- (void)setGroupSections:(BOOL)groupSections {
    if (groupSections) {
        [self setupGroupedSections];
    }
}

- (void)setNoMessagesText:(NSString *)noMessagesText {
    if(_inboxViewController) {
        _inboxViewController.noMessagesText = noMessagesText;
    }
}

- (void)setInboxDelegate:(id<BlueshiftInboxViewControllerDelegate>)inboxDelegate {
    if (_inboxViewController) {
        _inboxViewController.inboxDelegate = inboxDelegate;
    }
}

#pragma mark -
- (void)setUpInboxViewController {
    _showDoneButton = YES;
    if (self.viewControllers.count > 0 && [self.viewControllers[0] isKindOfClass:[BlueshiftInboxViewController class]]) {
        _inboxViewController = self.viewControllers.lastObject;
    } else {
        _inboxViewController = [[BlueshiftInboxViewController alloc] initWithStyle:UITableViewStylePlain];
        [self setViewControllers:@[_inboxViewController] animated:NO];
    }
}

- (void)setupGroupedSections {
    BlueshiftInboxViewController* inboxVC = [[BlueshiftInboxViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self setViewControllers:@[inboxVC] animated:NO];
}

- (void)setProperties:(BlueshiftInboxViewController*)inboxVC {
    
}

- (void)doneButtonTapped {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
