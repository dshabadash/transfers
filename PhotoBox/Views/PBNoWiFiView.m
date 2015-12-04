//
//  PBNoWiFiView.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBNoWiFiView.h"

@interface PBNoWiFiView ()

@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIImageView *signalAnimationView;

@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation PBNoWiFiView

- (void)setNoWiFiAnimation:(BOOL)noWiFiAnimation {
    self.showingWiFiConnectionState = noWiFiAnimation;
   
    if (self.showingWiFiConnectionState) {
        
        self.titleLabel.text = [self.titleLabel.text stringByReplacingOccurrencesOfString:@"Internet" withString:@"Wi-Fi"];
        self.textLabel.text = [self.textLabel.text stringByReplacingOccurrencesOfString:@"Internet" withString:@"Wi-Fi"];
        
        
        CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_4);
        _signalAnimationView.transform = transform;
        
        UIImage *frame0 = [UIImage imgNamed:@"transfer_animation_wifi_clean"];
        UIImage *frame1 = [UIImage imgNamed:@"transfer_animation_wifi_1"];
        UIImage *frame2 = [UIImage imgNamed:@"transfer_animation_wifi_2"];
        UIImage *frame3 = [UIImage imgNamed:@"transfer_animation_wifi_3"];
        _signalAnimationView.animationImages = @[frame0, frame1, frame2, frame3];
        _signalAnimationView.animationDuration = 1.6;
    }
    else {
        self.titleLabel.text = [self.titleLabel.text stringByReplacingOccurrencesOfString:@"Wi-Fi" withString:@"Internet"];
        self.textLabel.text = [self.textLabel.text stringByReplacingOccurrencesOfString:@"Wi-Fi" withString:@"Internet"];
        
        UIImage *frame0 = [UIImage imgNamed:@"offline_screen1"];
        UIImage *frame1 = [UIImage imgNamed:@"offline_screen2"];
        _signalAnimationView.animationImages = @[frame0, frame1];
        _signalAnimationView.animationDuration = 1.0;
        
    }
    [_signalAnimationView startAnimating];
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.center = self.center;
    } else {
        _containerView.backgroundColor = [UIColor clearColor];
        if (!PBDeviceIs4InchPhone()) {
            _containerView.center = self.center;
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc {
    [_textLabel release];
    [_titleLabel release];
    [_containerView release];
    [_okButton release];
    [_signalAnimationView release];
    [super dealloc];
}

#pragma mark - Actions

- (IBAction)okButtonTapped:(id)sender {
    [_delegate noWifiViewDidTapOkButton:self];
}


@end
