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

#define kBSInboxLoaderSize     50

@interface BlueshiftInboxViewController ()

@property (nonatomic, strong) BlueshiftInboxViewModel * viewModel;
@property UIActivityIndicatorView *activityIndicator;

@end

@implementation BlueshiftInboxViewController

@synthesize nibName;

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

- (void)dealloc {
    [_viewModel.sectionInboxMessages removeAllObjects];
    [BlueShiftRequestOperationManager.sharedRequestOperationManager.inboxImageDataCache removeAllObjects];
}

- (void)setDefaults {
    self.showActivityIndicator = YES;
    self.activityIndicatorColor = UIColor.grayColor;
    _viewModel.viewDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initInboxDelegate];
    [self setupTableView];
    [self setupPullToRefresh];
    [self registerTableViewCells];
    [self SyncInbox];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadTableView];
    [self setupObservers];
}

- (void)initInboxDelegate {
    @try {
        if (_inboxDelegate) {
            [self copyPropertiesToViewModel];
        } else if (_inboxDelegateName) {
            if([_inboxDelegateName componentsSeparatedByString:@"."].count > 1) {
                id<BlueshiftInboxViewControllerDelegate> delegate = (id<BlueshiftInboxViewControllerDelegate>)[[NSClassFromString(_inboxDelegateName) alloc] init];
                if (delegate) {
                    self.inboxDelegate = delegate;
                    [self copyPropertiesToViewModel];
                }
            } else {
                [BlueshiftLog logError:nil withDescription:@"Failed to init the inbox delegate as module name is missing. The class name should be of format module_name.class_name" methodName:nil];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
}

- (void)copyPropertiesToViewModel {
    if ([self.inboxDelegate respondsToSelector:@selector(messageFilter)]) {
        _viewModel.messageFilter = self.inboxDelegate.messageFilter;
    }
    if ([self.inboxDelegate respondsToSelector:@selector(messageComparator)]) {
        _viewModel.messageComparator =  self.inboxDelegate.messageComparator;
    }
}

- (void)setupTableView {
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)setupPullToRefresh {
    if (@available(iOS 10.0, *)) {
        self.refreshControl = [[UIRefreshControl alloc]init];
        [self.refreshControl addTarget:self action:@selector(SyncInbox) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
    }
}

- (void)setupObservers {
    __weak __typeof(self)weakSelf = self;
    if (_showActivityIndicator) {
        [NSNotificationCenter.defaultCenter addObserverForName:kBSInAppNotificationWillAppear object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            if (weakSelf.activityIndicator) {
                [weakSelf.activityIndicator stopAnimating];
                [weakSelf.activityIndicator removeFromSuperview];
            }
        }];
    }
    [NSNotificationCenter.defaultCenter addObserverForName:kBSInboxUnreadMessageCountDidChange object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        BlueshiftInboxChangeType type = (BlueshiftInboxChangeType)[note.userInfo[@"refreshType"] integerValue];
        if (type == BlueshiftInboxChangeTypeSync) {
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
            CGFloat x = (self.tableView.frame.size.width / 2) - (kBSInboxLoaderSize/2);
            CGFloat centerY = UIScreen.mainScreen.bounds.size.height/2;
            CGFloat tableViewY = self.tableView.bounds.origin.y > 0 ? self.tableView.bounds.origin.y : - self.tableView.bounds.origin.y;
            CGFloat y = (centerY-tableViewY) - (kBSInboxLoaderSize/2);
            self.activityIndicator.color = _activityIndicatorColor;
            self.activityIndicator.frame = CGRectMake(x, y, kBSInboxLoaderSize, kBSInboxLoaderSize);
        }
        [self.tableView addSubview:self.activityIndicator];
        [self.activityIndicator startAnimating];
    }
}

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
    [BlueshiftInboxManager syncNewInboxMessages:^{
        if (@available(iOS 10.0, *)) {
            [weakSelf.refreshControl endRefreshing];
        }
    }];
}

- (void)registerTableViewCells {
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
    //Register privided custom cell as default cell
    if (_customCellNibName) {
        UINib * nib = [self geNibForName:_customCellNibName];
        if(nib) {
            [self.tableView registerNib:nib forCellReuseIdentifier:kBSInboxDefaultCellIdentifier];
            return;
        }
    }
    //Register SDK cell as default cell
    [self.tableView registerClass:[BlueshiftInboxTableViewCell class] forCellReuseIdentifier:kBSInboxDefaultCellIdentifier];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_viewModel numberOfSections];;
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

#pragma mark Helper methods

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
        [BlueshiftInboxManager deleteInboxMessage:message completionHandler:^(BOOL status) {
            if (status) {
                [self reloadTableView];
                //Callback
                if (weakSelf.inboxDelegate && [weakSelf.inboxDelegate respondsToSelector:@selector(inboxMessageDeleted:)]) {
                    [weakSelf.inboxDelegate inboxMessageDeleted:message];
                }
            }
        }];
    }
}

- (void)handleDidSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    BlueshiftInboxMessage* message = [_viewModel itemAtIndexPath:indexPath];
    if (message) {
        BOOL isDisplayed = [BlueshiftInboxManager showInboxNotificationForMessage:message];
        if (isDisplayed) {
            [self startActivityIndicator];
            [_viewModel markMessageAsRead:message];
            [self reloadTableViewCellForIndexPath:indexPath animated:YES];
        }
        //Callback
        if (_inboxDelegate && [_inboxDelegate respondsToSelector:@selector(inboxMessageSelected:)]) {
            [_inboxDelegate inboxMessageSelected:message];
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
    return [_viewModel getDefaultFormatDate: message.date];
}

- (void)reloadTableViewCellForIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated{
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];
    }
}

@end
