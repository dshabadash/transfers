//
//  PBProgressIndicator.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 12/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBProgressIndicator : UIView

@property (retain, nonatomic) UIImage *backgroundImage;
@property (retain, nonatomic) UIImage *progressImage;

@property (assign, nonatomic) CGFloat progress;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;


@end

@interface PBProgressIndicatorRound : PBProgressIndicator

@property (nonatomic, strong) NSNumber *cornerRadius;

@end