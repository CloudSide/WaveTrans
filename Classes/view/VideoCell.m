//
//  VideoCell.m
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "VideoCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "WaveTransMetadata.h"
#import "EGOImageView.h"

@implementation VideoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setMetadata:(WaveTransMetadata *)metadata
{
    super.metadata = metadata;
    
    NSString *screenshotFilePath = [NSString stringWithFormat:@"%@.screenshot",[super.metadata cachePath:NO]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:screenshotFilePath]) {
    
        NSURL *mediaUrl = [NSURL fileURLWithPath:[super.metadata cachePath:NO]];
        if (mediaUrl != nil) {
            MPMoviePlayerController *mp = [[MPMoviePlayerController alloc] initWithContentURL:mediaUrl];
            UIImage *image=[mp thumbnailImageAtTime:(NSTimeInterval)1 timeOption:MPMovieTimeOptionNearestKeyFrame];
            [mp stop];
            [mp release];
            
            [UIImagePNGRepresentation(image) writeToFile:screenshotFilePath atomically:YES];
            
        }
    }
    
    self.screenshotImageView.imageURL = [NSURL fileURLWithPath:screenshotFilePath];

}

-(void)dealloc
{
    self.screenshotImageView = nil;
    [super dealloc];
}

@end
