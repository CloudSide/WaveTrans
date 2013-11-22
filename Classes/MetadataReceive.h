//
//  MetadataReceive.h
//  aurioTouch2
//
//  Created by Littlebox222 on 13-11-22.
//
//

#import <Foundation/Foundation.h>

@interface MetadataReceive : NSObject

@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *sha1;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSDate *ctime;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSString *size;

- (id)initWithDictionary:(NSDictionary *)dict;

@end
