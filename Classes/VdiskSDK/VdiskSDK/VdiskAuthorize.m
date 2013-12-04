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

#import "VdiskAuthorize.h"
#import "VdiskRequest.h"
#import "VdiskSDKGlobal.h"
#import "VdiskSession.h"
#import "VdiskError.h"


@interface VdiskAuthorize (Private)

- (void)requestAccessTokenWithAuthorizeCode:(NSString *)code;
- (void)requestAccessTokenWithUsername:(NSString *)username password:(NSString *)password;

@end

@implementation VdiskAuthorize

@synthesize appKey = _appKey;
@synthesize appSecret = _appSecret;
@synthesize redirectURI = _redirectURI;
@synthesize request = _request;
@synthesize delegate = _delegate;
@synthesize udid = _udid;

#pragma mark - VdiskAuthorize Life Circle

- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret udid:(NSString *)udid {
    
    if (self = [super init]) {
        
        self.appKey = appKey;
        self.appSecret = appSecret;
        self.udid = udid;
    }
    
    return self;
}

- (void)dealloc {
    
    [_appKey release], _appKey = nil;
    [_appSecret release], _appSecret = nil;
    [_udid release], _udid = nil;
    
    [_redirectURI release], _redirectURI = nil;
    
    [_request setDelegate:nil];
    [_request disconnect];
    [_request release], _request = nil;
    
    _delegate = nil;

    [super dealloc];
}

- (void)requestAccessTokenWithAuthorizeCode:(NSString *)code {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_appKey, @"client_id", _appSecret, @"client_secret", @"authorization_code", @"grant_type", _redirectURI, @"redirect_uri", code, @"code", nil];
    
    [_request disconnect];
    
    self.request = [VdiskRequest requestWithURL:kVdiskAccessTokenURL httpMethod:@"POST" params:params httpHeaderFields:[NSDictionary dictionaryWithObjectsAndKeys:[VdiskSession userAgent], @"User-Agent", nil] udid:_udid delegate:self];
    
    [_request connect];
}

- (void)requestAccessTokenWithUsername:(NSString *)username password:(NSString *)password {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_appKey, @"client_id", _appSecret, @"client_secret", @"password", @"grant_type", username, @"username", password, @"password", nil];
    
    [_request disconnect];
    
    self.request = [VdiskRequest requestWithURL:kVdiskAccessTokenURL httpMethod:@"POST" params:params httpHeaderFields:[NSDictionary dictionaryWithObjectsAndKeys:[VdiskSession userAgent], @"User-Agent", nil] udid:_udid delegate:self];
    
    [_request connect];
}

#pragma mark - VdiskAuthorize Public Methods

- (void)startAuthorize {
    
#if TARGET_OS_IPHONE
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_appKey, @"client_id", @"code", @"response_type", _redirectURI, @"redirect_uri", @"mobile", @"display", @"true", @"forcelogin", nil];
    
    //NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_appKey, @"client_id", @"code", @"response_type", _redirectURI, @"redirect_uri", @"mobile", @"display", nil];
    
    NSString *urlString = [VdiskRequest serializeURL:kVdiskAuthorizeURL params:params httpMethod:@"GET"];
    
    VdiskAuthorizeWebView *webView = [[VdiskAuthorizeWebView alloc] init];
    [webView setDelegate:self];
    [webView loadRequestWithURL:[NSURL URLWithString:urlString]];
    [webView show:YES];
    webView.authorize = self;
    [webView release];
    
#else
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_appKey, @"client_id", @"code", @"response_type", _redirectURI, @"redirect_uri", nil];
    
    NSString *urlString = [VdiskRequest serializeURL:kVdiskAuthorizeURL params:params httpMethod:@"GET"];
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];

#endif
    
}

- (void)startAuthorizeUsingUsername:(NSString *)username password:(NSString *)password {
    
    [self requestAccessTokenWithUsername:username password:password];
}

- (void)startAuthorizeUsingRefreshToken:(NSString *)refreshToken {

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:_appKey, @"client_id", _appSecret, @"client_secret", @"refresh_token", @"grant_type", refreshToken, @"refresh_token", nil];
    
    NSLog(@"%@", params);
    
    [_request disconnect];
    
    self.request = [VdiskRequest requestWithURL:kVdiskAccessTokenURL httpMethod:@"POST" params:params httpHeaderFields:[NSDictionary dictionaryWithObjectsAndKeys:[VdiskSession userAgent], @"User-Agent", nil] udid:_udid delegate:self];
    
    [_request connect];
}

#if TARGET_OS_IPHONE

#pragma mark - VdiskAuthorizeWebViewDelegate Methods

- (void)authorizeWebView:(VdiskAuthorizeWebView *)webView didReceiveAuthorizeCode:(NSString *)code {
    
    [webView hide:YES];
    
    // if not canceled
    if (![code isEqualToString:@"21330"]) {
        
        [self requestAccessTokenWithAuthorizeCode:code];
    
    } else {
    
        if (_delegate && [_delegate respondsToSelector:@selector(authorizeDidCancel:)]) {
        
            [_delegate authorizeDidCancel:self];
        }
    }
}

#else


- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    
    NSString *callbackURL = [[event descriptorForKeyword:keyDirectObject] stringValue];
    
    NSRange range = [callbackURL rangeOfString:@"?"];
    
    if (range.location != NSNotFound) {
        
        NSString *uri = [callbackURL substringFromIndex:range.location + range.length];
        
        NSArray *items = [uri componentsSeparatedByString:@"&"];
        
        for (NSString *item in items) {
            
            NSArray *param = [item componentsSeparatedByString:@"="];
            
            if ([param count] == 2 && [(NSString *)[param objectAtIndex:0] isEqualToString:@"code"]) {
                
                NSString *code = [param objectAtIndex:1];
                
                if (![code isEqualToString:@"21330"]) {
                    
                    [self requestAccessTokenWithAuthorizeCode:code];
                }
                
                break;
            }
        }
    }
    
    [[NSAppleEventManager sharedAppleEventManager] removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL];
}

#endif

#pragma mark - VdiskRequestDelegate Methods

- (void)request:(VdiskRequest *)theRequest didFinishLoadingWithResult:(id)result {
    
    NSLog(@"%@", result);
    
    BOOL success = NO;
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *dict = (NSDictionary *)result;
        
        NSString *accessToken = [dict objectForKey:@"access_token"];
        NSString *refreshToken = [dict objectForKey:@"refresh_token"];
        NSString *userId = [dict objectForKey:@"uid"];
        //NSInteger seconds = [[dict objectForKey:@"expires_in"] intValue];
        NSInteger seconds = [[dict objectForKey:@"time_left"] intValue] + [[NSDate date] timeIntervalSince1970];
        
        success = accessToken && refreshToken && seconds;
        
        if (success && [_delegate respondsToSelector:@selector(authorize:didSucceedWithAccessToken:refreshToken:userID:expiresIn:)]) {
            
            [_delegate authorize:self didSucceedWithAccessToken:accessToken refreshToken:refreshToken userID:userId expiresIn:seconds];
        }
        
    }
    
    // should not be possible
    
    if (!success && [_delegate respondsToSelector:@selector(authorize:didFailWithError:)]) {
        
        NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:nil];
        
        if ([_delegate respondsToSelector:@selector(authorize:didFailWithError:)]) {
            
            [_delegate authorize:self didFailWithError:error];
        }
    }
}

- (void)request:(VdiskRequest *)theReqest didFailWithError:(NSError *)error {
    
    //NSLog(@"%@", error);
    
    if ([_delegate respondsToSelector:@selector(authorize:didFailWithError:)]) {
        
        [_delegate authorize:self didFailWithError:error];
    }
}

@end
