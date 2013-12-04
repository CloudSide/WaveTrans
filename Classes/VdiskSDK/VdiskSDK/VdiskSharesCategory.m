//
//  VdiskSharesCategory.m
//  VdiskSDK
//
//  Created by Bruce on 13-1-15.
//
//

#import "VdiskSharesCategory.h"

@implementation VdiskSharesCategory

@synthesize categoryId = _categoryId;
@synthesize categoryName = _categoryName;
@synthesize categoryPid = _categoryPid;


- (id)initWithDictionary:(NSDictionary *)dict {

    if ((self = [super init])) {
        
        _categoryId = [[dict objectForKey:@"category_id"] retain];
        _categoryName = [[dict objectForKey:@"category_name"] retain];
        _categoryPid = [[dict objectForKey:@"category_pid"] retain];
        
    }
    
    return self;
}

- (void)dealloc {
    
    [_categoryName release];
    [_categoryId release];
    [_categoryPid release];
    
    [super dealloc];
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder *)coder {
    
    if ((self = [super init])) {
        
        _categoryId = [[coder decodeObjectForKey:@"categoryId"] retain];
        _categoryName = [[coder decodeObjectForKey:@"categoryName"] retain];
        _categoryPid = [[coder decodeObjectForKey:@"categoryPid"] retain];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {

    [coder encodeObject:_categoryId forKey:@"categoryId"];
    [coder encodeObject:_categoryName forKey:@"categoryName"];
    [coder encodeObject:_categoryPid forKey:@"categoryPid"];
}

@end
