//
//  PBNoWiFiView.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBStretchableBackgroundButton.h"

@protocol PBNoWiFiViewDelegate;


@interface PBNoWiFiView : UIView

@property (retain, nonatomic) IBOutlet PBStretchableBackgroundButton *okButton;
@property (nonatomic) BOOL showingWiFiConnectionState;
@property (assign, nonatomic) NSObject<PBNoWiFiViewDelegate> *delegate;

- (void)setNoWiFiAnimation:(BOOL)noWiFiAnimation;

@end

@protocol PBNoWiFiViewDelegate <NSObject>

- (void)noWifiViewDidTapOkButton:(PBNoWiFiView *)noWifiView;

@end
