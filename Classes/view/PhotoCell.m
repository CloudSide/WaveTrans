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

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.photoImageView.clipsToBounds = YES;
}

-(void)setMetadata:(WaveTransMetadata *)metadata
{
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
//    self.photoImageView.frame = CGRectMake(offsetX, 0, self.bounds.size.width, self.bounds.size.height);
    
    super.metadata = metadata;
    
    if (super.metadata.fileURL!= nil && [super.metadata.fileURL.absoluteString hasPrefix:@"http://"]) {
        [self.photoImageView setImageURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://vdisk-thumb-1.wcdn.cn/maxsize.100/%@",[super.metadata.fileURL.absoluteString substringFromIndex:7]]]];//
    }else if([super.metadata hasCache]){
        [self.photoImageView setImageURL:[NSURL fileURLWithPath:[super.metadata cachePath:NO]]];

    }
}

-(void)dealloc
{
    self.photoImageView = nil;
    
    [super dealloc];
}

@end
