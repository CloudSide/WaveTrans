//
//  WeiboCell.h
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "MainTableViewCell.h"

@class EGOImageView;

@interface WeiboCell : MainTableViewCell

@property (nonatomic,retain) IBOutlet EGOImageView *headerImageView;
@property (nonatomic,retain) IBOutlet UILabel *nameLabel;
@property (nonatomic,retain) IBOutlet UILabel *descriptionLabel;

@end
