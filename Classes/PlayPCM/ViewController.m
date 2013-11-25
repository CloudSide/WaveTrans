//
//  ViewController.m
//  PlayPCM
//
//  Created by hanchao on 13-11-21.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import "ViewController.h"

#import <stdio.h>

#import "PCMRender.h"

@interface ViewController ()

@property (nonatomic,assign) NSInteger freqNum;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(IBAction)sliderEvent:(UISlider *)slider
{
    self.freqNum = (NSInteger)slider.value;
	self.freqlabel.text = [NSString stringWithFormat:@"%d",(NSInteger)slider.value];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)playAction:(id)sender&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
{
    NSData *pcmData = [PCMRender renderChirpData:@"abcdefghijklmnopqrstuv"];
    
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:pcmData
                                                     error:&error];

    if (error) {
        NSLog(@"error....%@",[error localizedDescription]);
    }else{
        self.audioPlayer.delegate = self;
        [self.audioPlayer prepareToPlay];
    }

    [self.audioPlayer play];
    
    
    
}

#pragma mark - AVAudioPlayerDelegate <NSObject>

/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    
}

/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    
}
@end
