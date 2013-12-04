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

#import "VdiskRequest.h"
#import "VdiskUtil.h"
#import "VdiskJSON.h"
#import "VdiskSDKGlobal.h"
#import "VdiskError.h"
#import "ASIDownloadCache.h"




@interface VdiskRequest (Private)

+ (void)appendUTF8Body:(NSMutableData *)body dataString:(NSString *)dataString;
- (void)handleResponseData:(NSData *)data;
- (id)parseJSONData:(NSData *)data error:(NSError **)error;
- (id)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo;
- (void)failedWithError:(NSError *)error;

@end



@implementation VdiskRequest

@synthesize url = _url;
@synthesize httpMethod = _httpMethod;
@synthesize params = _params;
@synthesize httpHeaderFields = _httpHeaderFields;
@synthesize delegate = _delegate;
@synthesize request = _request;
@synthesize responseData = _responseData;
@synthesize udid = _udid;

#pragma mark - VdiskRequest Life Circle

- (id)init {
    
    if (self = [super init]) {
        
        //NSLog(@"request init");
    }
    
    return self;
}

- (void)dealloc {
    
    [_udid release], _udid = nil;
    
    [_url release], _url = nil;
    [_httpMethod release], _httpMethod = nil;
    [_params release], _params = nil;
    [_httpHeaderFields release], _httpHeaderFields = nil;
    
    [_responseData release];
	_responseData = nil;
    
    [_request clearDelegatesAndCancel];
    [_request release], _request = nil;
    
    _delegate = nil;
    
    [super dealloc];
}

#pragma mark - VdiskRequest Public Methods

+ (VdiskRequest *)requestWithURL:(NSString *)url httpMethod:(NSString *)httpMethod params:(NSDictionary *)params httpHeaderFields:(NSDictionary *)httpHeaderFields udid:(NSString *)udid delegate:(id<VdiskRequestDelegate>)delegate {
    
    VdiskRequest *request = [[[VdiskRequest alloc] init] autorelease];
    
    request.url = url;
    request.httpMethod = httpMethod;
    request.params = params;
    request.httpHeaderFields = httpHeaderFields;
    request.delegate = delegate;
    request.udid = udid;
    
    return request;
    
}

+ (VdiskRequest *)requestWithAccessToken:(NSString *)accessToken url:(NSString *)url httpMethod:(NSString *)httpMethod params:(NSDictionary *)params httpHeaderFields:(NSDictionary *)httpHeaderFields udid:(NSString *)udid delegate:(id<VdiskRequestDelegate>)delegate {
    
    
    // add the access_token field
    /*
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [mutableParams setObject:accessToken forKey:@"access_token"];
     */
    
    NSMutableDictionary *mutableHttpHeaderFields = [NSMutableDictionary dictionaryWithDictionary:httpHeaderFields];
    [mutableHttpHeaderFields setObject:[NSString stringWithFormat:@"OAuth2 %@", accessToken] forKey:@"Authorization"];
    
    
    return [VdiskRequest requestWithURL:url httpMethod:httpMethod params:params httpHeaderFields:mutableHttpHeaderFields udid:udid delegate:delegate];
    
}

+ (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params httpMethod:(NSString *)httpMethod {
    
    
    if (![httpMethod isEqualToString:@"GET"] || !params || [params count] < 1) {
        
        return baseURL;
    }
    
    NSURL *parsedURL = [NSURL URLWithString:baseURL];
	NSString *queryPrefix = parsedURL.query ? @"&" : @"?";
	NSString *query = [VdiskRequest stringFromDictionary:params];
	
	return [NSString stringWithFormat:@"%@%@%@", baseURL, queryPrefix, query];
    
}

- (void)connect {
    
    [self.request cancel];
    self.request = [self finalRequest];
    [_request setDelegate:self];
    [_request start];
}

- (void)start {

    [self connect];
}

- (void)disconnect {
    
    [_responseData release];
    _responseData = nil;
    
    [self.request clearDelegatesAndCancel];
    self.request = nil;
    self.params = nil;
}


+ (NSString *)stringFromDictionary:(NSDictionary *)dict {
    
    NSMutableArray *pairs = [NSMutableArray array];
    
	for (NSString *key in [dict keyEnumerator]) {
        
		if (!([[dict valueForKey:key] isKindOfClass:[NSString class]])) {
            
			continue;
		}
		
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [[dict objectForKey:key] URLEncodedString]]];
	}
	
	return [pairs componentsJoinedByString:@"&"];
}

- (NSUInteger)responseDataLength {
    
    if (_responseData != nil) {
        
        return [_responseData length];
    }
    
    return 0;
}


- (ASIFormDataRequest *)finalRequest {
    
    
    NSString *urlString = [VdiskRequest serializeURL:_url params:_params httpMethod:_httpMethod];
    
    ASIFormDataRequest *finalRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    //[finalRequest setDelegate:self];
    
    [finalRequest setUseCookiePersistence:NO];
	[finalRequest setUseSessionPersistence:NO];
	[finalRequest setValidatesSecureCertificate:NO];
    [finalRequest setShouldRedirect:NO];
    [finalRequest setRequestMethod:_httpMethod];
    [finalRequest setAllowCompressedResponse:YES];
    [finalRequest setShouldWaitToInflateCompressedResponses:NO];
    [finalRequest setShouldAttemptPersistentConnection:YES];
    [finalRequest setNumberOfTimesToRetryOnTimeout:3];
    [finalRequest addRequestHeader:@"x-vdisk-device-uuid" value:_udid];
    [finalRequest setShouldAttemptPersistentConnection:YES];
    [finalRequest setTimeOutSeconds:16.0];
    [finalRequest setPersistentConnectionTimeoutSeconds:30.0];
    
    /* 缓存相关
    [finalRequest setDownloadCache:[ASIDownloadCache sharedCache]];
    //[finalRequest setCachePolicy:ASIFallbackToCacheIfLoadFailsCachePolicy];
    [finalRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    */

    if ([_httpMethod isEqualToString:@"POST"]) {
        
        for (NSString *key in [_params keyEnumerator]) {
            
            [finalRequest setPostValue:[_params objectForKey:key] forKey:key];
        }
    }
    
    for (NSString *key in [_httpHeaderFields keyEnumerator]) {
        
        [finalRequest addRequestHeader:key value:[_httpHeaderFields objectForKey:key]];
    }
    
    
#if DEBUG_CURL_LOG
    
    NSString *curlString = @"[CURL] curl";
    
    for (NSString *key in [_httpHeaderFields allKeys]) {
        
        curlString = [curlString stringByAppendingFormat:@" -H '%@:%@'", key, [_httpHeaderFields objectForKey:key]];
    }
    
    if ([_httpMethod isEqualToString:@"POST"]) {
        
        curlString = [curlString stringByAppendingString:@" -d \""];
        
        for (NSString *key in [_params keyEnumerator]) {

            curlString = [curlString stringByAppendingFormat:@"%@=%@&", key, [_params objectForKey:key]];
        }
        
        curlString = [curlString stringByAppendingString:@"\""];
    }
    
    curlString = [curlString stringByAppendingFormat:@" \"%@\" -k -vv", urlString];
    
    NSLog(@"%@", curlString);
    
#endif
    
    
    return finalRequest;
}

- (void)cancel {
    
    [self disconnect];
}

#pragma mark - VdiskRequest Private Methods

+ (void)appendUTF8Body:(NSMutableData *)body dataString:(NSString *)dataString {
    
    [body appendData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)handleResponseData:(NSData *)data {
    
    if ([_delegate respondsToSelector:@selector(request:didReceiveRawData:)]) {
        
        [_delegate request:self didReceiveRawData:data];
    }
	
	NSError *error = nil;
    
	id result = [self parseJSONData:data error:&error];
	
	if (error) {
        
		[self failedWithError:error];
        
	} else {
        
        if ([_delegate respondsToSelector:@selector(request:didFinishLoadingWithResult:)]) {
            
            [_delegate request:self didFinishLoadingWithResult:(result == nil ? data : result)];
		}
	}
}

- (id)parseJSONData:(NSData *)data error:(NSError **)error {
	
	NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	VdiskJSON *jsonParser = [[VdiskJSON alloc]init];
	
	NSError *parseError = nil;
	id result = [jsonParser objectWithString:dataString error:&parseError];
	
	if (parseError) {
        
        if (error != nil) {
            
            //*error = [self errorWithCode:kVdiskErrorCodeSDK userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", kVdiskSDKErrorCodeParseError] forKey:kVdiskSDKErrorCodeKey]];
            *error = [self errorWithCode:kVdiskErrorInvalidResponse userInfo:@{@"errorMessage":[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]}];
        }
	}
    
	[dataString release];
	[jsonParser release];
	
	if ([result isKindOfClass:[NSDictionary class]]) {
        
		if ([result objectForKey:@"error_code"] != nil || [result objectForKey:@"code"] != nil) {
            
			if (error != nil) {
                
                if ([result objectForKey:@"error_code"]) {
                    
                    *error = [self errorWithCode:[[result objectForKey:@"error_code"] intValue] userInfo:result];
                }
                
				if ([result objectForKey:@"code"] != nil) {
                    
                    *error = [self errorWithCode:[[result objectForKey:@"code"] intValue] userInfo:result];
                }
			}
		}
	}
	
	return result;
}

- (id)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo {
    
    return [NSError errorWithDomain:kVdiskErrorDomain code:code userInfo:userInfo];
}

- (void)failedWithError:(NSError *)error {
    
    
	if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
        
		[_delegate request:self didFailWithError:error];
	}
}


#pragma mark - NSURLConnection Delegate Methods


- (void)requestStarted:(ASIHTTPRequest *)request {
    
}

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders {
    
    self.responseData = [[[NSMutableData alloc] init] autorelease];
    
	if ([_delegate respondsToSelector:@selector(request:didReceiveResponseHeaders:)]) {
        
		[_delegate request:self didReceiveResponseHeaders:responseHeaders];
	}
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    
    //NSLog(@"%@", request.responseHeaders);
    //NSLog(@"%@", request.requestHeaders);
    
    
    NSData *data = [[[NSData alloc] initWithData:_responseData] autorelease];
    
    self.responseData = nil;
    self.request = nil;
    
    [self handleResponseData:data];
    
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    
    self.responseData = nil;
    self.request = nil;
    [self failedWithError:request.error];
    
}

- (void)request:(ASIHTTPRequest *)request didReceiveData:(NSData *)data {
    
    [_responseData appendData:data];
}


@end