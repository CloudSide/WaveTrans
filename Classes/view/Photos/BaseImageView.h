//
//  BaseImageView.h
//  MaxFrameSize
//
//  Created by hanchao on 13-8-30.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseImageView : UIView

@property (nonatomic,retain) UIImage *image;

-(id)initWithImage:(UIImage *)image;

@end
