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

#import <Foundation/Foundation.h>

//Functions for Encoding Data.
@interface NSData (VdiskEncode)

- (NSString *)MD5EncodedString;
- (NSData *)HMACSHA1EncodedDataWithKey:(NSString *)key;
- (NSString *)base64EncodedString;
+ (NSData *)dataFromBase64String:(NSString *)aString;

@end

//Functions for Encoding String.
@interface NSString (VdiskEncode)

- (NSString *)MD5EncodedString;
- (NSData *)HMACSHA1EncodedDataWithKey:(NSString *)key;
- (NSString *)base64EncodedString;
- (NSString *)URLEncodedString;
- (NSString *)URLEncodedStringWithCFStringEncoding:(CFStringEncoding)encoding;
- (NSString *)stringByDecodingURLFormat;

@end

@interface NSString (VdiskUtil) 

+ (NSString *)GUIDString;

@end

#define FileHashDefaultChunkSizeForReadingData 64 * 1024

@interface VdiskUtil : NSObject

+ (NSString *)fileMD5HashCreateWithPath:(CFStringRef)filePath ChunkSize:(size_t)chunkSizeForReadingData;
+ (NSString *)fileSHA1HashCreateWithPath:(CFStringRef)filePath ChunkSize:(size_t)chunkSizeForReadingData;
+ (NSString *)md5WithData:(NSData *)data;

@end


