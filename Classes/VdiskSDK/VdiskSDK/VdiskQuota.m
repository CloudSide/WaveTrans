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

#import "VdiskQuota.h"

@implementation VdiskQuota

@synthesize consumedBytes = _consumedBytes;
@synthesize totalBytes = _totalBytes;


- (id)initWithDictionary:(NSDictionary *)dict {
    
    if ((self = [super init])) {
    
        _consumedBytes = [[dict objectForKey:@"consumed"] longLongValue];
        _totalBytes = [[dict objectForKey:@"quota"] longLongValue];
    }
    
    return self;
}

- (void)dealloc {
    
    [super dealloc];
}

#pragma mark NSCoding methods

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeInt64:_consumedBytes forKey:@"consumedBytes"];
    [coder encodeInt64:_totalBytes forKey:@"totalBytes"];
}

- (id)initWithCoder:(NSCoder *)coder {
    
    self = [super init];
    
    _consumedBytes = [coder decodeInt64ForKey:@"consumedBytes"];
    _totalBytes = [coder decodeInt64ForKey:@"totalBytes"];
 
    return self;
}

@end
