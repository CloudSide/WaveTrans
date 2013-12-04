//
//  VdiskComplexUpload.h
//  VdiskSDK
//
//  Created by gaopeng on 12-8-9.
//
//

#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#endif

#import "VdiskSDKGlobal.h"
#import "VdiskUtil.h"
#import "VdiskComplexRequest.h"
#import "VdiskRestClient.h"
#import "VdiskSession.h"
#import "VdiskError.h"
#import "VdiskLog.h"

@protocol VdiskComplexUploadDelegate;

//#define kVdiskComplexUploadSessionFilePath          [NSString stringWithFormat:@"%@/sessionFiles", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]]
#define kVdiskComplexUploadKeyTimeoutSecond         3600.0f * 24.0f * 2.0f
#define kVdiskComplexUploadFileRange                1024 * 1024 * 4


typedef enum {
    
    kVdiskComplexUploadStatusLocateHost         = 0,
    kVdiskComplexUploadStatusCreateFileSHA1,
    kVdiskComplexUploadStatusInitialize,
    kVdiskComplexUploadStatusSigning,
    kVdiskComplexUploadStatusCreateFileMD5s,
    kVdiskComplexUploadStatusUploading,
    kVdiskComplexUploadStatusMerging
    
} kVdiskComplexUploadStatus;


@interface VdiskComplexUpload : NSObject <VdiskRestClientDelegate> {
    
    VdiskRestClient *_vdiskRestClient;
    id<VdiskComplexUploadDelegate> _delegate;
    
    NSUInteger _partNum;
    unsigned long long _fileSize;
    
    NSString *_fileInfoKey;
    
    NSString *_sourcePath;
    NSString *_destPath;
    
    NSDate *_expiresIn;
    NSString *_s3host;
    NSString *_uploadId;
    NSString *_uploadKey;
    NSMutableArray *_fileMD5s;
    NSString *_fileSHA1;
    NSUInteger _pointer;
    unsigned long long _fileRange;
    
    NSDictionary *_otherParams;
    NSError *_error;
    NSDictionary *_signatures;
    VdiskComplexRequest *_uploadRequest;
    
    BOOL _force;
    BOOL _isCancelled;
    
    NSMutableDictionary *_userinfo;
}

@property (nonatomic, assign) id<VdiskComplexUploadDelegate> delegate;
@property (nonatomic, readonly) NSString *sourcePath;
@property (nonatomic, readonly) NSString *destPath;
@property (nonatomic, readonly) NSDate *expiresIn;
@property (nonatomic, readonly) NSString *s3host;
@property (nonatomic, readonly) NSString *uploadId;
@property (nonatomic, readonly) NSString *uploadKey;
@property (nonatomic, readonly) NSMutableArray *fileMD5s;
@property (nonatomic, readonly) NSString *fileSHA1;
@property (nonatomic, readonly) NSUInteger pointer;
@property (nonatomic, readonly) unsigned long long fileRange;
@property (nonatomic, readonly) NSDictionary *otherParams;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) NSDictionary *signatures;
@property (nonatomic, readonly) VdiskComplexRequest *uploadRequest;
@property (nonatomic, readonly) BOOL force;

- (id)initWithFile:(NSString *)filename fromPath:(NSString *)sourcePath toPath:(NSString *)toPath;
- (void)cancel;
- (void)clear;
- (void)start:(BOOL)force params:(NSDictionary *)params;

@end




@protocol VdiskComplexUploadDelegate <NSObject>

@optional

- (void)complexUpload:(VdiskComplexUpload *)complexUpload startedWithStatus:(kVdiskComplexUploadStatus)status destPath:(NSString *)destPath srcPath:(NSString *)srcPath;
- (void)complexUpload:(VdiskComplexUpload *)complexUpload failedWithError:(NSError *)error destPath:(NSString *)destPath srcPath:(NSString *)srcPath;
- (void)complexUpload:(VdiskComplexUpload *)complexUpload finishedWithMetadata:(VdiskMetadata *)metadata destPath:(NSString *)destPath srcPath:(NSString *)srcPath;
- (void)complexUpload:(VdiskComplexUpload *)complexUpload updateProgress:(CGFloat)newProgress destPath:(NSString *)destPath srcPath:(NSString *)srcPath;

- (NSMutableDictionary *)complexUpload:(VdiskComplexUpload *)complexUpload readSessionInfoForKey:(NSString *)fileInfoKey destPath:(NSString *)destPath srcPath:(NSString *)srcPath;
- (void)complexUpload:(VdiskComplexUpload *)complexUpload saveSessionInfoForKey:(NSString *)fileInfoKey destPath:(NSString *)destPath srcPath:(NSString *)srcPath;
- (void)complexUpload:(VdiskComplexUpload *)complexUpload deleteSessionInfoForKey:(NSString *)fileInfoKey destPath:(NSString *)destPath srcPath:(NSString *)srcPath;



@end
