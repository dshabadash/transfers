//
//  PBVideoModalControllerFormSheetView.h
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/28/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBVideoModalControllerFormSheetView : UIView
- (void)customizeAppearence;
@end

@interface PBVideoModalViewNavigationBar : UINavigationBar
+ (UIColor *)tintColor;
+ (UIImage *)backgroundImage;
+ (NSDictionary *)titleAttributes;
@end

