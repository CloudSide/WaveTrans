//
//  MetadataReceive.m
//  aurioTouch2
//
//  Created by Littlebox222 on 13-11-22.
//
//

#import "MetadataReceive.h"

@implementation MetadataReceive

@synthesize code = _code;
@synthesize sha1 = _sha1;
@synthesize type = _type;
@synthesize ctime = _ctime;
@synthesize content = _content;


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



- (void)dealloc {
    
    [_code release];
    [_sha1 release];
    [_type release];
    [_ctime release];
    [_content release];
    [_size release];
    
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
            self.size = [MetadataReceive humanReadableSize:self.totalBytes];
            self.ctime = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"ctime"] doubleValue]];
        
        
        } @catch (NSException *exception) {
            
            NSLog(@"%@", exception);
        }
    }
    
    return self;
}

@end
