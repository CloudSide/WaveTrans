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
    
<<<<<<< HEAD
    if (super.metadata.fileURL!= nil && [super.metadata.fileURL.absoluteString hasPrefix:@"http://"]) {
        [self.photoImageView setImageURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://vdisk-thumb-1.wcdn.cn/frame.640x480/%@",[super.metadata.fileURL.absoluteString substringFromIndex:7]]]];
    }else if([super.metadata hasCache]){
        [self.photoImageView setImage:[UIImage imageWithContentsOfFile:[super.metadata cachePath:NO]]];
=======
    if (metadata.fileURL) {
        
        [self.photoImageView setImageURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://vdisk-thumb-1.wcdn.cn/frame.640x480/%@",[super.metadata.fileURL.absoluteString substringFromIndex:7]]]];
    
    } else if ([metadata hasCache]) {
    
        [self.photoImageView setImage:[UIImage imageWithContentsOfFile:[metadata cachePath:NO]]];
>>>>>>> 237714877c7236b06a8b33824cebd075ccb171d6
    }
}

-(void)dealloc
{
    self.photoImageView = nil;
    
    [super dealloc];
}

@end
