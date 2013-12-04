//
//  VdiskSharesMetadata.h
//  VdiskSDK
//
//  Created by Bruce on 12-12-20.
//
//

#import <Foundation/Foundation.h>
#import "VdiskMetadata.h"

typedef enum {
    
    kVdiskSharesMetadataTypePublic = 0,
    kVdiskSharesMetadataTypeFromFriend,
    kVdiskSharesMetadataTypeLinkcommon,
    
} kVdiskSharesMetadataType;


@interface VdiskSharesMetadata : VdiskMetadata <NSCoding> {

    NSString *_appKey;
    NSString *_uid;
    NSString *_sinaUid;
    NSString *_name;
    NSString *_cpRef;
    NSString *_link;
    NSString *_url;
    NSDate *_shareTime;
    
    NSString *_countBrowse;
    NSString *_countDownload;
    NSString *_countCopy;
    NSString *_countLike;
    
    BOOL _webHot;
    BOOL _iosHot;
    BOOL _androidHot;
    BOOL _isPreview;
    BOOL _isStream;
    
    NSString *_categoryId;
    NSString *_shareId;
    NSString *_title;
    NSString *_descriptions;
    NSString *_shareType;
    NSString *_nick;
    NSString *_price;
    NSString *_degree;
    NSString *_shareAuth;
    NSString *_thumbnail;
    
    int _sharesMetadataType;
    
    NSString *_accessCode;
}

@property (nonatomic, readonly) NSString *appKey;
@property (nonatomic, readonly) NSString *uid;
@property (nonatomic, readonly) NSString *sinaUid;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *cpRef;
@property (nonatomic, readonly) NSString *link;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSDate *shareTime;

@property (nonatomic, readonly) NSString *countBrowse;
@property (nonatomic, readonly) NSString *countDownload;
@property (nonatomic, readonly) NSString *countCopy;
@property (nonatomic, readonly) NSString *countLike;

@property (nonatomic, readonly) BOOL webHot;
@property (nonatomic, readonly) BOOL iosHot;
@property (nonatomic, readonly) BOOL androidHot;
@property (nonatomic, readonly) BOOL isPreview;
@property (nonatomic, readonly) BOOL isStream;

@property (nonatomic, readonly) NSString *categoryId;
@property (nonatomic, readonly) NSString *shareId;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *descriptions;
@property (nonatomic, readonly) NSString *shareType;
@property (nonatomic, readonly) NSString *nick;
@property (nonatomic, readonly) NSString *price;
@property (nonatomic, readonly) NSString *degree;
@property (nonatomic, readonly) NSString *shareAuth;
@property (nonatomic, readonly) NSString *thumbnail;

@property (nonatomic, assign) int sharesMetadataType;

@property (nonatomic, readonly) NSString *accessCode;

- (id)initWithDictionary:(NSDictionary *)dict sharesMetadataType:(kVdiskSharesMetadataType)sharesMetadataType;
- (id)initWithDictionary:(NSDictionary *)dict sharesMetadataType:(kVdiskSharesMetadataType)sharesMetadataType accessCode:(NSString *)accessCode;

@end
