//
//  WeiboCell.m
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "WeiboCell.h"

#import "WaveTransMetadata.h"
#import "EGOImageView.h"

#import "VdiskJSON.h"

@implementation WeiboCell

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
    
//    self.coverImageView.frame = CGRectMake(offsetX, 0, self.bounds.size.width, self.bounds.size.height);
    
    NSDictionary *jsonDict = [metadata.content JSONValue];
    self.nameLabel.text = [jsonDict objectForKey:@"name"];
    self.descriptionLabel.text = [jsonDict objectForKey:@"description"];
    
    self.headerImageView.imageURL = [NSURL URLWithString:[jsonDict objectForKey:@"avatar_large"]];
    self.coverImageView.imageURL = [NSURL URLWithString:[jsonDict objectForKey:@"cover_image"]];
}

-(void)dealloc
{
    self.headerImageView = nil;
    self.nameLabel = nil;
    self.descriptionLabel = nil;
    self.coverImageView = nil;
    
    [super dealloc];
}

@end
