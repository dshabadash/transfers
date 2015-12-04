//
//  PBAssetPreviewCollectionCell.m
//  PhotoBox
//
//  Created by Andrew Kosovich on 16/11/2012.
//  Copyright (c) 2012 CapableBits. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PBAssetPreviewCollectionCell.h"

@interface PBAssetPreviewCollectionCell ()
@property (retain, nonatomic) IBOutlet UIImageView *_imageView;
@end

@implementation PBAssetPreviewCollectionCell
@synthesize _imageView;

- (void)awakeFromNib {
    [super awakeFromNib];

    self.backgroundColor = [UIColor clearColor];
    self.selected = NO;
    self.isVideo = NO;
    self.faded = NO;

    CGSize frameSize = _frameImageView.image.size;
    _frameImageView.image =
        [_frameImageView.image stretchableImageWithLeftCapWidth:frameSize.width /2.0
                                                   topCapHeight:frameSize.height /2.0];
    

    frameSize = _frameImageView.highlightedImage.size;
    _frameImageView.highlightedImage =
        [_frameImageView.highlightedImage stretchableImageWithLeftCapWidth:frameSize.width / 2.0
                                                              topCapHeight:frameSize.height / 2.0];
}

- (void)dealloc {
    [_imageView release];
    [_selectedImageView release];
    [_videoIndicatorView release];
    [_frameImageView release];

    [super dealloc];
}


#pragma mark - UIAccessibility protocol

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityValue {
    return _imageName;
}


#pragma mark - Properties

- (void)setImage:(UIImage *)image {
    _imageView.image = image;
}

- (UIImageView *)imageView {
    return _imageView;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (_faded) {
        return;
    }
    
    
    _selectedImageView.hidden = !selected;
    if (selected) {
        _frameImageView.highlighted = NO;
    }
    _imageView.alpha = selected ? 0.4 : 1;
}

- (void)setIsVideo:(BOOL)isVideo {
    _isVideo = isVideo;
    _videoIndicatorView.hidden = !isVideo;
    _durationLabel.hidden = !isVideo;
    _bottomBarBackgroundImage.hidden = !isVideo;
}

- (void)setOrange:(BOOL)orange {
    if (_orange == orange) {
        return;
    }
    
    _orange = orange;
    _frameImageView.highlighted = _orange;
    
}

- (void)setFaded:(BOOL)faded animated:(BOOL)animated {
    if (_faded != faded) {
        _faded = faded;

        [UIView animateWithDuration:animated ? 0.2 : 0.0
                         animations:^{
                             _imageView.alpha = _faded ? 0.2 : 1;
                         }];
    }
}

- (void)setFaded:(BOOL)faded {
    [self setFaded:faded animated:NO];
}

- (void)setDuration:(NSTimeInterval)duration {
    NSTimeInterval left = duration;

    if (nil == _durationLabel) {
        return;
    }

    NSInteger hours = floor(left / 3600.0);
    left = duration - hours * 3600;

    NSInteger minutes = floor(left / 60.0);
    NSInteger seconds = floor(left - minutes * 60.0);

    if (hours > 0) {
        _durationLabel.text = [NSString stringWithFormat:@"%02i:%02i:%02i", (int)hours, (int)minutes, (int)seconds];
    }
    else if (minutes > 0) {
        _durationLabel.text = [NSString stringWithFormat:@"%02i:%02i", (int)minutes, (int)seconds];
    }
    else {
        _durationLabel.text = [NSString stringWithFormat:@"0:%02i", (int)seconds];
    }
}

@end
