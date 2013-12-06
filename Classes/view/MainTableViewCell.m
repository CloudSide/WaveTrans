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
    
    
    CGFloat offsetX = 0;
    UIColor *statusColor;
    if (metadata.isReceived) {
        offsetX = -4;
        statusColor = RECEIVED_VIEW_COLOR;//[UIColor greenColor];
        self.receiveState.text = @"received";
    }else{
        offsetX = 4;
        statusColor = CREATED_VIEW_COLOR;//[UIColor blueColor];
        self.receiveState.text = @"created";
    }
    
    UIView *statusView = [self.contentView viewWithTag:999];
    if (!statusView) {
        statusView = [[[UIView alloc] init] autorelease];
        statusView.tag = 999;
        //        [self.contentView addSubview:statusView];
        [self.contentView insertSubview:statusView belowSubview:self.sepraterView];
        
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(-offsetX/2, 0, ABS(offsetX), self.frame.size.height);
        layer.shadowOffset = offsetX>0?CGSizeMake(-1, 0):CGSizeMake(1, 0);
        layer.shadowColor = [[UIColor blackColor] CGColor];
        layer.shadowRadius = 4.0f;
        layer.shadowOpacity = 0.80f;
        layer.shadowPath = [[UIBezierPath bezierPathWithRect:layer.bounds] CGPath];
        
        [statusView.layer addSublayer:layer];
        
    }
    statusView.frame = CGRectMake(offsetX>0?0:(self.bounds.size.width + offsetX), 0, ABS(offsetX), self.bounds.size.height);
    statusView.backgroundColor = statusColor;
    
    
    [self initViews];
    
}

-(void)awakeFromNib
{
    [self.sendBeepBtn setExclusiveTouch:YES];
    self.receiveState.text = @"created";
    
    self.clipsToBounds = YES;
    self.contentView.clipsToBounds = YES;
    
//    self.contentView.frame = CGRectMake(70, 0, self.bounds.size.width - 10, self.bounds.size.height);
}

#pragma mark - private method
-(void)initViews
{
    self.sepraterView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tableview_sep_line"]];
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    
    [formatter setDateFormat:@"HH:mm:ss"];//y-MM-dd HH:mm:ss
    
    self.createDateLabel.text = [formatter stringFromDate:self.metadata.ctime];
    self.fileNameLabel.text = self.metadata.filename;
    [self.sendBeepBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.sendBeepBtn addTarget:self action:@selector(sendBeepAction:) forControlEvents:UIControlEventTouchUpInside];
    
    
    if ([self.metadata.type isEqualToString:@"file"]) {

        if ((self.metadata.hasCache && !self.metadata.uploaded) || (!self.metadata.hasCache && self.metadata.uploaded)) {
            self.progressView.hidden = NO;
            self.progressView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        }else{
            self.progressView.hidden = YES;
        }
    }else{
        if (!self.metadata.uploaded) {
            self.progressView.hidden = NO;
            self.progressView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        }else{
            self.progressView.hidden = YES;
        }
    }
    
//    self.progressView.hidden = YES;
    
    if ([self getProgressLayer]==nil)
        [self initProgressView];
    
    
    self.sendBeepBtn.enabled = self.progressView.hidden;

}

-(void)sendBeepAction:(id)sender
{
    //TODO:send beep
    
    if ([self.delegate respondsToSelector:@selector(playWithMetadata:)]) {
        
        
        [self.delegate performSelector:@selector(playWithMetadata:) withObject:self.metadata];
    }
}

-(CALayer *)getProgressLayer{
    
    for (CALayer *layer in [self.progressView.layer sublayers]) {
        if ([layer.name isEqualToString:@"progressLayer"]) {
            return layer;
        }
    }
    
    return nil;
}

-(void)initProgressView
{
    if ([self getProgressLayer] == nil) {
        self.progressView.userInteractionEnabled = YES;
        self.progressView.backgroundColor = [UIColor clearColor];
        self.progressView.alpha = 1;
        CALayer *layer = [CALayer layer];
        layer.frame = self.progressView.bounds;
        layer.name = @"progressLayer";
        layer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor;
        [self.progressView.layer addSublayer:layer];
    }
}

-(void)setDownloadProgress:(CGFloat)downloadProgress
{
    _downloadProgress = downloadProgress;
    
    CALayer *layer = [self getProgressLayer];
    
    if (layer==nil)
        [self initProgressView];
    
    CGRect frame = layer.frame;
    frame.size.width = self.frame.size.width * (1-downloadProgress);
    frame.origin.x = self.progressView.frame.size.width - frame.size.width;
    layer.frame = frame;
    
    if (downloadProgress==0) {
        self.progressView.hidden = YES;
    }else{
        self.progressView.hidden = NO;
    }
    
    self.sendBeepBtn.enabled = self.progressView.hidden;

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

#pragma mark - MainViewControllerDelegate
-(void)updateDownloadProgress:(CGFloat)progress byMetadata:(WaveTransMetadata *)metadata
{
    if ([self.metadata isEqual:metadata]) {
        self.downloadProgress = progress;
    }
}

@end
