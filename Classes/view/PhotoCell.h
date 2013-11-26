//
//  PhotoCell.h
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "MainTableViewCell.h"

@class EGOImageView;

@interface PhotoCell : MainTableViewCell


@property (nonatomic,retain) IBOutlet EGOImageView *photoImageView;
@end
