//
//  FavoriteModel.h
//  VDiskMobile
//
//  Created by Bruce on 13-2-4.
//
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "WaveTransMetadata.h"

@interface WaveTransModel : NSObject


+ (NSMutableArray *)metadataList;
+ (unsigned long long)insertOrReplaceMetadata:(WaveTransMetadata *)metadata;
+ (BOOL)deleteMetadata:(WaveTransMetadata *)metadata;
+ (BOOL)existMetadata:(WaveTransMetadata *)metadata;


@end
