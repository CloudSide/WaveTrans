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

#import "VdiskUtil.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "VdiskBase64.h"

#pragma mark - NSData (VdiskEncode)

@implementation NSData (VdiskEncode)

- (NSString *)MD5EncodedString {
    
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5([self bytes], (CC_LONG)[self length], result);
	
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
}

- (NSData *)HMACSHA1EncodedDataWithKey:(NSString *)key {
    
	NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    void *buffer = malloc(CC_SHA1_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA1, [keyData bytes], [keyData length], [self bytes], [self length], buffer);
	
	NSData *encodedData = [NSData dataWithBytesNoCopy:buffer length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];
    return encodedData;
}

- (NSString *)base64EncodedString {
    
	return [VdiskBase64 stringByEncodingData:self];
}

+ (NSData *)dataFromBase64String:(NSString *)aString {

    return [VdiskBase64 decodeString:aString];
}

@end

#pragma mark - NSString (VdiskEncode)

@implementation NSString (VdiskEncode)

- (NSString *)MD5EncodedString {
    
	return [[self dataUsingEncoding:NSUTF8StringEncoding] MD5EncodedString];
}

- (NSData *)HMACSHA1EncodedDataWithKey:(NSString *)key {
    
	return [[self dataUsingEncoding:NSUTF8StringEncoding] HMACSHA1EncodedDataWithKey:key];
}

- (NSString *)base64EncodedString {
    
	return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString];
}

- (NSString *)URLEncodedString {
    
	return [self URLEncodedStringWithCFStringEncoding:kCFStringEncodingUTF8];
}

- (NSString *)URLEncodedStringWithCFStringEncoding:(CFStringEncoding)encoding {
    
	return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[[self mutableCopy] autorelease], NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"), encoding) autorelease];
}

- (NSString *)stringByDecodingURLFormat {
    
    NSString *result = [(NSString *)self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

@end

#pragma mark - NSString (VdiskUtil)

@implementation NSString (VdiskUtil)

+ (NSString *)GUIDString {
    
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return [(NSString *)string autorelease];
}

@end


@implementation VdiskUtil

+ (NSString *)fileSHA1HashCreateWithPath:(CFStringRef)filePath ChunkSize:(size_t)chunkSizeForReadingData {
	
    // Declare needed variables
    NSString *result = nil;
    CFReadStreamRef readStream = nil;
	
    // Get the file URL
    CFURLRef fileURL =
	CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
								  (CFStringRef)filePath,
								  kCFURLPOSIXPathStyle,
								  (Boolean)false);
    if (!fileURL) goto done;
	
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
	
    // Initialize the hash object
	CC_SHA1_CTX hashObject;
	CC_SHA1_Init(&hashObject);
	
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
	
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_SHA1_Update(&hashObject,
					   (const void *)buffer,
					   (CC_LONG)readBytesCount);
    }
	
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
	
    // Compute the hash digest
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(digest, &hashObject);
	
    // Abort if the read operation failed
    if (!didSucceed) goto done;
	
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
	/*
	 result = CFStringCreateWithCString(kCFAllocatorDefault,
	 (const char *)hash,
	 kCFStringEncodingUTF8);
	 */
	
	result = [NSString stringWithUTF8String:hash];
	
done:
	
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

// md5_file stream
+ (NSString *)fileMD5HashCreateWithPath:(CFStringRef)filePath ChunkSize:(size_t)chunkSizeForReadingData {
	
    // Declare needed variables
    NSString *result = nil;
    CFReadStreamRef readStream = nil;
	
    // Get the file URL
    CFURLRef fileURL =
	CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
								  (CFStringRef)filePath,
								  kCFURLPOSIXPathStyle,
								  (Boolean)false);
    if (!fileURL) goto done;
	
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
	
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
	
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
	
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,
                      (const void *)buffer,
                      (CC_LONG)readBytesCount);
    }
	
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
	
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
	
    // Abort if the read operation failed
    if (!didSucceed) goto done;
	
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
	/*
     result = CFStringCreateWithCString(kCFAllocatorDefault,
     (const char *)hash,
     kCFStringEncodingUTF8);
	 */
	
	result = [NSString stringWithUTF8String:hash];
	
done:
	
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

+ (NSString *)md5WithData:(NSData *)data {
    
	unsigned char hashedChars[CC_MD5_DIGEST_LENGTH];
    
	const char *cData = [data bytes];
    
    CC_MD5(cData, (CC_LONG)[data length], hashedChars);
	
	char hash[2 * sizeof(hashedChars) + 1];
	
    for (size_t i = 0; i < sizeof(hashedChars); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(hashedChars[i]));
    }
	
	return [NSString stringWithUTF8String:hash];
}

@end
