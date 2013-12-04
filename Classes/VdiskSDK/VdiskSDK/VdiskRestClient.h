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


#import "VdiskSession.h"


typedef enum {
    
    kVdiskShareListTypeRecommendListForUser     =   0,
    kVdiskShareListTypeRecommendListForFile,
    kVdiskShareListTypeShareList,
    kVdiskShareListTypeShareListAll,
    kVdiskShareListTypeShareSearch,
    
} VdiskShareListType;


@protocol VdiskRestClientDelegate;
@class VdiskAccountInfo;
@class VdiskMetadata;
@class VdiskSharesMetadata;
@class VdiskSession;

@interface VdiskRestClient : NSObject {
    
    VdiskSession *_session;
    NSString *_userId;
    NSString *_root;
    NSMutableSet *_requests;
    /* Map from path to the load request. Needs to be expanded to a general framework for cancelling
     requests. */
    NSMutableDictionary *_loadRequests;
    NSMutableDictionary *_imageLoadRequests;
    NSMutableDictionary *_uploadRequests;
    id<VdiskRestClientDelegate> _delegate;
    
    //NSUInteger _maxConcurrent;
    NSUInteger _maxOperationCount;
    
    NSOperationQueue *_requestQueue;
    
    NSRecursiveLock *_operationLock;
}

- (id)initWithSession:(VdiskSession *)session;
- (id)initWithSession:(VdiskSession *)session maxConcurrent:(NSUInteger)maxConcurrent maxOperationCount:(NSUInteger)maxOperationCount;


/* Cancels all outstanding requests. No callback for those requests will be sent */
- (void)cancelAllRequests;

#pragma - mark Rest API

/* Loads metadata for the object at the given root/path and returns the result to the delegate as a 
 dictionary */
- (void)loadMetadata:(NSString *)path withHash:(NSString *)hash;

- (void)loadMetadata:(NSString *)path;

/* This will load the metadata of a file at a given rev */
- (void)loadMetadata:(NSString *)path atRev:(NSString *)rev;

- (void)loadMetadata:(NSString *)path withParams:(NSDictionary *)params;

/* Loads a list of files (represented as VdiskDeltaEntry objects) that have changed since the cursor was generated */
- (void)loadDelta:(NSString *)cursor;


/* Loads the file contents at the given root/path and stores the result into destinationPath */
- (void)loadFile:(NSString *)path intoPath:(NSString *)destinationPath;
- (void)loadFileOfAddressBookAtRev:(NSString *)rev intoPath:(NSString *)destinationPath;

/* This will load a file as it existed at a given rev */
- (void)loadFile:(NSString *)path atRev:(NSString *)rev intoPath:(NSString *)destPath;
- (void)cancelFileLoad:(NSString *)path;

- (void)loadFileWithSharesMetadata:(VdiskSharesMetadata *)sharesMetadata intoPath:(NSString *)destPath;
- (void)cancelFileLoadWithSharesMetadata:(VdiskSharesMetadata *)sharesMetadata;

- (void)loadThumbnail:(NSString *)path ofSize:(NSString *)size intoPath:(NSString *)destinationPath;
- (void)cancelThumbnailLoad:(NSString *)path size:(NSString *)size;

- (void)loadThumbnailWithMetadata:(VdiskMetadata *)metadata ofSize:(NSString *)size intoPath:(NSString *)destinationPath params:(NSDictionary *)params;
- (void)cancelThumbnailLoadWithMetadata:(VdiskMetadata *)metadata size:(NSString *)size;

/* Uploads a file that will be named filename to the given path on the server. sourcePath is the
 full path of the file you want to upload. If you are modifying a file, parentRev represents the
 rev of the file before you modified it as returned from the server. If you are uploading a new
 file set parentRev to nil. */
- (void)uploadFile:(NSString *)filename toPath:(NSString *)path withParentRev:(NSString *)parentRev fromPath:(NSString *)sourcePath;
- (void)uploadFile:(NSString *)filename toPath:(NSString *)path fromPath:(NSString *)sourcePath params:(NSDictionary *)params;
- (void)uploadFileOfAddressBookFromPath:(NSString *)sourcePath params:(NSDictionary *)params;
- (void)cancelFileUpload:(NSString *)path;

/* Avoid using this because it is very easy to overwrite conflicting changes. Provided for backwards
 compatibility reasons only */
- (void)uploadFile:(NSString *)filename toPath:(NSString *)path fromPath:(NSString *)sourcePath __attribute__((deprecated));

- (void)locateComplexUploadHost;
- (void)initializeComplexUpload:(NSString *)path uploadHost:(NSString *)uploadHost partTotal:(NSUInteger)partTotal size:(NSNumber *)size params:(NSDictionary *)params;
- (void)signComplexUpload:(NSString *)partRange uploadId:(NSString *)uploadId uploadKey:(NSString *)uploadKey;
- (void)mergeComplexUpload:(NSString *)path uploadHost:(NSString *)uploadHost uploadId:(NSString *)uploadId uploadKey:(NSString *)uploadKey sha1:(NSString *)sha1 md5List:(NSString *)md5List params:(NSDictionary *)params;

/* Loads a list of up to 10 VdiskMetadata objects representing past revisions of the file at path */
- (void)loadRevisionsForFile:(NSString *)path;

/* Same as above but with a configurable limit to number of VdiskMetadata objects returned, up to 1000 */
- (void)loadRevisionsForFile:(NSString *)path limit:(NSInteger)limit;
- (void)loadRevisionsForFileOfAddressBookLimit:(NSInteger)limit;

/* Restores a file at path as it existed at the given rev and returns the metadata of the restored
 file after restoration */
- (void)restoreFile:(NSString *)path toRev:(NSString *)rev;

/* Creates a folder at the given root/path */
- (void)createFolder:(NSString *)path;

- (void)deletePath:(NSString *)path;

- (void)copyFrom:(NSString *)fromPath toPath:(NSString *)toPath;

- (void)createCopyRef:(NSString *)path; // Used to copy between Vdisk

- (void)createCopyRef:(NSString *)path toFriends:(NSArray *)friends;

- (void)createCopyRefAndAccessCode:(NSString *)path;

- (void)copyFromRef:(NSString *)copyRef toPath:(NSString *)toPath; // Takes copy ref created by above call

- (void)copyFromRef:(NSString *)copyRef toPath:(NSString *)toPath withAccessCode:(NSString *)accessCode;

- (void)copyFromMyFriendRef:(NSString *)copyRef toPath:(NSString *)toPath;

- (void)copyFromMyFriendRef:(NSString *)copyRef toPath:(NSString *)toPath params:(NSDictionary *)params;

- (void)moveFrom:(NSString *)fromPath toPath:(NSString *)toPath;

- (void)loadAccountInfo;

- (void)searchPath:(NSString *)path forKeyword:(NSString *)keyword;
- (void)searchPath:(NSString *)path forKeyword:(NSString *)keyword params:(NSDictionary *)params;

- (void)loadSharableLinkForFile:(NSString *)path;

- (void)loadStreamableURLForFile:(NSString *)path;
- (void)loadStreamableURLForFile:(NSString *)path params:(NSDictionary *)params;

- (void)loadStreamableURLFromRef:(NSString *)copyRef;
- (void)loadStreamableURLFromRef:(NSString *)copyRef params:(NSDictionary *)params;

- (void)blitz:(NSString *)filename toPath:(NSString *)path sha1:(NSString *)sha1 size:(unsigned long long)size;

- (void)loadShareList:(VdiskShareListType)type params:(NSDictionary *)params;

- (void)loadSharesMetadata:(NSString *)cpRef params:(NSDictionary *)params;

- (void)loadSharesMetadata:(NSString *)cpRef;

- (void)loadSharesMetadata:(NSString *)cpRef withAccessCode:(NSString *)accessCode;
- (void)loadSharesMetadata:(NSString *)cpRef withAccessCode:(NSString *)accessCode params:(NSDictionary *)params;

- (void)loadSharesMetadataFromMyFriend:(NSString *)cpRef;
- (void)loadSharesMetadataFromMyFriend:(NSString *)cpRef params:(NSDictionary *)params;

- (void)loadSharesCategory:(NSString *)categoryId params:(NSDictionary *)params; //platform: 可选，string，ios或者android，只有这两个值有效。表示不同设备

- (void)callWeiboAPI:(NSString *)apiName params:(NSDictionary *)params method:(NSString *)method responseType:(Class)responseType;

- (void)callOthersAPI:(NSString *)apiName params:(NSDictionary *)params method:(NSString *)method responseType:(Class)responseType;


#pragma - mark


- (NSUInteger)requestCount;

+ (NSString *)humanReadableSize:(unsigned long long)length;
+ (NSString *)humanReadableAppleSize:(unsigned long long)length;
+ (void)signRequest:(ASIHTTPRequest *)request;
// This method escapes all URI escape characters except "/"
+ (NSString *)escapePath:(NSString *)path;

@property (nonatomic, assign) id<VdiskRestClientDelegate> delegate;

@end




/* The delegate provides allows the user to get the result of the calls made on the VdiskRestClient.
 Right now, the error parameter of failed calls may be nil and [error localizedDescription] does
 not contain an error message appropriate to show to the user. */
@protocol VdiskRestClientDelegate <NSObject>

@optional

- (void)restClient:(VdiskRestClient *)client loadedMetadata:(VdiskMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client metadataUnchangedAtPath:(NSString *)path;
- (void)restClient:(VdiskRestClient *)client loadMetadataFailedWithError:(NSError*)error; 
// [error userInfo] contains the root and path of the call that failed

- (void)restClient:(VdiskRestClient *)client loadedDeltaEntries:(NSArray *)entries reset:(BOOL)shouldReset cursor:(NSString *)cursor hasMore:(BOOL)hasMore;
- (void)restClient:(VdiskRestClient *)client loadDeltaFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client loadedAccountInfo:(VdiskAccountInfo *)info;
- (void)restClient:(VdiskRestClient *)client loadAccountInfoFailedWithError:(NSError *)error; 

- (void)restClient:(VdiskRestClient *)client loadedFile:(NSString *)destPath;
// Implement the following callback instead of the previous if you care about the value of the
// Content-Type HTTP header and the file metadata. Only one will be called per successful response.
- (BOOL)restClient:(VdiskRestClient *)client loadedFileRealDownloadURL:(NSURL *)realDownloadURL metadata:(VdiskMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(VdiskMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client loadProgress:(CGFloat)progress forFile:(NSString *)destPath;
- (void)restClient:(VdiskRestClient *)client loadFileFailedWithError:(NSError *)error;
// [error userInfo] contains the destinationPath



- (void)restClient:(VdiskRestClient *)client loadedFile:(NSString *)destPath sharesMetadata:(VdiskSharesMetadata *)sharesMetadata;
- (void)restClient:(VdiskRestClient *)client loadProgress:(CGFloat)progress forFile:(NSString *)destPath sharesMetadata:(VdiskSharesMetadata *)sharesMetadata;
- (void)restClient:(VdiskRestClient *)client loadFileFailedWithError:(NSError *)error sharesMetadata:(VdiskSharesMetadata *)sharesMetadata;



- (void)restClient:(VdiskRestClient *)client loadedThumbnail:(NSString *)destPath metadata:(VdiskMetadata *)metadata size:(NSString *)size;
- (void)restClient:(VdiskRestClient *)client loadThumbnailProgress:(CGFloat)progress destPath:(NSString *)destPath metadata:(VdiskMetadata *)metadata size:(NSString *)size;
- (void)restClient:(VdiskRestClient *)client loadThumbnailFailedWithError:(NSError *)error metadata:(VdiskMetadata *)metadata size:(NSString *)size;
- (void)restClient:(VdiskRestClient *)client loadThumbnailFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(VdiskMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString *)srcPath;
- (void)restClient:(VdiskRestClient *)client uploadFileFailedWithError:(NSError *)error;
// [error userInfo] contains the sourcePath




- (void)restClient:(VdiskRestClient *)client locatedComplexUploadHost:(NSString *)uploadHost;
- (void)restClient:(VdiskRestClient *)client locateComplexUploadHostFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client initializedComplexUpload:(NSDictionary *)info;
- (void)restClient:(VdiskRestClient *)client initializeComplexUploadFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client signedComplexUpload:(NSDictionary *)signInfo;
- (void)restClient:(VdiskRestClient *)client signComplexUploadFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client mergedComplexUpload:(NSString *)destPath metadata:(VdiskMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client mergeComplexUploadFailedWithError:(NSError *)error;



// Deprecated upload callback
- (void)restClient:(VdiskRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath;

// Deprecated download callbacks
- (void)restClient:(VdiskRestClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType;
- (void)restClient:(VdiskRestClient *)client loadedThumbnail:(NSString *)destPath;

- (void)restClient:(VdiskRestClient *)client loadedRevisions:(NSArray *)revisions forFile:(NSString *)path;
- (void)restClient:(VdiskRestClient *)client loadRevisionsFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client restoredFile:(VdiskMetadata *)fileMetadata;
- (void)restClient:(VdiskRestClient *)client restoreFileFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client createdFolder:(VdiskMetadata *)folder;
// Folder is the metadata for the newly created folder
- (void)restClient:(VdiskRestClient*)client createFolderFailedWithError:(NSError *)error;
// [error userInfo] contains the root and path

- (void)restClient:(VdiskRestClient *)client deletedPath:(NSString *)path metadata:(VdiskMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client deletePathFailedWithError:(NSError *)error;
// [error userInfo] contains the root and path

- (void)restClient:(VdiskRestClient *)client copiedPath:(NSString *)fromPath to:(VdiskMetadata *)to;
- (void)restClient:(VdiskRestClient *)client copyPathFailedWithError:(NSError *)error;
// [error userInfo] contains the root and path

- (void)restClient:(VdiskRestClient *)client createdCopyRef:(NSString *)copyRef;
- (void)restClient:(VdiskRestClient *)client createCopyRefFailedWithError:(NSError *)error;


- (void)restClient:(VdiskRestClient *)client createdCopyRef:(NSString *)copyRef toFriends:(NSArray *)friends link:(NSString *)link;
- (void)restClient:(VdiskRestClient *)client createCopyRefToFriendsFailedWithError:(NSError *)error;


- (void)restClient:(VdiskRestClient *)client createdCopyRef:(NSString *)copyRef accessCode:(NSString *)accessCode link:(NSString *)link;
- (void)restClient:(VdiskRestClient *)client createCopyRefAndAccessCodeFailedWithError:(NSError *)error;



- (void)restClient:(VdiskRestClient *)client copiedRef:(NSString *)copyRef to:(VdiskMetadata *)to;
- (void)restClient:(VdiskRestClient *)client copyFromRefFailedWithError:(NSError *)error;


- (void)restClient:(VdiskRestClient *)client copiedRef:(NSString *)copyRef accessCode:(NSString *)accessCode to:(VdiskMetadata *)to;
- (void)restClient:(VdiskRestClient *)client copyFromRefWithAccessCodeFailedWithError:(NSError *)error;


- (void)restClient:(VdiskRestClient *)client copiedFromMyFriendRef:(NSString *)copyRef to:(VdiskMetadata *)to;
- (void)restClient:(VdiskRestClient *)client copyFromMyFriendRefFailedWithError:(NSError *)error;


- (void)restClient:(VdiskRestClient *)client movedPath:(NSString *)from_path to:(VdiskMetadata *)result;
- (void)restClient:(VdiskRestClient *)client movePathFailedWithError:(NSError *)error;
// [error userInfo] contains the root and path

- (void)restClient:(VdiskRestClient *)restClient loadedSearchResults:(NSArray *)results forPath:(NSString *)path keyword:(NSString *)keyword;
// results is a list of VdiskMetadata * objects
- (void)restClient:(VdiskRestClient *)restClient searchFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path;
- (void)restClient:(VdiskRestClient *)restClient loadSharableLinkFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)restClient loadedStreamableURL:(NSURL *)url info:(NSDictionary *)info forFile:(NSString *)path;
- (void)restClient:(VdiskRestClient *)restClient loadedStreamableURL:(NSURL *)url forFile:(NSString *)path;
- (void)restClient:(VdiskRestClient *)restClient loadStreamableURLFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)restClient loadedStreamableURL:(NSURL *)url info:(NSDictionary *)info fromRef:(NSString *)copyRef;
- (void)restClient:(VdiskRestClient *)restClient loadedStreamableURL:(NSURL *)url fromRef:(NSString *)copyRef;
- (void)restClient:(VdiskRestClient *)restClient loadStreamableURLFromRefFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)restClient blitzedFile:(NSString *)destPath sha1:(NSString *)sha1 size:(unsigned long long)size metadata:(VdiskMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)restClient blitzFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client loadedShareList:(NSArray *)shareList shareListType:(VdiskShareListType)shareListType; // results is a list of VdiskSharesMetadata * objects
- (void)restClient:(VdiskRestClient *)client loadShareListFailedWithError:(NSError *)error shareListType:(VdiskShareListType)shareListType;

- (void)restClient:(VdiskRestClient *)client loadedSharesMetadata:(VdiskSharesMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client loadSharesMetadataFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client loadedSharesMetadataWithAccessCode:(VdiskSharesMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client loadSharesMetadataWithAccessCodeFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client loadedSharesMetadataFromMyFriend:(VdiskSharesMetadata *)metadata;
- (void)restClient:(VdiskRestClient *)client loadSharesMetadataFromMyFriendFailedWithError:(NSError *)error;

- (void)restClient:(VdiskRestClient *)client loadedSharesCategory:(NSArray *)list categoryId:(NSString *)categoryId;
- (void)restClient:(VdiskRestClient *)client loadSharesCategoryFailedWithError:(NSError *)error categoryId:(NSString *)categoryId;

- (void)restClient:(VdiskRestClient *)client calledWeiboAPI:(NSString *)apiName result:(id)result;
- (void)restClient:(VdiskRestClient *)client callWeiboAPIFailedWithError:(NSError *)error apiName:(NSString *)apiName;

- (void)restClient:(VdiskRestClient *)client calledOthersAPI:(NSString *)apiName result:(id)result;
- (void)restClient:(VdiskRestClient *)client callOthersAPIFailedWithError:(NSError *)error apiName:(NSString *)apiName;



@end