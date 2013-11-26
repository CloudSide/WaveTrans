//
//  MetadataReceive.m
//  aurioTouch2
//
//  Created by Littlebox222 on 13-11-22.
//
//

#import "WaveTransMetadata.h"
#import "rscode.h"
#import "bb_freq_util.h"
#import "WaveTransModel.h"

@implementation WaveTransMetadata

@synthesize code = _code;
@synthesize sha1 = _sha1;
@synthesize type = _type;
@synthesize ctime = _ctime;
@synthesize content = _content;
@synthesize filename = _filename;


static NSDictionary *kSharedFileExtNameDictionary = nil;

+ (NSString *)codeWithSha1:(NSString *)sha1 {

    if ([sha1 length] != 40) {
        
        return nil;
    }
    
    unsigned int codeInt[20];
    
    for (int i=0; i<40; i+=2) {
        
        unsigned int hexAsInt;
        [[NSScanner scannerWithString:[sha1 substringWithRange:NSMakeRange(i, 2)]] scanHexInt:&hexAsInt];
        codeInt[i/2] = hexAsInt;
    }
    
    NSMutableArray *codes = [NSMutableArray array];
    
    for (int i = 0; i < 10; i++) {
        
        unsigned int n1 = codeInt[i];
        unsigned int n2 = codeInt[19-i];
        NSString *n3 = [NSString stringWithFormat:@"%06d", ((n1 * n1) + (n2 * n2))];
        n3 = [n3 substringWithRange:NSMakeRange(1, 4)];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        unsigned int n4 = [[formatter numberFromString:n3] unsignedIntValue];
        unsigned int n5 = n4 % 32;
        char n6;
        num_to_char(n5, &n6);
        [codes addObject:[NSString stringWithFormat:@"%c", n6]];
    }
    
    return [codes componentsJoinedByString:@""];
}


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

- (void)save {

    [WaveTransModel insertOrReplaceMetadata:self];
}


- (NSString *)code {

    if (_code == nil && _sha1 != nil && [_sha1 isKindOfClass:[NSString class]]) {
        
        _code = [[WaveTransMetadata codeWithSha1:_sha1] retain];
    }
    
    return _code;
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

- (BOOL)hasCache {
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[self cachePath:NO]];
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

- (void)setFilename:(NSString *)filename {

    if (_filename) {
        
        [_filename release];
        _filename = nil;
    }
    
    _filename = [filename copy];
}

- (NSString *)filename {
    
    if (_filename) {
        
        return _filename;
    }

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

    return [WaveTransMetadata humanReadableSize:self.totalBytes];
}

- (NSString *)reader {
    
    NSString *reader = nil;
    
    NSArray *nameItems = [self.filename componentsSeparatedByString:@"."];
    
    if ([nameItems count] > 1) {
        
        NSString *extName = [[nameItems lastObject] lowercaseString];
        
        if ([[[WaveTransMetadata sharedFileExtNameDictionary] objectForKey:extName] isKindOfClass:[NSDictionary class]]) {
            
            reader = [[[WaveTransMetadata sharedFileExtNameDictionary] objectForKey:extName] objectForKey:@"reader"];
            
        } else {
            
            reader = [[[WaveTransMetadata sharedFileExtNameDictionary] objectForKey:@"other"] objectForKey:@"reader"];
        }
        
    } else {
        
        reader = [[[WaveTransMetadata sharedFileExtNameDictionary] objectForKey:@"other"] objectForKey:@"reader"];
    }
    
    return reader;
}


- (void)dealloc {
    
    [_code release];
    [_sha1 release];
    [_type release];
    [_ctime release];
    [_content release];
    [_filename release];
    
    [super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)dict {
    
    if (self = [super init]) {
        
        @try {
            
            self.code = [dict objectForKey:@"code"];
            self.sha1 = [dict objectForKey:@"sha1"];
            self.type = [dict objectForKey:@"type"];
            self.content = [dict objectForKey:@"content"];
            self.totalBytes = [[NSString stringWithFormat:@"%@", [dict objectForKey:@"size"]] longLongValue];
            self.ctime = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"ctime"] doubleValue]];
        
        } @catch (NSException *exception) {
            
            NSLog(@"%@", exception);
        }
    }
    
    return self;
}

- (id)initWithSha1:(NSString *)sha1 type:(NSString *)type content:(NSString *)content size:(unsigned long long )size filename:(NSString *)filename {

    if (self = [super init]) {
        
        _sha1 = [sha1 copy];
        _type = [type copy];
        _content = [content copy];
        _totalBytes = size;
        _ctime = [[NSDate date] retain];
        _filename = [filename copy];
        _code = [[WaveTransMetadata codeWithSha1:_sha1] copy];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object {
    
    if (object == self) return YES;
    if (![object isKindOfClass:[WaveTransMetadata class]]) return NO;
    
    WaveTransMetadata *other = (WaveTransMetadata *)object;
   
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
    
    [coder encodeInt64:self.totalBytes forKey:@"totalBytes"];
    [coder encodeObject:self.content forKey:@"content"];
    [coder encodeObject:self.code forKey:@"code"];
    [coder encodeObject:self.sha1 forKey:@"sha1"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.ctime forKey:@"ctime"];
}



@end
