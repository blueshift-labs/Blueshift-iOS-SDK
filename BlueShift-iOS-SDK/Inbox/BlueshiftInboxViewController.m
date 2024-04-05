//
//  BlueshiftInboxViewController.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 15/11/22.
//

#import "BlueshiftInboxViewController.h"
#import "BlueshiftInboxTableViewCell.h"
#import "BlueshiftInboxMessage.h"
#import "BlueShiftInAppNotificationManager.h"
#import "BlueShiftInAppNotificationHelper.h"
#import "BlueshiftInboxViewModel.h"
#import "BlueshiftConstants.h"
#import "BlueshiftLog.h"
#import "BlueshiftInboxManager.h"
#import "BlueshiftInboxMessage.h"
#import "BlueshiftInboxTableViewCell.h"
#import "BlueshiftInboxMessage.h"
#import "BlueshiftInboxViewModel.h"

#define kBSInboxLoaderSize     50

@interface BlueshiftInboxViewController ()

@property (nonatomic, strong) BlueshiftInboxViewModel * viewModel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property UILabel* noMessageLabel;

@end

@implementation BlueshiftInboxViewController {
    _Nullable id inAppNotificationDidAppearToken;
    _Nullable id unreadMessageCountDidChangeToken;
}

@synthesize nibName;

#pragma mark Init methods
- (instancetype)init {
    self = [super init];
    if (self) {
        _viewModel = [[BlueshiftInboxViewModel alloc] init];
        [self setDefaults];
    }
    return self;
}

- (instancetype)initWithInboxDelegate:(id<BlueshiftInboxViewControllerDelegate>)inboxDelegate {
    self = [super init];
    if (self) {
        self.inboxDelegate = inboxDelegate;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _viewModel = [[BlueshiftInboxViewModel alloc] init];
        [self setDefaults];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _viewModel = [[BlueshiftInboxViewModel alloc] init];
        [self setDefaults];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _viewModel = [[BlueshiftInboxViewModel alloc] init];
        [self setDefaults];
    }
    return self;
}

#pragma mark Lifecycle methods
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setInboxDelegate];
    [self registerTableViewCells];
    [self setupTableView];
    [self setupPullToRefresh];
    [self SyncInbox];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupObservers];
    [self reloadTableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    if (inAppNotificationDidAppearToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:inAppNotificationDidAppearToken];
    }
    
    if (unreadMessageCountDidChangeToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:unreadMessageCountDidChangeToken];
    }
    [self.activityIndicator removeFromSuperview];
    self.activityIndicator = nil;
}

- (void)dealloc {
    [_viewModel.sectionInboxMessages removeAllObjects];
    [BlueShiftRequestOperationManager.sharedRequestOperationManager.sdkCachedData removeAllObjects];
}

#pragma mark Inbox Setup
- (void)setDefaults {
    self.showActivityIndicator = YES;
}

- (void)setInboxDelegate {
    @try {
        if (_inboxDelegate) {
            [self setPropertiesToViewModel];
        } else if (_inboxDelegateName) {
            if([_inboxDelegateName componentsSeparatedByString:@"."].count > 1) {
                id<BlueshiftInboxViewControllerDelegate> delegate = (id<BlueshiftInboxViewControllerDelegate>)[[NSClassFromString(_inboxDelegateName) alloc] init];
                if (delegate) {
                    self.inboxDelegate = delegate;
                    [self setPropertiesToViewModel];
                }
            } else {
                [BlueshiftLog logError:nil withDescription:@"Failed to init the inbox delegate as module name is missing. The class name should be of format module_name.class_name" methodName:nil];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
}

- (void)setPropertiesToViewModel {
    if ([self.inboxDelegate respondsToSelector:@selector(messageFilter)]) {
        _viewModel.messageFilter = self.inboxDelegate.messageFilter;
    }
    if ([self.inboxDelegate respondsToSelector:@selector(messageComparator)]) {
        _viewModel.messageComparator =  self.inboxDelegate.messageComparator;
    }
}

- (void)setupTableView {
    if (self.noMessagesText) {
        _noMessageLabel = [[UILabel alloc] init];
        _noMessageLabel.text = self.noMessagesText;
        _noMessageLabel.numberOfLines = 0;
        _noMessageLabel.textColor = UIColor.grayColor;
        _noMessageLabel.center = self.tableView.center;
        _noMessageLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)setupPullToRefresh {
    if (@available(iOS 10.0, *)) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        self.refreshControl.tintColor = self.refreshControlColor ? self.refreshControlColor : [UIColor colorWithRed:0/255.0 green:193.0/255.0 blue:193.0/255.0 alpha:1];
        [self.refreshControl addTarget:self action:@selector(SyncInbox) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
    }
}

- (void)setupObservers {
    __weak __typeof(self)weakSelf = self;
    if (_showActivityIndicator) {
        inAppNotificationDidAppearToken = [NSNotificationCenter.defaultCenter addObserverForName:kBSInAppNotificationDidAppear object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            if (weakSelf.activityIndicator && weakSelf.activityIndicator.isAnimating) {
                [weakSelf.activityIndicator stopAnimating];
            }
        }];
    }
    unreadMessageCountDidChangeToken = [NSNotificationCenter.defaultCenter addObserverForName:kBSInboxUnreadMessageCountDidChange object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        BlueshiftInboxChangeType type = (BlueshiftInboxChangeType)[note.userInfo[kBSInboxRefreshType] integerValue];
        if (type == BlueshiftInboxChangeTypeSync || type == BlueshiftInboxChangeTypeMarkAsUnread) {
            [weakSelf reloadTableView];
        }
    }];
}

- (void)startActivityIndicator {
    if (_showActivityIndicator) {
        if (!self.activityIndicator) {
            if (@available(iOS 13.0, *)) {
                self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
            } else {
                self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            }
            self.activityIndicator.color = _activityIndicatorColor ? _activityIndicatorColor :  [UIColor colorWithRed:0/255.0 green:193.0/255.0 blue:193.0/255.0 alpha:1];
            [self.tableView addSubview:self.activityIndicator];
            self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
            [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.tableView.superview.centerXAnchor].active = YES;
            [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.tableView.superview.centerYAnchor].active = YES;
        }
        [self.activityIndicator startAnimating];
        
        __weak __typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (weakSelf.activityIndicator && weakSelf.activityIndicator.isAnimating) {
                [weakSelf.activityIndicator stopAnimating];
            }
        });
    }
}

#pragma mark sync methods
- (void)reloadTableView {
    __weak __typeof(self)weakSelf = self;
    [_viewModel reloadInboxMessagesWithHandler:^(BOOL isRefresh) {
        if(isRefresh) {
            [weakSelf.tableView reloadData];
        }
    }];
}

- (void)SyncInbox {
    __weak __typeof(self)weakSelf = self;
    [BlueshiftInboxManager syncInboxMessages:^{
        if (@available(iOS 10.0, *)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.refreshControl.isRefreshing) {
                    [weakSelf.refreshControl endRefreshing];
                }
            });
        }
    }];
    //Force Dismiss the refresh control after 5 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (weakSelf.refreshControl.isRefreshing) {
            [weakSelf.refreshControl endRefreshing];
        }
    });
}

#pragma mark Register tableview cells
- (void)registerTableViewCells {
    [self registerDefaultTableViewCell];
    [self registerCustomTableViewCells];
}

- (void)registerDefaultTableViewCell {
    //Register either provided custom cell as default cell
    if (_customCellNibName) {
        UINib * nib = [self geNibForName:_customCellNibName];
        if(nib) {
            [self.tableView registerNib:nib forCellReuseIdentifier:kBSInboxDefaultCellIdentifier];
            return;
        }
    }
    //Or register SDK cell as default cell
    [self.tableView registerClass:[BlueshiftInboxTableViewCell class] forCellReuseIdentifier:kBSInboxDefaultCellIdentifier];
}

- (void)registerCustomTableViewCells {
    //Register multiple custom nibs
    if([self.inboxDelegate respondsToSelector:@selector(getCustomCellNibNameForMessage:)]) {
        if (_inboxDelegate.customCellNibNames && _inboxDelegate.customCellNibNames.count > 0) {
            [_inboxDelegate.customCellNibNames enumerateObjectsUsingBlock:^(NSString * _Nonnull nibName, NSUInteger idx, BOOL * _Nonnull stop) {
                UINib * nib = [self geNibForName:nibName];
                if(nib) {
                    [self.tableView registerNib:nib forCellReuseIdentifier:nibName];
                }
            }];
        }
    }
}

- (UINib* _Nullable)geNibForName:(NSString* _Nullable)nibName {
    if(nibName && [[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"] != nil) {
        UINib* nib = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
        if (nib) {
            return nib;
        } else {
            [BlueshiftLog logError:nil withDescription:[NSString stringWithFormat: @"Unable to find the custom tableview cell nib: %@ in the main bundle", nibName] methodName:nil];
        }
    }
    return nil;
}

#pragma mark - Table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    [self setNoMessagesLabelToTableView];
    return [_viewModel numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_viewModel numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BlueshiftInboxMessage* message = [_viewModel itemAtIndexPath:indexPath];
    BlueshiftInboxTableViewCell *cell = [self createCellForTableView:tableView atIndexPath:indexPath message:message];
    
    //Prepare cell
    return cell ? [self prepareCell:cell ForMessage:message] : [[UITableViewCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self handleDidSelectRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self handleDeleteRowAtIndexPath:indexPath];
    }
}

#pragma mark BlueshiftInboxInAppNotificationDelegate methods
-(void)inboxInAppNotificationActionTappedWithDeepLink:(NSString * _Nullable)deepLink options:(nonnull NSDictionary *)options{
    if([self.inboxDelegate respondsToSelector:@selector(inboxNotificationActionTappedWithDeepLink:inboxViewController:options:)]) {
        [self.inboxDelegate inboxNotificationActionTappedWithDeepLink:deepLink inboxViewController:self options:options];
    }
}

- (BOOL)isInboxNotificationActionTappedImplementedByHostApp {
    if([self.inboxDelegate respondsToSelector:@selector(inboxNotificationActionTappedWithDeepLink:inboxViewController:options:)]) {
        return YES;
    }
    return NO;
}

- (UIWindowScene* _Nullable)getInboxWindowScene API_AVAILABLE(ios(13.0)) {
    return self.view.window.windowScene;
}


#pragma mark Helper methods
- (void)setNoMessagesLabelToTableView {
    if (_noMessageLabel && _viewModel.sectionInboxMessages.firstObject && _viewModel.sectionInboxMessages.firstObject.count == 0) {
        self.tableView.backgroundView = _noMessageLabel;
    } else {
        self.tableView.backgroundView = nil;
    }
}

- (BlueshiftInboxTableViewCell* _Nullable)createCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath message:(BlueshiftInboxMessage*)message {
    BlueshiftInboxTableViewCell* cell = nil;
    if(message && [self.inboxDelegate respondsToSelector:@selector(getCustomCellNibNameForMessage:)]) {
        NSString* customNibName = [self.inboxDelegate getCustomCellNibNameForMessage:message];
        if (customNibName) {
            cell = (BlueshiftInboxTableViewCell*)[tableView dequeueReusableCellWithIdentifier:customNibName forIndexPath:indexPath];
        }
    }

    if (!cell) {
        cell = (BlueshiftInboxTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kBSInboxDefaultCellIdentifier forIndexPath:indexPath];
    }
    return cell;
}

- (BlueshiftInboxTableViewCell*)prepareCell:(BlueshiftInboxTableViewCell*)cell ForMessage:(BlueshiftInboxMessage*)message {
    @try {
        if (message) {
            //Set labels
            [self setText:message.title toLabel:cell.titleLabel];
            [self setText:message.detail toLabel:cell.detailLabel];
            [self setText:[self getFormattedDate: message] toLabel:cell.dateLabel];
            
            //Set unread status
            [cell.unreadBadgeView setHidden:message.readStatus];
            if (_unreadBadgeColor) {
                [cell.unreadBadgeView setBackgroundColor:_unreadBadgeColor];
            }
            
            //Set image
            [cell setIconImageURL:message.iconImageURL];
            
            //Configure custom fields callback
            if (_inboxDelegate && [_inboxDelegate respondsToSelector:@selector(configureCustomFieldsForCell:inboxMessage:)]) {
                [_inboxDelegate configureCustomFieldsForCell:cell inboxMessage:message];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
    return cell;
}

- (void)handleDeleteRowAtIndexPath:(NSIndexPath*)indexPath {
    BlueshiftInboxMessage* message = [_viewModel itemAtIndexPath:indexPath];
    // Delete the row from the data source
    if (message) {
        __weak __typeof(self)weakSelf = self;
        [BlueshiftInboxManager deleteInboxMessage:message completionHandler:^(BOOL status, NSString* errorMessage ) {
            dispatch_async(dispatch_get_main_queue(), ^{
            if (status) {
                    [self reloadTableView];
                    
                    //Callback
                    if (weakSelf.inboxDelegate && [weakSelf.inboxDelegate respondsToSelector:@selector(inboxMessageDeleted:)]) {
                        [weakSelf.inboxDelegate inboxMessageDeleted:message];
                    }
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:errorMessage preferredStyle: UIAlertControllerStyleAlert];
                NSString *okayText = NSLocalizedString(kBSAlertOkayButtonLocalizedKey, @"");
                okayText = [okayText isEqualToString: kBSAlertOkayButtonLocalizedKey] ? @"Okay" : okayText;
                UIAlertAction *action = [UIAlertAction actionWithTitle:okayText style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                }];
                
                [alert addAction:action];
                [self.navigationController presentViewController:alert animated:YES completion:^{
                }];
            }
            });
        }];
    }
}

- (void)handleDidSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    BlueshiftInboxMessage* message = [_viewModel itemAtIndexPath:indexPath];
    if (message) {
        BOOL isDisplayed = [BlueshiftInboxManager showNotificationForInboxMessage:message inboxInAppDelegate: self];
        if (isDisplayed) {
            [self startActivityIndicator];
            [self reloadTableViewCellForIndexPath:indexPath animated:YES];
        }
    }
}

- (void)setText:(NSString*)text toLabel:(UILabel *)label {
    if (label) {
        if (text && ![text isEqualToString:@""]) {
            [label setHidden: NO];
            label.text = text;
        } else {
            [label setHidden: YES];
            label.text = nil;
        }
    }
}

-(NSString*)getFormattedDate:(BlueshiftInboxMessage*)message {
    if (self.inboxDelegate && [self.inboxDelegate respondsToSelector:@selector(formatDate:)]) {
        return [self.inboxDelegate formatDate:message];
    }
    return [_viewModel getDefaultFormatDate: message.createdAtDate];
}

- (void)reloadTableViewCellForIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated{
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];
    }
}

@end
