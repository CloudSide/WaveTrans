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

#import "VdiskRestClient.h"

#import "VdiskAccountInfo.h"
#import "VdiskError.h"
#import "VdiskDeltaEntry.h"
#import "VdiskLog.h"
#import "VdiskMetadata.h"
#import "VdiskComplexRequest.h"
#import "VdiskSDKGlobal.h"
#import "VdiskUtil.h"
#import "VdiskJSON.h"
#import "ASIFormDataRequest.h"
#import "VdiskSharesMetadata.h"


#pragma - mark VdiskRestClient ()


@interface VdiskRestClient ()

- (ASIFormDataRequest *)requestWithHost:(NSString *)host path:(NSString *)path parameters:(NSDictionary *)params;
- (ASIFormDataRequest *)requestWithHost:(NSString *)host path:(NSString *)path parameters:(NSDictionary *)params method:(NSString *)method;
- (BOOL)checkSessionStatus;
- (NSDictionary *)requestHeadersWithWeiboAccessTokenAuthorization;

@end


#pragma - mark VdiskRestClient 

@implementation VdiskRestClient

- (id)initWithSession:(VdiskSession *)session {
    
    if (!session) {
        
        VdiskLogError(@"VdiskSDK: cannot initialize a VdiskRestClient with a nil session");
        return nil;
    }
    
    if ((self = [super init])) {
        
        _session = [session retain];
        _userId = [[session userID] retain];
        _root = [session.appRoot retain];
        _requests = [[NSMutableSet alloc] init];
        _loadRequests = [[NSMutableDictionary alloc] init];
        _imageLoadRequests = [[NSMutableDictionary alloc] init];
        _uploadRequests = [[NSMutableDictionary alloc] init];
        
        _maxOperationCount = 0;
        _requestQueue = nil;
        _operationLock = nil;
    }
    
    return self;
}

- (id)initWithSession:(VdiskSession *)session maxConcurrent:(NSUInteger)maxConcurrent maxOperationCount:(NSUInteger)maxOperationCount {

    if (self = [self initWithSession:session]) {
        
        _operationLock = [[NSRecursiveLock alloc] init];
        _requestQueue = [[NSOperationQueue alloc] init];
        [_requestQueue setMaxConcurrentOperationCount:maxConcurrent];
        
        if (maxOperationCount < 1) {
            
            _maxOperationCount = 1;
        
        } else {
        
            _maxOperationCount = maxOperationCount;
        }
    }
    
    return self;
}


- (void)readyToRequest:(VdiskComplexRequest *)request {

    if (_requestQueue != nil && _maxOperationCount > 0) {
        
        [_operationLock lock];
        
        if (_requestQueue.operationCount >= _maxOperationCount) {
            
            @try {
                
                VdiskComplexRequest *firstRequest = (VdiskComplexRequest *)[_requestQueue.operations objectAtIndex:0];
                [firstRequest cancel];
            
            } @catch (NSException *exception) {
              
                NSLog(@"readyToRequest: %@", exception);
                
            } @finally {
                
                
            }
        }
        
        [_requestQueue addOperation:request];
        
        [_operationLock unlock];
        
    } else {
    
        [request start];
    }
}


- (void)cancelAllRequests {
    
    for (VdiskComplexRequest *request in _requests) {
    
        [request clearSelectorsAndCancel];
    }
    
    [_requests removeAllObjects];
    
    for (VdiskComplexRequest *request in [_loadRequests allValues]) {
        
        [request clearSelectorsAndCancel];
    }
    
    [_loadRequests removeAllObjects];
    
    for (VdiskComplexRequest *request in [_imageLoadRequests allValues]) {
        
        [request clearSelectorsAndCancel];
    }
    
    [_imageLoadRequests removeAllObjects];
    
    for (VdiskComplexRequest *request in [_uploadRequests allValues]) {
      
        [request clearSelectorsAndCancel];
    }
    
    [_uploadRequests removeAllObjects];
}


- (void)dealloc {
    
    [self cancelAllRequests];
    
    [_requests release];
    [_loadRequests release];
    [_imageLoadRequests release];
    [_uploadRequests release];
    [_session release];
    [_userId release];
    [_root release];
    
    [_operationLock release], _operationLock = nil;
    [_requestQueue release], _requestQueue = nil;
    
    [super dealloc];
}



@synthesize delegate = _delegate;


- (void)loadMetadata:(NSString *)path withParams:(NSDictionary *)params {
    
    NSString *fullPath = [NSString stringWithFormat:@"/metadata/%@%@", _root, path];
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:params];
    
    //urlRequest.url = [NSURL URLWithString:@"http://www.baidu.com/"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadMetadata:)] autorelease];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:path forKey:@"path"];
    
    if (params) {
        
        [userInfo addEntriesFromDictionary:params];
    }
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)loadMetadata:(NSString *)path {
    
    [self loadMetadata:path withParams:nil];
}

- (void)loadMetadata:(NSString *)path withHash:(NSString *)hash {
    
    NSDictionary *params = nil;
    
    if (hash) {
    
        params = [NSDictionary dictionaryWithObject:hash forKey:@"hash"];
    }
    
    [self loadMetadata:path withParams:params];
}

- (void)loadMetadata:(NSString *)path atRev:(NSString *)rev {
    
    NSDictionary *params = nil;
    
    if (rev) {
        
        params = [NSDictionary dictionaryWithObject:rev forKey:@"rev"];
    }
    
    [self loadMetadata:path withParams:params];
}

- (void)requestDidLoadMetadata:(VdiskComplexRequest *)request {
    
    if (request.statusCode == 304) {
        
        if ([_delegate respondsToSelector:@selector(restClient:metadataUnchangedAtPath:)]) {
            
            NSString *path = [request.userInfo objectForKey:@"path"];
            [_delegate restClient:self metadataUnchangedAtPath:path];
        }
        
    } else if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadMetadataFailedWithError:)]) {
            [_delegate restClient:self loadMetadataFailedWithError:request.error];
        }
        
    } else {
        
        SEL sel = @selector(parseMetadataWithRequest:resultThread:);
        NSMethodSignature *sig = [self methodSignatureForSelector:sel];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:self];
        [inv setSelector:sel];
        [inv setArgument:&request atIndex:2];
        NSThread *currentThread = [NSThread currentThread];
        [inv setArgument:&currentThread atIndex:3];
        [inv retainArguments];
        [inv performSelectorInBackground:@selector(invoke) withObject:nil];
    }
    
    [_requests removeObject:request];
}


- (void)parseMetadataWithRequest:(VdiskComplexRequest *)request resultThread:(NSThread *)thread {
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    //NSDictionary *result = (NSDictionary *)[request resultJSON];
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
        
    VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
    
    if (metadata) {
        
        [self performSelector:@selector(didParseMetadata:) onThread:thread withObject:metadata waitUntilDone:NO];
    
    } else {
        
        [self performSelector:@selector(parseMetadataFailedForRequest:) onThread:thread withObject:request waitUntilDone:NO];
    }
    
    [pool drain];
}


- (void)didParseMetadata:(VdiskMetadata *)metadata {
    
    if ([_delegate respondsToSelector:@selector(restClient:loadedMetadata:)]) {
    
        [_delegate restClient:self loadedMetadata:metadata];
    }
}

- (void)parseMetadataFailedForRequest:(VdiskComplexRequest *)request {
    
    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
    
    VdiskLogWarning(@"VdiskSDK: error parsing metadata");
    
    if ([_delegate respondsToSelector:@selector(restClient:loadMetadataFailedWithError:)]) {
    
        [_delegate restClient:self loadMetadataFailedWithError:error];
    }
}


- (void)loadDelta:(NSString *)cursor {
    
    NSDictionary *params = nil;
    
    if (cursor) {
    
        params = [NSDictionary dictionaryWithObject:cursor forKey:@"cursor"];
    }
    
    NSString *fullPath = [NSString stringWithFormat:@"/delta"];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadDelta:)] autorelease];
    
    request.userInfo = params;
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidLoadDelta:(VdiskComplexRequest *)request {
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadDeltaFailedWithError:)]) {
        
            [_delegate restClient:self loadDeltaFailedWithError:request.error];
        }
        
    } else {
        
        SEL sel = @selector(parseDeltaWithRequest:resultThread:);
        NSMethodSignature *sig = [self methodSignatureForSelector:sel];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:self];
        [inv setSelector:sel];
        [inv setArgument:&request atIndex:2];
        NSThread *currentThread = [NSThread currentThread];
        [inv setArgument:&currentThread atIndex:3];
        [inv retainArguments];
        [inv performSelectorInBackground:@selector(invoke) withObject:nil];
    }
    
    [_requests removeObject:request];
}

- (void)parseDeltaWithRequest:(VdiskComplexRequest *)request resultThread:(NSThread *)thread {
    
    @autoreleasepool {
        
        NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
        
        if (result) {
            
            NSArray *entryArrays = [result objectForKey:@"entries"];
            NSMutableArray *entries = [NSMutableArray arrayWithCapacity:[entryArrays count]];
            
            for (NSArray *entryArray in entryArrays) {
                
                VdiskDeltaEntry *entry = [[VdiskDeltaEntry alloc] initWithArray:entryArray];
                [entries addObject:entry];
                [entry release];
            }
            
            BOOL reset = [[result objectForKey:@"reset"] boolValue];
            NSString *cursor = [result objectForKey:@"cursor"];
            BOOL hasMore = [[result objectForKey:@"has_more"] boolValue];
            
            SEL sel = @selector(restClient:loadedDeltaEntries:reset:cursor:hasMore:);
            
            if ([_delegate respondsToSelector:sel]) {
                
                NSMethodSignature *sig = [(NSObject *)_delegate methodSignatureForSelector:sel];
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                [inv setTarget:_delegate];
                [inv setSelector:sel];
                [inv setArgument:&self atIndex:2];
                [inv setArgument:&entries atIndex:3];
                [inv setArgument:&reset atIndex:4];
                [inv setArgument:&cursor atIndex:5];
                [inv setArgument:&hasMore atIndex:6];
                [inv retainArguments];
                [inv performSelector:@selector(invoke) onThread:thread withObject:nil waitUntilDone:NO];
            }
            
        } else {
            
            [self performSelector:@selector(parseDeltaFailedForRequest:) onThread:thread withObject:request waitUntilDone:NO];
        }
    }
}

- (void)parseDeltaFailedForRequest:(VdiskComplexRequest *)request {
    
    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
    
    VdiskLogWarning(@"VdiskSDK: error parsing metadata");
    
    if ([_delegate respondsToSelector:@selector(restClient:loadDeltaFailedWithError:)]) {
    
        [_delegate restClient:self loadDeltaFailedWithError:error];
    }
}

- (void)loadFile:(NSString *)path atRev:(NSString *)rev intoPath:(NSString *)destPath {

    [self loadFile:path atRev:rev intoPath:destPath root:_root];
}

- (void)loadFile:(NSString *)path atRev:(NSString *)rev intoPath:(NSString *)destPath root:(NSString *)root {
    
    NSString *fullPath = [NSString stringWithFormat:@"/files/%@%@", root, path];
    
    NSDictionary *params = nil;
    
    if (rev) {
    
        params = [NSDictionary dictionaryWithObject:rev forKey:@"rev"];
    }
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:params];
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadFile:)] autorelease];
    
    request.resultFilename = destPath;
    request.downloadProgressSelector = @selector(requestLoadProgress:);
    request.requestWillRedirectSelector = @selector(loadFileWillRedirect:);
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        path, @"path", 
                        destPath, @"destinationPath", 
                        rev, @"rev",
                        @"download", @"action", nil];
    
    if (![_loadRequests objectForKey:path]) {
        
        [_loadRequests setObject:request forKey:path];
        [self readyToRequest:request];
    }
    
}

- (void)loadFile:(NSString *)path intoPath:(NSString *)destPath {
    
    [self loadFile:path atRev:nil intoPath:destPath];
}

- (void)loadFileOfAddressBookAtRev:(NSString *)rev intoPath:(NSString *)destinationPath {

    [self loadFile:@"/" atRev:rev intoPath:destinationPath root:@"contact"];
}

- (void)cancelFileLoad:(NSString *)path {
    
    VdiskComplexRequest *outstandingRequest = [_loadRequests objectForKey:path];
    
    if (outstandingRequest) {
    
        [outstandingRequest clearSelectorsAndCancel];
        [_loadRequests removeObjectForKey:path];
    }
}


- (void)requestLoadProgress:(VdiskComplexRequest *)request {
    
    if ([_delegate respondsToSelector:@selector(restClient:loadProgress:forFile:)]) {
    
        [_delegate restClient:self loadProgress:request.downloadProgress forFile:request.resultFilename];
    }
}

- (NSNumber *)loadFileWillRedirect:(VdiskComplexRequest *)request {

    if ([request statusCode] == 302) {
        
        NSDictionary *headers = [request.request responseHeaders];
        
        if ([headers objectForKey:@"Location"]) {
            
            if ([_delegate respondsToSelector:@selector(restClient:loadedFileRealDownloadURL:metadata:)]) {
                
                NSDictionary *metadataDict = [request xVdiskMetadataJSON];
                VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:metadataDict] autorelease];
                BOOL allowRedirect = [_delegate restClient:self loadedFileRealDownloadURL:[NSURL URLWithString:[headers objectForKey:@"Location"]] metadata:metadata];
                
                if (!allowRedirect) {
                    
                    NSString *path = [request.userInfo objectForKey:@"path"];
                    [_loadRequests removeObjectForKey:path];
                }
                
                return [NSNumber numberWithBool:allowRedirect];
            }
        }
    }
    
    return [NSNumber numberWithBool:YES];
}


- (void)restClient:(VdiskRestClient *)restClient loadedFile:(NSString *)destPath contentType:(NSString *)contentType eTag:(NSString *)eTag {
    
    // Empty selector to get the signature from
}

- (void)requestDidLoadFile:(VdiskComplexRequest *)request {
    
    NSString *path = [request.userInfo objectForKey:@"path"];
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if (request.error.code != 302 && [_delegate respondsToSelector:@selector(restClient:loadFileFailedWithError:)]) {
        
            [_delegate restClient:self loadFileFailedWithError:request.error];
        }
        
    } else {
        
        NSString *filename = request.resultFilename;
        NSDictionary *headers = [request.request responseHeaders];
        NSString *contentType = [headers objectForKey:@"Content-Type"];
        NSDictionary *metadataDict = [request xVdiskMetadataJSON];
        NSString *eTag = [headers objectForKey:@"Etag"];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedFile:)]) {
        
            [_delegate restClient:self loadedFile:filename];
        
        } else if ([_delegate respondsToSelector:@selector(restClient:loadedFile:contentType:metadata:)]) {
        
            VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:metadataDict] autorelease];
            [_delegate restClient:self loadedFile:filename contentType:contentType metadata:metadata];
        
        } else if ([_delegate respondsToSelector:@selector(restClient:loadedFile:contentType:)]) {
        
            // This callback is deprecated and this block exists only for backwards compatibility.
            [_delegate restClient:self loadedFile:filename contentType:contentType];
        
        } else if ([_delegate respondsToSelector:@selector(restClient:loadedFile:contentType:eTag:)]) {
            
            // This code is for the official Vdisk client to get eTag information from the server
            NSMethodSignature *signature = [self methodSignatureForSelector:@selector(restClient:loadedFile:contentType:eTag:)];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:_delegate];
            [invocation setSelector:@selector(restClient:loadedFile:contentType:eTag:)];
            [invocation setArgument:&self atIndex:2];
            [invocation setArgument:&filename atIndex:3];
            [invocation setArgument:&contentType atIndex:4];
            [invocation setArgument:&eTag atIndex:5];
            [invocation invoke];
        }
    }
    
    [_loadRequests removeObjectForKey:path];
}


- (void)loadFileWithSharesMetadata:(VdiskSharesMetadata *)sharesMetadata intoPath:(NSString *)destPath {

    NSString *lowercaseURL = [sharesMetadata.url lowercaseString];
    NSRange expiresRange = [lowercaseURL rangeOfString:@"expires="];
    
    if (expiresRange.location != NSNotFound) {
        
        NSString *subString = nil;
        
        @try {
            
            subString = [lowercaseURL substringWithRange:NSMakeRange(expiresRange.location + expiresRange.length, 10)];
            
            if (subString != nil) {
                
                NSDate *now = [NSDate date];
                
                if ([now compare:[NSDate dateWithTimeIntervalSince1970:[subString doubleValue]]] == NSOrderedDescending) {
                    
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                              sharesMetadata.url, @"url",
                                              destPath, @"destinationPath",
                                              sharesMetadata, @"sharesMetadata",
                                              @"download", @"action", nil];
                    
                    NSInteger errorCode = kVdiskErrorS3URLExpired;
                    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:errorCode userInfo:userInfo];
                    NSString *errorMsg = @"VdiskSDK: S3 Download URL Expired";
                    
                    VdiskLogWarning(@"VdiskSDK: %@ (%@)", errorMsg, sharesMetadata.url);
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadFileFailedWithError:sharesMetadata:)]) {
                        
                        [_delegate restClient:self loadFileFailedWithError:error sharesMetadata:sharesMetadata];
                    }
                    
                    return;

                }
            }
        
        } @catch (NSException *exception) {
            
            NSLog(@"%@", exception);
            
        } @finally { }
        
    }
    
    ASIFormDataRequest *urlRequest = [[VdiskRequest requestWithURL:sharesMetadata.url httpMethod:@"GET" params:nil httpHeaderFields:nil udid:[VdiskSession sharedSession].udid delegate:nil] finalRequest];
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadFileWithSharesMetadata:)] autorelease];
    
    request.resultFilename = destPath;
    request.downloadProgressSelector = @selector(requestLoadFileWithSharesMetadataProgress:);
    
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        sharesMetadata.url, @"url",
                        destPath, @"destinationPath",
                        sharesMetadata, @"sharesMetadata", 
                        @"download", @"action", nil];
    
    [_loadRequests setObject:request forKey:sharesMetadata.url];
    
    request.metadataForDownload = sharesMetadata;
        
    [self readyToRequest:request];
}

- (void)requestLoadFileWithSharesMetadataProgress:(VdiskComplexRequest *)request {
    
    if ([_delegate respondsToSelector:@selector(restClient:loadProgress:forFile:sharesMetadata:)]) {
        
        [_delegate restClient:self loadProgress:request.downloadProgress forFile:request.resultFilename sharesMetadata:[request.userInfo objectForKey:@"sharesMetadata"]];
    }
}

- (void)requestDidLoadFileWithSharesMetadata:(VdiskComplexRequest *)request {

    VdiskSharesMetadata *sharesMetadata = [request.userInfo objectForKey:@"sharesMetadata"];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if (request.error.code != 302 && [_delegate respondsToSelector:@selector(restClient:loadFileFailedWithError:sharesMetadata:)]) {
            
            [_delegate restClient:self loadFileFailedWithError:request.error sharesMetadata:sharesMetadata];
        }
        
    } else {
        
        NSString *filename = request.resultFilename;
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedFile:sharesMetadata:)]) {
            
            [_delegate restClient:self loadedFile:filename sharesMetadata:sharesMetadata];
            
        }
    }
    
    [_loadRequests removeObjectForKey:sharesMetadata.url];
}

- (void)cancelFileLoadWithSharesMetadata:(VdiskSharesMetadata *)sharesMetadata {

    VdiskComplexRequest *outstandingRequest = [_loadRequests objectForKey:sharesMetadata.url];
    
    if (outstandingRequest) {
        
        [outstandingRequest clearSelectorsAndCancel];
        
        [_loadRequests removeObjectForKey:sharesMetadata.url];
    }
}


- (NSString *)thumbnailKeyForPath:(NSString *)path size:(NSString *)size {
    
    return [NSString stringWithFormat:@"%@##%@", path, size];
}

- (id)thumbnailKeyForMetadata:(VdiskMetadata *)metadata size:(NSString *)size {
    
    if (metadata == nil || size == nil) {
        
        return @[@"nil", @"nil"];
    }
    
    return @[size, metadata];
}


- (void)_loadThumbnail:(NSString *)path ofSize:(NSString *)size intoPath:(NSString *)destinationPath metadata:(VdiskMetadata *)metadata {
    
    NSString *fullPath = [NSString stringWithFormat:@"/thumbnails/%@%@", _root, path];
    
    NSString *format = @"JPEG";
    
    if ([path length] > 4) {
    
        NSString *extension = [[path substringFromIndex:[path length] - 4] uppercaseString];
        
        if ([[NSSet setWithObjects:@".PNG", @".GIF", nil] containsObject:extension]) {
        
            format = @"PNG";
        }
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:format forKey:@"format"];
    
    if (size) {
        
        [params setObject:size forKey:@"size"];
    }
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:params];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadThumbnail:)]
     autorelease];
    
    request.downloadProgressSelector = @selector(requestLoadThumbnailProgress:);
    
    request.resultFilename = destinationPath;
    
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        _root, @"root", 
                        path, @"path", 
                        destinationPath, @"destinationPath", 
                        size, @"size",
                        metadata, @"metadata", nil];
    
    [request setAllowResumeForFileDownloads:NO];
    
    if (![_imageLoadRequests objectForKey:[self thumbnailKeyForPath:path size:size]]) {
        
        [_imageLoadRequests setObject:request forKey:[self thumbnailKeyForPath:path size:size]];
        [self readyToRequest:request];
    }
}

- (void)loadThumbnail:(NSString *)path ofSize:(NSString *)size intoPath:(NSString *)destinationPath {

    [self _loadThumbnail:path ofSize:size intoPath:destinationPath metadata:nil];
}

- (void)loadThumbnailWithMetadata:(VdiskMetadata *)metadata ofSize:(NSString *)size intoPath:(NSString *)destinationPath params:(NSDictionary *)params {

    if ([metadata isKindOfClass:[VdiskSharesMetadata class]]) {
        
        NSMutableDictionary *mutableParams = nil;
        
        if (params != nil) {
            
            mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
            
        } else {
            
            mutableParams = [NSMutableDictionary dictionary];
        }
        
        if (size) {
            
            [mutableParams setObject:size forKey:@"size"];
        }
        
        NSString *apiName = nil;
        
        if ([(VdiskSharesMetadata *)metadata sharesMetadataType] == kVdiskSharesMetadataTypePublic) {
            
            apiName = @"/share/thumbnails";
            
            [mutableParams setValue:[(VdiskSharesMetadata *)metadata cpRef] forKey:@"copy_ref"];
            [mutableParams setValue:@"signRequest" forKey:@"x-vdisk-local-userinfo"];
            
        } else if ([(VdiskSharesMetadata *)metadata sharesMetadataType] == kVdiskSharesMetadataTypeFromFriend) {
            
            apiName = @"/sharefriend/thumbnails";
            
            [mutableParams setValue:[(VdiskSharesMetadata *)metadata cpRef] forKey:@"from_copy_ref"];
            
            if ([(VdiskSharesMetadata *)metadata path] && [[(VdiskSharesMetadata *)metadata path] isKindOfClass:[NSString class]]) {
                
                [mutableParams setValue:[(VdiskSharesMetadata *)metadata path] forKey:@"path"];
            }
            
        } else if ([(VdiskSharesMetadata *)metadata sharesMetadataType] == kVdiskSharesMetadataTypeLinkcommon) {
            
            apiName = @"/linkcommon/thumbnails";
            
            [mutableParams setValue:[(VdiskSharesMetadata *)metadata cpRef] forKey:@"from_copy_ref"];
            [mutableParams setValue:[(VdiskSharesMetadata *)metadata accessCode] forKey:@"access_code"];
        }
        
        ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:apiName parameters:mutableParams];
        
        VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadThumbnail:)]
                                        autorelease];
        
        request.downloadProgressSelector = @selector(requestLoadThumbnailProgress:);
        
        request.resultFilename = destinationPath;
        
        request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                            _root, @"root",
                            metadata.path, @"path",
                            destinationPath, @"destinationPath",
                            size, @"size",
                            metadata, @"metadata", nil];
        
        [request setAllowResumeForFileDownloads:NO];
        
        if (![_imageLoadRequests objectForKey:[self thumbnailKeyForMetadata:metadata size:size]]) {
            
            [_imageLoadRequests setObject:request forKey:[self thumbnailKeyForMetadata:metadata size:size]];
            [self readyToRequest:request];
        }
        
    } else if ([metadata isKindOfClass:[VdiskMetadata class]]) {
    
        [self _loadThumbnail:metadata.path ofSize:size intoPath:destinationPath metadata:metadata];
    }
}

- (void)requestLoadThumbnailProgress:(VdiskComplexRequest *)request {

    if ([_delegate respondsToSelector:@selector(restClient:loadThumbnailProgress:destPath:metadata:size:)]) {
        
        NSString *filename = request.resultFilename;
        
        VdiskMetadata *metadata = [request.userInfo objectForKey:@"metadata"];
        NSString *size = [request.userInfo objectForKey:@"size"];
        
        if (metadata == nil) {

            NSDictionary *metadataDict = [request xVdiskMetadataJSON];
            metadata = [[[VdiskMetadata alloc] initWithDictionary:metadataDict] autorelease];
        }
        
        [_delegate restClient:self loadThumbnailProgress:request.downloadProgress destPath:filename metadata:metadata size:size];
    }
}

- (void)requestDidLoadThumbnail:(VdiskComplexRequest *)request {
    
    VdiskMetadata *metadata = [request.userInfo objectForKey:@"metadata"];
    
    if (metadata == nil) {
        
        NSDictionary *metadataDict = [request xVdiskMetadataJSON];
        metadata = [[[VdiskMetadata alloc] initWithDictionary:metadataDict] autorelease];
    }
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadThumbnailFailedWithError:metadata:size:)]) {
            
            NSString *size = [request.userInfo objectForKey:@"size"];
            [_delegate restClient:self loadThumbnailFailedWithError:request.error metadata:metadata size:size];
            
        } else if ([_delegate respondsToSelector:@selector(restClient:loadThumbnailFailedWithError:)]) {
        
            [_delegate restClient:self loadThumbnailFailedWithError:request.error];
        }
        
    } else {
        
        NSString *filename = request.resultFilename;
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedThumbnail:metadata:size:)]) {
        
            NSString *size = [request.userInfo objectForKey:@"size"];
            [_delegate restClient:self loadedThumbnail:filename metadata:metadata size:size];
        
        } else if ([_delegate respondsToSelector:@selector(restClient:loadedThumbnail:)]) {
            
            // This callback is deprecated and this block exists only for backwards compatibility.
        
            [_delegate restClient:self loadedThumbnail:filename];
        }
    }
    
    NSString *path = [request.userInfo objectForKey:@"path"];
    NSString *size = [request.userInfo objectForKey:@"size"];
    
    [_imageLoadRequests removeObjectForKey:[self thumbnailKeyForPath:path size:size]];
    [_imageLoadRequests removeObjectForKey:[self thumbnailKeyForMetadata:metadata size:size]];
}


- (void)cancelThumbnailLoad:(NSString *)path size:(NSString *)size {
    
    NSString *key = [self thumbnailKeyForPath:path size:size];
    VdiskComplexRequest *request = [_imageLoadRequests objectForKey:key];
    
    if (request) {
    
        [request clearSelectorsAndCancel];
        [_imageLoadRequests removeObjectForKey:key];
    }
}

- (void)cancelThumbnailLoadWithMetadata:(VdiskMetadata *)metadata size:(NSString *)size {
    
    NSString *key = [self thumbnailKeyForMetadata:metadata size:size];
    VdiskComplexRequest *request = [_imageLoadRequests objectForKey:key];
    
    if (request) {
        
        [request clearSelectorsAndCancel];
        [_imageLoadRequests removeObjectForKey:key];
    }
}

- (NSString *)signatureForParams:(NSArray *)params url:(NSURL *)baseUrl {
   
    return nil;
}

- (ASIFormDataRequest *)requestForParams:(NSArray *)params urlString:(NSString *)urlString signature:(NSString *)sig {
    
    return nil;
}


- (void)locateComplexUploadHost {
    
    NSString *urlString = @"http://up.sinastorage.com/?extra&op=domain.json";
    
    ASIFormDataRequest *urlRequest = [[VdiskRequest requestWithURL:urlString httpMethod:@"GET" params:nil httpHeaderFields:nil udid:_session.udid delegate:nil] finalRequest];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLocateComplexUploadHost:)] autorelease];
    
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:_root, @"root", @"upload", @"action", @"complex", @"upload_type", nil];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidLocateComplexUploadHost:(VdiskComplexRequest *)request {
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:locateComplexUploadHostFailedWithError:)]) {
            
            [_delegate restClient:self locateComplexUploadHostFailedWithError:request.error];
        }
        
    } else {
        
        NSString *responseString = [[request resultString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *s3host = [responseString substringWithRange:NSMakeRange(1, [responseString length] - 2)];
        
        if ([s3host length] > 0) {
            
            if ([_delegate respondsToSelector:@selector(restClient:locatedComplexUploadHost:)]) {
                
                [_delegate restClient:self locatedComplexUploadHost:s3host];
            }
            
        } else {
            
            NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
            
            if ([_delegate respondsToSelector:@selector(restClient:locateComplexUploadHostFailedWithError:)]) {
                
                [_delegate restClient:self locateComplexUploadHostFailedWithError:error];
            }
        }
        
    }
    
    [_requests removeObject:request];
}

- (void)initializeComplexUpload:(NSString *)path uploadHost:(NSString *)uploadHost partTotal:(NSUInteger)partTotal size:(NSNumber *)size params:(NSDictionary *)params {
    
    NSMutableDictionary *initParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    
    [initParams setObject:_root forKey:@"root"];
    [initParams setObject:path forKey:@"path"];
    [initParams setObject:uploadHost forKey:@"s3host"];
    [initParams setObject:[[NSNumber numberWithUnsignedInteger:partTotal] stringValue] forKey:@"part_total"];
    [initParams setObject:[size stringValue] forKey:@"size"];
    [initParams setObject:@"application/octet-stream" forKey:@"type"];
    
    NSDictionary *requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   kVdiskAPIHost, @"host",
                                   @"/multipart/init", @"path",
                                   @"POST", @"method",
                                   initParams, @"params",
                                   nil];
    
    ASIFormDataRequest *urlRequest = [self requestWithParameters:requestParams];
    
    [requestParams release];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidInitializeComplexUpload:)] autorelease];
    
    request.userInfo = [[initParams mutableCopy] autorelease];
    [(NSMutableDictionary *)request.userInfo addEntriesFromDictionary:@{@"action" : @"upload", @"upload_type" : @"complex", @"destinationPath" : path, @"uploadTotalBytes" : [size stringValue]}];
    
    [initParams release];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidInitializeComplexUpload:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (!result) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:initializeComplexUploadFailedWithError:)]) {
            
            [_delegate restClient:self initializeComplexUploadFailedWithError:request.error];
        }
        
    } else {
                
        //NSDictionary *responseDic = (NSDictionary *)[request resultJSON];
        
        NSDictionary *responseDic = result;
        
        if ([responseDic objectForKey:@"path"] && [responseDic objectForKey:@"md5"] && [responseDic objectForKey:@"sha1"]) {
            
            VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:responseDic] autorelease];
            
            NSString *destPath = [request.userInfo objectForKey:@"destinationPath"];
            [(NSMutableDictionary *)request.userInfo setValue:@"blitz" forKey:@"upload_type"];
            
            if ([_delegate respondsToSelector:@selector(restClient:mergedComplexUpload:metadata:)]) {
                
                [_delegate restClient:self mergedComplexUpload:destPath metadata:metadata];
            }
            
        } else {
            
            [(NSMutableDictionary *)request.userInfo setValue:[responseDic objectForKey:@"upload_id"] forKey:@"uploadId"];
            
            if ([_delegate respondsToSelector:@selector(restClient:initializedComplexUpload:)]) {
                
                [_delegate restClient:self initializedComplexUpload:responseDic];
            }
        }
    }
    
    [_requests removeObject:request];
}

- (void)signComplexUpload:(NSString *)partRange uploadId:(NSString *)uploadId uploadKey:(NSString *)uploadKey {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                   _root, @"root",
                                   partRange, @"part_range",
                                   uploadKey, @"upload_key",
                                   uploadId, @"upload_id",
                                   nil];
    
    NSDictionary *requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   kVdiskAPIHost, @"host",
                                   @"/multipart/sign", @"path",
                                   @"POST", @"method",
                                   params, @"params",
                                   nil];
    [params release];
    
    ASIFormDataRequest *urlRequest = [self requestWithParameters:requestParams];
    [requestParams release];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidSignComplexUpload:)] autorelease];
    
    request.userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:uploadId, @"uploadId", uploadKey, @"uploadKey", partRange, @"partRange", nil];
    [(NSMutableDictionary *)request.userInfo addEntriesFromDictionary:@{@"action" : @"upload", @"upload_type" : @"complex"}];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidSignComplexUpload:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (!result) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:signComplexUploadFailedWithError:)]) {
            
            [_delegate restClient:self signComplexUploadFailedWithError:request.error];
        }
        
    } else {
        
        //NSDictionary *responseDic = (NSDictionary *)[request resultJSON];
        NSDictionary *responseDic = result;
        
        if ([_delegate respondsToSelector:@selector(restClient:signedComplexUpload:)]) {
            
            [_delegate restClient:self signedComplexUpload:responseDic];
        }
    }
    
    [_requests removeObject:request];
}

- (void)mergeComplexUpload:(NSString *)path uploadHost:(NSString *)uploadHost uploadId:(NSString *)uploadId uploadKey:(NSString *)uploadKey sha1:(NSString *)sha1 md5List:(NSString *)md5List params:(NSDictionary *)params {
    
    NSMutableDictionary *completeParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    
    [completeParams setObject:_root forKey:@"root"];
    [completeParams setObject:path forKey:@"path"];
    [completeParams setObject:uploadHost forKey:@"s3host"];
    [completeParams setObject:uploadId forKey:@"upload_id"];
    [completeParams setObject:uploadKey forKey:@"upload_key"];
    [completeParams setObject:sha1 forKey:@"sha1"];
    [completeParams setObject:md5List forKey:@"md5_list"];
    
    NSString *uploadTotalBytes = @"-";
    
    if ([completeParams objectForKey:@"upload_total_bytes"]) {
        
        uploadTotalBytes = [[[completeParams objectForKey:@"upload_total_bytes"] copy] autorelease];
        [completeParams removeObjectForKey:@"upload_total_bytes"];
        
    }
    
    NSDictionary *requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   kVdiskAPIHost, @"host",
                                   @"/multipart/complete", @"path",
                                   @"POST", @"method",
                                   completeParams, @"params",
                                   nil];
    [completeParams release];
    
    ASIFormDataRequest *urlRequest = [self requestWithParameters:requestParams];
    [urlRequest setTimeOutSeconds:100.0f];
    
    [requestParams release];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidMergeComplexUpload:)] autorelease];
    
    request.userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        path, @"destinationPath",
                        uploadId, @"uploadId",
                        uploadKey, @"uploadKey",
                        sha1, @"sha1",
                        md5List, @"md5List", nil];
    
    [(NSMutableDictionary *)request.userInfo addEntriesFromDictionary:@{@"action" : @"upload", @"upload_type" : @"complex", @"uploadTotalBytes" : uploadTotalBytes}];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidMergeComplexUpload:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (!result) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:mergeComplexUploadFailedWithError:)]) {
            
            [_delegate restClient:self mergeComplexUploadFailedWithError:request.error];
        }
        
    } else {
        
        //NSDictionary *responseDic = (NSDictionary *)[request resultJSON];
        
        NSDictionary *responseDic = result;
        
        VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:responseDic] autorelease];
        
        NSString *destPath = [request.userInfo objectForKey:@"destinationPath"];
        
        if ([_delegate respondsToSelector:@selector(restClient:mergedComplexUpload:metadata:)]) {
            
            [_delegate restClient:self mergedComplexUpload:destPath metadata:metadata];
        }
    }
    
    [_requests removeObject:request];
}

- (void)uploadFileOfAddressBookFromPath:(NSString *)sourcePath params:(NSDictionary *)params {

    [self uploadFile:@"" toPath:@"/" fromPath:sourcePath params:params root:@"contact" protocol:kVdiskProtocolHTTPS contentHost:kVdiskAPIContentSafeHost];
}

- (void)uploadFile:(NSString *)filename toPath:(NSString *)path fromPath:(NSString *)sourcePath params:(NSDictionary *)params {

    [self uploadFile:filename toPath:path fromPath:sourcePath params:params root:_root protocol:kVdiskProtocolHTTP contentHost:kVdiskAPIContentHost];
}

- (void)uploadFile:(NSString *)filename toPath:(NSString *)path fromPath:(NSString *)sourcePath params:(NSDictionary *)params root:(NSString *)root protocol:(NSString *)protocol contentHost:(NSString *)contentHost {
    
    if (![self checkSessionStatus]) {
        
        if (![_session isLinked]) {
            
            NSString *errorMsg = @"VdiskSDK: Access Token Empty";
            VdiskLogWarning(@"VdiskSDK: %@ (%@)", errorMsg, sourcePath);
            
            return;
        }
        
        /*
        
        NSString *destPath = [path stringByAppendingPathComponent:filename];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  sourcePath, @"sourcePath",
                                  destPath, @"destinationPath",
                                  @"upload", @"action",
                                  @"simple", @"upload_type", nil];
        
        NSInteger errorCode = kVdiskErrorSessionError;
        NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:errorCode userInfo:userInfo];
        NSString *errorMsg = @"VdiskSDK: Access Token Validation Failed / Access Token Expired / Access Token Empty";
        
        VdiskLogWarning(@"VdiskSDK: %@ (%@)", errorMsg, sourcePath);
        
        if ([_delegate respondsToSelector:@selector(restClient:uploadFileFailedWithError:)]) {
            
            [_delegate restClient:self uploadFileFailedWithError:error];
        }
        
        return;
         
         */
    }
    
    
    BOOL isDir = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:sourcePath isDirectory:&isDir];
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:sourcePath error:nil];
    
    if (!fileExists || isDir || !fileAttrs) {
    
        NSString *destPath = [path stringByAppendingPathComponent:filename];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  sourcePath, @"sourcePath",
                                  destPath, @"destinationPath",
                                  @"simple", @"upload_type", nil];
        
        NSInteger errorCode = isDir ? kVdiskErrorIllegalFileType : kVdiskErrorFileNotFound;
        NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:errorCode userInfo:userInfo];
        NSString *errorMsg = isDir ? @"Unable to upload folders" : @"File does not exist";
        
        VdiskLogWarning(@"VdiskSDK: %@ (%@)", errorMsg, sourcePath);
        
        if ([_delegate respondsToSelector:@selector(restClient:uploadFileFailedWithError:)]) {
        
            [_delegate restClient:self uploadFileFailedWithError:error];
        }
        
        return;
    }
    
    
    NSString *destPath = [path stringByAppendingPathComponent:filename];
    
    //HTTPS
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/files_put/%@%@", protocol, contentHost, kVdiskAPIVersion, root, [VdiskRestClient escapePath:destPath]];
        
    if (params != nil && [params isKindOfClass:[NSDictionary class]] && [params count] > 0) {
        
        urlString = [urlString stringByAppendingFormat:@"?%@", [VdiskRequest stringFromDictionary:params]];
    }
    
    
    //add globalParams
    if ([[_session.globalParams allKeys] count] > 0) {
        
        urlString = [VdiskRequest serializeURL:urlString params:_session.globalParams httpMethod:@"GET"];
    }
    
    
    NSString *contentLength = [NSString stringWithFormat: @"%qu", [fileAttrs fileSize]];
    
    NSDictionary *httpHeaderFields = @{@"Content-Length" : contentLength, @"Content-Type" : @"application/octet-stream", @"User-Agent" : [VdiskSession userAgent], @"Expect" : @"100-continue"};
    
    ASIFormDataRequest *urlRequest = [[VdiskRequest requestWithURL:urlString httpMethod:@"PUT" params:nil httpHeaderFields:httpHeaderFields udid:_session.udid delegate:nil] finalRequest];
    
    
    if (_session.sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        NSDictionary *requestHeaders = [self requestHeadersWithWeiboAccessTokenAuthorization];
        [urlRequest addRequestHeader:@"Authorization" value:[requestHeaders objectForKey:@"Authorization"]];
        
    } else {
        
        [urlRequest addRequestHeader:@"Authorization" value:[NSString stringWithFormat:@"OAuth2 %@", _session.accessToken]];
    }
            
	//[NSInputStream inputStreamWithFileAtPath:sourcePath]
    [urlRequest setShouldStreamPostDataFromDisk:YES];
    [urlRequest setPostBodyFilePath:sourcePath];
    [urlRequest setTimeOutSeconds:100.0f];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidUploadFile:)] autorelease];
    request.uploadProgressSelector = @selector(requestUploadProgress:);
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        sourcePath, @"sourcePath",
                        destPath, @"destinationPath",
                        @"upload", @"action",
                        @"simple", @"upload_type", nil];
    
    [_uploadRequests setObject:request forKey:destPath];
    
    [self readyToRequest:request];
}

- (void)uploadFile:(NSString *)filename toPath:(NSString *)path fromPath:(NSString *)sourcePath {
    
    [self uploadFile:filename toPath:path fromPath:sourcePath params:nil];
}

- (void)uploadFile:(NSString *)filename toPath:(NSString *)path withParentRev:(NSString *)parentRev fromPath:(NSString *)sourcePath {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@"false" forKey:@"overwrite"];
    
    if (parentRev) {
        
        [params setObject:parentRev forKey:@"parent_rev"];
    }
    
    [self uploadFile:filename toPath:path fromPath:sourcePath params:params];
}


- (void)requestUploadProgress:(VdiskComplexRequest *)request {
    
    NSString *sourcePath = [(NSDictionary*)request.userInfo objectForKey:@"sourcePath"];
    NSString *destPath = [request.userInfo objectForKey:@"destinationPath"];
    
    if ([_delegate respondsToSelector:@selector(restClient:uploadProgress:forFile:from:)]) {
        
        [_delegate restClient:self uploadProgress:request.uploadProgress forFile:destPath from:sourcePath];
    }
}


- (void)requestDidUploadFile:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (!result) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:uploadFileFailedWithError:)]) {
            
            [_delegate restClient:self uploadFileFailedWithError:request.error];
        }
        
    } else {
        
        VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
        
        NSString *sourcePath = [request.userInfo objectForKey:@"sourcePath"];
        NSString *destPath = [request.userInfo objectForKey:@"destinationPath"];
        
        if ([_delegate respondsToSelector:@selector(restClient:uploadedFile:from:metadata:)]) {
            
            [_delegate restClient:self uploadedFile:destPath from:sourcePath metadata:metadata];
        
        } else if ([_delegate respondsToSelector:@selector(restClient:uploadedFile:from:)]) {
        
            [_delegate restClient:self uploadedFile:destPath from:sourcePath];
        }
    }
    
    [_uploadRequests removeObjectForKey:[request.userInfo objectForKey:@"destinationPath"]];
}

- (void)cancelFileUpload:(NSString *)path {
    
    VdiskComplexRequest *request = [_uploadRequests objectForKey:path];
    
    if (request) {
    
        [request clearSelectorsAndCancel];
        [_uploadRequests removeObjectForKey:path];
    }
}


- (void)loadRevisionsForFile:(NSString *)path {
    
    [self loadRevisionsForFile:path limit:10];
}

- (void)loadRevisionsForFileOfAddressBookLimit:(NSInteger)limit {

    [self loadRevisionsForFile:@"/" limit:limit root:@"contact"];
}

- (void)loadRevisionsForFile:(NSString *)path limit:(NSInteger)limit {

    [self loadRevisionsForFile:path limit:limit root:_root];
}

- (void)loadRevisionsForFile:(NSString *)path limit:(NSInteger)limit root:(NSString *)root {
    
    NSString *fullPath = [NSString stringWithFormat:@"/revisions/%@%@", root, path];
    
    NSString *limitStr = [[NSNumber numberWithInteger:limit] stringValue];

    NSDictionary *params = [NSDictionary dictionaryWithObject:limitStr forKey:@"rev_limit"];
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:params];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadRevisions:)]
     autorelease];
    
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSNumber numberWithInt:limit], @"limit", nil];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidLoadRevisions:(VdiskComplexRequest *)request {
    
    [self checkForAuthenticationFailure:request];
    
    NSArray *resp = [request parseResponseAsType:[NSArray class]];
    
    if (!resp) {
        
        if ([_delegate respondsToSelector:@selector(restClient:loadRevisionsFailedWithError:)]) {
            
            [_delegate restClient:self loadRevisionsFailedWithError:request.error];
        }
        
    } else {
        
        NSMutableArray *revisions = [NSMutableArray arrayWithCapacity:[resp count]];
        
        for (NSDictionary *dict in resp) {
        
            VdiskMetadata *metadata = [[VdiskMetadata alloc] initWithDictionary:dict];
            [revisions addObject:metadata];
            [metadata release];
        }
        
        NSString *path = [request.userInfo objectForKey:@"path"];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedRevisions:forFile:)]) {
        
            [_delegate restClient:self loadedRevisions:revisions forFile:path];
        }
    }
    
    [_requests removeObject:request];
}

- (void)restoreFile:(NSString *)path toRev:(NSString *)rev {
    
    NSString *fullPath = [NSString stringWithFormat:@"/restore/%@%@", _root, path];
    NSDictionary *params = [NSDictionary dictionaryWithObject:rev forKey:@"rev"];
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:params method:@"POST"];
    
    VdiskComplexRequest* request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidRestoreFile:)]
     autorelease];
    
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        path, @"path",
                        rev, @"rev", nil];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidRestoreFile:(VdiskComplexRequest *)request {
    
    [self checkForAuthenticationFailure:request];
    
    NSDictionary *dict = [request parseResponseAsType:[NSDictionary class]];
    
    if (!dict) {
    
        if ([_delegate respondsToSelector:@selector(restClient:restoreFileFailedWithError:)]) {
        
            [_delegate restClient:self restoreFileFailedWithError:request.error];
        }
        
    } else {
        
        VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:dict] autorelease];
        
        if ([_delegate respondsToSelector:@selector(restClient:restoredFile:)]) {
        
            [_delegate restClient:self restoredFile:metadata];
        }
    }
    
    [_requests removeObject:request];
}


- (void)moveFrom:(NSString *)from_path toPath:(NSString *)to_path {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _root, @"root",
                            from_path, @"from_path",
                            to_path, @"to_path", nil];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/fileops/move" parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidMovePath:)]
     autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}



- (void)requestDidMovePath:(VdiskComplexRequest*)request {
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:movePathFailedWithError:)]) {
        
            [_delegate restClient:self movePathFailedWithError:request.error];
        }
        
    } else {
        
        NSDictionary *params = (NSDictionary *)request.userInfo;
        NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
        VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
        
        if ([_delegate respondsToSelector:@selector(restClient:movedPath:to:)]) {
            
            [_delegate restClient:self movedPath:[params valueForKey:@"from_path"] to:metadata];
        }
    }
    
    [_requests removeObject:request];
}


- (void)copyFrom:(NSString *)from_path toPath:(NSString *)to_path {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _root, @"root",
                            from_path, @"from_path",
                            to_path, @"to_path", nil];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/fileops/copy" parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCopyPath:)]
     autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}



- (void)requestDidCopyPath:(VdiskComplexRequest *)request {
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:copyPathFailedWithError:)]) {
        
            [_delegate restClient:self copyPathFailedWithError:request.error];
        }
        
    } else {
        
        NSDictionary *params = (NSDictionary *)request.userInfo;
        NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
        VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
        
        if ([_delegate respondsToSelector:@selector(restClient:copiedPath:to:)]) {
            
            [_delegate restClient:self copiedPath:[params valueForKey:@"from_path"] to:metadata];
        }
    }
    
    [_requests removeObject:request];
}


- (void)createCopyRef:(NSString *)path {
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:path forKey:@"path"];
    NSString *fullPath = [NSString stringWithFormat:@"/copy_ref/%@%@", _root, path];
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:nil method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCreateCopyRef:)]
     autorelease];
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}


- (void)requestDidCreateCopyRef:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (!result) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:createCopyRefFailedWithError:)]) {
        
            [_delegate restClient:self createCopyRefFailedWithError:request.error];
        }
        
    } else {
        
        NSString *copyRef = [result objectForKey:@"copy_ref"];
        
        if ([_delegate respondsToSelector:@selector(restClient:createdCopyRef:)]) {
        
            [_delegate restClient:self createdCopyRef:copyRef];
        }
    }
    
    [_requests removeObject:request];
}

- (void)createCopyRefAndAccessCode:(NSString *)path {

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", _root, @"root", nil];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/linkcommon/new" parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCreateCopyRefAndAccessCode:)]
                                    autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidCreateCopyRefAndAccessCode:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (!result) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:createCopyRefAndAccessCodeFailedWithError:)]) {
            
            [_delegate restClient:self createCopyRefAndAccessCodeFailedWithError:request.error];
        }
        
    } else {
        
        NSString *copyRef = [result objectForKey:@"copy_ref"];
        NSString *link = [result objectForKey:@"url"];
        NSString *accessCode = [result objectForKey:@"access_code"];
        
        if ([_delegate respondsToSelector:@selector(restClient:createdCopyRef:accessCode:link:)]) {
            
            [_delegate restClient:self createdCopyRef:copyRef accessCode:accessCode link:link];
        }
    }
    
    [_requests removeObject:request];
}

- (void)createCopyRef:(NSString *)path toFriends:(NSArray *)friends {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", [friends componentsJoinedByString:@","], @"sina_uids", _root, @"root", nil];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/sharefriend/new" parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCreateCopyRefToFriends:)]
                                    autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}



- (void)requestDidCreateCopyRefToFriends:(VdiskComplexRequest *)request {

    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (!result) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:createCopyRefToFriendsFailedWithError:)]) {
            
            [_delegate restClient:self createCopyRefToFriendsFailedWithError:request.error];
        }
        
    } else {
        
        NSString *copyRef = [result objectForKey:@"copy_ref"];
        NSString *link = [result objectForKey:@"url"];
        NSArray *friends = [(NSString *)[result objectForKey:@"receiver_sina_uids"] componentsSeparatedByString:@","];
        
        if ([_delegate respondsToSelector:@selector(restClient:createdCopyRef:toFriends:link:)]) {
            
            [_delegate restClient:self createdCopyRef:copyRef toFriends:friends link:link];
        }
    }
    
    [_requests removeObject:request];
}

- (void)copyFromRef:(NSString *)copyRef toPath:(NSString *)toPath withAccessCode:(NSString *)accessCode {

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:toPath, @"to_path", copyRef, @"from_copy_ref", accessCode, @"access_code", _root, @"root", nil];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/linkcommon/copy" parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCopyFromRefWithAccessCode:)]
                                    autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidCopyFromRefWithAccessCode:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    NSString *copyRef = [request.userInfo objectForKey:@"from_copy_ref"];
    NSString *accessCode = [request.userInfo objectForKey:@"access_code"];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:copyFromRefWithAccessCodeFailedWithError:)]) {
            
            [_delegate restClient:self copyFromRefWithAccessCodeFailedWithError:request.error];
        }
        
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (!result) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
                    
                    if ([_delegate respondsToSelector:@selector(restClient:copyFromRefWithAccessCodeFailedWithError:)]) {
                        
                        [_delegate restClient:self copyFromRefWithAccessCodeFailedWithError:error];
                    }
                    
                });
                
            } else {
                
                VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([_delegate respondsToSelector:@selector(restClient:copiedRef:accessCode:to:)]) {
                        
                        [_delegate restClient:self copiedRef:copyRef accessCode:accessCode to:metadata];
                    }
                    
                });
            }
        });
    }
    
    [_requests removeObject:request];
    
}

- (void)copyFromMyFriendRef:(NSString *)copyRef toPath:(NSString *)toPath params:(NSDictionary *)params {
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (params != nil) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    [mutableParams addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:toPath, @"to_path", copyRef, @"from_copy_ref", _root, @"root", nil]];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/sharefriend/copy" parameters:mutableParams method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCopyFromMyFriendRef:)]
                                    autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)copyFromMyFriendRef:(NSString *)copyRef toPath:(NSString *)toPath {

    [self copyFromMyFriendRef:copyRef toPath:toPath params:nil];
}

- (void)requestDidCopyFromMyFriendRef:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    NSString *copyRef = [request.userInfo objectForKey:@"from_copy_ref"];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:copyFromMyFriendRefFailedWithError:)]) {
            
            [_delegate restClient:self copyFromMyFriendRefFailedWithError:request.error];
        }
        
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (!result) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
                    
                    if ([_delegate respondsToSelector:@selector(restClient:copyFromMyFriendRefFailedWithError:)]) {
                        
                        [_delegate restClient:self copyFromMyFriendRefFailedWithError:error];
                    }
                    
                });
                
            } else {
                
                VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([_delegate respondsToSelector:@selector(restClient:copiedFromMyFriendRef:to:)]) {
                        
                        [_delegate restClient:self copiedFromMyFriendRef:copyRef to:metadata];
                    }
                    
                });
            }
        });
    }
    
    [_requests removeObject:request];
}


- (void)copyFromRef:(NSString *)copyRef toPath:(NSString *)toPath {
    
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            copyRef, @"from_copy_ref",
                            _root, @"root",
                            toPath, @"to_path", nil];
    
    
    NSString *fullPath = [NSString stringWithFormat:@"/fileops/copy/"];
    ASIFormDataRequest* urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCopyFromRef:)]
     autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidCopyFromRef:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (!result) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:copyFromRefFailedWithError:)]) {
        
            [_delegate restClient:self copyFromRefFailedWithError:request.error];
        }
        
    } else {
        
        NSString *copyRef = [request.userInfo objectForKey:@"from_copy_ref"];
        
        VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
        
        if ([_delegate respondsToSelector:@selector(restClient:copiedRef:to:)]) {
        
            [_delegate restClient:self copiedRef:copyRef to:metadata];
        }
    }
    
    [_requests removeObject:request];
}


- (void)deletePath:(NSString *)path {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _root, @"root",
                            path, @"path", nil];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/fileops/delete" parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidDeletePath:)]
     autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}



- (void)requestDidDeletePath:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:deletePathFailedWithError:)]) {
        
            [_delegate restClient:self deletePathFailedWithError:request.error];
        }
        
    } else {
        
        if ([_delegate respondsToSelector:@selector(restClient:deletedPath:metadata:)]) {
        
            NSString *path = [request.userInfo objectForKey:@"path"];
            VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
            [_delegate restClient:self deletedPath:path metadata:metadata];
        }
    }
    
    [_requests removeObject:request];
}




- (void)createFolder:(NSString *)path {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _root, @"root",
                            path, @"path", nil];
    
    NSString *fullPath = @"/fileops/create_folder";
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:params method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCreateDirectory:)]
     autorelease];
    
    request.userInfo = params;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}



- (void)requestDidCreateDirectory:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:createFolderFailedWithError:)]) {
        
            [_delegate restClient:self createFolderFailedWithError:request.error];
        }
        
    } else {
        
        //NSDictionary *result = (NSDictionary *)[request resultJSON];
        
        VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result] autorelease];
        
        if ([_delegate respondsToSelector:@selector(restClient:createdFolder:)]) {
        
            [_delegate restClient:self createdFolder:metadata];
        }
    }
    
    [_requests removeObject:request];
}



- (void)loadAccountInfo {
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/account/info" parameters:nil];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadAccountInfo:)] autorelease];
    
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:_root, @"root", nil];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}


- (void)requestDidLoadAccountInfo:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (request.error) {
        
        if (![self.delegate isKindOfClass:[VdiskSession class]]) {
            
            [self checkForAuthenticationFailure:request];
        }
        
        if ([_delegate respondsToSelector:@selector(restClient:loadAccountInfoFailedWithError:)]) {
         
            [_delegate restClient:self loadAccountInfoFailedWithError:request.error];
        }
        
    } else {
        
        //NSDictionary *result = (NSDictionary *)[request resultJSON];
        
        VdiskAccountInfo *accountInfo = [[[VdiskAccountInfo alloc] initWithDictionary:result] autorelease];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedAccountInfo:)]) {
         
            [_delegate restClient:self loadedAccountInfo:accountInfo];
        }
    }
    
    [_requests removeObject:request];
}


- (void)searchPath:(NSString *)path forKeyword:(NSString *)keyword params:(NSDictionary *)params {
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (params != nil) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    [mutableParams setValue:keyword forKey:@"query"];
    
    NSString *fullPath = [NSString stringWithFormat:@"/search/%@%@", _root, path];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:mutableParams];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidSearchPath:)] autorelease];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"path", keyword, @"keyword", nil];
    
    if (mutableParams) {
        
        [userInfo addEntriesFromDictionary:mutableParams];
    }
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
    
}


- (void)searchPath:(NSString *)path forKeyword:(NSString *)keyword {
    
    [self searchPath:path forKeyword:keyword params:nil];
}


- (void)requestDidSearchPath:(VdiskComplexRequest *)request {
    
    NSArray *result = [request parseResponseAsType:[NSArray class]];
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:searchFailedWithError:)]) {
        
            [_delegate restClient:self searchFailedWithError:request.error];
        }
        
    } else {
    
        NSMutableArray *results = nil;
        
        if ([result isKindOfClass:[NSArray class]]) {
        
            NSArray *response = result;
            
            results = [NSMutableArray arrayWithCapacity:[response count]];
            
            for (NSDictionary *dict in response) {
            
                VdiskMetadata *metadata = [[VdiskMetadata alloc] initWithDictionary:dict];
                [results addObject:metadata];
                [metadata release];
            }
        }
        
        NSString *path = [request.userInfo objectForKey:@"path"];
        NSString *keyword = [request.userInfo objectForKey:@"keyword"];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedSearchResults:forPath:keyword:)]) {
        
            [_delegate restClient:self loadedSearchResults:results forPath:path keyword:keyword];
        }
        
    }
    
    [_requests removeObject:request];
}


- (void)loadSharableLinkForFile:(NSString *)path {
    
    NSString *fullPath = [NSString stringWithFormat:@"/shares/%@%@", _root, path];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:nil method:@"POST"];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadSharableLink:)]
     autorelease];
    
    request.userInfo = [NSDictionary dictionaryWithObject:path forKey:@"path"];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidLoadSharableLink:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (request.error) {
    
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadSharableLinkFailedWithError:)]) {
        
            [_delegate restClient:self loadSharableLinkFailedWithError:request.error];
        }
        
    } else {
        
        NSString *sharableLink = [(NSDictionary *)result objectForKey:@"url"];
        NSString *path = [request.userInfo objectForKey:@"path"];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedSharableLink:forFile:)]) {
        
            [_delegate restClient:self loadedSharableLink:sharableLink forFile:path];
        }
    }
    
    [_requests removeObject:request];
}


- (void)loadStreamableURLForFile:(NSString *)path params:(NSDictionary *)params {
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (params != nil) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    NSString *fullPath = [NSString stringWithFormat:@"/media/%@%@", _root, path];
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:fullPath parameters:mutableParams];
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadStreamableURL:)] autorelease];
    
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:path forKey:@"path"];
    
    if (mutableParams) {
        
        [userInfo addEntriesFromDictionary:mutableParams];
    }
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)loadStreamableURLForFile:(NSString *)path {
    
    [self loadStreamableURLForFile:path params:nil];
}

- (void)requestDidLoadStreamableURL:(VdiskComplexRequest *)request {
   
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
    
        if ([_delegate respondsToSelector:@selector(restClient:loadStreamableURLFailedWithError:)]) {
        
            [_delegate restClient:self loadStreamableURLFailedWithError:request.error];
        }
    
    } else {
        
        NSDictionary *response = [request parseResponseAsType:[NSDictionary class]];
        NSURL *url = [NSURL URLWithString:[response objectForKey:@"url"]];
        NSString *path = [request.userInfo objectForKey:@"path"];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedStreamableURL:forFile:)]) {
        
            [_delegate restClient:self loadedStreamableURL:url forFile:path];
        
        } else if ([_delegate respondsToSelector:@selector(restClient:loadedStreamableURL:info:forFile:)]) {
        
            [_delegate restClient:self loadedStreamableURL:url info:response forFile:path];
        }
    }
    
    [_requests removeObject:request];
}

- (void)loadStreamableURLFromRef:(NSString *)copyRef params:(NSDictionary *)params {
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (params != nil) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    [mutableParams setValue:copyRef forKey:@"from_copy_ref"];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:@"/shareops/media" parameters:mutableParams];
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadStreamableURLFromRef:)] autorelease];
    
    request.userInfo = [[mutableParams mutableCopy] autorelease];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)loadStreamableURLFromRef:(NSString *)copyRef {
    
    [self loadStreamableURLFromRef:copyRef params:nil];
}

- (void)requestDidLoadStreamableURLFromRef:(VdiskComplexRequest *)request {
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadStreamableURLFromRefFailedWithError:)]) {
            
            [_delegate restClient:self loadStreamableURLFromRefFailedWithError:request.error];
        }
        
    } else {
        
        NSDictionary *response = [request parseResponseAsType:[NSDictionary class]];
        NSURL *url = [NSURL URLWithString:[response objectForKey:@"url"]];
        NSString *copyRef = [request.userInfo objectForKey:@"from_copy_ref"];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadedStreamableURL:fromRef:)]) {
            
            [_delegate restClient:self loadedStreamableURL:url fromRef:copyRef];
        
        } else if ([_delegate respondsToSelector:@selector(restClient:loadedStreamableURL:info:fromRef:)]) {
        
            [_delegate restClient:self loadedStreamableURL:url info:response fromRef:copyRef];
        }
    }
    
    [_requests removeObject:request];
}

- (void)blitz:(NSString *)filename toPath:(NSString *)path sha1:(NSString *)sha1 size:(unsigned long long)size {

    NSString *destPath = [path stringByAppendingPathComponent:filename];
    NSString *blitzInfoString = [@[@{@"sha1":sha1, @"path":destPath, @"type":@"application/octet-stream", @"size":[NSString stringWithFormat:@"%llu", size]}] JSONRepresentation];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:blitzInfoString, @"data", _root, @"root", nil];
    
    
    NSDictionary *requestParams = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   kVdiskAPIHost, @"host",
                                   @"/relax/batch", @"path",
                                   @"POST", @"method",
                                   params, @"params",
                                   nil];
    
    ASIFormDataRequest *urlRequest = [self requestWithParameters:requestParams];
    [requestParams release];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidBlitz:)] autorelease];
    
    request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        sha1, @"fileSha1",
                        destPath, @"destinationPath",
                        [NSNumber numberWithUnsignedLongLong:size], @"fileSize",
                        @"upload", @"action",
                        @"blitz", @"upload_type", nil];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidBlitz:(VdiskComplexRequest *)request {
    
    NSArray *result = [request parseResponseAsType:[NSArray class]];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:blitzFailedWithError:)]) {
            
            [_delegate restClient:self blitzFailedWithError:request.error];
        }
        
    } else {
                
        if ([result isKindOfClass:[NSArray class]] &&
            [result count] > 0 &&
            [[result objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *result0 = (NSDictionary *)[result objectAtIndex:0];
            
            VdiskMetadata *metadata = [[[VdiskMetadata alloc] initWithDictionary:result0] autorelease];
            
            if (metadata && metadata.rev && metadata.lastModifiedDate && metadata.humanReadableSize) {
                
                if ([_delegate respondsToSelector:@selector(restClient:blitzedFile:sha1:size:metadata:)]) {
                    
                    [_delegate restClient:self blitzedFile:[request.userInfo objectForKey:@"destinationPath"] sha1:[request.userInfo objectForKey:@"fileSha1"] size:[(NSNumber *)[request.userInfo objectForKey:@"fileSize"] unsignedLongLongValue] metadata:metadata];
                }
                
            } else if ([result0 objectForKey:@"error_code"]) {
                
                NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionaryWithDictionary:request.userInfo];
                [errorUserInfo addEntriesFromDictionary:result0];
                 
                NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:[[result0 objectForKey:@"error_code"] integerValue] userInfo:errorUserInfo];
                
                NSMutableDictionary *requestUserInfo = [NSMutableDictionary dictionaryWithDictionary:request.userInfo];
                [requestUserInfo setValue:error forKey:@"error"];
                request.userInfo = requestUserInfo;
                
                if ([_delegate respondsToSelector:@selector(restClient:blitzFailedWithError:)]) {
                    
                    [_delegate restClient:self blitzFailedWithError:error];
                }
            
            } else {
            
                NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
                
                if ([_delegate respondsToSelector:@selector(restClient:blitzFailedWithError:)]) {
                    
                    [_delegate restClient:self blitzFailedWithError:error];
                }
            }
            
        } else {
        
            NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
            
            if ([_delegate respondsToSelector:@selector(restClient:blitzFailedWithError:)]) {
                
                [_delegate restClient:self blitzFailedWithError:error];
            }
        }
    }
    
    [_requests removeObject:request];
}


/*
 
 ApiName: { 
    
    /recommend/list_for_user, 
    /recommend/list_for_file, 
    /share/list, 
    /share/search, 
    //以上返回值一样，都是数组，数组里面是VdiskSharesMetadata, VdiskSharesMetadata属性以"/recommend/list_for_user"的返回值为准，是Metadata的超级
 
    /category/get, //返回一个数组，数组里面的对象未定义
    /share/get  //直接返回一个VdiskSharesMetadata
 }
 
 */

- (void)loadShareList:(VdiskShareListType)type params:(NSDictionary *)params {

    NSString *apiName = nil;
    
    switch (type) {
            
        case kVdiskShareListTypeRecommendListForUser:
            apiName = kVdiskShareListRecommendListForUser;
            break;
        case kVdiskShareListTypeRecommendListForFile:
            apiName = kVdiskShareListRecommendListForFile;
            break;
        case kVdiskShareListTypeShareList:
            apiName = kVdiskShareListShareList;
            break;
        case kVdiskShareListTypeShareListAll:
            apiName = kVdiskShareListShareListAll;
            break;
        case kVdiskShareListTypeShareSearch:
            apiName = kVdiskShareListShareSearch;
            break;
    }
    
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:apiName parameters:params];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadShareList:)] autorelease];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:apiName forKey:@"apiName"];
    [userInfo setValue:[NSNumber numberWithInt:type] forKey:@"shareListType"];
    
    if (params) {
        
        [userInfo addEntriesFromDictionary:params];
    }
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];

}


- (void)requestDidLoadShareList:(VdiskComplexRequest *)request {

    NSArray *result = [request parseResponseAsType:[NSArray class]];
    VdiskShareListType shareListType = [[request.userInfo objectForKey:@"shareListType"] intValue];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadShareListFailedWithError:shareListType:)]) {
            
            [_delegate restClient:self loadShareListFailedWithError:request.error shareListType:shareListType];
        }
        
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
            //NSArray *result = (NSArray *)[request resultJSON];
            
            if (!result) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadShareListFailedWithError:shareListType:)]) {
                        
                        [_delegate restClient:self loadShareListFailedWithError:error shareListType:shareListType];
                    }
                    
                });
                
            } else {
            
                NSMutableArray *shareList = [NSMutableArray array];
                
                for (NSDictionary *item in result) {
                    
                    VdiskSharesMetadata *metadata = [[[VdiskSharesMetadata alloc] initWithDictionary:item] autorelease];
                    
                    if (metadata) {
                        
                        [shareList addObject:metadata];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadedShareList:shareListType:)]) {
                        
                        [_delegate restClient:self loadedShareList:shareList shareListType:shareListType];
                    }
                    
                });
                
            }
            
        });
        
    }
    
    [_requests removeObject:request];
}


- (void)loadSharesMetadata:(NSString *)cpRef params:(NSDictionary *)params {
    
    NSString *apiName = @"/share/get";
    
    NSMutableDictionary *mutableParams = nil;
    
    if (params != nil) {
        
        mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    
    } else {
    
        mutableParams = [NSMutableDictionary dictionary];
    }
    
    [mutableParams setValue:cpRef forKey:@"copy_ref"];
    [mutableParams setValue:@"signRequest" forKey:@"x-vdisk-local-userinfo"];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:apiName parameters:mutableParams];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadSharesMetadata:)] autorelease];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:apiName forKey:@"apiName"];
    
    if (mutableParams) {
        
        [userInfo addEntriesFromDictionary:mutableParams];
    }
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)loadSharesMetadata:(NSString *)cpRef {
    
    [self loadSharesMetadata:cpRef params:nil];
}


- (void)requestDidLoadSharesMetadata:(VdiskComplexRequest *)request {
    
    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadSharesMetadataFailedWithError:)]) {
            
            [_delegate restClient:self loadSharesMetadataFailedWithError:request.error];
        }
        
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //NSDictionary *result = (NSDictionary *)[request resultJSON];
            
            if (!result) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                
                    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadSharesMetadataFailedWithError:)]) {
                        
                        [_delegate restClient:self loadSharesMetadataFailedWithError:error];
                    }
                    
                });
                
                
            } else {
            
                VdiskSharesMetadata *metadata = [[[VdiskSharesMetadata alloc] initWithDictionary:result] autorelease];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadedSharesMetadata:)]) {
                        
                        [_delegate restClient:self loadedSharesMetadata:metadata];
                    }
                    
                });
            }
        });
    }
    
    [_requests removeObject:request];
}

- (void)loadSharesMetadata:(NSString *)cpRef withAccessCode:(NSString *)accessCode params:(NSDictionary *)params {

    NSString *apiName = @"/linkcommon/get";
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (params != nil) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    [mutableParams setValue:cpRef forKey:@"from_copy_ref"];
    [mutableParams setValue:accessCode forKey:@"access_code"];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:apiName parameters:mutableParams];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadSharesMetadataWithAccessCode:)] autorelease];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:apiName forKey:@"apiName"];
    
    if (mutableParams) {
        
        [userInfo addEntriesFromDictionary:mutableParams];
    }
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)loadSharesMetadata:(NSString *)cpRef withAccessCode:(NSString *)accessCode {
    
    [self loadSharesMetadata:cpRef withAccessCode:accessCode params:nil];
}

- (void)requestDidLoadSharesMetadataWithAccessCode:(VdiskComplexRequest *)request {

    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadSharesMetadataWithAccessCodeFailedWithError:)]) {
            
            [_delegate restClient:self loadSharesMetadataWithAccessCodeFailedWithError:request.error];
        }
        
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
            if (!result) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadSharesMetadataWithAccessCodeFailedWithError:)]) {
                        
                        [_delegate restClient:self loadSharesMetadataWithAccessCodeFailedWithError:error];
                    }
                    
                });
                
                
            } else {
                
                NSString *accessCode = [request.userInfo objectForKey:@"access_code"];
                
                VdiskSharesMetadata *metadata = [[[VdiskSharesMetadata alloc] initWithDictionary:result sharesMetadataType:kVdiskSharesMetadataTypeLinkcommon accessCode:accessCode] autorelease];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadedSharesMetadataWithAccessCode:)]) {
                        
                        [_delegate restClient:self loadedSharesMetadataWithAccessCode:metadata];
                    }
                    
                });
            }
        });
    }
    
    [_requests removeObject:request];
}

- (void)loadSharesMetadataFromMyFriend:(NSString *)cpRef params:(NSDictionary *)params {

    NSString *apiName = @"/sharefriend/get";
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (params != nil) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    [mutableParams setValue:cpRef forKey:@"from_copy_ref"];
            
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:apiName parameters:mutableParams];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadSharesMetadataFromMyFriend:)] autorelease];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:apiName forKey:@"apiName"];
    
    if (mutableParams) {
        
        [userInfo addEntriesFromDictionary:mutableParams];
    }
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)loadSharesMetadataFromMyFriend:(NSString *)cpRef {

    [self loadSharesMetadataFromMyFriend:cpRef params:nil];
}

- (void)requestDidLoadSharesMetadataFromMyFriend:(VdiskComplexRequest *)request {

    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadSharesMetadataFromMyFriendFailedWithError:)]) {
            
            [_delegate restClient:self loadSharesMetadataFromMyFriendFailedWithError:request.error];
        }
        
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (!result) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadSharesMetadataFromMyFriendFailedWithError:)]) {
                        
                        [_delegate restClient:self loadSharesMetadataFromMyFriendFailedWithError:error];
                    }
                    
                });
                
                
            } else {
                
                VdiskSharesMetadata *metadata = [[[VdiskSharesMetadata alloc] initWithDictionary:result sharesMetadataType:kVdiskSharesMetadataTypeFromFriend] autorelease];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadedSharesMetadataFromMyFriend:)]) {
                        
                        [_delegate restClient:self loadedSharesMetadataFromMyFriend:metadata];
                    }
                    
                });
            }
        });
    }
    
    [_requests removeObject:request];
}


- (void)loadSharesCategory:(NSString *)categoryId params:(NSDictionary *)params { //platform: 可选，string，ios或者android，只有这两个值有效。表示不同设备

    NSString *apiName = @"/category/detail";
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    [mutableParams setValue:categoryId forKey:@"category_id"];
    
    if (params != nil && [params isKindOfClass:[NSDictionary class]]) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:apiName parameters:mutableParams];
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidLoadSharesCategory:)] autorelease];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:apiName forKey:@"apiName"];
    
    if (mutableParams) {
        
        [userInfo addEntriesFromDictionary:mutableParams];
    }
    
    request.userInfo = userInfo;
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidLoadSharesCategory:(VdiskComplexRequest *)request {

    NSDictionary *result = [request parseResponseAsType:[NSDictionary class]];
    
    NSString *categoryId = [request.userInfo objectForKey:@"category_id"];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:loadSharesCategoryFailedWithError:categoryId:)]) {
            
            [_delegate restClient:self loadSharesCategoryFailedWithError:request.error categoryId:categoryId];
        }
        
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (!(result && [result objectForKey:@"child"] && [[result objectForKey:@"child"] isKindOfClass:[NSArray class]])) {
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    
                    NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:request.userInfo];
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadSharesCategoryFailedWithError:categoryId:)]) {
                        
                        [_delegate restClient:self loadSharesCategoryFailedWithError:error categoryId:categoryId];
                    }
                    
                });
                
                
            } else {
                
                NSMutableArray *list = [NSMutableArray array];
                
                for (NSDictionary *item in [result objectForKey:@"child"]) {
                    
                    if ([item isKindOfClass:[NSDictionary class]]) {
                        
                        [list addObject:[[[VdiskSharesCategory alloc] initWithDictionary:item] autorelease]];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    
                    if ([_delegate respondsToSelector:@selector(restClient:loadedSharesCategory:categoryId:)]) {
                        
                        [_delegate restClient:self loadedSharesCategory:list categoryId:categoryId];
                    }
                    
                });
            }
        });
    }
    
    [_requests removeObject:request];
}


- (void)callWeiboAPI:(NSString *)apiName params:(NSDictionary *)params method:(NSString *)method responseType:(Class)class {
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (params != nil) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    [mutableParams setValue:@"callWeiboAPI" forKey:@"x-vdisk-local-userinfo"];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:apiName parameters:mutableParams method:method];
    [urlRequest addRequestHeader:@"x-vdisk-version" value:@"2"];
    
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCallWeiboAPI:)] autorelease];
    
    request.userInfo = [[mutableParams mutableCopy] autorelease];
    
    [(NSMutableDictionary *)request.userInfo addEntriesFromDictionary:@{@"apiName" : apiName, @"responseType" : class}];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidCallWeiboAPI:(VdiskComplexRequest *)request {
    
    Class responseType = (Class)[request.userInfo objectForKey:@"responseType"];
    NSString *apiName = (NSString *)[request.userInfo objectForKey:@"apiName"];
    
    NSDictionary *result = [request parseResponseAsType:responseType];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:callWeiboAPIFailedWithError:apiName:)]) {
            
            [_delegate restClient:self callWeiboAPIFailedWithError:request.error apiName:apiName];
        }
        
    } else {
    
        if ([_delegate respondsToSelector:@selector(restClient:calledWeiboAPI:result:)]) {
            
            [_delegate restClient:self calledWeiboAPI:apiName result:result];
        }
    }
    
    [_requests removeObject:request];
}


- (void)callOthersAPI:(NSString *)apiName params:(NSDictionary *)params method:(NSString *)method responseType:(Class)class {
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (params != nil) {
        
        [mutableParams addEntriesFromDictionary:params];
    }
    
    [mutableParams setValue:@"callOthersAPI" forKey:@"x-vdisk-local-userinfo"];
    
    ASIFormDataRequest *urlRequest = [self requestWithHost:kVdiskAPIHost path:apiName parameters:mutableParams method:method];
    [urlRequest addRequestHeader:@"x-vdisk-version" value:@"2"];
    
    
    VdiskComplexRequest *request = [[[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestDidCallOthersAPI:)] autorelease];
    
    request.userInfo = [[mutableParams mutableCopy] autorelease];
    
    [(NSMutableDictionary *)request.userInfo addEntriesFromDictionary:@{@"apiName" : apiName, @"responseType" : class}];
    
    [_requests addObject:request];
    
    [self readyToRequest:request];
}

- (void)requestDidCallOthersAPI:(VdiskComplexRequest *)request {
    
    Class responseType = (Class)[request.userInfo objectForKey:@"responseType"];
    NSString *apiName = (NSString *)[request.userInfo objectForKey:@"apiName"];
    
    NSDictionary *result = [request parseResponseAsType:responseType];
    
    if (request.error) {
        
        [self checkForAuthenticationFailure:request];
        
        if ([_delegate respondsToSelector:@selector(restClient:callOthersAPIFailedWithError:apiName:)]) {
            
            [_delegate restClient:self callOthersAPIFailedWithError:request.error apiName:apiName];
        }
        
    } else {
        
        if ([_delegate respondsToSelector:@selector(restClient:calledOthersAPI:result:)]) {
            
            [_delegate restClient:self calledOthersAPI:apiName result:result];
        }
    }
    
    [_requests removeObject:request];
}


#pragma mark -

- (NSUInteger)requestCount {
    
    return [_requests count] + [_loadRequests count] + [_imageLoadRequests count] + [_uploadRequests count];
}


#pragma mark private methods

+ (void)signRequest:(ASIHTTPRequest *)request {

    NSMutableDictionary *xVdiskHeaders = [[NSMutableDictionary alloc] init];
    
    for (NSString *keyString in [[request requestHeaders] allKeys]) {
        
        NSString *lowerKeyString = [keyString lowercaseString];
        
        if ([lowerKeyString rangeOfString:@"x-vdisk-"].location != NSNotFound) {
            
            [xVdiskHeaders setValue:[[request requestHeaders] objectForKey:keyString] forKey:lowerKeyString];
        }
    }
    
    NSArray *xVdiskHeadersKeySortStrings = [[xVdiskHeaders allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    NSMutableArray *xVdiskSortedHeaders = [[NSMutableArray alloc] init];
    
    for (NSString *lowerKeyString in xVdiskHeadersKeySortStrings) {
        
        [xVdiskSortedHeaders addObject:[NSString stringWithFormat:@"%@:%@", lowerKeyString, [xVdiskHeaders objectForKey:lowerKeyString]]];
    }
    
    [xVdiskHeaders release];
    
    NSString *xVdiskHeadersString = [xVdiskSortedHeaders componentsJoinedByString:@"\n"];
    
    [xVdiskSortedHeaders release];
    
    
    NSURL *parsedURL = request.url;
    
    NSString *destURI = nil;
    
    if (parsedURL.query) {
        
        destURI = [NSString stringWithFormat:@"%@?%@", [parsedURL path], parsedURL.query];
        
    } else {
        
        destURI = [NSString stringWithString:[parsedURL path]];
    }
    
    long expires = time((time_t *)NULL) + 3600;
    NSString *expiresString = [NSString stringWithFormat:@"%ld", expires];
    
    NSString *stringToSign = [NSString stringWithFormat:@"%@\n\n%@\n%@\n%@", request.requestMethod, expiresString, xVdiskHeadersString, destURI];
    
    NSString *sign = [[[[stringToSign HMACSHA1EncodedDataWithKey:[VdiskSession sharedSession].appSecret] base64EncodedString] substringWithRange:NSMakeRange(5, 10)] URLEncodedString];
    
    NSString *queryPrefix = parsedURL.query ? @"&" : @"?";
    NSString *urlString = [NSString stringWithFormat:@"%@%@app_key=%@&expire=%@&ssig=%@", parsedURL.absoluteString, queryPrefix, [VdiskSession sharedSession].appKey, expiresString, sign];
    [request setURL:[NSURL URLWithString:urlString]];
}

+ (NSString *)humanReadableAppleSize:(unsigned long long)length {

    /*
     
     x < 1000字节， 显示：xxx字节
     1000 <= x <= 1024字节， 显示1KB
     1024字节 < x < 1000KB， 显示：xxxKB
     1000KB <= x < 1000MB， 显示：xxx.x MB
     1000MB <= x < 1G, 显示：xxx.xx GB
     x >= 1G : humanReadableSize:
     
     */
	
	NSArray *filesizename = [NSArray arrayWithObjects:@" 字节", @" KB", @" MB", @" GB", @" TB", @" PB", @" EB", @" ZB", @" YB", nil];
	
	if (length > 0) {
		
        if (length < 1000) {
            
            return [NSString stringWithFormat:@"%llu%@", length, [filesizename objectAtIndex:0]];
        
        } else if (length >= 1000 && length <= 1024) {
        
            return [NSString stringWithFormat:@"1%@", [filesizename objectAtIndex:1]];
            
        } else if (length > 1024 && length < 1024 * 1000) {
            
            double s = length / pow(1024, 1);
            return [NSString stringWithFormat:@"%.0f%@", s, [filesizename objectAtIndex:1]];
        
        } else if (length >= 1024 * 1000 && length < 1024 * 1024 * 1000) {
            
            double s = length / pow(1024, 2);
            return [NSString stringWithFormat:@"%.1f%@", s, [filesizename objectAtIndex:2]];
            
        } else if (length >= 1024 * 1024 * 1000 && length < 1024 * 1024 * 1024) {
        
            double s = length / pow(1024, 3);
            return [NSString stringWithFormat:@"%.2f%@", s, [filesizename objectAtIndex:3]];
        
        } else {
        
            return [VdiskRestClient humanReadableSize:length];
        }
	}
	
	return @"0 字节";
}


+ (NSString *)humanReadableSize:(unsigned long long)length {
	
	NSArray *filesizename = [NSArray arrayWithObjects:@" Bytes", @" KB", @" MB", @" GB", @" TB", @" PB", @" EB", @" ZB", @" YB", nil];
	
	if (length > 0) {
		
		int i = floor(log2(length) / 10);
        if (i > 8) i = 8;
		double s = length / pow(1024, i);
        
		return [NSString stringWithFormat:@"%.2f%@", s, [filesizename objectAtIndex:i]];
	}
	
	return @"0 Bytes";
}

+ (NSString *)escapePath:(NSString *)path {
    
    CFStringEncoding encoding = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
    
    NSString *escapedPath = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)path, NULL, (CFStringRef)@":?=,!$&'()*+;[]@#~", encoding);
    
    return [escapedPath autorelease];
}

- (ASIFormDataRequest *)requestWithHost:(NSString *)host path:(NSString *)path parameters:(NSDictionary *)params {
    
    return [self requestWithHost:host path:path parameters:params method:@"GET"];
}

- (ASIFormDataRequest *)requestWithParameters:(NSDictionary *)params {
    
    if ([params objectForKey:@"host"] == nil && [params objectForKey:@"path"] == nil) {
        
        return nil;
    }
    
    if ([params objectForKey:@"method"] == nil) {
        
        return [self requestWithHost:[params objectForKey:@"host"] path:[params objectForKey:@"path"] parameters:[params objectForKey:@"params"]];
    
    } else {
    
        return [self requestWithHost:[params objectForKey:@"host"] path:[params objectForKey:@"path"] parameters:[params objectForKey:@"params"] method:[params objectForKey:@"method"]];
    }
}

- (ASIFormDataRequest *)requestWithHost:(NSString *)host path:(NSString *)path parameters:(NSDictionary *)params method:(NSString *)method {
    
    BOOL needSign = (![_session isLinked] || [_session isExpired]) && params != nil && [params objectForKey:@"x-vdisk-local-userinfo"] && [[params objectForKey:@"x-vdisk-local-userinfo"] isEqualToString:@"signRequest"];
    
    if (![self checkSessionStatus] && !needSign) {
        
        if (![_session isLinked]) {
            
            NSString *errorMsg = @"VdiskSDK: Access Token Empty";
            VdiskLogWarning(@"VdiskSDK: %@ (%@)", errorMsg, path);
            
            return nil;
        }
        
        /*
         
        ASIFormDataRequest *requset = [ASIFormDataRequest requestWithURL:nil];
        
        NSInteger errorCode = kVdiskErrorSessionError;
        NSError *error = [NSError errorWithDomain:kVdiskErrorDomain code:errorCode userInfo:nil];
        requset.error = error;
        //NSString *errorMsg = @"VdiskSDK: Access Token Validation Failed / Access Token Expired / Access Token Empty";
        VdiskLogWarning(@"VdiskSDK: Access Token Validation Failed / Access Token Expired / Access Token Empty");
        
        return requset;
         
         */

    }
    
    NSString *escapedPath = [VdiskRestClient escapePath:path];
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@%@", kVdiskProtocolHTTPS, host, kVdiskAPIVersion, escapedPath];
    
    if (params != nil && [params objectForKey:@"x-vdisk-local-userinfo"]) {
        
        if ([[params objectForKey:@"x-vdisk-local-userinfo"] isEqualToString:@"callWeiboAPI"]) {
            
            urlString = [NSString stringWithFormat:@"%@://%@/%@%@", kVdiskProtocolHTTPS, host, @"weibo", escapedPath];
        }
        
        @try {
            
            [(NSMutableDictionary *)params removeObjectForKey:@"x-vdisk-local-userinfo"];
        
        } @catch (NSException *exception) {
            
            NSLog(@"exception");
        }
    }
    
    //add globalParams
    if ([[_session.globalParams allKeys] count] > 0) {
        
        urlString = [VdiskRequest serializeURL:urlString params:_session.globalParams httpMethod:@"GET"];
    }

    VdiskRequest *request;
    
    if (needSign) {
        
        request = [VdiskRequest requestWithURL:urlString httpMethod:method params:params httpHeaderFields:nil udid:_session.udid delegate:nil];
        ASIFormDataRequest *finalRequest = [request finalRequest];
        [VdiskRestClient signRequest:finalRequest];
        
        return finalRequest;
        
    } else if (_session.sessionType == kVdiskSessionTypeWeiboAccessToken) {
                
        NSDictionary *requestHeaders = [self requestHeadersWithWeiboAccessTokenAuthorization];
        
        request = [VdiskRequest requestWithURL:urlString httpMethod:method params:params httpHeaderFields:requestHeaders udid:_session.udid delegate:nil];
        
        
    } else {
                
        request = [VdiskRequest requestWithAccessToken:_session.accessToken url:urlString httpMethod:method params:params httpHeaderFields:[NSDictionary dictionaryWithObjectsAndKeys:[VdiskSession userAgent], @"User-Agent", nil] udid:_session.udid delegate:nil];
    }
    
    return [request finalRequest];
    
}

- (void)checkForAuthenticationFailure:(VdiskComplexRequest *)request {
    
    if (request.error &&
        ((request.error.code == 401 &&
          [request.error.domain isEqual:kVdiskErrorDomain]) ||
         (request.error.code == ASIAuthenticationErrorType &&
          [request.error.domain isEqual:NetworkRequestErrorDomain]))) {
        
             
             VdiskLogWarning(@"VdiskSDK: Access Token Validation Failed / Access Token Expired");
        
             if (![_session isLinked]) {
                 
                 if ([_session.delegate respondsToSelector:@selector(sessionNotLink:)]) {
                     
                     [_session.delegate sessionNotLink:_session];
                 }
                 
             } else {
             
                 if ([_session.delegate respondsToSelector:@selector(sessionExpired:)]) {
                     
                     [_session.delegate sessionExpired:_session];
                 }
             }
             
             /*
             
             if ([_session.delegate respondsToSelector:@selector(sessionExpired:)]) {
                 
                 [_session.delegate sessionExpired:_session];
                 
             } else if ([_session.delegate respondsToSelector:@selector(sessionNotLink:)]) {
                 
                 [_session.delegate sessionNotLink:_session];
             }
              
              */
    }
}

- (BOOL)checkSessionStatus {

    // Step 1.
    // Check if the user has been logged in.
    
	if (![_session isLinked]) {
        
        /*
        
        if (_session.sessionType == kVdiskSessionTypeWeiboAccessToken) {
            
            if ([_session.delegate respondsToSelector:@selector(sessionWeiboAccessTokenIsNull:)]) {
                
                [_session.delegate sessionWeiboAccessTokenIsNull:_session];
            } 
            
        } else {
            
            if ([_session.delegate respondsToSelector:@selector(sessionNotLink:)]) {
                
                [_session.delegate sessionNotLink:_session];
            }
        }
         
         */
        
        
        if ([_session.delegate respondsToSelector:@selector(sessionNotLink:)]) {
            
            [_session.delegate sessionNotLink:_session];
        }
        
        return NO;
	}
    
	// Step 2.
    // Check if the access token is expired.
    
    if ([_session isExpired]) {
        
        /*
        
        if (_session.sessionType == kVdiskSessionTypeWeiboAccessToken) {
            
            if ([_session.delegate respondsToSelector:@selector(sessionWeiboAccessTokenIsNull:)]) {
                
                [_session.delegate sessionWeiboAccessTokenIsNull:_session];
            } 
            
        } else {
            
            if ([_session.delegate respondsToSelector:@selector(sessionExpired:)]) {
                
                [_session.delegate sessionExpired:_session];
            }
        }
         
         */
        
        if ([_session.delegate respondsToSelector:@selector(sessionExpired:)]) {
            
            [_session.delegate sessionExpired:_session];
        }
        
        return NO;
    }
    
    return YES;
}

- (NSDictionary *)requestHeadersWithWeiboAccessTokenAuthorization {

    /*
     
     Authorization: Weibo {"appkey":"3098041711","access_token":"9821de2bf1827ee84b8ab69b2b13afb4","expires":1340779661,"sign":"BjN2hzyy4\/"}
     
     */
    
    //long expires = time((time_t *)NULL) + 3600 * 24;
    long expires = time((time_t *)NULL) + 3600;
    NSString *expiresString = [NSString stringWithFormat:@"%ld", expires];
    
    NSString *stringToSign = [NSString stringWithFormat:@"%@%@%@", _session.appKey, _session.accessToken, expiresString];
    NSString *sign = [[[stringToSign HMACSHA1EncodedDataWithKey:_session.appSecret] base64EncodedString] substringWithRange:NSMakeRange(5, 10)];
    
    NSDictionary *authorizationDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                      _session.appKey, @"appkey", 
                                      _session.accessToken, @"access_token",
                                      expiresString, @"expires", 
                                      sign, @"sign", nil];
    
    NSString *authorization = [authorizationDic JSONRepresentation];
    
    NSDictionary *requestHeaders = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [VdiskSession userAgent], @"User-Agent",
                                    [NSString stringWithFormat:@"Weibo %@", authorization], @"Authorization", nil];
    
    return requestHeaders;
}

/*
- (MPOAuthCredentialConcreteStore *)credentialStore {
    
    return [_session credentialStoreForUserId:_userId];
}
 */


@end
