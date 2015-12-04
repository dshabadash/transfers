//
//  PBNearbyDeviceListViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 08/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBNearbyDeviceListViewController.h"
#import "PBServiceBrowser.h"
#import "PBAssetUploader.h"

static NSString *kCellIdentifier = @"cellIdentifier";

@interface PBNearbyDeviceListViewController () <UITableViewDataSource, UITableViewDelegate> {
    PBServiceBrowser *_serviceBrowser;
    NSMutableArray *_serviceNames;
}

@property (nonatomic, unsafe_unretained) IBOutlet UITableView *tableView;
@property (nonatomic, unsafe_unretained) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *lookingForLabel;
@property (nonatomic, retain) IBOutlet UIView *headerView;

@end

@implementation PBNearbyDeviceListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.topBarShadowType = PBViewControllerTopBarShadowTypeNormal;
        self.showTopToolbar = YES;
        self.topToolbarShowFreeToSendPhotosOnly = YES;
        
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(servicesChanged:)
            name:PBServiceBrowserServicesDidUpdateNotification
            object:nil];

        _serviceNames = [NSMutableArray new];
        _serviceBrowser = [PBServiceBrowser new];
        [_serviceBrowser start];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_serviceBrowser stop];
    [_serviceBrowser release];

    [_serviceNames removeAllObjects];
    [_serviceNames release];
    _serviceNames = nil;

    [_headerView release];
    _headerView = nil;

    [_tableViewCellNib release];
    _tableViewCellNib = nil;

    _tableView = nil;
    _activityIndicator = nil;
    _lookingForLabel = nil;
    
    [super dealloc];
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:self.tableViewCellNib
        forCellReuseIdentifier:kCellIdentifier];
    
    UIView *tableViewBgView = [[[UIView alloc] init] autorelease];
    tableViewBgView.backgroundColor = self.tableView.backgroundColor;
    self.tableView.backgroundView = tableViewBgView;
        
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *cancelButton =
            [[[UIBarButtonItem alloc]
                initWithTitle:NSLocalizedString(@"Cancel", @"")
                style:UIBarButtonItemStylePlain
                target:self
                action:@selector(dismiss)]
             autorelease];

        self.navigationItem.rightBarButtonItem = cancelButton;
    }

    [_activityIndicator startAnimating];

    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationDidBecomeActive)
        name:UIApplicationDidBecomeActiveNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(applicationWillResignActive)
        name:UIApplicationWillResignActiveNotification
        object:nil];
}

- (void)dismiss {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}


#pragma mark - Events handling

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismiss];
}


#pragma mark - Service Browser

- (void)servicesChanged:(NSNotification *)notification {
    @synchronized(_serviceNames) {
        [_serviceNames removeAllObjects];
        [_serviceNames addObjectsFromArray:_serviceBrowser.availableServiceNames];

        [self.tableView reloadData];
        
        if (_serviceNames.count) {
            [_activityIndicator stopAnimating];
            _lookingForLabel.hidden = YES;
        } else {
            [_activityIndicator startAnimating];
            _lookingForLabel.hidden = NO;
        }
    }
}


#pragma mark - UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _serviceNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    cell.textLabel.text = _serviceNames[indexPath.row];
    
    return cell;
}


#pragma mark - UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger serviceIndex = indexPath.row;
    NSString *serviceUrlString = nil;
    NSString *serviceName = nil;
    @synchronized(_serviceNames) {
        if (_serviceNames.count > serviceIndex) {
            serviceName = [[[_serviceNames objectAtIndex:serviceIndex] copy] autorelease];
        }
    }
    
    if (serviceName) {
        serviceUrlString = [_serviceBrowser serviceURLStringWithName:serviceName];
        NSLog(@"%@", serviceUrlString);

        // Reload table view if we did tap on cell which service has been removed
        if (nil == serviceUrlString) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self servicesChanged:nil];
            });

            return;
        }
        
        NSString *deviceType = [_serviceBrowser serviceDeviceNameWithName:serviceName];
        NSLog(@"Sending to device type: %@", deviceType);
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self.presentingViewController dismissViewControllerAnimated:NO completion:^{

            }];
            
        } else {
            [self.navigationController popToRootViewControllerAnimated:NO];
        }

        PBAssetUploader *uploader = [PBAssetUploader uploader];
        [uploader sendAssetsToDeviceWithUrlString:serviceUrlString
                                       deviceName:serviceName
                                       deviceType:deviceType];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return _headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return _headerView.bounds.size.height;
}


#pragma mark - Notifications

- (void)applicationDidBecomeActive {
    [_serviceBrowser start];
}

- (void)applicationWillResignActive {
    [_serviceBrowser stop];
}

@end
