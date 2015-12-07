//
//  UILabel+CB.m
//  Browser
//
//  Created by Andrew Kosovich on 9/17/12.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "UILabel+CB.h"

@implementation UILabel (CB)

- (CGSize)textSize {
    UIFont *font = self.font;
    NSString *text = self.text;

    CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    return textSize;
}

- (void)setupAppearance {
    id labelAppearance = [UILabel appearance];
    
    self.textColor = [labelAppearance textColor];
    self.shadowColor = [labelAppearance shadowColor];
    self.shadowOffset = [labelAppearance shadowOffset];
    self.backgroundColor = [labelAppearance backgroundColor];
}

- (void)setupLabelWithFontOfSize:(CGFloat)fontSize {
    if (fontSize == 0) {
        fontSize = 17;
    }
    
    
    self.font = [UIFont systemFontOfSize:fontSize];
    
    self.textColor = [UIColor colorWithRed:0.38f green:0.36f blue:0.34f alpha:1.00f];
    self.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.shadowOffset = CGSizeMake(0, 1);
}

- (void)setupLabelWithBoldFontOfSize:(CGFloat)fontSize {
    if (fontSize == 0) {
        fontSize = 17;
    }

    self.font = [UIFont boldSystemFontOfSize:fontSize];
    
    self.textColor = [UIColor colorWithRed:0.39f green:0.37f blue:0.35f alpha:1.00f];
    self.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.shadowOffset = CGSizeMake(0, 1);
}

@end
