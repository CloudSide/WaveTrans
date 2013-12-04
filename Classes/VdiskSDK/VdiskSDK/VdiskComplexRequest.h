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

#import <Foundation/Foundation.h>
#import "ASIFormDataRequest.h"
#import "VdiskMetadata.h"

@protocol VdiskNetworkRequestDelegate;

/* VdiskRequest will download a URL either into a file that you provied the name to or it will
 create an NSData object with the result. When it has completed downloading the URL, it will
 notify the target with a selector that takes the VdiskRequest as the only parameter. */

@interface VdiskComplexRequest : NSOperation <ASIHTTPRequestDelegate, ASIProgressDelegate> {

    ASIFormDataRequest *_request;
    
    id _target;
    SEL _selector;
        
    SEL _failureSelector;
    SEL _downloadProgressSelector;
    SEL _uploadProgressSelector;
    SEL _requestDidReceiveResponseSelector;
    SEL _requestWillRedirectSelector;
    
    NSString *_resultFilename;
    NSString *_tempFilename;
    NSDictionary *_userInfo;
    
    NSDictionary *_xVdiskMetadataJSON;
    unsigned long long _bytesDownloaded;
    
    CGFloat _downloadProgress;
    CGFloat _uploadProgress;

    NSError *_error;    
}

/*  Set this to get called when _any_ request starts or stops. This should hook into whatever network activity indicator system you have. */

+ (void)setNetworkRequestDelegate:(id<VdiskNetworkRequestDelegate>)delegate;

/*  This constructor downloads the URL into the resultData object */

- (id)initWithRequest:(ASIFormDataRequest *)request andInformTarget:(id)target selector:(SEL)selector;


//- (void)start;

/*  Cancels the request and prevents it from sending additional messages to the delegate. */

//- (void)cancel;

- (void)clearSelectorsAndCancel;

/* If there is no error, it will parse the response as JSON and make sure the JSON object is the
 correct type. If not, it will set the error object with an error code of VdiskErrorInvalidResponse */

- (id)parseResponseAsType:(Class)cls;


/* Downloads */
- (void)startDownloadWithMetadata:(VdiskMetadata *)metadata;


@property (nonatomic, assign) SEL failureSelector; // To send failure events to a different selector set this
@property (nonatomic, assign) SEL downloadProgressSelector; // To receive download progress events set this
@property (nonatomic, assign) SEL uploadProgressSelector; // To receive upload progress events set this
@property (nonatomic, assign) SEL requestDidReceiveResponseSelector;
@property (nonatomic, assign) SEL requestWillRedirectSelector;
@property (nonatomic, retain) NSString *resultFilename; // The file to put the HTTP body in, otherwise body is stored in resultData
@property (nonatomic, retain) NSDictionary *userInfo;

@property (nonatomic, readonly) ASIFormDataRequest *request;
@property (nonatomic, readonly) NSDictionary *xVdiskMetadataJSON;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) CGFloat downloadProgress;
@property (nonatomic, readonly) CGFloat uploadProgress;

@property (nonatomic, readonly) NSString *resultString;
@property (nonatomic, readonly) NSObject *resultJSON;
@property (nonatomic, readonly) NSError *error;

@property (nonatomic, retain) VdiskMetadata *metadataForDownload;

@property (nonatomic, assign) BOOL allowResumeForFileDownloads;


@end



@protocol VdiskNetworkRequestDelegate 

- (void)networkRequestStarted;
- (void)networkRequestStopped;

@end
