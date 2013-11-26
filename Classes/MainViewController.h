//
//  MainViewController.h
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import <UIKit/UIKit.h>

@class WaveTransMetadata;

@interface MainViewController : UIViewController

@end


@protocol PostWaveTransMetadataDelegate <NSObject>

- (void)postWaveTransMetadata:(WaveTransMetadata *)metadata;

@end