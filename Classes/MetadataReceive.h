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
@property (nonatomic, retain, readwrite) NSString *size;
@property (nonatomic, readwrite) long long totalBytes;

- (id)initWithDictionary:(NSDictionary *)dict;
+ (NSString *)humanReadableSize:(unsigned long long)length;

@end
