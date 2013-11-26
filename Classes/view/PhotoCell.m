//
//  PhotoCell.m
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "PhotoCell.h"
#import "EGOImageView.h"
#import "WaveTransMetadata.h"

@implementation PhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)setMetadata:(WaveTransMetadata *)metadata
{
    super.metadata = metadata;
    
    if (metadata.fileURL) {
        
        [self.photoImageView setImageURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://vdisk-thumb-1.wcdn.cn/frame.640x480/%@",[super.metadata.fileURL.absoluteString substringFromIndex:7]]]];
    
    } else if ([metadata hasCache]) {
    
        [self.photoImageView setImage:[UIImage imageWithContentsOfFile:[metadata cachePath:NO]]];
    }
}

-(void)dealloc
{
    self.photoImageView = nil;
    
    [super dealloc];
}

@end
