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

#import <Foundation/Foundation.h>

@class VdiskAuthorizeWebView;
@class VdiskAuthorize;

@protocol VdiskAuthorizeWebViewDelegate <NSObject>

- (void)authorizeWebView:(VdiskAuthorizeWebView *)webView didReceiveAuthorizeCode:(NSString *)code;

@end

@interface VdiskAuthorizeWebView : UIView <UIWebViewDelegate> {
    
    UIView *_panelView;
    UIView *_containerView;
    UIActivityIndicatorView *_indicatorView;
	UIWebView *_webView;
    UIInterfaceOrientation _previousOrientation;
    id<VdiskAuthorizeWebViewDelegate> _delegate;
    UIButton *_closeButton;
}

@property (nonatomic, assign) id<VdiskAuthorizeWebViewDelegate> delegate;
@property (nonatomic, assign) VdiskAuthorize *authorize;

- (void)loadRequestWithURL:(NSURL *)url;
- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

@end

#endif