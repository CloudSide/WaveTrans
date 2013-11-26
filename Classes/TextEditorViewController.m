//
//  TextEditorViewController.m
//  WaveTrans
//
//  Created by Bruce on 13-11-26.
//
//

#import "TextEditorViewController.h"
#import "DDHTextView.h"

@interface TextEditorViewController ()

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
    [super loadView];
    
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *contentView = [[UIView alloc] initWithFrame:frame];
    
    DDHTextView *textView = [[[DDHTextView alloc] init] autorelease];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
    textView.text = @"欢迎使用声波传输";
    [contentView addSubview:textView];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(textView);
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[textView]|" options:0 metrics:nil views:viewsDictionary]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-15)-[textView(200)]" options:0 metrics:nil views:viewsDictionary]];
    
    [contentView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    [self.view addSubview:contentView];
}

- (void)close {

    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


- (void)ok {
    
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

@end
