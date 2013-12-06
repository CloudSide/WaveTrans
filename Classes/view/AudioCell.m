//
//  AudioCell.m
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "AudioCell.h"
#import "WaveTransModel.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AudioCell ()<AVAudioPlayerDelegate>
@end

@implementation AudioCell

- (void)dealloc {
    
    self.playAudioBtn = nil;
    self.bgImageView = nil;
    
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
    [super awakeFromNib];
    [self.playAudioBtn addTarget:self action:@selector(playAudioAction:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)setMetadata:(WaveTransMetadata *)metadata
{
    [super setMetadata:metadata];
    
//    CGFloat offsetX = 0;
//    UIColor *statusColor;
//    if (metadata.isReceived) {
//        offsetX = -4;
//        statusColor = RECEIVED_VIEW_COLOR;//[UIColor greenColor];
//    }else{
//        offsetX = 4;
//        statusColor = CREATED_VIEW_COLOR;//[UIColor blueColor];
//    }
//    
//    UIView *statusView = [self.contentView viewWithTag:999];
//    if (!statusView) {
//        statusView = [[[UIView alloc] init] autorelease];
//        statusView.tag = 999;
//        [self.contentView addSubview:statusView];
//        
//        CALayer *layer = [CALayer layer];
//        layer.frame = CGRectMake(-offsetX/2, 0, ABS(offsetX), self.frame.size.height);
//        layer.shadowOffset = offsetX>0?CGSizeMake(-1, 0):CGSizeMake(1, 0);
//        layer.shadowColor = [[UIColor blackColor] CGColor];
//        layer.shadowRadius = 4.0f;
//        layer.shadowOpacity = 0.80f;
//        layer.shadowPath = [[UIBezierPath bezierPathWithRect:layer.bounds] CGPath];
//        
//        [statusView.layer addSublayer:layer];
//        
//    }
//    statusView.frame = CGRectMake(offsetX>0?0:(self.bounds.size.width + offsetX), 0, ABS(offsetX), self.bounds.size.height);
//    statusView.backgroundColor = statusColor;
    
//    self.bgImageView.frame = CGRectMake(offsetX, 0, self.bounds.size.width, self.bounds.size.height);
    
}

-(void)playAudioAction:(id)sender
{
    NSLog(@"=========================");
    
    WaveTransMetadata *md = [WaveTransModel metadata:self.metadata];
    
    if (md != nil && [md.reader isEqualToString:@"sound"]) {
        
        /*
        NSURL *url = [[[NSURL alloc] initFileURLWithPath:[md cachePath:NO]] autorelease];
        MPMoviePlayerController *player = [[[MPMoviePlayerController alloc] initWithContentURL:url] autorelease];
        player.view.frame = self.bounds;
        
        [self.contentView addSubview:player.view];
        
        [player setFullscreen:YES];
        
        [player setContentURL:url];
        
        [player play];
         */
        
        /*
        NSData *pcmData = [NSData dataWithContentsOfFile:[md cachePath:NO]];
        
        NSError *error = nil;
        
        AVAudioPlayer *audioPlayer = [[[AVAudioPlayer alloc] initWithData:pcmData error:&error] autorelease];
        [audioPlayer setVolume:1.0];
        
        if (error) {
            
            NSLog(@"error....%@",[error localizedDescription]);
            
        } else {
            
            audioPlayer.delegate = self;
            UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
            AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride), &audioRouteOverride);
            
            [audioPlayer prepareToPlay];
        }
        
        [audioPlayer play];
         */
        
    }else {
        
        //TODO:获取文件失败
    }
    
}

#pragma mark - AVAudioPlayerDelegate <NSObject>

/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"aaaaaaa");
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"bbbbbbb");
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    NSLog(@"ccccccc");
}

/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    NSLog(@"dddddddd");
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
