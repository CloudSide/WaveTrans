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


@interface VdiskMetadata : NSObject <NSCoding> {
    
    BOOL _thumbnailExists;
    long long _totalBytes;
    NSDate *_lastModifiedDate;
    NSDate *_clientMtime; // file's mtime for display purposes only
    NSString *_path;
    BOOL _isDirectory;
    NSArray *_contents;
    NSString *_hash;
    NSString *_humanReadableSize;
    NSString *_root;
    NSString *_icon;
    NSString *_rev;
    NSString *_revision; // Deprecated; will be removed in version 2. Use rev whenever possible
    BOOL _isDeleted;
    NSString *_filename;
    NSString *_fileMd5;
    NSString *_fileSha1;
    NSString *_extInfo;
    NSMutableDictionary *_userinfo;
    
    /* need_ext */
    
    NSString *_shareStatus; //private, public, forbidden
    NSString *_readURL;
    NSString *_videoMP4URL;
    NSString *_audioMP3URL;
    NSString *_readThumbnail;
    NSString *_videoThumbnail;
    
    NSString *_sharefriend;
    NSString *_linkcommon;
}

+ (NSDateFormatter *)dateFormatter;

- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;

- (BOOL)existsReadURL;
- (BOOL)existsVideoMP4URL;
- (BOOL)existsAudioMP3URL;
- (BOOL)existsReadThumbnail;
- (BOOL)existsVideoThumbnail;



@property (nonatomic, readonly) BOOL thumbnailExists;
@property (nonatomic, readonly) long long totalBytes;
@property (nonatomic, readonly) NSDate *lastModifiedDate;
@property (nonatomic, readonly) NSDate *clientMtime;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) BOOL isDirectory;
@property (nonatomic, readonly) NSArray *contents;
@property (nonatomic, readonly) NSString *hash;
@property (nonatomic, readonly) NSString *humanReadableSize;
@property (nonatomic, readonly) NSString *root;
@property (nonatomic, readonly) NSString *icon;
@property (nonatomic, readonly) NSString *revision; // Deprecated, use rev instead
@property (nonatomic, readonly) NSString *rev;
@property (nonatomic, readonly) BOOL isDeleted;
@property (nonatomic, readonly) NSString *filename;
@property (nonatomic, readonly) NSString *fileMd5;
@property (nonatomic, readonly) NSString *fileSha1;
@property (nonatomic, readonly) NSString *extInfo;
@property (nonatomic, readonly) NSMutableDictionary *userinfo;
@property (nonatomic, readonly) NSString *sharefriend;
@property (nonatomic, readonly) NSString *linkcommon;


/* need_ext */

@property (nonatomic, readonly) NSString *shareStatus; //private, public, forbidden
@property (nonatomic, readonly) NSString *readURL;
@property (nonatomic, readonly) NSString *videoMP4URL;
@property (nonatomic, readonly) NSString *audioMP3URL;
@property (nonatomic, readonly) NSString *readThumbnail;
@property (nonatomic, readonly) NSString *videoThumbnail;


@end
