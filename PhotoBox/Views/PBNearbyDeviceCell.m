//
//  PBNearbyDeviceCell.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/13/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import "PBNearbyDeviceCell.h"

@implementation PBNearbyDeviceCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupAppearence];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (nil != self) {
        [self setupAppearence];
    }

    return self;
}

- (void)setupAppearence {
    self.backgroundColor = [UIColor defaultTableViewCellBackgroundColor];
    self.textLabel.textColor = [UIColor defaultTextColor];
    self.textLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.3];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.textLabel.font = [UIFont boldSystemFontOfSize:20];
    }
}

@end
