//
//  BaseImageView.m
//  MaxFrameSize
//
//  Created by hanchao on 13-8-30.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import "BaseImageView.h"

#import "TileView.h"

#define kTILED_MIN_WIDTH            1024
#define kTILED_MIN_HEIGHT           1024
#define kTILED_MIN_PIXEL            (kTILED_MIN_WIDTH * kTILED_MIN_HEIGHT)

#define kUSE_TILED_LAYER(_rect)     ((_rect.size.height * _rect.size.width) >= kTILED_MIN_PIXEL ? YES : NO)

@interface BaseImageView()

@property (nonatomic,retain) UIView *childView;

@end

@implementation BaseImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithImage:(UIImage *)image
{
    if (self = [super init]) {
        
        self.image = image;
        
    }
    
    return self;
}

-(void)setImage:(UIImage *)image
{
    [_image release];
    _image = nil;
    
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    
    self.childView = nil;//TODO:??
    
    if (image!=nil) {
        
        _image = [image retain];
        
        [self initView];
        
        [self sizeToFit];
    }
}

-(void)initView
{
    if (kUSE_TILED_LAYER(self.image)) {
        
        TileView *view = [[TileView alloc] initWithImage:self.image];
        self.childView = view;
        [view release];
        
    }else{
        UIImageView *view = [[UIImageView alloc] initWithImage:self.image];
        self.childView = view;
        [view release];
    }
    
    [self addSubview:self.childView];
//    [self sizeToFit];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return ((UIView *)self.childView).bounds.size;
}

-(void)dealloc
{
    [_childView release];
    _childView = nil;
//    self.childView = nil;
    self.image = nil;
    
    [super dealloc];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
