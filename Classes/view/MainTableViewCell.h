//
//  MainTableViewCell.h
//  SoundTransform
//
//  Created by hanchao on 13-11-22.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MSCMoreOptionTableViewCell.h"

#import "MainViewController.h"

#define RECEIVED_VIEW_COLOR     [UIColor colorWithRed:0.18f green:0.67f blue:0.84f alpha:1.0f]
#define CREATED_VIEW_COLOR     [UIColor colorWithRed:30/255.0f green:252/255.0f blue:192/255.0f alpha:1.0f]

@class WaveTransMetadata;

//@protocol MainTableViewCellProtocol <NSObject>
//
//@required
//-(void)setMetadata:(WaveTransMetadata *)metadata;
//
//@end

@interface MainTableViewCell : MSCMoreOptionTableViewCell <MainViewControllerDelegate>

@property (nonatomic,retain) WaveTransMetadata *metadata;

@property (nonatomic,assign) CGFloat downloadProgress;

@property (nonatomic,retain) IBOutlet UILabel *fileNameLabel;
@property (nonatomic,retain) IBOutlet UILabel *createDateLabel;
@property (nonatomic,retain) IBOutlet UIButton *sendBeepBtn;
@property (nonatomic,retain) IBOutlet UILabel *receiveState;

@property (nonatomic,retain) IBOutlet UIView *sepraterView;
@property (nonatomic,retain) IBOutlet UIView *progressView;

@end



