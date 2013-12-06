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
//    
//    self.screenshotImageView.frame = CGRectMake(offsetX, 0, self.bounds.size.width, self.bounds.size.height);
    
    
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
