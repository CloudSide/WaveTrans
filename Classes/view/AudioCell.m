//
//  AudioCell.m
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "AudioCell.h"


@implementation AudioCell

- (void)dealloc {
    
    self.playAudioBtn = nil;
    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    
    [self.playAudioBtn addTarget:self action:@selector(playAudioAction:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)playAudioAction:(id)sender
{
    NSLog(@"=========================");
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
