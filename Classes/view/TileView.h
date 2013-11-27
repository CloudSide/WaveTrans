//
//  TileView.h
//  BitmapSlice
//
//  Created by Matt Long on 2/17/11.
//  Copyright 2011 Skye Road Systems, Inc. All rights reserved.
//

@interface TileView : UIView

@property (nonatomic,retain) UIImage *image;

- (UIImage*)tileAtCol:(int)col row:(int)row;

-(id)initWithImage:(UIImage *)image;

+ (UIImage *)fixOrientation:(UIImage *)aImage;

@end
