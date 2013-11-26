//
//  PureTextCell.m
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "PureTextCell.h"

#import "WaveTransMetadata.h"

@implementation PureTextCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
    self.pureTextParentView.layer.cornerRadius = 4.0f;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)setMetadata:(WaveTransMetadata *)metadata
{
    super.metadata = metadata;
    
    self.pureTextLabel.text = super.metadata.content;
}


-(void)dealloc
{
    self.pureTextLabel = nil;
    self.pureTextParentView = nil;
    
    [super dealloc];
}

@end
