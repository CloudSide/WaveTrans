//
//  RootViewController.h
//  aurioTouch2
//
//  Created by Littlebox222 on 13-11-22.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@interface RootViewController : UIViewController <AVAudioPlayerDelegate>

@property (nonatomic,retain) AVAudioPlayer *audioPlayer;

@property (nonatomic, retain) NSData *pcmData;

@end
