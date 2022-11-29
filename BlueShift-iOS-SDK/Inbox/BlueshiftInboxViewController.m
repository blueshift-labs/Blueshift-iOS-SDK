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

@interface BlueshiftInboxViewController ()

@property (nonatomic, strong) BlueshiftInboxViewModel * viewModel;

@end

@implementation BlueshiftInboxViewController

@synthesize nibName;

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _viewModel = [[BlueshiftInboxViewModel alloc] init];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _viewModel = [[BlueshiftInboxViewModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableView];
    [self registerTableViewCells];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [BlueShift.sharedInstance registerForInAppMessage:@"Inbox"];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [BlueShift.sharedInstance unregisterForInAppMessage];
}

- (void)setupTableView {
    [self initInboxDelageFor:_inboxDelegateName];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    //        self.tableView.allowsSelection = NO;
    [self reloadTableView];
}

- (void)initInboxDelageFor:(NSString*)className {
    if (!_inboxDelegate && className && [className componentsSeparatedByString:@"."].count > 1) {
        id<BlueshiftInboxViewControllerDelegate> delegate = (id<BlueshiftInboxViewControllerDelegate>)[[NSClassFromString(className) alloc] init];
        if (delegate) {
            self.inboxDelegate = delegate;
        }
    } else {
//        assertionFailure(@"Failed to init the inbox delegate as module name is missing. The class name should be of format module_name.class_name");
    }

}

- (void)reloadTableView {
    [_viewModel reloadInboxMessagesInOrder:_inboxDelegate.sortOrder handler:^(BOOL isRefresh) {
        if(isRefresh) {
            if ([NSThread isMainThread]) {
                [self.tableView reloadData];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }
        }
    }];
}

- (void)registerTableViewCells {
    if (_customCellNibName) {
        UINib * nib = [self geNibForName:_customCellNibName];
        if(nib) {
            [self.tableView registerNib:nib forCellReuseIdentifier:kBSInboxDefaultCellIdentifier];
            return;
        }
    }
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_viewModel.inboxMessages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BlueshiftInboxTableViewCell *cell = (BlueshiftInboxTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kBSInboxDefaultCellIdentifier forIndexPath:indexPath];
    BlueshiftInboxMessage* message = [_viewModel itemAtIndexPath:indexPath];

    //Set labels
    [self setText:message.title toLabel:cell.titleLabel];
    [self setText:message.detail toLabel:cell.detailLabel];
    [self setText:[self getFormattedDate: message] toLabel:cell.dateLabel];
    //Set unread status
    [cell.unreadBadgeView setHidden:message.readStatus];
    //Download image
    [_viewModel downloadImageForURLString:message.iconImageURL completionHandler:^(NSData * _Nullable imageData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (imageData) {
                [cell.iconImageView setHidden: NO];
                cell.iconImageView.image = [[UIImage alloc] initWithData:imageData];
            } else {
                [cell.iconImageView setHidden: YES];
            }
        });
    }];
    //Callbacks
    if (_inboxDelegate && [_inboxDelegate respondsToSelector:@selector(configureCustomFieldsForCell:inboxMessage:)]) {
        [_inboxDelegate configureCustomFieldsForCell:cell inboxMessage:message];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BlueshiftInboxMessage* message = [_viewModel itemAtIndexPath:indexPath];
    [BlueShift.sharedInstance showInboxNotificationForMessage:message];
    if (_inboxDelegate && [_inboxDelegate respondsToSelector:@selector(inboxMessageSelected:)]) {
        [_inboxDelegate inboxMessageSelected:message];
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        BlueshiftInboxMessage* message = [_viewModel itemAtIndexPath:indexPath];
        // Delete the row from the data source
        [BlueShift.sharedInstance deleteMessageFromInbox:message completionHandler:^(BOOL status) {
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if (status) {
                [self reloadTableView];
            }
        }];
        if (_inboxDelegate && [_inboxDelegate respondsToSelector:@selector(inboxMessageDeleted:)]) {
            [_inboxDelegate inboxMessageDeleted:message];
        }
    }
}

- (void)setText:(NSString*)text toLabel:(UILabel *)label {
    if (text && ![text isEqualToString:@""]) {
        [label setHidden: NO];
        label.text = text;
    } else {
        [label setHidden: YES];
        label.text = nil;
    }
}

-(NSString*)getFormattedDate:(BlueshiftInboxMessage*)message {
    if (self.inboxDelegate && [self.inboxDelegate respondsToSelector:@selector(formatDate:)]) {
        return [self.inboxDelegate formatDate:message];
    }
    return [_viewModel getDefaultFormatDate: message.date];
}

@end
