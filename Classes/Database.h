//
//  Database.h
//  VDiskMobile
//
//  Created by Bruce on 13-2-5.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"

@interface Database : NSObject

//+ (Database *)sharedDatabase;
- (FMResultSet *)executeQuery:(NSString *)sql;
- (FMResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments;
- (BOOL)executeUpdate:(NSString *)sql;
- (BOOL)executeUpdate:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments;

@property (nonatomic, readonly) NSString *dbPath;
@property (nonatomic, readonly) FMDatabase *database;

@end
