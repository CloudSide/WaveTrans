//
//  ViewController.h
//  PlayPCM
//
//  Created by hanchao on 13-11-21.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVAudioPlayerDelegate>

@property (nonatomic,strong) AVAudioPlayer *audioPlayer;

@property (nonatomic,strong) IBOutlet UILabel *freqlabel;
-(IBAction)playAction:(id)sender;

-(IBAction)sliderEvent:(id)sender;

@end
