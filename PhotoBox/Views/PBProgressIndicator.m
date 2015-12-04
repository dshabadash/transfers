//
//  PBProgressIndicator.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBProgressIndicator.h"

const CGFloat kDefaultCornerRadius = 3.0;

@interface PBProgressIndicator () {
    UIImageView *_bgImageView;
    UIImageView *_fgImageView;
}

@end

@implementation PBProgressIndicator

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setup];
}

- (void)setup {
    _bgImageView = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
    _bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_bgImageView];
    
    _fgImageView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
    _bgImageView.backgroundColor = [UIColor darkGrayColor];
    [self addSubview:_fgImageView];
    
    self.progress = 0;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    [_backgroundImage autorelease];
    _backgroundImage = [backgroundImage retain];
    
    _bgImageView.image = backgroundImage;
}

- (void)setProgressImage:(UIImage *)progressImage {
    [_progressImage autorelease];
    _progressImage = [progressImage retain];
    
    _fgImageView.image = progressImage;
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    if (progress > 1) progress = 1;
    if (progress < 0) progress = 0;

    _progress = progress;
    
    CGRect bounds = self.bounds;
    CGSize size = bounds.size;
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    [UIView animateWithDuration:animated ? 0.2 : 0.0
                     animations:^{
                         _fgImageView.frame = CGRectMake(0, 0, width * _progress, height);
                     }];
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

@end

@implementation PBProgressIndicatorRound

- (void)awakeFromNib {
    [super awakeFromNib];

    CGFloat radius = (_cornerRadius) ? [_cornerRadius floatValue] : kDefaultCornerRadius;
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = YES;
}

- (void)dealloc {
    [_cornerRadius release];

    [super dealloc];
}
@end