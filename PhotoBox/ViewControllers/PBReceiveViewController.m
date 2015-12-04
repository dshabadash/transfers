//
//  PBReceiveViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 10/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBReceiveViewController.h"
#import "PBConnectionManager.h"
#import "PBRootViewController.h"
#import "PBPageControl.h"

@interface PBReceiveViewController () <UIScrollViewDelegate> {
    CGFloat _initialLastInstructionLabelY;
    NSInteger _currentPage;
}

@property (retain, nonatomic) IBOutlet UIView *containerView;


@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIView *instructionContentView;

@property (retain, nonatomic) IBOutlet UILabel *deviceNameLabel1;
@property (retain, nonatomic) IBOutlet UILabel *deviceNameLabel2;

@property (retain, nonatomic) IBOutlet PBPageControl *pageControl;

@property (retain, nonatomic) IBOutlet UIButton *buttonComputer;
@property (retain, nonatomic) IBOutlet UIButton *buttonIphone;
@property (retain, nonatomic) IBOutlet UIButton *buttonIpad;


@property (retain, nonatomic) IBOutlet UILabel *firstAddressLabel;
@property (retain, nonatomic) IBOutlet UILabel *firstAddressBrowserLabel;
@property (retain, nonatomic) IBOutlet UILabel *secondAddressLabel;
@property (retain, nonatomic) IBOutlet UIView *secondAddressView;
@property (retain, nonatomic) IBOutlet UILabel *lastInstructionLabel;

@property (retain, nonatomic) IBOutlet UIButton *sendPhotosButton;

@end

@implementation PBReceiveViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    CGRect instructionContentViewFrame = _instructionContentView.frame;
    instructionContentViewFrame.origin.x = 0;
    _instructionContentView.frame = instructionContentViewFrame;
    
    _scrollView.contentSize = instructionContentViewFrame.size;
    
    NSString *deviceName = [PBAppDelegate serviceName];
    _deviceNameLabel1.text = deviceName;
    _deviceNameLabel2.text = deviceName;
    
    
    _pageControl.dotColorCurrentPage = [UIColor colorWithRed:0.38f green:0.37f blue:0.34f alpha:1.00f];
    _pageControl.dotColorOtherPage = [UIColor colorWithRed:0.77f green:0.76f blue:0.74f alpha:1.00f];
    _pageControl.numberOfPages = 3;
    
    _initialLastInstructionLabelY = _lastInstructionLabel.frame.origin.y;
    
    [self updateLocalAddressLabel];

    _currentPage = 0;

    _containerView.backgroundColor = [UIColor clearColor];
    _containerView.center = self.view.center;
    
    CALayer *layer = [_sendPhotosButton layer];
    layer.shadowOffset = CGSizeMake(0, 0);
    layer.shadowColor = [[UIColor blackColor] CGColor];
    layer.shadowRadius = 1.0;
    layer.shadowOpacity = 0.7;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 1024, 44)];
    layer.shadowPath = [shadowPath CGPath];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
    [self updateButtons];
    [self registerOnConnectionManagerNotifications];
    [self hideToolbarShadow];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self restoreToolbarShadow];
}

- (void)updateLocalAddressLabel {
    NSString *localAddressString = nil;
    NSString *localUrlString = [[PBConnectionManager sharedManager] localUrlString];
    if (localUrlString) {
        localAddressString = localUrlString;
    } else {
        localAddressString = NSLocalizedString(@"Not connected to Wi-Fi", @"Not connected to Wi-Fi");
    }
    
    CGFloat lastInstructionLabelY;
    CGFloat secondAddressViewAlpha;
    
    NSString *permanentUrlString = [[PBConnectionManager sharedManager] permanentUrlString];
    if (permanentUrlString) {
        _firstAddressLabel.text = permanentUrlString;
        _firstAddressBrowserLabel.text = permanentUrlString;
        _secondAddressLabel.text = localAddressString;
        
        lastInstructionLabelY = _initialLastInstructionLabelY;
        secondAddressViewAlpha = 1;
    } else {
        _firstAddressLabel.text = localAddressString;
        _firstAddressBrowserLabel.text = localAddressString;
        _secondAddressLabel.text = @"";
        
        lastInstructionLabelY = _secondAddressView.frame.origin.y;
        secondAddressViewAlpha = 0;
    }
    
    CGRect lastInstructionLabelFrame = _lastInstructionLabel.frame;
    lastInstructionLabelFrame.origin.y = lastInstructionLabelY;
    [UIView animateWithDuration:0.2
                     animations:^{
                         _lastInstructionLabel.frame = lastInstructionLabelFrame;
                         _secondAddressView.alpha = secondAddressViewAlpha;
                     }];
}

- (void)hideToolbarShadow {
    self.navigationController.toolbar.layer.masksToBounds = YES;
}

- (void)restoreToolbarShadow {
    self.navigationController.toolbar.layer.masksToBounds = NO;
}


#pragma mark - Notifications

- (void)registerOnConnectionManagerNotifications {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(updateLocalAddressLabel)
        name:PBConnectionManagerPermanentUrlDidChangeNotification
        object:nil];
}


#pragma mark - UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger pageNumber = round( scrollView.contentOffset.x / scrollView.bounds.size.width );

    _currentPage = pageNumber;
    _pageControl.currentPage = pageNumber;
    
    if (scrollView.tracking || scrollView.decelerating) {
        [self updateButtons];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self updateButtons];
}

- (void)setPage:(NSInteger)pageNumber {
    _currentPage = pageNumber;
    
    CGFloat width = _scrollView.bounds.size.width;
    CGFloat x = width * pageNumber;
    [_scrollView scrollRectToVisible:CGRectMake(x, 0, width, 100) animated:YES];
}

- (void)updateButtons {
    NSInteger pageNumber = _currentPage;    
    NSArray *items = @[_buttonComputer, _buttonIphone, _buttonIpad];
    for (UIButton *button in items) {
        button.selected = (pageNumber == button.tag);

        // StateDisabled is used as storage for original StateNormal
        // or original state for each button need to be stored on viewDidLoad

        UIColor *color = (button.selected)
            ? [button titleColorForState:UIControlStateSelected]
            : [button titleColorForState:UIControlStateDisabled];

        [button setTitleColor:color forState:UIControlStateNormal];
        [button setTitleColor:color forState:UIControlStateHighlighted];


        UIImage *backgroundImage = (button.selected)
            ? [button backgroundImageForState:UIControlStateSelected]
            : [button backgroundImageForState:UIControlStateDisabled];

        [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        [button setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];

        
        UIImage *image = (button.selected)
            ? [button imageForState:UIControlStateSelected]
            : [button imageForState:UIControlStateDisabled];

        [button setImage:image forState:UIControlStateNormal];
        [button setImage:image forState:UIControlStateHighlighted];
    }
}


#pragma mark - Actions

- (IBAction)senderButtonTapped:(id)sender {
    NSInteger pageNumber = [sender tag];
    [self setPage:pageNumber];
    [self updateButtons];
}

- (IBAction)sendPhotosButtonTapped:(id)sender {
    [[PBRootViewController sharedController] toggleViewController];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [[PBRootViewController sharedController] presentStartCoverViewsAnimated:YES];
}

- (IBAction)helpButtonTapped:(id)sender {
    [[PBRootViewController sharedController] presentHelpViewController];
}


#pragma mark - Memory management

- (void)dealloc {
    _sendPhotosButton = nil;
    [_scrollView release];
    [_instructionContentView release];
    [_deviceNameLabel1 release];
    [_pageControl release];
    [_deviceNameLabel2 release];
    [_buttonComputer release];
    [_buttonIphone release];
    [_buttonIpad release];
    [_firstAddressLabel release];
    [_firstAddressBrowserLabel release];
    [_secondAddressLabel release];
    [_secondAddressView release];
    [_lastInstructionLabel release];
    [_containerView release];
    [_sendPhotosButton release];
    
    [super dealloc];
}

@end
