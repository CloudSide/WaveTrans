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
@property (nonatomic, assign) BOOL playFlag;
@end

@protocol MainViewControllerDelegate <NSObject>
//更新下载进度
- (void)updateDownloadProgress:(CGFloat)progress byMetadata:(WaveTransMetadata *)metadata;

@end


@protocol PostWaveTransMetadataDelegate <NSObject>

- (void)postWaveTransMetadata:(WaveTransMetadata *)metadata;

@end