//
//  MetadataReceive.m
//  aurioTouch2
//
//  Created by Littlebox222 on 13-11-22.
//
//

#import "MetadataReceive.h"
#import "rscode.h"
#import "bb_freq_util.h"

@implementation MetadataReceive

@synthesize code = _code;
@synthesize sha1 = _sha1;
@synthesize type = _type;
@synthesize ctime = _ctime;
@synthesize content = _content;


static NSDictionary *kSharedFileExtNameDictionary = nil;


+ (NSDictionary *)sharedFileExtNameDictionary {
    
    if (kSharedFileExtNameDictionary == nil) {
        
        kSharedFileExtNameDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FileExt" ofType:@"plist"]];
    }
    
    return kSharedFileExtNameDictionary;
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

- (NSURL *)fileURL {

    if ([self.type isEqualToString:@"file"] && self.content != nil && [self.content isKindOfClass:[NSString class]]) {
        
        return [NSURL URLWithString:self.content];
    }
    
    return nil;
}


- (NSString *)documentsPath {
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	if ([paths count] > 0) {
		
		return [paths objectAtIndex:0];
	}
	
	return [NSHomeDirectory() stringByAppendingString:@"/Documents"];
}

- (BOOL)createDirectory:(NSString *)path {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [[self documentsPath] stringByAppendingFormat:@"/%@", path];
    BOOL isDir = NO;
    BOOL isExists = [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
    
    if (!(isExists && isDir)) {
        
        return  [fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        
    } else {
        
        return YES;
    }
}


- (NSString *)cachePath:(BOOL)create { //如果文件所在目录不存在，create参数判断是否创建
    
    if ([self.type isEqualToString:@"file"] && self.sha1 != nil && [self.sha1 isKindOfClass:[NSString class]] && ![self.sha1 isEqualToString:@""]) {
        
        NSString *theUserCachePath = [NSString stringWithFormat:@"cache/files/%@", self.sha1];
        
        if (create) {
            
            [self createDirectory:theUserCachePath];
        }
        
        NSString *theFileCachePath = [theUserCachePath stringByAppendingFormat:@"/%@", self.filename];
        NSString *cachePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:theFileCachePath];
        
        return cachePath;
    }
	
	return nil;
}

- (NSString *)rsCode {

    if (self.code && [self.code isKindOfClass:[NSString class]] && [self.code length] == 10) {
        
        const char *src = [self.code UTF8String];
        
        unsigned char data[RS_TOTAL_LEN];
        
        for (int i=0; i<RS_TOTAL_LEN; i++) {
            
            if (i < RS_DATA_LEN) {
                
                char_to_num(src[i], (unsigned int *)(data+i));
                
            } else {
                
                data[i] = 0;
            }
        }
        
        unsigned char *code = data + RS_DATA_LEN;
        
        RS *rs = init_rs(RS_SYMSIZE, RS_GFPOLY, RS_FCR, RS_PRIM, RS_NROOTS, RS_PAD);
        encode_rs_char(rs, data, code);
        
        char rs_code[RS_TOTAL_LEN+1];
        
        for (int i=0; i<RS_TOTAL_LEN; i++) {
            
            num_to_char(code[i], &(rs_code[i]));
        }
        
        rs_code[RS_TOTAL_LEN] = '\0';
        
        return [NSString stringWithUTF8String:rs_code];
    }
    
    return nil;
}

- (NSString *)filename {

    if (self.fileURL) {
        
        NSString *query = [self.fileURL query];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        NSArray *paramsArray = [query componentsSeparatedByString:@"&"];
        
        for (NSString *paramStr in paramsArray) {
            
            NSArray *paramArray = [paramStr componentsSeparatedByString:@"="];
            if ([paramArray count] != 2) continue;
            [dict setObject:[[[paramArray objectAtIndex:1] stringByDecodingURLFormat] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:[paramArray objectAtIndex:0]];
            
        }
        
        return [dict objectForKey:@"fn"];
        
    }
    
    return nil;
}

- (NSString *)size {

    return [MetadataReceive humanReadableSize:self.totalBytes];
}

- (NSString *)reader {
    
    NSString *reader = nil;
    
    NSArray *nameItems = [self.filename componentsSeparatedByString:@"."];
    
    if ([nameItems count] > 1) {
        
        NSString *extName = [[nameItems lastObject] lowercaseString];
        
        if ([[[MetadataReceive sharedFileExtNameDictionary] objectForKey:extName] isKindOfClass:[NSDictionary class]]) {
            
            reader = [[[MetadataReceive sharedFileExtNameDictionary] objectForKey:extName] objectForKey:@"reader"];
            
        } else {
            
            reader = [[[MetadataReceive sharedFileExtNameDictionary] objectForKey:@"other"] objectForKey:@"reader"];
        }
        
    } else {
        
        reader = [[[MetadataReceive sharedFileExtNameDictionary] objectForKey:@"other"] objectForKey:@"reader"];
    }
    
    return reader;
}


- (void)dealloc {
    
    [_code release];
    [_sha1 release];
    [_type release];
    [_ctime release];
    [_content release];
    
    [super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)dict {
    
    if (self = [super init]) {
        
        @try {
            
            self.code = [NSString stringWithFormat:@"%@", [dict objectForKey:@"code"]];
            self.sha1 = [NSString stringWithFormat:@"%@", [dict objectForKey:@"sha1"]];
            self.type = [NSString stringWithFormat:@"%@", [dict objectForKey:@"type"]];
            self.content = [NSString stringWithFormat:@"%@", [dict objectForKey:@"content"]];
            self.totalBytes = [[NSString stringWithFormat:@"%@", [dict objectForKey:@"size"]] longLongValue];
            self.ctime = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"ctime"] doubleValue]];
        
        } @catch (NSException *exception) {
            
            NSLog(@"%@", exception);
        }
    }
    
    return self;
}

- (BOOL)isEqual:(id)object {
    
    if (object == self) return YES;
    if (![object isKindOfClass:[MetadataReceive class]]) return NO;
    
    MetadataReceive *other = (MetadataReceive *)object;
   
    if ([other.type isEqualToString:self.type] && [other.sha1 isEqualToString:self.sha1] && [other.code isEqualToString:self.code] && other.totalBytes == self.totalBytes) {
        
        if ([self.type isEqualToString:@"file"]) {
            
            if ([self.filename isEqualToString:other.filename]) {
                
                return YES;
            
            } else {
            
                return NO;
            }
            
        } else {
        
            return YES;
        }
    }
    
    return NO;
}




#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder *)coder {
    
    if ((self = [super init])) {
        
        _totalBytes = [coder decodeInt64ForKey:@"totalBytes"];
        _content = [[coder decodeObjectForKey:@"content"] retain];
        _code = [[coder decodeObjectForKey:@"code"] retain];
        _sha1 = [[coder decodeObjectForKey:@"sha1"] retain];
        _type = [[coder decodeObjectForKey:@"type"] retain];
        _ctime = [[coder decodeObjectForKey:@"ctime"] retain];
        
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeInt64:_totalBytes forKey:@"totalBytes"];
    [coder encodeObject:_content forKey:@"content"];
    [coder encodeObject:_code forKey:@"code"];
    [coder encodeObject:_sha1 forKey:@"sha1"];
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_ctime forKey:@"ctime"];
}



@end
