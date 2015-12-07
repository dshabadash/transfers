//
//  PBVideoModalControllerFormSheetView.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/28/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBVideoModalControllerFormSheetView.h"

@implementation PBVideoModalControllerFormSheetView

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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.layer.borderWidth = 2.0;
        self.layer.cornerRadius = 4.0;
        self.layer.masksToBounds = YES;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if ((nil != self.superview) &&
        ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {

        self.superview.layer.cornerRadius = 6.0;
        self.superview.layer.masksToBounds = YES;
    }
}


@end

@implementation PBVideoModalViewNavigationBar

+ (UIColor *)tintColor {
    return [UIColor colorWithRGB:0xbdbdbd];
}

+ (UIImage *)backgroundImage {
    return [UIImage imageNamed:@"window_navbar_bg"];
}

+ (NSDictionary *)titleAttributes {
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];

    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [UIColor colorWithRGB:0xd7d7d7];
    shadow.shadowOffset = CGSizeMake(0, 1.0);
    
    NSDictionary *titleAttributes = @{
        NSFontAttributeName : font,
        NSForegroundColorAttributeName : [UIColor colorWithRGB:0x535252],
        NSShadowAttributeName : shadow
    };

    return titleAttributes;
}

@end
