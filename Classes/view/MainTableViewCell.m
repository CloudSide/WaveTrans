//
//  MainTableViewCell.m
//  SoundTransform
//
//  Created by hanchao on 13-11-22.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import "MainTableViewCell.h"
#import "WaveTransMetadata.h"

@implementation MainTableViewCell

-(void)setMetadata:(WaveTransMetadata *)metadata
{
    if (self.metadata == metadata) {
        return;
    }
    
    [_metadata release];
    _metadata = [metadata retain];
    
    [self initViews];
    
}

#pragma mark - private method
-(void)initViews
{
    self.sepraterView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tableview_sep_line"]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"HH:mm:ss"];//y-MM-dd HH:mm:ss
    
    self.createDateLabel.text = [formatter stringFromDate:self.metadata.ctime];
    self.fileNameLabel.text = self.metadata.filename;
    [self.sendBeepBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.sendBeepBtn addTarget:self action:@selector(sendBeepAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.metadata.hasCache) {
        self.progressView.hidden = YES;
    }else{
        self.progressView.hidden = NO;
    }
    
    if (!self.metadata.uploaded) {
        self.progressView.hidden = NO;
        self.progressView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    }else{
        self.progressView.hidden = YES;
    }
}

-(void)sendBeepAction:(id)sender
{
    //TODO:send beep
}

-(void)setDownloadProgress:(CGFloat)downloadProgress
{
    _downloadProgress = downloadProgress;
    CGRect frame = self.progressView.frame;
    frame.size.width = self.frame.size.width * (1-downloadProgress);
    self.progressView.frame = frame;
    
    if (frame.size.width == 0) {
        self.progressView.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
//    [super setSelected:selected animated:animated];
//    
//    // Configure the view for the selected state
//    NSLog(@"set cell %d Selected: %d", indexPath.row, selected);
//    if (selected) {
//        _contentLbl.textColor = [UIColor whiteColor];
//    }
//    else {
//        _contentLbl.textColor = [UIColor blackColor];
//    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
//    [super setHighlighted:highlighted animated:animated];
//    
//    NSLog(@"set cell %d highlighted: %d", indexPath.row, highlighted);
//    if (highlighted) {
//        _contentLbl.textColor = [UIColor whiteColor];
//    }
//    else {
//        _contentLbl.textColor = [UIColor blackColor];
//    }
}

-(void)dealloc
{
    self.metadata = nil;
    
    self.fileNameLabel = nil;
    self.createDateLabel = nil;
    self.sendBeepBtn = nil;
    self.receiveState = nil;
    
    self.sepraterView = nil;
    
    
    [super dealloc];
}

@end
