//
//  Database.m
//  VDiskMobile
//
//  Created by Bruce on 13-2-5.
//
//

#import "Database.h"

@interface Database () {
    
    NSString *_dbPath;
    FMDatabase *_database;
}

@end


@implementation Database

@synthesize dbPath = _dbPath;
@synthesize database = _database;


- (NSString *)documentsPath {
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	if ([paths count] > 0) {
		
		return [paths objectAtIndex:0];
	}
	
	return [NSHomeDirectory() stringByAppendingString:@"/Documents"];
}


- (BOOL)createDirectory:(NSString *)path {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [[self documentsPath] stringByAppendingFormat:@"/%@", path];
    BOOL isDir = NO;
    BOOL isExists = [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
    
    if (!(isExists && isDir)) {
        
        return  [fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        
    } else {
        
        return YES;
    }
}

- (id)init {
    
    if (self = [super init]) {
        
        NSString *dbDirPath = @"userdata";
        [self createDirectory:dbDirPath];
        _dbPath = [[[self documentsPath] stringByAppendingFormat:@"/%@/userdata.sqlite", dbDirPath] retain];
        _database = [[FMDatabase alloc] initWithPath:_dbPath];
        
        /* DEBUG
         
        _database.traceExecution = YES;
        _database.logsErrors = YES;
         
         */
        
        [_database open];
    }
    
    return self;
}

- (void)dealloc {
 
    [_database close];
    
    [_dbPath release], _dbPath = nil;
    [_database release], _database = nil;
    
    [super dealloc];
}




- (FMResultSet *)executeQuery:(NSString *)sql {

    return [self.database executeQuery:sql];
}

- (FMResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments {

    return [self.database executeQuery:sql withParameterDictionary:arguments];
}


- (BOOL)executeUpdate:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments {

    BOOL ret = NO;
     
    if (arguments == nil) {
        
        ret = [_database executeUpdate:sql];
        
    } else {
        
        ret = [_database executeUpdate:sql withParameterDictionary:arguments];
    }
    
    return ret;
}

- (BOOL)executeUpdate:(NSString *)sql {
    
    return [self executeUpdate:sql withParameterDictionary:nil];
}


@end
