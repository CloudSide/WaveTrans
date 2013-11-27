//
//  EGOImageView.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/15/09.
//  Copyright (c) 2009-2010 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOImageView.h"
#import "EGOImageLoader.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+UIImageScale.h"

@implementation EGOImageView
@synthesize imageURL, placeholderImage, delegate,needPlayAnim,rectSize,mNSTimer = _mNSTimer;

-(void)awakeFromNib {
    [super awakeFromNib];
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"tile_default_img" ofType:@"png"];
//    self.placeholderImage = [UIImage imageWithContentsOfFile:path];
    
//    self.placeholderImage = [UIImage imageNamed:@"tile_default_img"];
}

- (id)initWithPlaceholderImage:(UIImage*)anImage {
	return [self initWithPlaceholderImage:anImage delegate:nil];	
}

- (id)initWithPlaceholderImage:(UIImage*)anImage delegate:(id<EGOImageViewDelegate>)aDelegate {
	if((self = [super initWithImage:anImage])) {
		self.placeholderImage = anImage;
		self.delegate = aDelegate;
        
//        self.clipsToBounds = YES; 
//        self.contentMode = UIViewContentModeScaleAspectFill;
	}
	
	return self;
}

- (void)setImageURL:(NSURL *)aURL {
	if(imageURL) {
		[[EGOImageLoader sharedImageLoader] removeObserver:self forURL:imageURL];
		[imageURL release];
		imageURL = nil;
	}
	
	if(!aURL) {
		self.image = self.placeholderImage;
		imageURL = nil;
		return;
	} else {
		imageURL = [aURL retain];
	}

    UIImage* anImage;
    if ([aURL.scheme isEqualToString:@"file"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        
        NSString *thumb = [NSString stringWithFormat:@"%@.thumb",aURL.path];
        if ([fileManager fileExistsAtPath:thumb isDirectory:&isDir]) {
            anImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:thumb]]];
        }else{
            UIImage *img = [UIImage imageWithData:[NSData dataWithContentsOfURL:aURL]];
            CGFloat width = CGImageGetWidth(img.CGImage);
            CGFloat height = CGImageGetHeight(img.CGImage);
            if(width*height > self.frame.size.width*2*self.frame.size.height*2*2){
                img = [img scaleToSize:CGSizeMake(self.frame.size.width*2, self.frame.size.height*2)];
                
                [UIImagePNGRepresentation(img) writeToFile:thumb atomically:YES];
                
            }
            
            anImage = img;
        }
        
    }else{
        [[EGOImageLoader sharedImageLoader] removeObserver:self];
        anImage = [[EGOImageLoader sharedImageLoader] imageForURL:aURL shouldLoadWithObserver:self];
    }
    
    if(anImage) {
        self.image = anImage;
        rectSize = anImage.size;
        
        // trigger the delegate callback if the image was found in the cache
        if([self.delegate respondsToSelector:@selector(imageViewLoadedImage:)]) {
            [self.delegate imageViewLoadedImage:self];
        }
    } else {
        self.image = self.placeholderImage;
    }
}

-(CGSize)returnSize
{
    return rectSize;
}
#pragma mark -
#pragma mark Image loading

- (void)cancelImageLoad {
	[[EGOImageLoader sharedImageLoader] cancelLoadForURL:self.imageURL];
	[[EGOImageLoader sharedImageLoader] removeObserver:self forURL:self.imageURL];
}

- (void)imageLoaderDidLoad:(NSNotification*)notification {
	if(![[[notification userInfo] objectForKey:@"imageURL"] isEqual:self.imageURL]) return;

	UIImage* anImage = [[notification userInfo] objectForKey:@"image"];
    
    self.image = anImage;
    
//    [self playAnim];
    
	[self setNeedsDisplay];
	
	if([self.delegate respondsToSelector:@selector(imageViewLoadedImage:)]) {
		[self.delegate imageViewLoadedImage:self];
	}	
}

- (void)imageLoaderDidFailToLoad:(NSNotification*)notification {
	if(![[[notification userInfo] objectForKey:@"imageURL"] isEqual:self.imageURL]) return;
	
	if([self.delegate respondsToSelector:@selector(imageViewFailedToLoadImage:error:)]) {
		[self.delegate imageViewFailedToLoadImage:self error:[[notification userInfo] objectForKey:@"error"]];
	}
    
    self.image = self.placeholderImage;
}

#pragma mark -
- (void)dealloc {
	[[EGOImageLoader sharedImageLoader] removeObserver:self];
	self.imageURL = nil;
	self.placeholderImage = nil;
    self.image = nil;
    [self.mNSTimer invalidate];
    self.mNSTimer = nil;
    [super dealloc];
}

#pragma mark - touch method
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    UIView *coverView = [[UIView alloc] init];
//    coverView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
//    coverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
//    coverView.tag = 100;
//    [self addSubview:coverView];
//    [coverView release];

    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    UIView *highlightDot = [[UIView alloc] initWithFrame:CGRectMake(point.x - 25
                                                                    , point.y - 25
                                                                    , 50, 50)];
    highlightDot.clipsToBounds = YES;
    
    //    [highlightDot setBackgroundColor:[UIColor grayColor]];
    [highlightDot setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"highlight_dot" ofType:@"png"]]]];
    
    
    highlightDot.layer.cornerRadius = 10;
    [self addSubview:highlightDot];
    
    [highlightDot release];
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         highlightDot.alpha = 0;
                     } completion:^(BOOL finished) {
                         [highlightDot removeFromSuperview];
                     }];
    



}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
//    UIView *coverView = [self viewWithTag:100];
//    [coverView removeFromSuperview];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
//    UIView *coverView = [self viewWithTag:100];
//    [coverView removeFromSuperview];
}

@end
