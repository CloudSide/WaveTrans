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

#import "VdiskDeltaEntry.h"

@implementation VdiskDeltaEntry

@synthesize lowercasePath = _lowercasePath;
@synthesize metadata = _metadata;

- (id)initWithArray:(NSArray *)array {
    
    if ((self = [super init])) {
    
        _lowercasePath = [[array objectAtIndex:0] retain];
        NSObject *maybeMetadata = [array objectAtIndex:1];
        
        if (maybeMetadata != [NSNull null]) {
            
            _metadata = [[VdiskMetadata alloc] initWithDictionary:[array objectAtIndex:1]];
        }
    }
    
    return self;
}

- (void)dealloc {
    
    [_lowercasePath release];
    [_metadata release];
    [super dealloc];
}

- (BOOL)isEqualToDeltaEntry:(VdiskDeltaEntry *)entry {
    
    if (self == entry) return YES;
    
    return (_lowercasePath == entry.lowercasePath || [_lowercasePath isEqual:entry.lowercasePath]) &&
        (_metadata == entry.metadata || [_metadata isEqual:entry.metadata]);
}

- (BOOL)isEqual:(id)other {
    
    if (other == self) return YES;
    
    if (!other || ![other isKindOfClass:[self class]]) return NO;
    
    return [self isEqualToDeltaEntry:other];
}


#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder*)coder {
    
    if ((self = [super init])) {
    
        _lowercasePath = [[coder decodeObjectForKey:@"lowercasePath"] retain];
        _metadata = [[coder decodeObjectForKey:@"metadata"] retain];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    
    [coder encodeObject:_lowercasePath forKey:@"lowercasePath"];
    [coder encodeObject:_metadata forKey:@"metadata"];
}


@end
