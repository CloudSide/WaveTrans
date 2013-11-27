//
//  PhotoViewerViewController.h
//  WaveTrans
//
//  Created by hanchao on 13-11-27.
//
//

#import <UIKit/UIKit.h>

@class WaveTransMetadata;

@interface PhotoViewerViewController : UIViewController

@property (nonatomic,retain) WaveTransMetadata *metadata;

-(id)initWithMetadata:(WaveTransMetadata *)metadata;

@end
