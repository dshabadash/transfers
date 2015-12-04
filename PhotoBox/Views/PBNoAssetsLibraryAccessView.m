//
//  PBNoAssetsLibraryAccessView.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 26/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBNoAssetsLibraryAccessView.h"
#import "PBWebViewController.h"

@interface PBNoAssetsLibraryAccessView () 
@property (retain, nonatomic) IBOutlet UIView *contentContainerView;

@end

@implementation PBNoAssetsLibraryAccessView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
        _contentContainerView.backgroundColor = [UIColor clearColor];
        _contentContainerView.center = self.center;
    } else {
        _contentContainerView.backgroundColor = [UIColor clearColor];
        if (!PBDeviceIs4InchPhone()) {
            _contentContainerView.center = self.center;
        }
    }
}

- (IBAction)helpButtonTapped:(id)sender {
    
    NSString *htmlName = nil;
    if (PBGetSystemVersion() < 6.0) {
        htmlName = @"location"; //iOS5 Location services help
    } else {
        htmlName = @"photolibrary"; //iOS6 Privacy settings help
    }

    PBWebViewController *wvc = [[[PBWebViewController alloc] initWithTitle:nil
                                                                 htmlName:htmlName] autorelease];
    
    wvc.showCloseButton = YES;
    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:wvc] autorelease];
    
    PBRootViewController *rootVC = [PBRootViewController sharedController];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [rootVC presentViewController:nc
                         animated:YES
                       completion:^{
                           nc.navigationBar.layer.masksToBounds = YES;
                       }];
}

- (void)dealloc {
    [_contentContainerView release];
    [super dealloc];
}
@end
