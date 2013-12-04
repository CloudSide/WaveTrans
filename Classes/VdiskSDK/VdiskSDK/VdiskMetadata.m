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

#import "VdiskMetadata.h"

@implementation VdiskMetadata


@synthesize thumbnailExists = _thumbnailExists;
@synthesize totalBytes = _totalBytes;
@synthesize lastModifiedDate = _lastModifiedDate;
@synthesize clientMtime = _clientMtime;
@synthesize path = _path;
@synthesize isDirectory = _isDirectory;
@synthesize contents = _contents;
@synthesize hash = _hash;
@synthesize humanReadableSize = _humanReadableSize;
@synthesize root = _root;
@synthesize icon = _icon;
@synthesize rev = _rev;
@synthesize revision = _revision;
@synthesize isDeleted = _isDeleted;
@synthesize fileMd5 = _fileMd5;
@synthesize fileSha1 = _fileSha1;
@synthesize extInfo = _extInfo;
@synthesize userinfo = _userinfo;

@synthesize shareStatus = _shareStatus;
@synthesize readURL = _readURL;
@synthesize videoMP4URL = _videoMP4URL;
@synthesize audioMP3URL = _audioMP3URL;
@synthesize readThumbnail = _readThumbnail;
@synthesize videoThumbnail = _videoThumbnail;

@synthesize linkcommon = _linkcommon;
@synthesize sharefriend = _sharefriend;




+ (NSDateFormatter *)dateFormatter {
    
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    static NSString *dateFormatterKey = @"VdiskMetadataDateFormatter";
    
    NSDateFormatter *dateFormatter = [dictionary objectForKey:dateFormatterKey];
    
    if (dateFormatter == nil) {
    
        dateFormatter = [[NSDateFormatter new] autorelease];
        // Must set locale to ensure consistent parsing:
        // http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
        
        dateFormatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
        [dictionary setObject:dateFormatter forKey:dateFormatterKey];
    }
    
    return dateFormatter;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    
    if ((self = [super init])) {
    
        @try {
            
            _thumbnailExists = [[dict objectForKey:@"thumb_exists"] boolValue];
            _totalBytes = [[dict objectForKey:@"bytes"] longLongValue];
            
            if ([dict objectForKey:@"modified"]) {
                
                _lastModifiedDate = [[[VdiskMetadata dateFormatter] dateFromString:[dict objectForKey:@"modified"]] retain];
            }
            
            if ([dict objectForKey:@"client_mtime"]) {
                
                _clientMtime = [[[VdiskMetadata dateFormatter] dateFromString:[dict objectForKey:@"client_mtime"]] retain];
            }
            
            _path = [[dict objectForKey:@"path"] retain];
            _isDirectory = [[dict objectForKey:@"is_dir"] boolValue];
            
            if ([dict objectForKey:@"contents"]) {
                
                NSArray *subfileDicts = [dict objectForKey:@"contents"];
                NSMutableArray *mutableContents = [[NSMutableArray alloc] initWithCapacity:[subfileDicts count]];
                
                for (NSDictionary *subfileDict in subfileDicts) {
                    
                    VdiskMetadata *subfile = [[VdiskMetadata alloc] initWithDictionary:subfileDict];
                    [mutableContents addObject:subfile];
                    [subfile release];
                }
                
                _contents = mutableContents;
            }
            
            if ([dict objectForKey:@"ext_info"]) {
                
                _extInfo = [[dict objectForKey:@"ext_info"] retain];
            }
            
            _hash = [[dict objectForKey:@"hash"] retain];
            _humanReadableSize = [[dict objectForKey:@"size"] retain];
            _root = [[dict objectForKey:@"root"] retain];
            _icon = [[dict objectForKey:@"icon"] retain];
            _rev = [[dict objectForKey:@"rev"] retain];
            _revision = [[dict objectForKey:@"revision"] retain];
            _isDeleted = [[dict objectForKey:@"is_deleted"] boolValue];
            _fileMd5 = [[dict objectForKey:@"md5"] retain];
            _fileSha1 = [[dict objectForKey:@"sha1"] retain];
            _userinfo = [[NSMutableDictionary alloc] init];
            
            /* need_ext */
            _shareStatus = [[dict objectForKey:@"share_status"] retain];
            _readURL = [[dict objectForKey:@"read_url"] retain];
            _videoMP4URL = [[dict objectForKey:@"video_mp4_url"] retain];
            _audioMP3URL = [[dict objectForKey:@"audio_mp3_url"] retain];
            _readThumbnail = [[dict objectForKey:@"read_thumbnail"] retain];
            _videoThumbnail = [[dict objectForKey:@"video_thumbnail"] retain];
            _linkcommon = [[dict objectForKey:@"linkcommon"] retain];
            _sharefriend = [[dict objectForKey:@"sharefriend"] retain];
            
            
        } @catch (NSException *exception) {
            
            
        } @finally {
            
            
        }
    }
    
    return self;
}

- (void)dealloc {
    
    [_lastModifiedDate release];
    [_clientMtime release];
    [_path release];
    [_contents release];
    [_hash release];
    [_humanReadableSize release];
    [_root release];
    [_icon release];
    [_rev release];
    [_revision release];
    [_filename release];
    [_fileMd5 release];
    [_fileSha1 release];
    [_extInfo release];
    [_userinfo release];
    
    [_shareStatus release];
    [_readURL release];
    [_videoMP4URL release];
    [_audioMP3URL release];
    [_readThumbnail release];
    [_videoThumbnail release];
    
    [_linkcommon release];
    [_sharefriend release];
    
    [super dealloc];
}

- (BOOL)isEqual:(id)object {
    
    if (object == self) return YES;
    if (![object isKindOfClass:[VdiskMetadata class]]) return NO;
    VdiskMetadata *other = (VdiskMetadata *)object;
    //return [self.rev isEqualToString:other.rev];
    
    return [_path isEqualToString:other.path] && ((!self.isDirectory && [self.rev isEqual:other.rev] && [self.fileSha1 isEqual:other.fileSha1]) || (self.isDirectory && [self.rev isEqual:other.rev] /*&& [self.hash isEqual:other.hash]*/));
}

- (NSString *)filename {
    
    if (_filename == nil) {
        
        _filename = [[_path lastPathComponent] retain];
    }
    
    return _filename;
}



- (BOOL)existsReadURL {
    
    if (_readURL && [_readURL isKindOfClass:[NSString class]] && [_readURL length] > 0) {
        
        return YES;
    }
    
    return NO;
}

- (BOOL)existsVideoMP4URL {

    if (_videoMP4URL && [_videoMP4URL isKindOfClass:[NSString class]] && [_videoMP4URL length] > 0) {
        
        return YES;
    }
    
    return NO;
}

- (BOOL)existsAudioMP3URL {

    if (_audioMP3URL && [_audioMP3URL isKindOfClass:[NSString class]] && [_audioMP3URL length] > 0) {
        
        return YES;
    }
    
    return NO;
}

- (BOOL)existsReadThumbnail {

    if (_readThumbnail && [_readThumbnail isKindOfClass:[NSString class]] && [_readThumbnail length] > 0) {
        
        return YES;
    }
    
    return NO;
}

- (BOOL)existsVideoThumbnail {

    if (_videoThumbnail && [_videoThumbnail isKindOfClass:[NSString class]] && [_videoThumbnail length] > 0) {
        
        return YES;
    }
    
    return NO;
}


- (NSDictionary *)dictionaryValue {
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setValue:[NSNumber numberWithBool:_isDirectory] forKey:@"is_dir"];
    
    if (_fileMd5) {
        
        [dictionary setValue:_fileMd5 forKey:@"md5"];
    }
    
    if (_totalBytes > 0) {
        
        [dictionary setValue:[NSNumber numberWithUnsignedLongLong:_totalBytes] forKey:@"bytes"];
    }
    
    if (_fileSha1) {
        
        [dictionary setValue:_fileSha1 forKey:@"sha1"];
    }
    
    if (_icon) {
        
        [dictionary setValue:_icon forKey:@"icon"];
    }
    
    if (_path) {
        
        [dictionary setValue:_path forKey:@"path"];
    }
    
    if (_humanReadableSize) {
        
        [dictionary setValue:_humanReadableSize forKey:@"size"];
    }
    
    if (_hash) {
        
        [dictionary setValue:_hash forKey:@"hash"];
    }
    
    if (_root) {
        
        [dictionary setValue:_root forKey:@"root"];
    }
    
    if (_rev) {
        
        [dictionary setValue:_rev forKey:@"rev"];
    }
    
    if (_revision) {
        
        [dictionary setValue:_revision forKey:@"revision"];
    }
    
    if (_extInfo) {
        
        [dictionary setValue:_extInfo forKey:@"ext_info"];
    }
    
    return (NSDictionary *)[dictionary autorelease];
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder *)coder {
    
    if ((self = [super init])) {
    
        _thumbnailExists = [coder decodeBoolForKey:@"thumbnailExists"];
        _totalBytes = [coder decodeInt64ForKey:@"totalBytes"];
        _lastModifiedDate = [[coder decodeObjectForKey:@"lastModifiedDate"] retain];
        _clientMtime = [[coder decodeObjectForKey:@"clientMtime"] retain];
        _path = [[coder decodeObjectForKey:@"path"] retain];
        _isDirectory = [coder decodeBoolForKey:@"isDirectory"];
        _contents = [[coder decodeObjectForKey:@"contents"] retain];
        _hash = [[coder decodeObjectForKey:@"hash"] retain];
        _humanReadableSize = [[coder decodeObjectForKey:@"humanReadableSize"] retain];
        _root = [[coder decodeObjectForKey:@"root"] retain];
        _icon = [[coder decodeObjectForKey:@"icon"] retain];
        _rev = [[coder decodeObjectForKey:@"rev"] retain];
        _revision = [[coder decodeObjectForKey:@"revision"] retain];
        _isDeleted = [coder decodeBoolForKey:@"isDeleted"];
        _fileMd5 = [[coder decodeObjectForKey:@"md5"] retain];
        _fileSha1 = [[coder decodeObjectForKey:@"sha1"] retain];
        _extInfo = [[coder decodeObjectForKey:@"extInfo"] retain];
        _userinfo = [[NSMutableDictionary alloc] initWithDictionary:[coder decodeObjectForKey:@"userinfo"]];
        
        
        /* need_ext */
        _shareStatus = [[coder decodeObjectForKey:@"shareStatus"] retain];
        _readURL = [[coder decodeObjectForKey:@"readURL"] retain];
        _videoMP4URL = [[coder decodeObjectForKey:@"videoMP4URL"] retain];
        _audioMP3URL = [[coder decodeObjectForKey:@"audioMP3URL"] retain];
        _readThumbnail = [[coder decodeObjectForKey:@"readThumbnail"] retain];
        _videoThumbnail = [[coder decodeObjectForKey:@"videoThumbnail"] retain];
        _linkcommon = [[coder decodeObjectForKey:@"linkcommon"] retain];
        _sharefriend = [[coder decodeObjectForKey:@"sharefriend"] retain];
        
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeBool:_thumbnailExists forKey:@"thumbnailExists"];
    [coder encodeInt64:_totalBytes forKey:@"totalBytes"];
    [coder encodeObject:_lastModifiedDate forKey:@"lastModifiedDate"];
    [coder encodeObject:_clientMtime forKey:@"clientMtime"];
    [coder encodeObject:_path forKey:@"path"];
    [coder encodeBool:_isDirectory forKey:@"isDirectory"];
    [coder encodeObject:_contents forKey:@"contents"];
    [coder encodeObject:_hash forKey:@"hash"];
    [coder encodeObject:_humanReadableSize forKey:@"humanReadableSize"];
    [coder encodeObject:_root forKey:@"root"];
    [coder encodeObject:_icon forKey:@"icon"];
    [coder encodeObject:_rev forKey:@"rev"];
    [coder encodeObject:_revision forKey:@"revision"];
    [coder encodeBool:_isDeleted forKey:@"isDeleted"];
    [coder encodeObject:_fileMd5 forKey:@"md5"];
    [coder encodeObject:_fileSha1 forKey:@"sha1"];
    [coder encodeObject:_extInfo forKey:@"extInfo"];
    [coder encodeObject:_userinfo forKey:@"userinfo"];
    
    
    /* need_ext */
    [coder encodeObject:_shareStatus forKey:@"shareStatus"];
    [coder encodeObject:_readURL forKey:@"readURL"];
    [coder encodeObject:_videoMP4URL forKey:@"videoMP4URL"];
    [coder encodeObject:_audioMP3URL forKey:@"audioMP3URL"];
    [coder encodeObject:_readThumbnail forKey:@"readThumbnail"];
    [coder encodeObject:_videoThumbnail forKey:@"videoThumbnail"];
    [coder encodeObject:_linkcommon forKey:@"linkcommon"];
    [coder encodeObject:_sharefriend forKey:@"sharefriend"];
}

@end
