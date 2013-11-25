//
//  MetadataReceive.h
//  aurioTouch2
//
//  Created by Littlebox222 on 13-11-22.
//
//

#import <Foundation/Foundation.h>


@interface MetadataReceive : NSObject

@property (nonatomic, retain, readwrite) NSString *code;
@property (nonatomic, retain, readwrite) NSString *sha1;
@property (nonatomic, retain, readwrite) NSString *type;
@property (nonatomic, retain, readwrite) NSDate *ctime;
@property (nonatomic, retain, readwrite) NSString *content;
@property (nonatomic, readonly) NSString *size;
@property (nonatomic, readwrite) long long totalBytes;

//file
@property (nonatomic, readonly) NSString *filename;
@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSString *reader;

- (id)initWithDictionary:(NSDictionary *)dict;
+ (NSString *)humanReadableSize:(unsigned long long)length;
- (NSString *)cachePath:(BOOL)create;

@end
