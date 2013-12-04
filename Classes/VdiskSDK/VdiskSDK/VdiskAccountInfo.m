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

#import "VdiskAccountInfo.h"


@implementation VdiskAccountInfo


@synthesize quota = _quota;
@synthesize userId = _userId;
@synthesize sinaUserId = _sinaUserId;

@synthesize screenname = _screenname;
@synthesize username = _username;
@synthesize avatarLarge = _avatarLarge;
@synthesize avatar = _avatar;


/*
 

 

 screen_name: "一个开发者",
 user_name: "一个开发者",
 profile_image_url: "http://tp2.sinaimg.cn/1656360925/50/5622701668/1",
 avatar_large: "http://tp2.sinaimg.cn/1656360925/180/5622701668/1",

 
 */



- (id)initWithDictionary:(NSDictionary *)dict {
    
    
    if ((self = [super init])) {
    
        
        if ([dict objectForKey:@"quota_info"]) {
        
            _quota = [[VdiskQuota alloc] initWithDictionary:[dict objectForKey:@"quota_info"]];
        }
        
        if ([[dict objectForKey:@"uid"] isKindOfClass:[NSNumber class]]) {
            
            _userId = [[[dict objectForKey:@"uid"] stringValue] retain];
            
        } else {
            
            _userId = [[dict objectForKey:@"uid"] retain];
        }
        
        if ([[dict objectForKey:@"sina_uid"] isKindOfClass:[NSNumber class]]) {
            
            _sinaUserId = [[[dict objectForKey:@"sina_uid"] stringValue] retain];
            
        } else {
            
            _sinaUserId = [[dict objectForKey:@"sina_uid"] retain];
        }
        
        
        if ([dict objectForKey:@"screen_name"]) {
            
            _screenname = [[dict objectForKey:@"screen_name"] retain];
            
        }
        
        if ([dict objectForKey:@"user_name"]) {
            
            _username = [[dict objectForKey:@"user_name"] retain];
            
        }
        
        if ([dict objectForKey:@"profile_image_url"]) {
            
            _avatarLarge = [[NSURL URLWithString:[dict objectForKey:@"profile_image_url"]] retain];
        }
        
        if ([dict objectForKey:@"avatar_large"]) {
            
            
            _avatar = [[NSURL URLWithString:[dict objectForKey:@"avatar_large"]] retain];
        }
        
        
        _original = [dict retain];
    }
    
    return self;
}

- (void)dealloc {
    
    [_quota release];
    [_userId release];
    [_sinaUserId release];
    [_original release];
    
    [_screenname release];
    [_username release];
    [_avatarLarge release];
    [_avatar release];
    
    [super dealloc];
}




#pragma mark NSCoding methods

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeObject:_original forKey:@"original"];
}

- (id)initWithCoder:(NSCoder *)coder {
    
    if ([coder containsValueForKey:@"original"]) {
    
        return [self initWithDictionary:[coder decodeObjectForKey:@"original"]];
    
    } else {
        
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];

        VdiskQuota *tempQuota = [coder decodeObjectForKey:@"quota"];
        
        NSDictionary *quotaDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLongLong:tempQuota.consumedBytes], @"consumed", [NSNumber numberWithLongLong:tempQuota.totalBytes], @"quota", nil];
        
        [mDict setObject:quotaDict forKey:@"quota_info"];
        [mDict setObject:[coder decodeObjectForKey:@"uid"] forKey:@"uid"];
        [mDict setObject:[coder decodeObjectForKey:@"sina_uid"] forKey:@"sina_uid"];
        [mDict setObject:[coder decodeObjectForKey:@"screen_name"] forKey:@"screen_name"];
        [mDict setObject:[coder decodeObjectForKey:@"user_name"] forKey:@"user_name"];
        [mDict setObject:[(NSURL *)[coder decodeObjectForKey:@"profile_image_url"] absoluteString] forKey:@"profile_image_url"];
        [mDict setObject:[(NSURL *)[coder decodeObjectForKey:@"avatar_large"] absoluteString] forKey:@"avatar_large"];
        

        return [self initWithDictionary:mDict];
    }
}

@end
