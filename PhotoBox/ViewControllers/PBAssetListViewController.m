 //
//  PBAssetListViewController.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 16/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import "PBAssetListViewController.h"
#import "PBConnectViewController.h"
#import "PBAssetPreviewCollectionCell.h"
#import "PBAssetManager.h"

static NSString * const cellIdentifier = @"AssetPreviewCell";
static NSString * const footerIdentifier = @"CollectionFooterView";

@interface PBAssetListViewController () <PSTCollectionViewDataSource, PSTCollectionViewDelegate, PSTCollectionViewDelegateFlowLayout>
{
    NSInteger _lastAssetCount;
    PBAssetManager *_assetManager;

    BOOL _willAppearForTheFirstTime;

    NSInteger _selectionStartIndex;
    NSInteger _selectionEndIndex;

    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    CGPoint _dragPoint;

    NSMutableSet *_selectedIndexPaths;

    CGFloat _screenScale;
    
    BOOL _showFooter;

    UIView *_noAssetsView;
    
}

@end

@implementation PBAssetListViewController

- (id)initWithAssetsGroup:(ALAssetsGroup *)group {
    self = [super init];
    if (self) {
        self.assetsGroupUrl = [group valueForProperty:ALAssetsGroupPropertyURL];

        _assetsGroup = [group retain];
        _assetManager = [PBAssetManager sharedManager];

        _selectedIndexPaths = [NSMutableSet new];

        self.title = [_assetsGroup valueForProperty:ALAssetsGroupPropertyName];

        self.showTopToolbar = YES;
        self.topBarShadowType = PBViewControllerTopBarShadowTypeBold;

        _selectionStartIndex = -1;
        _selectionEndIndex = -1;

        _screenScale = [[UIScreen mainScreen] scale];
        
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_assetsGroup release];
    [_selectedIndexPaths release];

    _collectionView = nil;
    _cellNibName = nil;
    
    [super dealloc];
}


#pragma mark - Appearence

+ (UIColor *)collectionViewBackgroundColor {
    return [UIColor colorWithRed:0.98f green:0.96f blue:0.93f alpha:1.00f];
}

+ (UIView *)noAssetsViewWithRect:(CGRect)rect {
    return nil;
}

+ (UIBarButtonItem *)sendBarButtonItemTarget:(id)target action:(SEL)action {
    UIBarButtonItem *sendButton =
        [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"")
            style:UIBarButtonItemStyleDone
            target:target
            action:action]
        autorelease];

    return sendButton;
}

- (PSTCollectionView *)collectionViewWithFrame:(CGRect)frame layout:(PSTCollectionViewLayout *)layout {

    PSTCollectionView *collectionView =
        [[[PSTCollectionView alloc]
            initWithFrame:frame
            collectionViewLayout:layout]
        autorelease];

    collectionView.allowsMultipleSelection = YES;
    
    collectionView.alwaysBounceVertical = YES;
    collectionView.backgroundColor = [[self class] collectionViewBackgroundColor];
    collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    collectionView.contentMode = UIViewContentModeBottom | UIViewContentModeTop;


    collectionView.dataSource = self;
    collectionView.delegate = self;

    _longPressGestureRecognizer =
        [[[UILongPressGestureRecognizer alloc]
            initWithTarget:self
            action:@selector(handleLongPressGesture:)]
        autorelease];

    [collectionView addGestureRecognizer:_longPressGestureRecognizer];

    return collectionView;
}

- (PSTCollectionViewFlowLayout *)collectionViewLayout {
    PSTCollectionViewFlowLayout *collectionViewLayout = [[[PSTCollectionViewFlowLayout alloc] init] autorelease];
    collectionViewLayout.itemSize = CGSizeMake(70, 70);
    collectionViewLayout.minimumLineSpacing = 8;
    collectionViewLayout.minimumInteritemSpacing = 5;
    collectionViewLayout.sectionInset = UIEdgeInsetsMake(6, 12, 6, 12);

    
    return collectionViewLayout;
}

- (UINib *)collectionViewCellNib {
    UINib *nib = [UINib nibWithNibName:@"PBAssetPreviewCollectionCell" bundle:[NSBundle mainBundle]];

    return nib;
}


#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect frame = self.view.bounds;
    
    frame.origin.y -= [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 12.0 : 20.0;
    frame.size.height -= 88.0;
    _collectionView = [self collectionViewWithFrame:frame
                                             layout:[self collectionViewLayout]];
    
    UINib *collectionViewCellNib = [self collectionViewCellNib];
    [_collectionView registerNib:collectionViewCellNib
        forCellWithReuseIdentifier:cellIdentifier];
    
    [self.view addSubview:_collectionView];
    self.view.backgroundColor = _collectionView.backgroundColor;

    _noAssetsView = [[self class] noAssetsViewWithRect:_collectionView.bounds];
    [self.view insertSubview:_noAssetsView aboveSubview:_collectionView];
    [_noAssetsView setFrame:_collectionView.frame];
    [_noAssetsView setHidden:YES];

    
    [self.view insertSubview:_noAssetsView aboveSubview:_collectionView];
    

    self.toolbarItems = @[ [[[UIBarButtonItem alloc] initWithCustomView:[[UIView new] autorelease]] autorelease] ];
    self.navigationItem.rightBarButtonItem =
        [[self class] sendBarButtonItemTarget:self
                                       action:@selector(sendButtonTapped:)];
 

    _showFooter = _assetManager.isImportAssetInProgress;
    _willAppearForTheFirstTime = YES;

    [self registerOnNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:NO animated:animated];

    if (_willAppearForTheFirstTime) {
        [self scrollToBottom];
        _willAppearForTheFirstTime = NO;
    }

    [self updateSendButtonState];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    //Temporarily disabled
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self showMultiselectionTip];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [_noAssetsView setFrame:_collectionView.frame];
}

- (void)scrollToBottom {
    NSInteger numberOfAssets = _assetsGroup.numberOfAssets;
    if (numberOfAssets > 1) {
        NSIndexPath *lastItemIndexPath = [NSIndexPath indexPathForItem:numberOfAssets - 1
                                                             inSection:0];
        [_collectionView scrollToItemAtIndexPath:lastItemIndexPath
                                atScrollPosition:PSTCollectionViewScrollPositionTop
                                        animated:NO];
    }
}

- (void)scrollToAsset:(ALAsset *)asset {
    if (asset == nil) {
        return;
    }

    NSURL *assetUrl = asset.defaultRepresentation.url;
    
    [_assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if ([result.defaultRepresentation.url isEqual:assetUrl]) {
            *stop = YES;

            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [_collectionView scrollToItemAtIndexPath:indexPath
                                        atScrollPosition:PSTCollectionViewScrollPositionCenteredVertically
                                                animated:NO];

                [self performSelector:@selector(bounceCellAtIndexPath:)
                           withObject:indexPath
                           afterDelay:0.1];
            });
        }
    }];
   
}

- (void)bounceCellAtIndexPath:(NSIndexPath *)indexPath {
    PSTCollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];

    NSTimeInterval animationDuration = 0.15;
    CGFloat bounceScale = 1.15;

    [UIView animateWithDuration:animationDuration
                     animations:^{
                         cell.transform = CGAffineTransformMakeScale(bounceScale, bounceScale);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:animationDuration
                                          animations:^{
                                              cell.transform = CGAffineTransformIdentity;
                                          }];
                     }];

}

- (void)updateSendButtonState {
    self.navigationItem.rightBarButtonItem.enabled = [[PBAssetManager sharedManager] assetCount] != 0;
}

- (void)showMultiselectionTip {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPBDontShowMultiselectionHint]) {
        return;
    }

    [[PBRootViewController sharedController] presentMultiselectionTipView];
}

- (void)registerOnNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(reloadAssets)
                               name:ALAssetsLibraryChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(reloadAssets)
                               name:PBAssetManagerDidGetAccessToAssetsLibraryNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(reloadAssets)
                               name:kPBImportAssetsFinishedNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(updateSendButtonState)
                               name:PBAssetManagerDidAddAssetNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(updateSendButtonState)
                               name:PBAssetManagerDidRemoveAssetNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(updateSendButtonState)
                               name:PBAssetManagerDidRemoveAllAssetsNotification
                             object:nil];
}


#pragma mark - Assets

- (void)reloadAssets {
    BOOL isImportAssetInProgress = _assetManager.isImportAssetInProgress;
    
//    if (_showFooter == isImportAssetInProgress) {
//        return;
//    }

    _showFooter = isImportAssetInProgress;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_assetsGroup autorelease];
        _assetsGroup = [[_assetManager groupForUrl:_assetsGroupUrl] retain];

        if (_lastAssetCount != _assetsGroup.numberOfAssets) {
            [_collectionView reloadData];
        }
    });
}


#pragma mark - Actions

- (void)sendButtonTapped:(id)sender {
    [[PBAppDelegate sharedDelegate] presentConnectViewControllerInNavigationController:self.navigationController];
}

- (void)cancel {
    [self setAssetsGroupUrl:nil];
}


#pragma mark - Gestures

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    UIGestureRecognizerState state = gestureRecognizer.state;
    CGPoint point = [gestureRecognizer locationInView:_collectionView];
    NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];

    if (state == UIGestureRecognizerStateBegan) {
//        NSLog(@"Start");

        if (indexPath) {
            _selectionStartIndex = indexPath.item;
            _selectionEndIndex = indexPath.item;
            [self preselectItems];
        } else {
            gestureRecognizer.enabled = NO;
            gestureRecognizer.enabled = YES;
            return;
        }
    } else if (state == UIGestureRecognizerStateChanged) {
//        NSLog(@"Changed");
        if (indexPath) {
            _selectionEndIndex = indexPath.item;
        }
        _dragPoint = point;
        [self scrollToDragPoint];
        [self preselectItems];
    } else if (state == UIGestureRecognizerStateEnded) {
//        NSLog(@"Ended");
        if (indexPath) {
            _selectionEndIndex = indexPath.item;
        }
        _dragPoint = CGPointZero;
//        [self preg];
        [self selectItems];

        _selectionStartIndex = -1;
        _selectionEndIndex = -1;
    }
}

- (void)scrollToDragPoint {
    CGPoint contentOffset = _collectionView.contentOffset;
    CGFloat y = _dragPoint.y - contentOffset.y;
    if (y == 0) {
        return;
    }

    CGFloat h = _collectionView.bounds.size.height;
    CGFloat mid = round(h / 2.0);

    CGFloat delta = (y - mid) * 0.1;

    //the dead (non-scrolling zone)
    if (fabs(delta) < 3) {
        delta = 0;
    } else {
        float coef = fabs(delta) / delta;
        delta -= coef * 3;
    }

//    NSLog(@"Delta = %f, mid = %f, y = %f", delta, mid, y);


    CGFloat newContentOffsetY = contentOffset.y + delta;
    if (newContentOffsetY >= 0 && newContentOffsetY < _collectionView.contentSize.height-h) {
        contentOffset.y = newContentOffsetY;
        _collectionView.contentOffset = contentOffset;
    }

}

- (void)preselectItems {
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
        PSTCollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
        cell.selected = [self isCellSelectedAtIndexPath:indexPath];
    }
}

- (void)selectItems {
    NSInteger start = MIN(_selectionStartIndex, _selectionEndIndex);
    NSInteger end = MAX(_selectionStartIndex, _selectionEndIndex);


    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, end-start+1)];
    [_assetsGroup enumerateAssetsAtIndexes:indexSet
                                   options:0
                                usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                    if (result) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [_assetManager addAsset:result];

                                            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                                            [_selectedIndexPaths addObject:indexPath];

                                            [_assetManager setGroup:_assetsGroup
                                                        forAssetUrl:result.defaultRepresentation.url];
                                        });
                                    }
                                }];

    //analytics
    NSInteger itemCount = end-start+1;
    NSString *itemCountStr = [NSString stringWithInteger:itemCount];
    [[CBAnalyticsManager sharedManager] logEvent:@"assetMultiselectionGesture"
                                  withParameters:@{ @"itemCount":itemCountStr }];
}


#pragma mark - CollectionView

- (NSInteger)collectionView:(PSTCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfAssets = _assetsGroup.numberOfAssets;
    
    _lastAssetCount = numberOfAssets;

    [_noAssetsView setHidden:(_assetsGroup.numberOfAssets > 0)];

    return numberOfAssets;
}

- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PBAssetPreviewCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSAssert(cell, @"No cell");

    [cell setImage:nil];
    [cell setDeleted:YES];
    
    ALAssetsGroup *assetsGroup = _assetsGroup;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.row];
        
        [assetsGroup enumerateAssetsAtIndexes:indexSet
            options:0
            usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
               if (result) {
                   CGImageRef cgThumb = _aspectThumbnail ? result.aspectRatioThumbnail
                                                         : result.thumbnail;
                   
                   UIImage *thumbnail = [UIImage imageWithCGImage:cgThumb
                                                            scale:_screenScale
                                                      orientation:UIImageOrientationUp];
                   
                   BOOL isVideo = [result valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo;
                   NSTimeInterval duration = isVideo ? [[result valueForProperty:ALAssetPropertyDuration] doubleValue] : 0.0;

                   dispatch_async(dispatch_get_main_queue(), ^{
                       PBAssetPreviewCollectionCell *cellToUpdate =
                           (PBAssetPreviewCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];

                       [cellToUpdate setImage:thumbnail];
                       [cellToUpdate setDeleted:NO];
                       cellToUpdate.isVideo = isVideo;

                       if (isVideo) {
                           [cellToUpdate setDuration:duration];
                       }

                       BOOL withinSelectionRange = [self isCellSelectedAtIndexPath:indexPath];
                       BOOL assetSelected = [_assetManager hasAsset:result];

                       if (assetSelected) {
                           [_selectedIndexPaths addObject:indexPath];
                       }

                       cellToUpdate.selected = (withinSelectionRange || assetSelected);
                       cellToUpdate.imageName = result.defaultRepresentation.filename;
                   });
               }
            }];
    });

    return cell;
}

- (void)collectionView:(PSTCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self toggleItemAtIndexPath:indexPath];
}

- (void)collectionView:(PSTCollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self toggleItemAtIndexPath:indexPath];
}

- (void)toggleItemAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.row];
    ALAssetsGroup *assetsGroup = _assetsGroup;

    [assetsGroup enumerateAssetsAtIndexes:indexSet
                                   options:0
                                usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                    if (result) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            BOOL selecting = [_selectedIndexPaths member:indexPath] == nil;
                                            if (selecting) {
                                                //okay, not in selected list, but let's check if it was previously selected in another VC
                                                if ([_assetManager hasAsset:result]) {
                                                    [_selectedIndexPaths addObject:indexPath];
                                                    selecting = NO;
                                                }
                                            }

                                            if (selecting) {
                                                [_assetManager addAsset:result];
                                                [_selectedIndexPaths addObject:indexPath];
                                                NSURL *assetUrl = result.defaultRepresentation.url;
                                                [_assetManager setGroup:assetsGroup forAssetUrl:assetUrl];
                                            } else {
                                                [_assetManager removeAsset:result];

                                                id objectToRemove = [_selectedIndexPaths member:indexPath];
                                                if (objectToRemove) {
                                                    [_selectedIndexPaths removeObject:objectToRemove];
                                                }
                                            }

                                            PSTCollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
                                            cell.selected = selecting;
                                        });
                                    }
                                }];

}

- (CGSize)collectionView:(PSTCollectionView *)collectionView
    layout:(PSTCollectionViewLayout *)collectionViewLayout
    referenceSizeForFooterInSection:(NSInteger)section {

    return _showFooter ? CGSizeMake(0, 60) : CGSizeZero;
}

- (PSTCollectionReusableView *)collectionView:(UICollectionView *)collectionView
    viewForSupplementaryElementOfKind:(NSString *)kind
    atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:footerIdentifier
                                                                           forIndexPath:indexPath];
    

    return ((PSTCollectionReusableView *)cell);
}

- (BOOL)isCellSelectedAtIndexPath:(NSIndexPath *)indexPath {
    BOOL wasSelected = [_selectedIndexPaths member:indexPath] != nil;

    NSInteger index = indexPath.item;
    NSInteger multiSelectionStart = MIN(_selectionStartIndex, _selectionEndIndex);
    NSInteger multiSelectionEnd = MAX(_selectionStartIndex, _selectionEndIndex);
    BOOL withinMultiselectionRange = (index >= multiSelectionStart && index <= multiSelectionEnd);


    return (wasSelected || withinMultiselectionRange);
}


#pragma mark - Properties

- (ALAssetsGroup *)assetsGroup {
    return _assetsGroup;
}

- (void)setAssetsGroupUrl:(NSURL *)assetsGroupUrl {
    if ([assetsGroupUrl isEqual:_assetsGroupUrl] == NO) {
        if (assetsGroupUrl == nil) {
            assetsGroupUrl = [_assetManager savedPhotosAssetsGroupUrl];
        }
        
        [_assetsGroupUrl autorelease];
        _assetsGroupUrl = [assetsGroupUrl copy];
        
        _selectionStartIndex = -1;
        _selectionEndIndex = -1;
        [_selectedIndexPaths removeAllObjects];
        

        [_assetsGroup autorelease];
        _assetsGroup = [[_assetManager groupForUrl:_assetsGroupUrl] retain];
        
        self.title = [_assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        
        if (self.isViewLoaded) {
            [_collectionView reloadData];
            [self scrollToBottom];
        }
    }
}

@end
