//
//  PBToolbar.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 11/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBToolbar.h"
#import "PBRootViewController.h"

@interface PBToolbar () {
    UIButton *_button;
    UIButton *_helpButton;
}

@end

@implementation PBToolbar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (nil != self) {
        _button = [[[UIButton alloc] initWithFrame:self.bounds] autorelease];
        _button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_button];
        
        _button.backgroundColor = [UIColor redColor];
        _button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        
        [_button addTarget:self
            action:@selector(buttonTapped)
            forControlEvents:UIControlEventTouchDown];

        _helpButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)] autorelease];
        [_helpButton setTitle:@"?" forState:UIControlStateNormal];
        [_helpButton setTitleColor:[UIColor colorWithRGB:0x505050]
                          forState:UIControlStateNormal];

        [_helpButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.3] forState:UIControlStateNormal];
        [_helpButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        _helpButton.titleLabel.font = [UIFont boldSystemFontOfSize:26];
        [_helpButton addTarget:[PBRootViewController sharedController]
            action:@selector(presentHelpViewController)
            forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:_helpButton];

        if (PBGetSystemVersion() < 6.0) {
            CALayer *layer = [self layer];
            layer.shadowOffset = CGSizeMake(0, 1);
            layer.shadowColor = [[UIColor darkGrayColor] CGColor];
            layer.shadowRadius = 3.0;
            layer.shadowOpacity = 0.8;
            UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 1024, 44)];
            layer.shadowPath = [shadowPath CGPath];
        }
        
        self.receiveMode = YES;        
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    UIImage *arrowImage = [_button imageForState:UIControlStateNormal];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        CGFloat insetLeft = _button.titleLabel.bounds.size.width * 2.0 + arrowImage.size.width * 2.0 + 3.0;
        [_button setImageEdgeInsets:UIEdgeInsetsMake(3, insetLeft, 0, 0)];
        [_button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    } else {
        CGFloat insetLeft = CGRectGetMaxX(_button.titleLabel.frame) + 3.0;
        [_button setImageEdgeInsets:UIEdgeInsetsMake(3, insetLeft, 0, 0)];
        [_button setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
    }
}

- (void)buttonTapped {
    SEL selector = @selector(toolbarToggleButtonTapped);
    if ([_tapDelegate respondsToSelector:selector]) {
        [_tapDelegate performSelector:selector];
    }
}

- (void)setReceiveMode:(BOOL)receiveMode {
    _receiveMode = receiveMode;
    
    if (receiveMode) {
        _button.backgroundColor = [UIColor clearColor];
        [_button setTitle:NSLocalizedString(@"Receive Photos", @"Receive Photos")
                 forState:UIControlStateNormal];

        [_button setImage:[UIImage imageNamed:@"receive_bottom_bar_arrow_down"]
                 forState:UIControlStateNormal];

        [_button setTitleColor:[UIColor colorWithRGB:0x505050]
                      forState:UIControlStateNormal];

        [_button setBackgroundImage:[UIImage imageNamed:@"receive_bottom_bar_bg"]
                           forState:UIControlStateNormal];
    }
    else {
        _button.backgroundColor = [UIColor colorWithRed:0.99f green:0.50f blue:0.30f alpha:1.00f];
        [_button setTitle:@"Send Photos 💩" forState:UIControlStateNormal];
        [_button setTitleColor:[UIColor whiteColor]
                      forState:UIControlStateNormal];
    }

    [self setNeedsLayout];
}

@end
