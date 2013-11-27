//
//  TextViewController.m
//  WaveTrans
//
//  Created by Bruce on 13-11-27.
//
//

#import "TextViewController.h"
#import "VdiskJSON.h"

@interface TextViewController () <UIWebViewDelegate> {

    UIWebView *_webView;
}

@end

@implementation TextViewController

@synthesize contentText = _contentText;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
    
    }
    
    
    return self;
}

- (void)close {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)copyText {

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:_contentText];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_webView];
    _webView.delegate = self;
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"html/text_reader.html" ofType:nil]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0]];
    
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"复制文本" style:UIBarButtonItemStylePlain target:self action:@selector(copyText)] autorelease];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	
    NSLog(@"%@", _contentText);
    
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"display_text(%@)", [@{@"text":_contentText} JSONRepresentation]]];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {

    [_contentText release];
    
    [_webView stopLoading];
    _webView.delegate = nil;
    [_webView release];
    
    [super dealloc];
}

@end
