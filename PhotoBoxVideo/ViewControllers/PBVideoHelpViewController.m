//
//  PBVideoHelpViewController.m
//  PhotoBox
//
//  Created by Viacheslav Savchenko on 5/27/13.
//  Copyright (c) 2013 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBVideoHelpViewController.h"
#import "PBSubscribeViewController.h"
#import "PBWebViewController.h"
#import "PBPurchaseManager.h"
#import <DropboxSDK/DropboxSDK.h>

@interface PBVideoHelpViewController ()

@end

@implementation PBVideoHelpViewController

+ (NSString *)shareThisAppText {
    return NSLocalizedString(@"Video Transfer, the easiest and fastest way to send and receive photos on your iPhone", @"Text for emails and social networks post");
}

+ (UITableView *)tableViewWithFrame:(CGRect)frame {
    UITableView *tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped] autorelease];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.backgroundColor = [UIColor colorWithRGB:0xf2f2f2];
    tableView.backgroundView = [[UIView new] autorelease];
    tableView.backgroundView.backgroundColor = tableView.backgroundColor;
    tableView.separatorColor = [UIColor defaultTableViewSeparatorColor];
    
    return tableView;
}

+ (NSArray *)tableViewCells {
    NSMutableArray *cells = [NSMutableArray arrayWithCapacity:0];

    //1st section
    {
        NSMutableArray *section = [NSMutableArray array];
        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Troubleshooting", @"")
                                                           image:[UIImage imageNamed:@"troubleshooting_icon"]
                                                          action:@selector(troubleshootingCellSelected)]];

        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Support", @"")
                                                           image:[UIImage imageNamed:@"support_icon"]
                                                          action:@selector(supportCellSelected)]];

#if PB_LITE
        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Restore purchases", @"")
                                                           image:[UIImage imageNamed:@"restore_icon"]
                                                          action:@selector(restorePurchasesCellSelected)]];
#endif

        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Register Video Transfer", @"")
                                                           image:[UIImage imageNamed:@"news_icon"]
                                                          action:@selector(subscribeToNewsCellSelected)]];
        

        [cells addObject:section];
    }

    //2nd section
    {
        NSMutableArray *section = [NSMutableArray array];
        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Rate This App", @"")
                                                           image:[UIImage imageNamed:@"rate_app_icon"]
                                                          action:@selector(rateThisAppCellSelected)]];

        if (PBGetSystemVersion() >= 6.0) {
            [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Share via Facebook", @"")
                                                               image:[UIImage imageNamed:@"fcebook_icon"]
                                                              action:@selector(shareFacebookCellSelected)]];
        }

        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Share via Twitter", @"")
                                                           image:[UIImage imageNamed:@"twitter_icon"]
                                                          action:@selector(shareTwitterCellSelected)]];

        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Share via Email", @"")
                                                           image:[UIImage imageNamed:@"mail_icon"]
                                                          action:@selector(shareEmailCellSelected)]];

        [cells addObject:section];
    }

    //3rd section
    {
        NSMutableArray *section = [NSMutableArray array];
        [section addObject:[[self class] cellDictionaryWithTitle:[[DBSession sharedSession] isLinked] ? [NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"Dropbox"] : [NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"Dropbox"]
                                                           image:[UIImage imageNamed:@"icon_dropbox"]
                                                          action:@selector(dropboxLoggingStuff)]];
        [section addObject:[[self class] cellDictionaryWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"GoogleDrive"]
                                                           image:[UIImage imageNamed:@"icon_google"]
                                                          action:@selector(googleDriveLoggingStuff)]];
        BOOL hasAuthToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"FlickrOAuthToken"] && [[NSUserDefaults standardUserDefaults] objectForKey:@"FlickrOAuthTokenSecret"];
        [section addObject:[[self class] cellDictionaryWithTitle:hasAuthToken ? [NSString stringWithFormat:NSLocalizedString(@"Logout from %@", @""), @"Flickr"] : [NSString stringWithFormat:NSLocalizedString(@"Login to %@", @""), @"Flickr"]
                                                           image:[UIImage imageNamed:@"icon_flickr"]
                                                          action:@selector(flickrLoggingStuff)]];
        [cells addObject:section];
    }
    
    //4rd section
    {
        NSMutableArray *section = [NSMutableArray array];
        [section addObject:[[self class] cellDictionaryWithTitle:NSLocalizedString(@"Legal Notes", @"")
                                                           image:[UIImage imageNamed:@"legal_notes_icon"]
                                                          action:@selector(legalNotesCellSelected)]];
        [cells addObject:section];
    }

    //    //4th section
    //    {
    //        NSMutableArray *section = [NSMutableArray array];
    //        [section addObject:[self cellDictionaryWithTitle:<#(NSString *)#>
    //                                                   image:[UIImage imageNamed:<#(NSString *)#>]
    //                                                  action:@selector(<#selector#>)]];
    //        [_sections addObject:section];
    //    }
    
    return cells;
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    // Hide navigation bar shadow
    self.navigationController.navigationBar.layer.masksToBounds = YES;
}


#pragma mark - Events handling

- (void)subscribeToNewsCellSelected {
    PBSubscribeViewController *vc = [[PBSubscribeViewController new] autorelease];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self presentChildViewController:vc];
    }
    else {
        [self presentViewController:vc
                           animated:YES
                         completion:nil];
    }

    //analytics
    NSDictionary *params = @{@"item" : @"registerApp"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)troubleshootingCellSelected {
    PBWebViewController *wvc = [[[PBWebViewController alloc] initWithTitle:nil htmlName:@"troubleshooting"] autorelease];
    [self presentChildViewController:wvc hideNavigationBar:NO];

    //analytics
    NSDictionary *params = @{ @"item" : @"troubleshooting"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}

- (void)legalNotesCellSelected {
    PBWebViewController *wvc = [[[PBWebViewController alloc] initWithTitle:@"Legal Notes" htmlName:@"legal"] autorelease];
    [self presentChildViewController:wvc hideNavigationBar:NO];

    //analytics
    NSDictionary *params = @{@"item" : @"legalNotes"};
    [[CBAnalyticsManager sharedManager] logEvent:@"helpVcItemSelected" withParameters:params];
}


#pragma mark - UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 36.0 : 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0];

    CGSize titleSize = [title sizeWithFont:font
                                  forWidth:tableView.bounds.size.width
                             lineBreakMode:NSLineBreakByTruncatingTail];

    CGFloat headerHeight = [self tableView:tableView heightForHeaderInSection:section];

    CGFloat paddingLeft = 32.0;
    CGFloat paddingBottom = 5.0;

    CGRect frame = CGRectMake(paddingLeft,
                              headerHeight - titleSize.height - paddingBottom,
                              tableView.bounds.size.width - titleSize.width - paddingBottom,
                              titleSize.height);

    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    label.text = title;
    label.backgroundColor = [UIColor clearColor];
    label.font = font;
    label.textColor = [UIColor colorWithRGB:0x696969];
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0, 1.0);

    CGRect viewFrame = CGRectMake(0, 0, tableView.bounds.size.width, headerHeight);
    UIView *headerView = [[[UIView alloc] initWithFrame:viewFrame] autorelease];
    headerView.backgroundColor = [UIColor clearColor];
    [headerView addSubview:label];


    return headerView;
}


@end
