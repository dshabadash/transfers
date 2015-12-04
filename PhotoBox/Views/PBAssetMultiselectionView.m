//
//  PBAssetMultiselectionView.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 20/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBAssetMultiselectionView.h"

@interface PBAssetMultiselectionView () {
    IBOutlet UILabel *orangeLabel;
}

@end

@implementation PBAssetMultiselectionView

+ (id)view {
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self)
                                         owner:nil
                                       options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    orangeLabel.textColor = [UIColor colorWithRed:1.00f green:0.51f blue:0.27f alpha:1.00f];

}

- (void)dismiss {
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                     }];
}

#pragma mark - Actions

- (IBAction)closeButtonTapped:(id)sender {
    [self dismiss];
}

- (IBAction)neverShowAgainButtonTapped:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPBDontShowMultiselectionHint];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismiss];
}


- (void)dealloc {
    [orangeLabel release];
    [super dealloc];
}
@end
