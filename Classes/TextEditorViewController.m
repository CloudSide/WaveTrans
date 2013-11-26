//
//  TextEditorViewController.m
//  WaveTrans
//
//  Created by Bruce on 13-11-26.
//
//

#import "TextEditorViewController.h"
#import "DDHTextView.h"
#import "WaveTransMetadata.h"

@interface TextEditorViewController () {

    DDHTextView *_textView;
}

@end

@implementation TextEditorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *contentView = [[UIView alloc] initWithFrame:frame];
    
    _textView = [[DDHTextView alloc] init];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
    _textView.text = @"欢迎使用声波传输";
    [contentView addSubview:_textView];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_textView);
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_textView]|" options:0 metrics:nil views:viewsDictionary]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(8)-[_textView(200)]" options:0 metrics:nil views:viewsDictionary]];
    
    [contentView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    self.view = [contentView autorelease];
}

- (void)close {

    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


- (void)ok {
    
    NSString *content = [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    WaveTransMetadata *md = [[[WaveTransMetadata alloc] initWithSha1:[content SHA1EncodedString] type:@"text" content:content size:[content lengthOfBytesUsingEncoding:NSUTF8StringEncoding] filename:nil] autorelease];
    [md setUploaded:NO];
    [md save];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(ok)] autorelease];
    
    
#ifdef __IPHONE_7_0
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        //self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
 
    [_textView release];
    
    [super dealloc];
}

@end
