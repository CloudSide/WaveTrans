//
//  VdiskSharesCategory.h
//  VdiskSDK
//
//  Created by Bruce on 13-1-15.
//
//

#import <Foundation/Foundation.h>

@interface VdiskSharesCategory : NSObject <NSCoding> {

    NSString *_categoryId;
    NSString *_categoryName;
    NSString *_categoryPid;    
}

@property (nonatomic, readonly) NSString *categoryId;
@property (nonatomic, readonly) NSString *categoryName;
@property (nonatomic, readonly) NSString *categoryPid;

- (id)initWithDictionary:(NSDictionary *)dict;

@end
