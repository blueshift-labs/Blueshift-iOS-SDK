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
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.viewControllers.count > 0 && self.viewControllers[0]) {
            UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonTapped)];
            self.viewControllers[0].navigationItem.rightBarButtonItem = doneButton;
            self.viewControllers[0].navigationItem.title = self.title;
        }
    });
}

#pragma mark getters and setters
//- (void)setTableViewCellNibName:(NSString *)tableViewCellNibName {
//    _inboxViewController.tableViewCellNibName = tableViewCellNibName;
//}
//
//- (NSString* _Nullable)tableViewCellNibName {
//    return _inboxViewController.tableViewCellNibName;
//}

- (void)setInboxDelegate:(id<BlueshiftInboxViewControllerDelegate>)inboxDelegate {
    _inboxViewController.inboxDelegate = inboxDelegate;
}

- (id<BlueshiftInboxViewControllerDelegate>)inboxDelegate {
    return _inboxViewController.inboxDelegate;
}

- (void)setInboxDelegateName:(NSString *)inboxDelegateName {
    _inboxViewController.inboxDelegateName = inboxDelegateName;
}

#pragma mark -
- (void)setUpInboxViewController {
    if (self.viewControllers.count > 0 && [self.viewControllers[0] isKindOfClass:[BlueshiftInboxViewController class]]) {
        _inboxViewController = self.viewControllers.lastObject;
    } else {
        _inboxViewController = [[BlueshiftInboxViewController alloc] init];
        [self setViewControllers:@[_inboxViewController] animated:NO];
    }
    _inboxViewController.customCellNibName = @"CustomInboxTableViewCell";
}

- (void)doneButtonTapped {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
