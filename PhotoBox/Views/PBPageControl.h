//
//  PBPageControl.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 18/01/2013.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PBPageControlDelegate;

@interface PBPageControl : UIView
{
@private
    NSInteger _currentPage;
    NSInteger _numberOfPages;
    UIColor *dotColorCurrentPage;
    UIColor *dotColorOtherPage;
    NSObject<PBPageControlDelegate> *delegate;
}

// Set these to control the PBPageControl.
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) NSInteger numberOfPages;

// Customize these as well as the backgroundColor property.
@property (nonatomic, retain) UIColor *dotColorCurrentPage;
@property (nonatomic, retain) UIColor *dotColorOtherPage;

// Optional delegate for callbacks when user taps a page dot.
@property (nonatomic, assign) NSObject<PBPageControlDelegate> *delegate;

@end

@protocol PBPageControlDelegate<NSObject>
@optional
- (void)PBPageControlPageDidChange:(PBPageControl *)PBPageControl;
@end