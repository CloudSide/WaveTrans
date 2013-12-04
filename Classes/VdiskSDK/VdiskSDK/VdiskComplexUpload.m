//
//  VdiskComplexUpload.m
//  VdiskSDK
//
//  Created by gaopeng on 12-8-9.
//
//

#import "VdiskComplexUpload.h"


@interface VdiskComplexUpload (Private)

- (void)_locateHost;
//- (void)_createSha1;
- (void)_uploadInit;
- (void)_sign;
- (BOOL)_createMd5s;
- (void)_upload;
- (void)_merge;

- (NSString *)_md5sString;
- (NSString *)_fileInfoKey;
- (BOOL)_readFileInfo;
- (BOOL)_saveFileInfo;
- (BOOL)_deleteFileInfo;
- (void)_clearFileInfo;
- (void)_start;

- (void)_setExpiresIn:(NSDate *)expiresIn;
- (void)_setUploadId:(NSString *)uploadId;
- (void)_setUploadKey:(NSString *)uploadKey;
- (void)_setS3host:(NSString *)s3host;
- (void)_setFileSHA1:(NSString *)fileSHA1;
- (void)_setFileMD5s:(NSMutableArray *)fileMD5s;
- (void)_setExpiresInSinceNow;
- (void)_setSignatures:(NSDictionary *)signatures;

@end


@implementation VdiskComplexUpload

@synthesize sourcePath = _sourcePath;
@synthesize destPath = _destPath;
@synthesize expiresIn = _expiresIn;
@synthesize s3host = _s3host;
@synthesize uploadId = _uploadId;
@synthesize uploadKey = _uploadKey;
@synthesize fileMD5s = _fileMD5s;
@synthesize fileSHA1 = _fileSHA1;
@synthesize pointer = _pointer;
@synthesize fileRange = _fileRange;
@synthesize otherParams = _otherParams;
@synthesize error = _error;
@synthesize signatures = _signatures;
@synthesize uploadRequest = _uploadRequest;
@synthesize force = _force;
@synthesize delegate = _delegate;


- (id)initWithFile:(NSString *)filename fromPath:(NSString *)sourcePath toPath:(NSString *)toPath {
    
    if (self = [super init]) {
        
        _force = NO;
        
        _destPath = [[toPath stringByAppendingPathComponent:filename] copy];
        _sourcePath = [sourcePath copy];
        
        _vdiskRestClient = [[VdiskRestClient alloc] initWithSession:[VdiskSession sharedSession]];
        _vdiskRestClient.delegate = self;

        _fileRange = kVdiskComplexUploadFileRange;
        _pointer = 0;
        
        _partNum = 1;
        _isCancelled = NO;
        
        _userinfo = [[NSMutableDictionary dictionaryWithObjectsAndKeys:_sourcePath, @"sourcePath", _destPath, @"destinationPath", nil] retain];
        [_userinfo addEntriesFromDictionary:@{@"action" : @"upload", @"upload_type" : @"complex"}];
        
    }
    
    return self;
}

- (void)dealloc {
    
    [_vdiskRestClient cancelAllRequests];
    [_vdiskRestClient setDelegate:nil];
    [_vdiskRestClient release];
    
    [_uploadRequest release];
    [_fileInfoKey release];
    [_signatures release];
    [_error release];
    
    [_otherParams release];
    
    [_userinfo release];
    
    [_fileSHA1 release];
    [_fileMD5s release];
    [_uploadKey release];
    [_uploadId release];
    [_s3host release];
    [_expiresIn release];
    [_destPath release];
    [_sourcePath release];
    
    [super dealloc];
}

- (void)_setError:(NSError *)theError {
    
    if (theError == _error) return;
    
    [_error release];
    _error = [theError retain];    
}


- (NSString *)_fileInfoKey {
    
    if (_fileInfoKey != nil) {
        
        return _fileInfoKey;
    }
    
    NSString *hashString = [[self.destPath stringByAppendingFormat:@"_%@_%@", self.sourcePath, [[VdiskSession sharedSession] userID]] MD5EncodedString];
    
    _fileInfoKey = [[NSString alloc] initWithFormat:@"%@", hashString];
    
    return _fileInfoKey;
}

- (void)_setExpiresIn:(NSDate *)expiresIn {

    if (expiresIn != nil) {
        
        [_expiresIn release], _expiresIn = nil;
    }
    
    _expiresIn = [expiresIn retain];
}

- (void)_setUploadId:(NSString *)uploadId {
    
    if (_uploadId != nil) {
        
        [_uploadId release], _uploadId = nil;
    }
        
    _uploadId = [uploadId retain];
}

- (void)_setUploadKey:(NSString *)uploadKey {
    
    if (_uploadId != nil) {
        
        [_uploadKey release], _uploadKey = nil;
    }
    
    _uploadKey = [uploadKey retain];
}

- (void)_setS3host:(NSString *)s3host {
    
    if (_s3host != nil) {
        
        [_s3host release], _s3host = nil;
    }
    
    _s3host = [s3host retain];
}

- (void)_setFileSHA1:(NSString *)fileSHA1 {
    
    if (_fileSHA1) {
        
        [_fileSHA1 release], _fileSHA1 = nil;
    }

    _fileSHA1 = [fileSHA1 retain];
}

- (void)_setFileMD5s:(NSMutableArray *)fileMD5s {
    
    if (_fileMD5s != nil) {
        
        [_fileMD5s release], _fileMD5s = nil;
    }
    
    _fileMD5s = [fileMD5s retain];
}

- (void)_setExpiresInSinceNow {

    [self _setExpiresIn:[NSDate dateWithTimeIntervalSinceNow:kVdiskComplexUploadKeyTimeoutSecond]];
}

- (void)_clearFileInfo {

    [self _setExpiresIn:nil];
    [self _setUploadId:nil];
    [self _setUploadKey:nil];
    [self _setS3host:nil];
    [self _setFileSHA1:nil];
    [self _setFileMD5s:nil];
}

- (void)_setSignatures:(NSDictionary *)signatures {

    if (_signatures != nil) {
        
        [_signatures release], _signatures = nil;
    }
    
    _signatures = [signatures retain];
}

- (BOOL)_readFileInfo {
    
	NSMutableDictionary *fileInfo = nil;
    
    if (_delegate && [_delegate respondsToSelector:@selector(complexUpload:readSessionInfoForKey:destPath:srcPath:)]) {
        
        fileInfo = [_delegate complexUpload:self readSessionInfoForKey:[self _fileInfoKey] destPath:_destPath srcPath:_sourcePath];
        
    } else {
    
        fileInfo = [[NSUserDefaults standardUserDefaults] objectForKey:[self _fileInfoKey]];
    }
    
	if (fileInfo != nil) {
		
		if (([fileInfo objectForKey:@"UploadId"] &&
             [fileInfo objectForKey:@"UploadKey"] &&
             [fileInfo objectForKey:@"S3host"] &&
             [fileInfo objectForKey:@"FileRange"] &&
             [fileInfo objectForKey:@"FileMD5s"] &&
             [fileInfo objectForKey:@"Pointer"] &&
             [fileInfo objectForKey:@"ExpiresIn"]) &&
             [fileInfo objectForKey:@"FileSHA1"]) {
            
			
			[self _setExpiresIn:(NSDate *)[fileInfo objectForKey:@"ExpiresIn"]];
			            
			if ([_expiresIn timeIntervalSinceNow] <= 0.0f) {
				
				return NO;
			}
            
            [self _setUploadId:[fileInfo objectForKey:@"UploadId"]];
            [self _setUploadKey:[fileInfo objectForKey:@"UploadKey"]];
            [self _setS3host:[fileInfo objectForKey:@"S3host"]];
            [self _setFileSHA1:[fileInfo objectForKey:@"FileSHA1"]];
            [self _setFileMD5s:[fileInfo objectForKey:@"FileMD5s"]];
            
			_fileRange = [[fileInfo objectForKey:@"FileRange"] unsignedLongLongValue];
			_pointer = [[fileInfo objectForKey:@"Pointer"] unsignedIntegerValue];
            _partNum = [_fileMD5s count];
			
			return YES;
            
        }
		
		return NO;
	} 
    
	return NO;
}

- (BOOL)_saveFileInfo {
    
	NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithCapacity:7];
	
	[fileInfo setObject:self.uploadKey forKey:@"UploadKey"];
    [fileInfo setObject:self.uploadId forKey:@"UploadId"];
	[fileInfo setObject:self.s3host forKey:@"S3host"];
	[fileInfo setObject:[NSNumber numberWithUnsignedLongLong:self.fileRange] forKey:@"FileRange"];
	[fileInfo setObject:self.fileMD5s forKey:@"FileMD5s"];
    [fileInfo setObject:self.fileSHA1 forKey:@"FileSHA1"];
	[fileInfo setObject:[NSNumber numberWithUnsignedInteger:self.pointer] forKey:@"Pointer"];
	[fileInfo setObject:self.expiresIn forKey:@"ExpiresIn"];
    
    if (_delegate && [_delegate respondsToSelector:@selector(complexUpload:saveSessionInfoForKey:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self saveSessionInfoForKey:[self _fileInfoKey] destPath:_destPath srcPath:_sourcePath];
        
    } else {
        
        [[NSUserDefaults standardUserDefaults] setObject:fileInfo forKey:[self _fileInfoKey]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    return YES;
}

- (BOOL)_deleteFileInfo {
    
    [self _clearFileInfo];
    
    if (_delegate && [_delegate respondsToSelector:@selector(complexUpload:deleteSessionInfoForKey:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self deleteSessionInfoForKey:[self _fileInfoKey] destPath:_destPath srcPath:_sourcePath];
        
    } else {
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self _fileInfoKey]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return YES;
}

- (void)_locateHost {
    
    if (_s3host) {
        
        [self _uploadInit];
        
        return;
    }
    
    if (_isCancelled) {
        
        [self clear];
        
        return;
    }
    
    /*
     deleted by bruce chen
    [_vdiskRestClient locateComplexUploadHost];
     */
    
    if ([_delegate respondsToSelector:@selector(complexUpload:startedWithStatus:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self startedWithStatus:kVdiskComplexUploadStatusLocateHost destPath:_destPath srcPath:_sourcePath];
    }
    
    [self restClient:_vdiskRestClient locatedComplexUploadHost:@"up.sinastorage.com"];
}

- (void)_readData:(NSFileHandle *)fileHandle offset:(unsigned long long)offset length:(unsigned long long)length content:(NSData **)content {
	
	[fileHandle seekToFileOffset:offset];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSData *data = [fileHandle readDataOfLength:[[NSNumber numberWithUnsignedLongLong:length] unsignedIntegerValue]];
	*content = [[NSData alloc] initWithData:data];
	[pool release];
}

- (BOOL)_createMd5s {
    
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *statError = nil;
	NSDictionary *stat = [fileManager attributesOfItemAtPath:_sourcePath error:&statError];
	
	if (stat == nil) {
		
        [self _setError:[NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorFileNotFound userInfo:_userinfo]];
        
        if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
            
            [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
        }
		
	} else {
		

        if ([_delegate respondsToSelector:@selector(complexUpload:startedWithStatus:destPath:srcPath:)]) {
            
            [_delegate complexUpload:self startedWithStatus:kVdiskComplexUploadStatusCreateFileMD5s destPath:_destPath srcPath:_sourcePath];
        }
        
		_fileSize = [stat fileSize];
				
		unsigned long long lastRange = _fileSize % self.fileRange;
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:_sourcePath];
        
		unsigned long long fileOffset = 0;
        
        [self _setFileMD5s:[[[NSMutableArray alloc] initWithCapacity:_partNum] autorelease]];
        
		for (NSUInteger i=0; i<_partNum; i++) {
            
            if (_isCancelled) break;
            
			unsigned long long readLength = self.fileRange;
			
			if (i == _partNum - 1) readLength = lastRange;
			
			NSData *chunkData = nil;
            
			[self _readData:fileHandle offset:fileOffset length:readLength content:&chunkData];
			[_fileMD5s addObject:[VdiskUtil md5WithData:chunkData]];
			[chunkData release];
			
			fileOffset += readLength;
		}
        
		if (_isCancelled) {
            
            [self clear];
            
            return NO;
        }
        
		[self _saveFileInfo];
        
        [self _upload];
        
		return YES;
	}
	
	return NO;
}

- (NSString *)_md5sString {
    
	return [_fileMD5s componentsJoinedByString:@","];
}

- (void)_uploadInit {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *statError = nil;
	NSDictionary *stat = [fileManager attributesOfItemAtPath:_sourcePath error:&statError];
    
    if (statError || stat == nil || (stat && [stat fileSize] == 0)) {
        
        [self _setError:[NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorFileNotFound userInfo:_userinfo]];
        
        if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
            
            [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
        }
        
    } else {
        
        if (!self.fileSHA1) {
            
            if ([_delegate respondsToSelector:@selector(complexUpload:startedWithStatus:destPath:srcPath:)]) {
                
                [_delegate complexUpload:self startedWithStatus:kVdiskComplexUploadStatusCreateFileSHA1 destPath:_destPath srcPath:_sourcePath];
            }
            
            [self _setFileSHA1:[VdiskUtil fileSHA1HashCreateWithPath:(CFStringRef)_sourcePath ChunkSize:FileHashDefaultChunkSizeForReadingData]];
        }
        
        unsigned long long fileSize = [stat fileSize];
        
        _partNum = [[NSNumber numberWithUnsignedLongLong:(fileSize / _fileRange)] unsignedIntegerValue];
        if ((fileSize % _fileRange) != 0) _partNum++;
        
        [self _setExpiresInSinceNow];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:_otherParams];
        
        [params setObject:_fileSHA1 forKey:@"sha1"];
        //[params setObject:@"1234567890123456789012345678901234567890" forKey:@"sha1"];
        
        if (_isCancelled) {
            
            [self clear];
            
            [params release];
            
            return;
        }
        
        /* custom_key_4 = upload_total_bytes, custom_value_4 = 文件总大小 */
        
        [_vdiskRestClient initializeComplexUpload:_destPath uploadHost:_s3host partTotal:_partNum size:[NSNumber numberWithUnsignedLongLong:fileSize] params:params];
        
        [params release];
        
        if ([_delegate respondsToSelector:@selector(complexUpload:startedWithStatus:destPath:srcPath:)]) {
            
            [_delegate complexUpload:self startedWithStatus:kVdiskComplexUploadStatusInitialize destPath:_destPath srcPath:_sourcePath];
        }
    }
}


- (NSDictionary *)_objectInSignaturesForKey:(NSString *)key {
    
    if (_signatures == nil) {
        
        [self _setExpiresInSinceNow];
        
        if (_isCancelled) {
            
            [self clear];
            
            return nil;
        }
        
        [_vdiskRestClient signComplexUpload:[NSString stringWithFormat:@"%d-%@", 1, [[NSNumber numberWithUnsignedInteger:[_fileMD5s count]+1] stringValue]] uploadId:_uploadId uploadKey:_uploadKey];
        
        if ([_delegate respondsToSelector:@selector(complexUpload:startedWithStatus:destPath:srcPath:)]) {
            
            [_delegate complexUpload:self startedWithStatus:kVdiskComplexUploadStatusSigning destPath:_destPath srcPath:_sourcePath];
        }
        
        return nil;
        
    } else {
        
        if ([[_signatures objectForKey:key] isKindOfClass:[NSDictionary class]]) {

            return [_signatures objectForKey:key];
        }
        
        return nil;
    }
}

- (void)_upload {
    
    //清理工作
    
    if (_uploadRequest != nil) {
        
        //[_uploadRequest cancel];
        [_uploadRequest release], _uploadRequest = nil;
    }
    
    if (self.pointer <= _partNum - 1) {
        
        NSDictionary *partSignInfo = (NSDictionary *)[self _objectInSignaturesForKey:[[NSNumber numberWithUnsignedInteger:_pointer + 1] stringValue]];
        
        if (partSignInfo == nil) return;
        
        if (_fileSize == 0) {
			
			NSFileManager *fileManager = [NSFileManager defaultManager];
			NSError *statError = nil;
			NSDictionary *stat = [fileManager attributesOfItemAtPath:_sourcePath error:&statError];
			
			if (stat == nil) {
				
				[self _setError:[NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorFileNotFound userInfo:_userinfo]];
                
                if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
                    
                    [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
                }
				
			} else {
				
				_fileSize = [stat fileSize];
			}
            
		}
        
        
        if (_fileSize > 0) {
			
			unsigned long long lastRange = _fileSize % self.fileRange;
			NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:_sourcePath];
            
			if (fileHandle == nil) {
				
                [self _setError:[NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorFileNotFound userInfo:_userinfo]];
                
                if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
                    
                    [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
                }
                
                return;
				
			}
            
			unsigned long long readLength = self.fileRange;
			unsigned long long fileOffset = self.pointer * readLength;
			
            if (self.pointer == _partNum - 1) readLength = lastRange;
			
			NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", kVdiskProtocolHTTP, self.s3host, [partSignInfo objectForKey:@"uri"]];
            
            
            NSString *contentLength = [NSString stringWithFormat: @"%qu", readLength];
            NSDictionary *httpHeaderFields = @{@"Content-Length" : contentLength, @"Content-Type" : @"application/octet-stream", @"User-Agent" : [VdiskSession userAgent]};

            
            ASIFormDataRequest *urlRequest =  [[VdiskRequest requestWithURL:urlString httpMethod:@"PUT" params:nil httpHeaderFields:httpHeaderFields udid:[VdiskSession sharedSession].udid delegate:nil] finalRequest];
            
            NSData *chunkData = nil;
			[self _readData:fileHandle offset:fileOffset length:readLength content:&chunkData];
            [urlRequest setPostBody:(NSMutableData *)chunkData];
            [chunkData release];
            
            if (_isCancelled) {
                
                [self clear];
                return;
            }
            
            /*
            
             if (_uploadRequest != nil) {
                
                [_uploadRequest cancel];
                [_uploadRequest release], _uploadRequest = nil;
            }
             
             */
            
            _uploadRequest = [[VdiskComplexRequest alloc] initWithRequest:urlRequest andInformTarget:self selector:@selector(requestFinished:)];
            
            _uploadRequest.uploadProgressSelector = @selector(requestUploadProgress:);
            
            [_userinfo setValue:_uploadId forKey:@"uploadId"];
            _uploadRequest.userInfo = [[_userinfo mutableCopy] autorelease];
            
            [_uploadRequest start];
            
            if ([_delegate respondsToSelector:@selector(complexUpload:startedWithStatus:destPath:srcPath:)]) {
                
                [_delegate complexUpload:self startedWithStatus:kVdiskComplexUploadStatusUploading destPath:_destPath srcPath:_sourcePath];
            }
            
        }
        
    } else {
        
        [self _merge];
    }
}

- (void)requestFinished:(VdiskComplexRequest *)request {
    
    NSError *requestError = [request error];
    
    if (requestError) {
        
        [self _setError:requestError];
        
        if ([requestError.domain isEqual:kVdiskErrorDomain]) {
            
            [self _deleteFileInfo];
        }
            
        if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
            
            [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
        }
        
    } else {
        
        if (request.statusCode / 100 == 2) {
            
            _pointer++;
            
            [self _saveFileInfo];
            [self _upload];
            
        } else {
            
            [self _setError:[NSError errorWithDomain:kVdiskErrorDomain code:_uploadRequest.statusCode userInfo:_userinfo]];
            
            if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
                
                [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
            }
            
            [self _deleteFileInfo];
        }
    }
}

- (void)requestUploadProgress:(VdiskComplexRequest *)request {
    
    float newProgress = (request.uploadProgress + _pointer) / [_fileMD5s count];
    
    if ([_delegate respondsToSelector:@selector(complexUpload:updateProgress:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self updateProgress:newProgress destPath:_destPath srcPath:_sourcePath];
    }
}

- (void)_merge {
    
    if (_isCancelled) {
        
        [self clear];
        
        return;
    }
    
    /* custom_key_4 = upload_total_bytes, custom_value_4 = 文件总大小 */
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.otherParams];
    [params setValue:[NSString stringWithFormat:@"%llu", _fileSize] forKey:@"upload_total_bytes"];
    
    [_vdiskRestClient mergeComplexUpload:self.destPath uploadHost:self.s3host uploadId:self.uploadId uploadKey:self.uploadKey sha1:self.fileSHA1 md5List:[self _md5sString] params:params];
    
    if ([_delegate respondsToSelector:@selector(complexUpload:startedWithStatus:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self startedWithStatus:kVdiskComplexUploadStatusMerging destPath:_destPath srcPath:_sourcePath];
    }
}

- (void)start:(BOOL)force params:(NSDictionary *)params {
    
    _force = force;
    _otherParams = [params retain];
    
    [self _start];
}

- (void)_start {

    if (_isCancelled) return;
    
    if (_force) {
        
        [self _deleteFileInfo];
    }
    
    if ([self _readFileInfo]) {
        
        [self _upload];
        
    } else {
        
        [self _locateHost];
    }
}

- (void)cancel {
    
    _isCancelled = YES;
    
    if (_uploadRequest) {
        
        [_uploadRequest clearSelectorsAndCancel];
    }
    
    [self clear];
}

- (void)clear {
    
    [_uploadRequest clearSelectorsAndCancel];
    _isCancelled = NO;
    _force = NO;
    
    [_fileInfoKey release], _fileInfoKey = nil;
    
    _pointer = 0;
    _partNum = 1;
    
    [_signatures release], _signatures = nil;
    [_fileSHA1 release], _fileSHA1 = nil;
    [_fileMD5s release], _fileMD5s = nil;
    
    [_expiresIn release], _expiresIn = nil;
    [_s3host release], _s3host = nil;
    [_uploadId release], _uploadId = nil;
    [_uploadKey release], _uploadKey = nil;
    
    _fileSize = 0;
}




#pragma mark - VdiskRestClientDelegate

- (void)restClient:(VdiskRestClient *)client locatedComplexUploadHost:(NSString *)uploadHost {
    
    [self _setS3host:[[uploadHost copy] autorelease]];
    
    [self _uploadInit];
}

- (void)restClient:(VdiskRestClient *)client locateComplexUploadHostFailedWithError:(NSError *)error {
    
    [self clear];
    
    [self _setError:error];
    
    if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
    }
}

- (void)restClient:(VdiskRestClient *)client initializedComplexUpload:(NSDictionary *)info {
    
    if ([info objectForKey:@"upload_id"] &&
        [info objectForKey:@"upload_key"] &&
        [info objectForKey:@"part_sign"] &&
        [[info objectForKey:@"part_sign"] isKindOfClass:[NSDictionary class]]) {
        
        [self _setUploadId:[[[info objectForKey:@"upload_id"] copy] autorelease]];
        [self _setUploadKey:[[[info objectForKey:@"upload_key"] copy] autorelease]];        
        [self _setSignatures:(NSDictionary *)[[[info objectForKey:@"part_sign"] copy] autorelease]];
        
        [self _createMd5s];
        
    } else {
        
        [self clear];
        
        [self _setError:[NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:_userinfo]];
        
        if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
            
            [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
        }
    }
}

- (void)restClient:(VdiskRestClient *)client initializeComplexUploadFailedWithError:(NSError *)error {
    
    [self clear];
    
    [self _setError:error];
    
    if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
    }
}

- (void)restClient:(VdiskRestClient *)client mergedComplexUpload:(NSString *)destPath metadata:(VdiskMetadata *)metadata {
    
    [self _deleteFileInfo];
    
    [self clear];
    
    if ([_delegate respondsToSelector:@selector(complexUpload:finishedWithMetadata:destPath:srcPath:)]) {
            
        [_delegate complexUpload:self finishedWithMetadata:metadata destPath:_destPath srcPath:_sourcePath];
    }
}

- (void)restClient:(VdiskRestClient *)client mergeComplexUploadFailedWithError:(NSError *)error {
    
    [self _deleteFileInfo];
    
    [self clear];
    
    [self _setError:error];
    
    if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
    }
}

- (void)restClient:(VdiskRestClient *)client signedComplexUpload:(NSDictionary *)signInfo {
    
    if ([signInfo objectForKey:@"part_sign"] && [[signInfo objectForKey:@"part_sign"] isKindOfClass:[NSDictionary class]]) {
        
        [self _setSignatures:[signInfo objectForKey:@"part_sign"]];
        
        [self _upload];
        
    } else {
        
        [self clear];
        
        if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
            
            [self _setError:[NSError errorWithDomain:kVdiskErrorDomain code:kVdiskErrorInvalidResponse userInfo:_userinfo]];
            
            if (_delegate && [_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
                
                [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
            }
        }
    }
}

- (void)restClient:(VdiskRestClient *)client signComplexUploadFailedWithError:(NSError *)error {
    
    [self clear];
    
    [self _setError:error];
    
    if ([_delegate respondsToSelector:@selector(complexUpload:failedWithError:destPath:srcPath:)]) {
        
        [_delegate complexUpload:self failedWithError:_error destPath:_destPath srcPath:_sourcePath];
    }
}

@end
