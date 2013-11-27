//
//  PhotoViewerViewController.m
//  WaveTrans
//
//  Created by hanchao on 13-11-27.
//
//

#import "PhotoViewerViewController.h"

#import "BaseImageView.h"
#import "WaveTransMetadata.h"

@interface PhotoViewerViewController () <UIScrollViewDelegate>

@property (nonatomic,retain) UIScrollView *mscrollView;

@end

@implementation PhotoViewerViewController

-(id)initWithMetadata:(WaveTransMetadata *)metadata
{
    if(self = [self initWithNibName:nil bundle:nil]){
        self.metadata = metadata;
    }
    
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.mscrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.mscrollView.delegate = self;
    
    [self.view addSubview:self.mscrollView];
    
    UIImage *img = [UIImage imageWithContentsOfFile:[self.metadata cachePath:NO]];
    BaseImageView *biv = [[[BaseImageView alloc] initWithImage:img] autorelease];
    
    [self.mscrollView addSubview:biv];
    self.mscrollView.contentSize = CGSizeMake(CGImageGetWidth(img.CGImage),CGImageGetHeight(img.CGImage));
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
