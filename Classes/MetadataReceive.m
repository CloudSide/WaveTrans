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
            self.size = [NSString stringWithFormat:@"%@", [dict objectForKey:@"size"]];
            self.ctime = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"ctime"] doubleValue]];
        
        }
        @catch (NSException *exception) {
            
            NSLog(@"%@", exception);
        }
    }
    
    return self;
}

@end
