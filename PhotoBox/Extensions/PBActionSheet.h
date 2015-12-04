//
//  PBActionSheet.h
//  PhotoBox
//
//  Created by Andrew Kosovich on 08/12/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PBActionSheetDelegate;

@interface PBActionSheet : UIActionSheet<UIActionSheetDelegate> {
	id                                  userInfo;
	NSMutableArray                      *selectorsArray;
	NSObject<PBActionSheetDelegate>     *pbActionSheetDelegate;
}

- (id)initWithTitle:(NSString *)title delegate:(NSObject<PBActionSheetDelegate> *)delegate;
- (void)addButtonWithTitle:(NSString *)title action:(SEL)action;
+ (void)cancelAllActionSheets;
@property (nonatomic, retain) id userInfo;
@end

@protocol PBActionSheetDelegate
@optional
- (void)willShowPBActionSheet:(PBActionSheet *)actionSheet;
- (void)willHidePBActionSheet:(PBActionSheet *)actionSheet;
@end

