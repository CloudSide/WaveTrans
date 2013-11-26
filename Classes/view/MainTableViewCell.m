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
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"HH:mm:ss"];//y-MM-dd HH:mm:ss
    
    self.createDateLabel.text = [formatter stringFromDate:self.metadata.ctime];
    self.fileNameLabel.text = self.metadata.filename;
    [self.sendBeepBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.sendBeepBtn addTarget:self action:@selector(sendBeepAction:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)sendBeepAction:(id)sender
{
    //TODO:send beep
}

-(void)dealloc
{
    self.metadata = nil;
    
    self.fileNameLabel = nil;
    self.createDateLabel = nil;
    self.sendBeepBtn = nil;
    self.receiveState = nil;
    
    
    [super dealloc];
}

@end
