//
//  VdiskSharesMetadata.m
//  VdiskSDK
//
//  Created by Bruce on 12-12-20.
//
//

#import "VdiskSharesMetadata.h"

@implementation VdiskSharesMetadata

@synthesize appKey = _appKey;
@synthesize uid = _uid;
@synthesize sinaUid = _sinaUid;
@synthesize name = _name;
@synthesize cpRef = _cpRef;
@synthesize link = _link;
@synthesize url = _url;
@synthesize shareTime = _shareTime;

@synthesize countBrowse = _countBrowse;
@synthesize countDownload = _countDownload;
@synthesize countCopy = _countCopy;
@synthesize countLike = _countLike;

@synthesize webHot = _webHot;
@synthesize iosHot = _iosHot;
@synthesize androidHot = _androidHot;
@synthesize isPreview = _isPreview;
@synthesize isStream = _isStream;

@synthesize categoryId = _categoryId;
@synthesize shareId = _shareId;
@synthesize title = _title;
@synthesize descriptions = _descriptions;
@synthesize shareType = _shareType;
@synthesize nick = _nick;
@synthesize price = _price;
@synthesize degree = _degree;
@synthesize shareAuth = _shareAuth;
@synthesize thumbnail = _thumbnail;
@synthesize sharesMetadataType = _sharesMetadataType;

@synthesize accessCode = _accessCode;


- (id)initWithDictionary:(NSDictionary *)dict sharesMetadataType:(kVdiskSharesMetadataType)sharesMetadataType {

    return [self initWithDictionary:dict sharesMetadataType:sharesMetadataType accessCode:nil];
}

- (id)initWithDictionary:(NSDictionary *)dict sharesMetadataType:(kVdiskSharesMetadataType)sharesMetadataType accessCode:(NSString *)accessCode {

    
    if ((self = [super initWithDictionary:dict])) {
        
        @try {
            
            _sharesMetadataType = sharesMetadataType;
            
            if ([dict objectForKey:@"share_time"]) {
                
                _shareTime = [[[VdiskSharesMetadata dateFormatter] dateFromString:[dict objectForKey:@"share_time"]] retain];
            }
            
            if ([dict objectForKey:@"contents"]) {
                
                NSArray *subfileDicts = [dict objectForKey:@"contents"];
                NSMutableArray *mutableContents = [[NSMutableArray alloc] initWithCapacity:[subfileDicts count]];
                
                for (NSDictionary *subfileDict in subfileDicts) {
                    
                    VdiskSharesMetadata *subfile = [[VdiskSharesMetadata alloc] initWithDictionary:subfileDict];
                    subfile.sharesMetadataType = self.sharesMetadataType;
                    [mutableContents addObject:subfile];
                    [subfile release];
                }
                
                [_contents release], _contents = nil;
                _contents = mutableContents;
            }
            
            /*
             
             app_key: "123456",
             uid: "371811",
             sina_uid: "1860293774",
             name: "【店铺设计】页面让客户一“见”钟情之首页设计.zip",
             copy_ref: "fQJvH",
             link: "",
             url: "",
             share_time: "Tue, 16 Oct 2012 09:48:12 +0000",
             
             count_browse: "0",
             count_download: "515",
             count_copy: "147",
             count_like: "0",
             
             web_hot: false,
             ios_hot: false,
             android_hot: false,
             is_preview: false,
             is_stream: false,
             
             category_id: "0",
             share_id: null,
             title: null,
             description: null,
             share_type: null,
             nick: null,
             price: null,
             degree: null,
             share_auth: null
             
             */
            
            
            _webHot = [[dict objectForKey:@"web_hot"] boolValue];
            _iosHot = [[dict objectForKey:@"ios_hot"] boolValue];
            _androidHot = [[dict objectForKey:@"android_hot"] boolValue];
            _isPreview = [[dict objectForKey:@"is_preview"] boolValue];
            _isStream = [[dict objectForKey:@"is_stream"] boolValue];
            
            
            _appKey = [[dict objectForKey:@"app_key"] retain];
            _uid = [[dict objectForKey:@"uid"] retain];
            _sinaUid = [[dict objectForKey:@"sina_uid"] retain];
            _name = [[dict objectForKey:@"name"] retain];
            _cpRef = [[dict objectForKey:@"copy_ref"] retain];
            _link = [[dict objectForKey:@"link"] retain];
            _url = [[dict objectForKey:@"url"] retain];
            
            
            _countBrowse = [[dict objectForKey:@"count_browse"] retain];
            _countDownload = [[dict objectForKey:@"count_download"] retain];
            _countCopy = [[dict objectForKey:@"count_copy"] retain];
            _countLike = [[dict objectForKey:@"count_like"] retain];
            
            
            _categoryId = [[dict objectForKey:@"category_id"] retain];
            _shareId = [[dict objectForKey:@"share_id"] retain];
            _title = [[dict objectForKey:@"title"] retain];
            _descriptions = [[dict objectForKey:@"description"] retain];
            _shareType = [[dict objectForKey:@"share_type"] retain];
            _nick = [[dict objectForKey:@"nick"] retain];
            _price = [[dict objectForKey:@"price"] retain];
            _degree = [[dict objectForKey:@"degree"] retain];
            _shareAuth = [[dict objectForKey:@"share_auth"] retain];
            
            _thumbnail = [[dict objectForKey:@"thumbnail"] retain];
            
            
            if (sharesMetadataType == kVdiskSharesMetadataTypeLinkcommon) {
                
                _accessCode = [accessCode copy];
            }
            
            
        } @catch (NSException *exception) {
            
            NSLog(@"%@", exception);
            
        } @finally {
            
            
        }
    }
    
    return self;
    
}

- (id)initWithDictionary:(NSDictionary *)dict {
    
    return [self initWithDictionary:dict sharesMetadataType:kVdiskSharesMetadataTypePublic];
}

- (void)dealloc {
    
    [_appKey release];
    [_uid release];
    [_sinaUid release];
    [_name release];
    [_cpRef release];
    [_link release];
    [_url release];
    [_shareTime release];
    
    [_countBrowse release];
    [_countDownload release];
    [_countCopy release];
    [_countLike release];
    
    [_categoryId release];
    [_shareId release];
    [_title release];
    [_descriptions release];
    [_shareType release];
    [_nick release];
    [_price release];
    [_degree release];
    [_shareAuth release];
    
    [_thumbnail release];
    
    [_accessCode release];
    
    [super dealloc];
}

- (NSString *)filename {
    
    return _name;
}

- (BOOL)isEqual:(id)object {
    
    if (object == self) return YES;
    if (![object isKindOfClass:[VdiskSharesMetadata class]]) return NO;
    
    VdiskSharesMetadata *other = (VdiskSharesMetadata *)object;
    
    return [self.fileSha1 isEqual:other.fileSha1] && [self.fileMd5 isEqual:other.fileMd5] && [self.name isEqual:other.name] && [self.cpRef isEqual:other.cpRef];
}

- (NSDictionary *)dictionaryValue {

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary:[super dictionaryValue]];
    
    if (_title) {
        
        [dictionary setValue:_title forKey:@"title"];
    }
    
    if (_name) {
        
        [dictionary setValue:_name forKey:@"name"];
    }
    
    if (_cpRef) {
        
        [dictionary setValue:_cpRef forKey:@"copy_ref"];
    }
    
    if (_url) {
        
        [dictionary setValue:_url forKey:@"url"];
    }
    
    if (_link) {
        
        [dictionary setValue:_link forKey:@"link"];
    }
    
    if (_uid) {
        
        [dictionary setValue:_uid forKey:@"uid"];
    }
    
    if (_sinaUid) {
        
        [dictionary setValue:_sinaUid forKey:@"sina_uid"];
    }
    
    if (_appKey) {
        
        [dictionary setValue:_appKey forKey:@"app_key"];
    }
    
    if (_thumbnail) {
        
        [dictionary setValue:_thumbnail forKey:@"thumbnail"];
    }
    
    return [dictionary autorelease];
}

- (BOOL)thumbnailExists {

    if (_thumbnail && [_thumbnail isKindOfClass:[NSString class]] && [_thumbnail length] > 0) {
        
        return YES;
    }
    
    return NO;
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder *)coder {
    
    if ((self = [super initWithCoder:coder])) {
                
        _webHot = [coder decodeBoolForKey:@"webHot"];
        _iosHot = [coder decodeBoolForKey:@"iosHot"];
        _androidHot = [coder decodeBoolForKey:@"androidHot"];
        _isPreview = [coder decodeBoolForKey:@"isPreview"];
        _isStream = [coder decodeBoolForKey:@"isStream"];
        
        _appKey = [[coder decodeObjectForKey:@"appKey"] retain];
        _uid = [[coder decodeObjectForKey:@"uid"] retain];
        _sinaUid = [[coder decodeObjectForKey:@"sinaUid"] retain];
        _name = [[coder decodeObjectForKey:@"name"] retain];
        _cpRef = [[coder decodeObjectForKey:@"cpRef"] retain];
        _link = [[coder decodeObjectForKey:@"link"] retain];
        _url = [[coder decodeObjectForKey:@"url"] retain];
        
        _countBrowse = [[coder decodeObjectForKey:@"countBrowse"] retain];
        _countDownload = [[coder decodeObjectForKey:@"countDownload"] retain];
        _countCopy = [[coder decodeObjectForKey:@"countCopy"] retain];
        _countLike = [[coder decodeObjectForKey:@"countLike"] retain];
        
        _categoryId = [[coder decodeObjectForKey:@"categoryId"] retain];
        _shareId = [[coder decodeObjectForKey:@"shareId"] retain];
        _title = [[coder decodeObjectForKey:@"title"] retain];
        _descriptions = [[coder decodeObjectForKey:@"descriptions"] retain];
        _shareType = [[coder decodeObjectForKey:@"shareType"] retain];
        _nick = [[coder decodeObjectForKey:@"nick"] retain];
        _price = [[coder decodeObjectForKey:@"price"] retain];
        _degree = [[coder decodeObjectForKey:@"degree"] retain];
        _shareAuth = [[coder decodeObjectForKey:@"shareAuth"] retain];
        _thumbnail = [[coder decodeObjectForKey:@"thumbnail"] retain];
        
        _sharesMetadataType = [coder decodeIntForKey:@"sharesMetadataType"];
        
        _accessCode = [[coder decodeObjectForKey:@"accessCode"] retain];
    
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {

    [super encodeWithCoder:coder];
    
    
    [coder encodeBool:_webHot forKey:@"webHot"];
    [coder encodeBool:_iosHot forKey:@"iosHot"];
    [coder encodeBool:_androidHot forKey:@"androidHot"];
    [coder encodeBool:_isPreview forKey:@"isPreview"];
    [coder encodeBool:_isStream forKey:@"isStream"];
    
    [coder encodeObject:_appKey forKey:@"appKey"];
    [coder encodeObject:_uid forKey:@"uid"];
    [coder encodeObject:_sinaUid forKey:@"sinaUid"];
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_cpRef forKey:@"cpRef"];
    [coder encodeObject:_link forKey:@"link"];
    [coder encodeObject:_url forKey:@"url"];
    
    [coder encodeObject:_countBrowse forKey:@"countBrowse"];
    [coder encodeObject:_countDownload forKey:@"countDownload"];
    [coder encodeObject:_countCopy forKey:@"countCopy"];
    [coder encodeObject:_countLike forKey:@"countLike"];
    
    [coder encodeObject:_categoryId forKey:@"categoryId"];
    [coder encodeObject:_shareId forKey:@"shareId"];
    [coder encodeObject:_title forKey:@"title"];
    [coder encodeObject:_descriptions forKey:@"descriptions"];
    [coder encodeObject:_shareType forKey:@"shareType"];
    [coder encodeObject:_nick forKey:@"nick"];
    [coder encodeObject:_price forKey:@"price"];
    [coder encodeObject:_degree forKey:@"degree"];
    [coder encodeObject:_shareAuth forKey:@"shareAuth"];
    [coder encodeObject:_thumbnail forKey:@"thumbnail"];
    
    [coder encodeInt:_sharesMetadataType forKey:@"sharesMetadataType"];
    
    [coder encodeObject:_accessCode forKey:@"accessCode"];
}

@end
