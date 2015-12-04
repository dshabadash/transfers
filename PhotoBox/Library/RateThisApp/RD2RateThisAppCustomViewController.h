//
//  RD2RateThisAppCustomViewController.h
//  rgCalendar
//
//  Created by Viktor Gedzenko on 3/20/13.
//  Modified by Viacheslav Savchenko on 5/20/13.
//
//

#import <UIKit/UIKit.h>
#import "RD2RateThisAppModel.h"
#import "PBVideoModalControllerFormSheetView.h"

@protocol RD2RateThisAppCustomViewControllerDelegate;

@interface RD2RateThisAppCustomViewController : UIViewController
@property (assign) id<RD2RateThisAppCustomViewControllerDelegate> delegate;
- (IBAction)rateThisAppButtonTapped:(id)sender;
- (IBAction)laterButtonTapped:(id)sender;
- (IBAction)closeButtonTapped:(id)sender;
@end

@protocol RD2RateThisAppCustomViewControllerDelegate<NSObject>
- (void)rateThisAppViewController:(RD2RateThisAppCustomViewController *)rtaViewController
            didFinishedWithResult:(RTARequestResult)result;

@end


#pragma mark - PBVideoRD2RateThisAppCustomView class

@interface PBVideoRD2RateThisAppCustomView : PBVideoModalControllerFormSheetView
@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@end
