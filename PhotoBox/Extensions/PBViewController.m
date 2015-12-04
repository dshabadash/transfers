//
//  PBViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 09/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBViewController.h"
#import "PBNavigationController.h"

@interface PBViewController () {
    UIView *_originalView;
}

@end

@implementation PBViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSString *className = NSStringFromClass([self class]);
    static NSString *deviceSuffix = @"";
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            deviceSuffix = @"-ipad";
        } else {
            if (PBDeviceIs4InchPhone()) {
                deviceSuffix = @"-568phone";
            }
        }
        
        [deviceSuffix retain];
    });
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *nibName = [className stringByAppendingString:deviceSuffix];
    if (![bundle pathForResource:nibName ofType:@"nib"]) {
        nibName = className;
        if (![bundle pathForResource:nibName ofType:@"nib"]) {
            nibName = nil;
        }
    }

    
    self = [super initWithNibName:nibName bundle:nibBundleOrNil];
    if (self) {
        //custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self replaceView];
}

- (void)replaceView {
    if (_showTopToolbar) {
        BOOL shouldSetOriginalView = _originalView == nil;
        
        if (shouldSetOriginalView) {
            _originalView = [self.view retain];
            self.view = [[[UIView alloc] initWithFrame:_originalView.frame] autorelease];
            
            self.view.backgroundColor = _originalView.backgroundColor;
        }
        
        CGFloat topToolbarHeight = 0;
        UINavigationController *nc = self.navigationController;
        if ([nc isKindOfClass:[PBNavigationController class]]) {
            PBNavigationController *pnc = (PBNavigationController *)nc;
            topToolbarHeight = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 54.0 : 10.0; //pnc.topToolBar.bounds.size.height;
        }
        
        _originalView.frame = CGRectMake(_originalView.frame.origin.x, self.view.frame.origin.y + topToolbarHeight,
                                         _originalView.frame.size.width, self.view.frame.size.height - topToolbarHeight);

        if (shouldSetOriginalView) {
            [self.view addSubview:_originalView];
            [_originalView release];
        }
    }

}

+ (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return YES;
    }
    
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return [PBViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

@end
