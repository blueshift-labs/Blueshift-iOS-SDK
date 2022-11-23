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
        self.viewModel = [[BlueshiftInboxViewModel alloc] init];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.viewModel = [[BlueshiftInboxViewModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableView];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self registerTableViewCells];
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
        self.tableView.tableFooterView = [[UIView alloc]init];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
//        self.tableView.allowsSelection = NO;
        [self reloadTableView];
    });
}

- (void)reloadTableView {
    [_viewModel reloadInboxMessages:^(BOOL isRefresh) {
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
    if (_tableViewCellNibName) {
        UINib * nib = [self geNibForName:_tableViewCellNibName];
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

- (void)setBlueshiftInboxDateFormat:(NSString *)dateFormatter {
    _viewModel.blueshiftInboxDateFormat = dateFormatter;
}

- (NSString* _Nullable)getBlueshiftInboxDateFormat {
    return _viewModel.blueshiftInboxDateFormat;
}


- (void)setBlueshiftInboxDateFormatType:(BlueshiftInboxDateFormatType)type {
    _viewModel.blueshiftInboxDateFormatType = type;
}

- (BlueshiftInboxDateFormatType)getBlueshiftInboxDateFormatType {
    return _viewModel.blueshiftInboxDateFormatType;
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
    cell.titleLabel.text = message.title ? message.title : @"Buy Now";
    cell.detailLabel.text = message.detail ? message.detail : @"Starbucks 99% off";
    cell.dateLabel.text = [_viewModel getFormattedDateForDate: message.date];
    
    [_viewModel downloadImageForURLString:message.iconImageURL completionHandler:^(NSData * _Nullable imageData) {
        if (imageData) {
            [cell.iconImageView setHidden: NO];
            cell.iconImageView.image = [[UIImage alloc] initWithData:imageData];
        } else {
            [cell.iconImageView setHidden: YES];
        }
    }];
    
    if (_inboxDelegate && [_inboxDelegate respondsToSelector:@selector(configureCustomFieldsForCell:inboxMessage:)]) {
        [_inboxDelegate configureCustomFieldsForCell:cell inboxMessage:message];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [BlueShift.sharedInstance showInboxNotificationForMessage:[_viewModel itemAtIndexPath:indexPath]];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [BlueShift.sharedInstance deleteMessageFromInbox:[_viewModel itemAtIndexPath:indexPath] completionHandler:^(BOOL status) {
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if (status) {
                [self reloadTableView];
            }
        }];
    }
}

@end
