//
//  UIImage+UIImageScale.h
//  Color
//
//  Created by chao han on 12-5-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (UIImageScale)

-(UIImage*)getSubImage:(CGRect)rect; 
-(UIImage*)scaleToSize:(CGSize)size;  

@end
