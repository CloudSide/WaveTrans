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
    
    NSDictionary *jsonDict = [metadata.content JSONValue];
    self.nameLabel.text = [jsonDict objectForKey:@"name"];
    self.descriptionLabel.text = [jsonDict objectForKey:@"description"];
    
    self.headerImageView.imageURL = [NSURL URLWithString:[jsonDict objectForKey:@"avatar_large"]];
}

-(void)dealloc
{
    self.headerImageView = nil;
    self.nameLabel = nil;
    self.descriptionLabel = nil;
    
    [super dealloc];
}

@end
