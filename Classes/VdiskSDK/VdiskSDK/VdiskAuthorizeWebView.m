//
//  VdiskSDK
//  Based on OAuth 2.0
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//
//  Created by Bruce Chen (weibo: @一个开发者) on 12-6-15.
//
//  Copyright (c) 2012 Sina Vdisk. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "VdiskAuthorizeWebView.h"
#import <QuartzCore/QuartzCore.h> 
#import "VdiskAuthorize.h"

@interface VdiskAuthorizeWebView (Private)

- (void)bounceOutAnimationStopped;
- (void)bounceInAnimationStopped;
- (void)bounceNormalAnimationStopped;
- (void)allAnimationsStopped;

- (UIInterfaceOrientation)currentOrientation;
- (void)sizeToFitOrientation:(UIInterfaceOrientation)orientation;
- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation;
- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation;

- (void)addObservers;
- (void)removeObservers;

@end

@implementation VdiskAuthorizeWebView

@synthesize delegate = _delegate;
@synthesize authorize = _authorize;

#pragma mark - VdiskAuthorizeWebView Life Circle

- (id)init {
    
    if (self = [super initWithFrame:CGRectZero]) {
        
        // background settings
        [self setBackgroundColor:[UIColor clearColor]];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        
                
        // add the panel view
        _panelView = [[UIView alloc] initWithFrame:CGRectZero];
        [_panelView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.20f]];
        //[_panelView setBackgroundColor:[UIColor clearColor]];
        [[_panelView layer] setMasksToBounds:NO]; // very important
        [[_panelView layer] setCornerRadius:4.0];
        [self addSubview:_panelView];
        
        
        // add the conainer view
        _containerView = [[UIView alloc] initWithFrame:CGRectZero];
        [[_containerView layer] setBorderColor:[UIColor colorWithRed:0. green:0. blue:0. alpha:0.7].CGColor];
        [[_containerView layer] setBorderWidth:1.0];
        
        
        // add the web view
        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
		[_webView setDelegate:self];
		[_containerView addSubview:_webView];
        
        [_panelView addSubview:_containerView];
        
        
        UIImage *closeImage = [UIImage imageNamed:@"SinaWeibo.bundle/images/close.png"];
        UIColor *color = [UIColor colorWithRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
        //UIColor *color = [UIColor clearColor];
        _closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [_closeButton setImage:closeImage forState:UIControlStateNormal];
        [_closeButton setTitleColor:color forState:UIControlStateNormal];
        [_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_closeButton addTarget:self action:@selector(onCloseButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        _closeButton.showsTouchWhenHighlighted = YES;
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_closeButton sizeToFit];
        [_panelView addSubview:_closeButton];
        
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:_indicatorView];
        
    }
    
    return self;
}

- (void)dealloc {
    
    self.authorize = nil;
    
    [_panelView release], _panelView = nil;
    [_containerView release], _containerView = nil;
    [_webView release], _webView = nil;
    [_indicatorView release], _indicatorView = nil;
    [_closeButton release], _closeButton = nil;
    
    [super dealloc];
}

#pragma mark Actions

- (void)onCloseButtonTouched:(id)sender {
    
    [self hide:YES];
    
    if (_authorize && _authorize.delegate != nil && [_authorize.delegate respondsToSelector:@selector(authorizeDidCancel:)]) {
        
        [_authorize.delegate authorizeDidCancel:_authorize];
    }
}

#pragma mark Orientations

- (UIInterfaceOrientation)currentOrientation {
    
    return [UIApplication sharedApplication].statusBarOrientation;
}

- (void)setupFrameWithOrientation:(UIInterfaceOrientation)orientation {

    CGRect frame = [UIScreen mainScreen].applicationFrame;
    
    CGFloat scaleFactor = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0.6f : 1.0f;
    CGFloat width = floor(scaleFactor * frame.size.width);
    CGFloat height = floor(scaleFactor * frame.size.height);
    CGPoint centerPanelView;
    CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2), frame.origin.y + ceil(frame.size.height/2));
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        
        [self setFrame:CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width)];
        centerPanelView = CGPointMake(frame.size.height / 2, frame.size.width / 2);
        [_panelView setFrame:CGRectMake(0, 0, height, width)];
        
    } else {
        
        [self setFrame:frame];
        centerPanelView = CGPointMake(frame.size.width / 2, frame.size.height / 2);
        [_panelView setFrame:CGRectMake(0, 0, width, height)];
    }
    
    self.center = center;
    [_panelView setCenter:centerPanelView];
    [_indicatorView setCenter:centerPanelView];
    [_containerView setFrame:CGRectMake(10, 10, _panelView.frame.size.width - 20.0f, _panelView.frame.size.height - 20.0f)];
    [_webView setFrame:CGRectMake(0, 0, _containerView.frame.size.width, _containerView.frame.size.height)];
    
    _closeButton.frame = CGRectMake(_containerView.frame.size.width - 8, 2, 29, 29);
}

- (void)sizeToFitOrientation:(UIInterfaceOrientation)orientation {
    
    [self setTransform:CGAffineTransformIdentity];
    
    [self setupFrameWithOrientation:orientation];
    
    [self setTransform:[self transformForOrientation:orientation]];
    
    _previousOrientation = orientation;
}

- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation {
    
	if (orientation == UIInterfaceOrientationLandscapeLeft) {
        
		return CGAffineTransformMakeRotation(-M_PI / 2);
        
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        
		return CGAffineTransformMakeRotation(M_PI / 2);
        
	} else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		
        return CGAffineTransformMakeRotation(-M_PI);
        
    } else {
        
		return CGAffineTransformIdentity;
	}
}

- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation  {
    
	if (orientation == _previousOrientation) {
        
		return NO;
        
    } else {
        
		return orientation == UIInterfaceOrientationLandscapeLeft
		|| orientation == UIInterfaceOrientationLandscapeRight
		|| orientation == UIInterfaceOrientationPortrait
		|| orientation == UIInterfaceOrientationPortraitUpsideDown;
	}
    
    return YES;
}

#pragma mark Obeservers

- (void)addObservers {
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (void)removeObservers {
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}


#pragma mark Animations

- (void)bounceOutAnimationStopped {
    
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.13];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounceInAnimationStopped)];
    [_panelView setAlpha:0.8];
	[_panelView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9)];
	[UIView commitAnimations];
}

- (void)bounceInAnimationStopped {
    
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.13];
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounceNormalAnimationStopped)];
    [_panelView setAlpha:1.0];
	[_panelView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)];
	[UIView commitAnimations];
}

- (void)bounceNormalAnimationStopped {
    
    [self allAnimationsStopped];
}

- (void)allAnimationsStopped {
    
    // nothing shall be done here
}

#pragma mark Dismiss

- (void)hideAndCleanUp {
    
    [self removeObservers];
	[self removeFromSuperview];
}

#pragma mark - VdiskAuthorizeWebView Public Methods

- (void)loadRequestWithURL:(NSURL *)url {
    
    NSURLRequest *request =[NSURLRequest requestWithURL:url
                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                        timeoutInterval:60.0];
    [_webView loadRequest:request];
}

- (void)show:(BOOL)animated {
    
    [self sizeToFitOrientation:[self currentOrientation]];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
	
    if (!window) {
        
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
    
  	[window addSubview:self];
    
    if (animated) {
        
        [_panelView setAlpha:0];
        CGAffineTransform transform = CGAffineTransformIdentity;
        [_panelView setTransform:CGAffineTransformScale(transform, 0.3, 0.3)];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(bounceOutAnimationStopped)];
        [_panelView setAlpha:0.5];
        [_panelView setTransform:CGAffineTransformScale(transform, 1.1, 1.1)];
        [UIView commitAnimations];
        
    } else {
        
        [self allAnimationsStopped];
    }
    
    [self addObservers];
}

- (void)hide:(BOOL)animated {
    
	if (animated) {
        
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(hideAndCleanUp)];
		[self setAlpha:0];
		[UIView commitAnimations];
	} 
    
    [self hideAndCleanUp];
}

#pragma mark - UIDeviceOrientationDidChangeNotification Methods

- (void)deviceOrientationDidChange:(id)object {
    
	UIInterfaceOrientation orientation = [self currentOrientation];
	if ([self shouldRotateToOrientation:orientation]) {
        
        NSTimeInterval duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[self sizeToFitOrientation:orientation];
		[UIView commitAnimations];
	}
}

#pragma mark - UIWebViewDelegate Methods

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
    
	[_indicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    
	[_indicatorView stopAnimating];
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error {
    
    [_indicatorView stopAnimating];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    
    if ([request.URL.absoluteString rangeOfString:@"thebox.sinaapp.com/weibo/reg.php"].location != NSNotFound) {
        
        [[UIApplication sharedApplication] openURL:request.URL];
        
        return NO;
    }
    
    //NSLog(@"%@", [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease]);
    
    
    NSRange range = [request.URL.absoluteString rangeOfString:@"?"];
    
    
    if (range.location != NSNotFound) {
        
        NSString *uri = [request.URL.absoluteString substringFromIndex:range.location + range.length];
        
        NSArray *items = [uri componentsSeparatedByString:@"&"];
        
        for (NSString *item in items) {
            
            NSArray *param = [item componentsSeparatedByString:@"="];
                        
            if ([param count] == 2 && [(NSString *)[param objectAtIndex:0] isEqualToString:@"code"]) {
                
                NSString *code = [param objectAtIndex:1];
                
                if ([_delegate respondsToSelector:@selector(authorizeWebView:didReceiveAuthorizeCode:)]) {
                    
                    [_delegate authorizeWebView:self didReceiveAuthorizeCode:code];
                }
                
                return NO;
                
                break;
            }
        }
    }
    
    
    
    /*
     
     NSRange range = [request.URL.absoluteString rangeOfString:@"code="];
     
     if (range.location != NSNotFound)
     {
     NSString *code = [request.URL.absoluteString substringFromIndex:range.location + range.length];
     
     if ([delegate respondsToSelector:@selector(authorizeWebView:didReceiveAuthorizeCode:)])
     {
     [delegate authorizeWebView:self didReceiveAuthorizeCode:code];
     }
     }
     */
    
    return YES;
}

@end

#endif
