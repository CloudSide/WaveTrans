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

@interface VdiskAccountInfo : NSObject <NSCoding> {
    
    VdiskQuota *_quota;
    NSString *_userId;
    NSString *_sinaUserId;
    NSDictionary *_original;
    
    NSString *_screenname;
    NSString *_username;
    NSURL *_avatarLarge;
    NSURL *_avatar;
}

- (id)initWithDictionary:(NSDictionary *)dict;

@property (nonatomic, readonly) VdiskQuota *quota;
@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSString *sinaUserId;

@property (nonatomic, readonly) NSString *screenname;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSURL *avatarLarge;
@property (nonatomic, readonly) NSURL *avatar;



@end