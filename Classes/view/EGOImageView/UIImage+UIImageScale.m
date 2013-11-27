//
//  UIImage+UIImageScale.m
//  Color
//
//  Created by chao han on 12-5-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "UIImage+UIImageScale.h"


@implementation UIImage (UIImageScale)


-(UIImage*)getSubImage:(CGRect)rect 
{ 
    CGImageRef subImageRef = CGImageCreateWithImageInRect(self.CGImage, rect); 
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef)); 
    
    UIGraphicsBeginImageContext(smallBounds.size); 
    CGContextRef context = UIGraphicsGetCurrentContext(); 
    CGContextDrawImage(context, smallBounds, subImageRef); 
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    if (subImageRef != NULL) {
        CFRelease(subImageRef);
    }
    UIGraphicsEndImageContext(); 
    
    return smallImage; 
} 


-(UIImage*)scaleToSize:(CGSize)size  
{
    CGFloat width = CGImageGetWidth(self.CGImage);
    CGFloat height = CGImageGetHeight(self.CGImage);
    
    if (!(self.imageOrientation == UIImageOrientationUp || self.imageOrientation == UIImageOrientationDown)){
    
        width = CGImageGetHeight(self.CGImage);
        height = CGImageGetWidth(self.CGImage);
    }
    
    float radio = 1;
    
    if (size.width > size.height) {
        radio = size.width *1.0 / width;
    }else{
        radio = size.height *1.0 / height;
    }
    
    width = width*radio; 
    height = height*radio; 
    
    int xPos = (size.width - width)/2;
    int yPos = (size.height-height)/2; 
    
    
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    
    [self drawInRect:CGRectMake(0, 0, width, height)];
    
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();   
    
    
    UIGraphicsEndImageContext();   
    
    
    return scaledImage; 
}  




@end
