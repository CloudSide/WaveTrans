//
//  TileView.m
//  BitmapSlice
//
//  Created by Matt Long on 2/17/11.
//  Copyright 2011 Skye Road Systems, Inc. All rights reserved.
//

#import "TileView.h"
#import <QuartzCore/QuartzCore.h>
#import <CommonCrypto/CommonDigest.h>

@interface FastCATiledLayer : CATiledLayer
@end

@implementation FastCATiledLayer
+(CFTimeInterval)fadeDuration {
    return 0;
}
@end


#define kIMAGE_PREFIX @"bigimage_"
#define kIMAGE_CATCHE_PATH ([[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"tiledImage"])

#define kTILED_MIN_WIDTH            1024
#define kTILED_MIN_HEIGHT           1024
#define kTILED_MIN_PIXEL            (kTILED_MIN_WIDTH * kTILED_MIN_HEIGHT)

#define kUSE_TILED_LAYER(_rect)     ((_rect.size.height * _rect.size.width) >= kTILED_MIN_PIXEL ? YES : NO)

@interface TileView()

@property (nonatomic,retain) NSString *hashOfImage;

//@property (nonatomic,assign) CGRect imageRect;

@property (nonatomic,retain) NSOperationQueue *queue;

@property (nonatomic,assign) TileView *blockDelegate;

@end

@implementation TileView

+ layerClass
{
    return [FastCATiledLayer class];
}

-(id)initWithImage:(UIImage *)image
{
    if (self = [self init]) {
        
        self.image = image;
    }
    
    return self;
}

-(id)init
{
    if (self = [super init]) {
        self.blockDelegate = self;
    }
    
    return self;
}

-(void)setImage:(UIImage *)image
{
    [_image release];
    _image = nil;
    
    FastCATiledLayer *tiledLayer = (FastCATiledLayer *)[self layer];
    tiledLayer.contents = nil;
    
    if (image!=nil) {
        
        _image = [TileView fixOrientation:image];
        
        self.hashOfImage = [self hashOfImage:self.image];
        
        [self initView];
    }
}

-(void)initView
{
    if (!self.queue) {
        self.queue = [[[NSOperationQueue alloc] init] autorelease];
        self.queue.maxConcurrentOperationCount = 20;
    }
    
    size_t imageWidth = CGImageGetWidth(self.image.CGImage);
    size_t imageHeight = CGImageGetHeight(self.image.CGImage);
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, imageWidth, imageHeight);
    self.bounds = CGRectMake(0, 0, imageWidth, imageHeight);
    

    FastCATiledLayer *tiledLayer = (FastCATiledLayer *)[self layer];
    // levelsOfDetail and levelsOfDetailBias determine how
    // the layer is rendered at different zoom levels.  This
    // only matters while the view is zooming, since once the
    // the view is done zooming a new TiledImageView is created
    // at the correct size and scale.
    tiledLayer.levelsOfDetail = 4;
    tiledLayer.levelsOfDetailBias = 2;
    tiledLayer.tileSize = CGSizeMake(kTILED_MIN_WIDTH, kTILED_MIN_HEIGHT);

//    tiledLayer.contentsScale = 1.0;
//    self.contentScaleFactor = .5;
//    tiledLayer.shouldRasterize = NO;
    
    // adjustments for retina displays
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.00)
    {
        tiledLayer.contentsScale = 1.0;
        self.contentScaleFactor = .5;
        tiledLayer.shouldRasterize = NO;
//        tiledLayer.levelsOfDetailBias ++;
    }
    
    [self saveTilesOfSize:(CGSize){kTILED_MIN_WIDTH, kTILED_MIN_HEIGHT}
                 forImage:self.image
              usingPrefix:kIMAGE_PREFIX];
}


- (void)dealloc
{
    self.blockDelegate = nil;
    
    [self.queue cancelAllOperations];
    self.queue = nil;
    
    self.hashOfImage = nil;
    
    self.image = nil;
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
//    NSLog(@"==drawRect===%@",NSStringFromCGRect(rect));
    
    CGSize tileSize = (CGSize){kTILED_MIN_WIDTH, kTILED_MIN_HEIGHT};
    
    int firstCol = floorf(CGRectGetMinX(rect) / tileSize.width);
    int lastCol = floorf((CGRectGetMaxX(rect)-1) / tileSize.width);
    int firstRow = floorf(CGRectGetMinY(rect) / tileSize.height);
    int lastRow = floorf((CGRectGetMaxY(rect)-1) / tileSize.height);
    
    for (int row = firstRow; row <= lastRow; row++) {
        for (int col = firstCol; col <= lastCol; col++) {
            UIImage *tile = [self tileAtCol:col row:row];
            
            if (tile)
            {
                CGRect tileRect = CGRectMake(tileSize.width * col, tileSize.height * row,
                                             tileSize.width, tileSize.height);
                
                tileRect = CGRectIntersection(self.bounds, tileRect);
                
                [tile drawInRect:tileRect];
            }
        }
    }

}

#pragma mark - private method
- (void)saveTilesOfSize:(CGSize)size
               forImage:(UIImage*)image
            usingPrefix:(NSString*)prefix
{
    NSBlockOperation *operation = [[[NSBlockOperation alloc] init] autorelease];
    __unsafe_unretained NSBlockOperation *weakOperation = operation;
    
    __block typeof(self.blockDelegate) bself = self.blockDelegate;
    
    UIImage *blockImage = image;
    
    [operation addExecutionBlock:^{
        
        if ([bself isNeedToGenerateTileImage]) {
            
            CGFloat cols = [blockImage size].width / size.width;
            CGFloat rows = [blockImage size].height / size.height;
            
            NSString* directoryPath = [kIMAGE_CATCHE_PATH stringByAppendingPathComponent:bself.hashOfImage];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:nil];
                
            }
            
            int fullColumns = floorf(cols);
            int fullRows = floorf(rows);
            
            CGFloat remainderWidth = [blockImage size].width - (fullColumns * size.width);
            CGFloat remainderHeight = [blockImage size].height -(fullRows * size.height);
            
            
            if (cols > fullColumns) fullColumns++;
            if (rows > fullRows) fullRows++;
            
            CGImageRef fullImage = [blockImage CGImage];
            
            for (int y = 0; y < fullRows; ++y) {
                
                if ([weakOperation isCancelled]) return;//stop operation
                
                for (int x = 0; x < fullColumns; ++x) {
                    if ([weakOperation isCancelled]) return;//stop operation
                    
                    CGSize tileSize = size;
                    if (x + 1 == fullColumns && remainderWidth > 0) {
                        // Last column
                        tileSize.width = remainderWidth;
                    }
                    if (y + 1 == fullRows && remainderHeight > 0) {
                        // Last row
                        tileSize.height = remainderHeight;
                    }
                    
                    
                    CGRect imageRect = (CGRect){{x*size.width, y*size.height},tileSize};
                    CGImageRef tileImage = CGImageCreateWithImageInRect(fullImage,imageRect);
                    NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithCGImage:tileImage],1);
                    
                    CGImageRelease(tileImage);
                    
                    NSString *path = [NSString stringWithFormat:@"%@/%@%d_%d.png",
                                      directoryPath, prefix, x, y];
                    
                    [imageData writeToFile:path atomically:NO];
                
                }
                
                if ([weakOperation isCancelled]) return;
                
                CGRect visibleRect = CGRectIntersection(bself.frame, [[UIScreen mainScreen] bounds]);
                
                CGFloat scaleRate = bself.superview.transform.a;
                CGRect imageRect = (CGRect){{0, y*size.height},size};
                
                if (CGRectIntersectsRect(visibleRect,CGRectMake(imageRect.origin.x * scaleRate,
                                                                imageRect.origin.y * scaleRate,
                                                                imageRect.size.width * scaleRate,
                                                                imageRect.size.height * scaleRate))) {
                    
                    if ([weakOperation isCancelled]) return;
                    
                    [bself performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
                }

            }
            
            if ([weakOperation isCancelled]) return;
        
            [bself performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
            
            //生成标记文件
            NSString *generatedPath = [NSString stringWithFormat:@"%@/generated",
                                       [kIMAGE_CATCHE_PATH stringByAppendingPathComponent:bself.hashOfImage]];
            [@"1" writeToFile:generatedPath
                   atomically:NO
                     encoding:NSUTF8StringEncoding
                        error:nil];
        }
        
    }];
    
    [self.queue addOperation:operation];
    
}


- (BOOL)saveTilesOfSize:(CGSize)size
               forImage:(UIImage*)image
                   path:(NSString*)path
                  atCol:(int)col row:(int)row
{
    UIImage *blockImage = image;
        
    CGFloat cols = [blockImage size].width / size.width;
    CGFloat rows = [blockImage size].height / size.height;
    
    int fullColumns = floorf(cols);
    int fullRows = floorf(rows);
    
    CGFloat remainderWidth = [blockImage size].width - (fullColumns * size.width);
    CGFloat remainderHeight = [blockImage size].height -(fullRows * size.height);
    
    
    if (cols > fullColumns) fullColumns++;
    if (rows > fullRows) fullRows++;
    
    CGImageRef fullImage = [blockImage CGImage];
    
//    for (int y = 0; y < fullRows; ++y) {
    
    int y = row;
    
    int x = col;


            
            CGSize tileSize = size;
            if (x + 1 == fullColumns && remainderWidth > 0) {
                // Last column
                tileSize.width = remainderWidth;
            }
            if (y + 1 == fullRows && remainderHeight > 0) {
                // Last row
                tileSize.height = remainderHeight;
            }
            
            
            CGRect imageRect = (CGRect){{x*size.width, y*size.height},tileSize};
            CGImageRef tileImage = CGImageCreateWithImageInRect(fullImage,imageRect);
            NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithCGImage:tileImage],1);
            
            CGImageRelease(tileImage);
            
//            NSString *path = [NSString stringWithFormat:@"%@/%@%d_%d.png",
//                              directoryPath, prefix, x, y];
    
            //                    NSLog(@"===========queue!!!=========%@",path);
            
            [imageData writeToFile:path atomically:NO];
            
            
            
            //                    CGRect visibleRect = CGRectIntersection(self.frame, [[UIScreen mainScreen] bounds]);
            //                    NSLog(@"------%f   %f",self.superview.transform.a,self.superview.transform.a);
            //
            //                    CGFloat scaleRate = self.superview.transform.a;
            //
            //                    if (CGRectIntersectsRect(visibleRect,CGRectMake(imageRect.origin.x * scaleRate,
            //                                                                    imageRect.origin.y * scaleRate,
            //                                                                    imageRect.size.width * scaleRate,
            //                                                                    imageRect.size.height * scaleRate))) {
            //                        [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
            //                    }
    return YES;
    
}



-(BOOL)isNeedToGenerateTileImage
{
    NSString *path = [NSString stringWithFormat:@"%@/generated",
                      [kIMAGE_CATCHE_PATH stringByAppendingPathComponent:self.hashOfImage]];
    
//    if (self.image) {
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
            return YES;
        }
//    }
    
    return NO;
}

- (UIImage*)tileAtCol:(int)col row:(int)row
{
    NSString *path = [NSString stringWithFormat:@"%@/%@%d_%d.png",
                    [kIMAGE_CATCHE_PATH stringByAppendingPathComponent:self.hashOfImage],
                    kIMAGE_PREFIX, col, row];

    UIImage *image = [UIImage imageWithContentsOfFile:path];
    
    if (!image) {

        [self saveTilesOfSize:(CGSize){kTILED_MIN_WIDTH, kTILED_MIN_HEIGHT}
                     forImage:self.image
                         path:path atCol:col row:row];
    }

    image = [UIImage imageWithContentsOfFile:path];


    return image;
}

-(NSString *)hashOfImage:(UIImage *)image
{   
    return image.accessibilityIdentifier;
}

+ (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    NSString *accessibilityIdentifier = [aImage.accessibilityIdentifier copy];
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    img.accessibilityIdentifier = accessibilityIdentifier;
    [accessibilityIdentifier release];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
