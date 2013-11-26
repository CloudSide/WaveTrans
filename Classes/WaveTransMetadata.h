//
//  MetadataReceive.h
//  aurioTouch2
//
//  Created by Littlebox222 on 13-11-22.
//
//

#import <Foundation/Foundation.h>


@interface WaveTransMetadata : NSObject

@property (nonatomic, retain, readwrite) NSString *code;
@property (nonatomic, retain, readwrite) NSString *sha1;
@property (nonatomic, retain, readwrite) NSString *type;
@property (nonatomic, retain, readwrite) NSDate *ctime;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, readonly) NSString *size;
@property (nonatomic, readwrite) long long totalBytes;
@property (nonatomic, retain, readwrite) NSString *rsCode;

//file
@property (nonatomic, readonly) NSString *filename;
@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSString *reader;
@property (nonatomic, readonly) BOOL hasCache;

@property (nonatomic, assign) BOOL uploaded;

/*
 code
 sha1
 type
 content
 size
 ctime
 */


- (void)setFilename:(NSString *)filename;

- (id)initWithDictionary:(NSDictionary *)dict;

- (id)initWithSha1:(NSString *)sha1 type:(NSString *)type content:(NSString *)content size:(unsigned long long )size filename:(NSString *)filename;

+ (NSString *)humanReadableSize:(unsigned long long)length;
- (NSString *)cachePath:(BOOL)create;
+ (NSString *)codeWithSha1:(NSString *)sha1;

- (void)save;


@end
