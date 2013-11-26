//
//  FavoriteModel.m
//  VDiskMobile
//
//  Created by Bruce on 13-2-4.
//
//

#import "WaveTransModel.h"

@interface WaveTransModel () {
    
    Database *_database;
}

- (NSError *)lastError;
- (int)lastErrorCode;
- (NSString *)lastErrorMessage;

- (NSMutableArray *)metadataList;
- (unsigned long long)insertOrReplaceMetadata:(WaveTransMetadata *)metadata;
- (BOOL)deleteMetadata:(WaveTransMetadata *)metadata;
- (BOOL)existMetadata:(WaveTransMetadata *)metadata;
- (WaveTransMetadata *)metadata:(WaveTransMetadata *)metadata;

@end


@implementation WaveTransModel


+ (NSMutableArray *)metadataList {
    
    WaveTransModel *waveTransModel = [[WaveTransModel alloc] init];
    NSMutableArray *metadataList = [waveTransModel metadataList];
    [waveTransModel release];

    return metadataList;
}

+ (unsigned long long)insertOrReplaceMetadata:(WaveTransMetadata *)metadata {

    WaveTransModel *waveTransModel = [[WaveTransModel alloc] init];
    unsigned long long result = [waveTransModel insertOrReplaceMetadata:metadata];
    [waveTransModel release];
    
    return result;
}

+ (BOOL)deleteMetadata:(WaveTransMetadata *)metadata {
    
    WaveTransModel *waveTransModel = [[WaveTransModel alloc] init];
    BOOL result = [waveTransModel deleteMetadata:metadata];
    [waveTransModel release];
    
    return result;
}

+ (WaveTransMetadata *)metadata:(WaveTransMetadata *)metadata {
    
    WaveTransModel *waveTransModel = [[WaveTransModel alloc] init];
    WaveTransMetadata *result = [waveTransModel metadata:metadata];
    [waveTransModel release];
    
    return result;
}

+ (BOOL)existMetadata:(WaveTransMetadata *)metadata {
    
    WaveTransModel *waveTransModel = [[WaveTransModel alloc] init];
    BOOL result = [waveTransModel existMetadata:metadata];
    [waveTransModel release];
    
    return result;
}





#pragma mark - implementation




- (NSError *)lastError {
    
    return [_database.database lastError];
}

- (int)lastErrorCode {
    
    return [_database.database lastErrorCode];
}

- (NSString *)lastErrorMessage {
    
    return [_database.database lastErrorMessage];
}

- (void)dealloc {
    
    [_database release], _database = nil;
    [super dealloc];
}

- (NSMutableArray *)tableColumns {
	
    NSMutableArray *arr = [NSMutableArray array];
    
	FMResultSet *results = [_database executeQuery:@"PRAGMA table_info(wave_trans_info);"];
	
    while ([results next]) {
        
        [arr addObject:[results stringForColumn:@"name"]];
    }
    
    return arr;
}

- (id)init {

    if (self = [super init]) {
        
        
        _database = [[Database alloc] init];
       
        NSString *createSQL = @"CREATE  TABLE  IF NOT EXISTS 'wave_trans_info' ('id' INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL , 'code' VARCHAR, 'sha1' VARCHAR, 'type' VARCHAR, 'content' TEXT, 'size' VARCHAR, 'ctime' VARCHAR, 'object' BLOB); CREATE  INDEX 'sha1_type_ctime' ON 'wave_trans_info' ('sha1' ASC, 'type' ASC, 'ctime' DESC); CREATE  INDEX 'ctime' ON 'wave_trans_info' ('ctime' DESC);";
        
        [_database executeUpdate:createSQL];
        
        /*
        NSMutableArray *tableColumns = [self tableColumns];
        
        if ([tableColumns indexOfObject:@"status"] == NSNotFound) {
            
            [_database executeUpdate:@"ALTER TABLE 'wave_trans_info' ADD COLUMN 'status' INTEGER NOT NULL DEFAULT 0;"];
        }
        
        if ([tableColumns indexOfObject:@"read_last"] == NSNotFound) {
            
            [_database executeUpdate:@"ALTER TABLE 'wave_trans_info' ADD COLUMN 'read_last' VARCHAR NOT NULL DEFAULT '0';"];
        }
         */
    }
    
    return self;
}


- (NSMutableArray *)selectWithSQL:(NSString *)sql withParameterDictionary:(NSDictionary *)parameterDictionary {
	
	NSMutableArray *arr = [NSMutableArray array];
    
    FMResultSet *results = parameterDictionary != nil && [parameterDictionary isKindOfClass:[NSDictionary class]] ? [_database executeQuery:sql withParameterDictionary:parameterDictionary] : [_database executeQuery:sql];
    
    while ([results next]) {
        
        WaveTransMetadata *md = [NSKeyedUnarchiver unarchiveObjectWithData:[results dataForColumn:@"object"]];
        [arr addObject:md];
    }
    
    return arr;
}



- (NSMutableArray *)metadataList {
    
    NSMutableArray *arr = nil;
    
    @try {
        
        @synchronized(self) {
        
            arr = [self selectWithSQL:@"select object from wave_trans_info order by ctime desc limit 1000" withParameterDictionary:nil];
        }
            
    } @catch (NSException *exception) {
      
        arr = [NSMutableArray array];
        NSLog(@"%@", exception);
        
    } @finally {
        
        return arr;
    }
}


- (unsigned long long)insertOrReplaceMetadata:(WaveTransMetadata *)metadata {
    
    if (metadata.content == nil) {
        
        metadata.content = @"";
    }
    
    if ([self existMetadata:metadata]) {
        
        if ([metadata isKindOfClass:[WaveTransMetadata class]]) {
            
            [self queryWithSQL:@"UPDATE 'wave_trans_info' SET 'code' = :code, 'content' = :content, 'size' = :size, 'ctime' = :ctime, 'object' = :object WHERE  'sha1' = :sha1 and 'type' = :type limit 1"
           parameterDictionary:@{
                                 
                                 @"code" : metadata.code,
                                 @"content" : metadata.content,
                                 @"size" : [NSString stringWithFormat:@"%llu", metadata.totalBytes],
                                 @"ctime" : [NSString stringWithFormat:@"%f", [metadata.ctime timeIntervalSince1970]],
                                 @"object" : [NSKeyedArchiver archivedDataWithRootObject:metadata],
                                 @"sha1" : metadata.sha1,
                                 @"type" : metadata.type
                                 
                                 }];
            
        }
        
        return 1;
    }
    
	NSString *sql = @"INSERT INTO 'wave_trans_info' ('code','sha1','type','content','size','ctime','object') VALUES (:code,:sha1,:type,:content,:size,:ctime,:object);";
    
    NSDictionary *parameterDictionary = @{@"code" : metadata.code,
                                          @"sha1" : metadata.sha1,
                                          @"type" : metadata.type,
                                          @"content" : metadata.content,
                                          @"size" : [NSString stringWithFormat:@"%llu", metadata.totalBytes],
                                          @"ctime" : [NSString stringWithFormat:@"%f", [metadata.ctime timeIntervalSince1970]],
                                          @"object" : [NSKeyedArchiver archivedDataWithRootObject:metadata]};
        
    return [self insertWithSQL:sql parameterDictionary:parameterDictionary];
}



- (BOOL)existMetadata:(WaveTransMetadata *)metadata {

    if ([metadata isKindOfClass:[WaveTransMetadata class]]) {
    
        NSMutableArray *arr = [self selectWithSQL:[NSString stringWithFormat:@"select object from 'wave_trans_info' where sha1='%@' and type='%@' limit 1", metadata.sha1, metadata.type] withParameterDictionary:nil];
        
        if ([arr count] > 0) {
            
            if ([arr[0] isKindOfClass:[WaveTransMetadata class]] /*&& [metadata isEqual:arr[0]]*/) {
                
                return YES;
            }
        }
    }
    
    return NO;
}

- (WaveTransMetadata *)metadata:(WaveTransMetadata *)metadata {

    if ([metadata isKindOfClass:[WaveTransMetadata class]]) {
        
        NSMutableArray *arr = [self selectWithSQL:[NSString stringWithFormat:@"select object from 'wave_trans_info' where sha1='%@' and type='%@' limit 1", metadata.sha1, metadata.type] withParameterDictionary:nil];
        
        if ([arr count] > 0) {
            
            if ([arr[0] isKindOfClass:[WaveTransMetadata class]]) {
                
                return arr[0];
            }
        }
    }
    
    return nil;
}


- (BOOL)deleteMetadata:(WaveTransMetadata *)metadata {
	
    if ([metadata isKindOfClass:[WaveTransMetadata class]]) {
        
        return [self queryWithSQL:@"DELETE FROM 'wave_trans_info' WHERE sha1=:sha1 and type=:type"
              parameterDictionary:@{@"sha1":metadata.sha1, @"type":metadata.type}] && [[NSFileManager defaultManager] removeItemAtPath:[[metadata cachePath:NO] stringByDeletingLastPathComponent] error:nil];
        
    }
    
    return NO;
}

- (BOOL)queryWithSQL:(NSString *)sql {
    
    return [self queryWithSQL:sql parameterDictionary:nil];
}

- (BOOL)queryWithSQL:(NSString *)sql parameterDictionary:(NSDictionary *)parameterDictionary {
	
    if (parameterDictionary != nil) {
        
        return [_database executeUpdate:sql withParameterDictionary:parameterDictionary];
    }
    
	return [_database executeUpdate:sql];
}

- (unsigned long long)insertWithSQL:(NSString *)sql parameterDictionary:(NSDictionary *)parameterDictionary {
	
    [self queryWithSQL:sql parameterDictionary:parameterDictionary];
    
	return [_database.database lastInsertRowId];
}



@end
