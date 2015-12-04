//
//  RD2RateThisAppCustomViewController.m
//  rgCalendar
//
//  Created by Viktor Gedzenko on 3/20/13.
//  Modified by Viacheslav Savchenko on 5/20/13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "RD2RateThisAppCustomViewController.h"

@implementation RD2RateThisAppCustomViewController

#pragma mark - View

- (BOOL)shouldAutorotate {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        ? YES
        : NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        ? UIInterfaceOrientationMaskAll
        : UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        ? YES
        : NO;
}


#pragma mark - RD2RateThisAppCustomViewControllerDelegate protocol

- (IBAction)rateThisAppButtonTapped:(id)sender {
    [self.delegate rateThisAppViewController:self didFinishedWithResult:RTARequestYes];
}

- (IBAction)laterButtonTapped:(id)sender {
    [self.delegate rateThisAppViewController:self didFinishedWithResult:RTARequestRemind];
}

- (IBAction)closeButtonTapped:(id)sender {
    [self.delegate rateThisAppViewController:self didFinishedWithResult:RTARequestNo];
}

@end


#pragma mark - PBVideoRD2RateThisAppCustomView class

@interface PBVideoRD2RateThisAppCustomView ()
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIView *logoView;
@property (nonatomic, retain) IBOutlet UIView *titleView;
@end

@implementation PBVideoRD2RateThisAppCustomView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (nil != self) {
        [self customizeAppearence];
    }

    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self customizeAppearence];
}

- (void)customizeAppearence {
    [super customizeAppearence];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.contentView.layer.cornerRadius = 6.0;
        self.contentView.layer.masksToBounds = YES;
    }
    else if ([UIScreen mainScreen].bounds.size.height > 480.0) {
        CGRect logoFrame = self.logoView.frame;
        logoFrame.origin.y += 33.0;
        [self.logoView setFrame:logoFrame];

        CGRect titleFrame = self.titleView.frame;
        titleFrame.origin.y += 33.0;
        [self.titleView setFrame:titleFrame];
    }
}

@end
