//
//  VdiskSDK
//  Based on OAuth 2.0
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//
//  Created by Bruce Chen (weibo: @一个开发者) on 12-6-15.
//
//  Copyright (c) 2012 Sina Vdisk. All rights reserved.
//

#import "VdiskSession.h"
#import "VdiskAccountInfo.h"
#import "VdiskJSON.h"

int ddLogLevel;

static VdiskSession *kVdiskSharedSession = nil;
static NSString *kUserAgentAddition = nil;

@interface VdiskSession (Private) <VdiskRestClientDelegate>

- (NSString *)urlSchemeString;

- (void)saveAuthorizeDataToKeychain;
- (void)readAuthorizeDataFromKeychain;
- (void)deleteAuthorizeDataInKeychain;

@end


@implementation VdiskSession

@synthesize appKey = _appKey;
@synthesize appSecret = _appSecret;
@synthesize sinaUserID = _sinaUserID;
@synthesize userID = _userID;
@synthesize accessToken = _accessToken;
@synthesize refreshToken = _refreshToken;
@synthesize expireTime = _expireTime;
@synthesize redirectURI = _redirectURI;
@synthesize isUserExclusive = _isUserExclusive;
@synthesize authorize = _authorize;
@synthesize sinaWeibo = _sinaWeibo;
@synthesize delegate = _delegate;
@synthesize appRoot = _appRoot;
@synthesize sessionType = _sessionType;
//@synthesize weiboAccessToken = _weiboAccessToken;
@synthesize udid = _udid;
@synthesize globalParams = _globalParams;


+ (VdiskSession *)sharedSession {
    
    return kVdiskSharedSession;
}

+ (void)setSharedSession:(VdiskSession *)session {
    
    if (session == kVdiskSharedSession) return;
    
    [kVdiskSharedSession release];
    kVdiskSharedSession = [session retain];
    
    
    
    /* CLog */
    
    CLog *clog = [[[CLog alloc] init] autorelease];
    [clog setCustomType:@"user_event"];
    [clog setCustomKeys:@[@"app_launched"] andValues:@[@"-"]];
    
    DDLogInfo(@"%@", clog);
}

#pragma mark - userAgent

+ (void)userAgentAddition:(NSString *)userAgentAddition {

    if (kUserAgentAddition != nil) {
        
        [kUserAgentAddition release], kUserAgentAddition = nil;
    }
    
    kUserAgentAddition = [userAgentAddition copy];
}

+ (NSString *)userAgent {
    
    /*
    
    static NSString *userAgent;
    
    if (!userAgent) {
        
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *appName = [[bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSString *appVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        userAgent = [[NSString alloc] initWithFormat:@"%@/%@ OfficialVdiskIosSdk/%@", appName, appVersion, kVdiskSDKVersion];
    }
    
    return userAgent;
     */
    
    if (kUserAgentAddition != nil && [kUserAgentAddition length] > 0) {
        
        return [NSString stringWithFormat:@"%@ %@", [ASIHTTPRequest defaultUserAgentString], kUserAgentAddition];
        
    } else {
    
        return [ASIHTTPRequest defaultUserAgentString];
    }
}


- (NSDictionary *)requestHeadersWithAuthorization {
    
    NSDictionary *requestHeaders = nil;
    
    if (self.sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        long expires = time((time_t *)NULL) + 3600;
        NSString *expiresString = [NSString stringWithFormat:@"%ld", expires];
        
        NSString *stringToSign = [NSString stringWithFormat:@"%@%@%@", self.appKey, self.accessToken, expiresString];
        NSString *sign = [[[stringToSign HMACSHA1EncodedDataWithKey:self.appSecret] base64EncodedString] substringWithRange:NSMakeRange(5, 10)];
        
        NSDictionary *authorizationDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                          self.appKey, @"appkey",
                                          self.accessToken, @"access_token",
                                          expiresString, @"expires",
                                          sign, @"sign", nil];
        
        NSString *authorization = [authorizationDic JSONRepresentation];
        
        requestHeaders = [NSDictionary dictionaryWithObjectsAndKeys:
                          [VdiskSession userAgent], @"User-Agent",
                          [NSString stringWithFormat:@"Weibo %@", authorization], @"Authorization", nil];
        
    } else {
        
        requestHeaders = @{@"Authorization" : [NSString stringWithFormat:@"OAuth2 %@", self.accessToken],
                           @"User-Agent": [VdiskSession userAgent]};
    }
    
    return requestHeaders;
}

#pragma mark - Log

- (void)setupLogger {

    static BOOL setupLoggerStatus = NO;
    if (setupLoggerStatus) return;
    
#ifdef DEBUG
    ddLogLevel = LOG_LEVEL_VERBOSE;
#else
    ddLogLevel = LOG_LEVEL_INFO;
#endif
    
    

#ifdef DEBUG
#if DEBUG_REQUEST_LOG
    VdiskLogDebugFormatter *debugformatter = [[[VdiskLogDebugFormatter alloc] init] autorelease];
    //[[DDASLLogger sharedInstance] setLogFormatter:debugformatter];
    //[DDLog addLogger:[DDASLLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setLogFormatter:debugformatter];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
#endif
    
    VdiskLogFormatter *formatter = [[[VdiskLogFormatter alloc] init] autorelease];
    
    CompressingLogFileManager *logFileManager = [[[CompressingLogFileManager alloc] init] autorelease];
    DDFileLogger *fileLogger = [[[DDFileLogger alloc] initWithLogFileManager:logFileManager] autorelease];
    [fileLogger setLogFormatter:formatter];
    
    fileLogger.maximumFileSize  = 1024 * 1024;
    fileLogger.rollingFrequency =   60 * 60 * 3;
    fileLogger.logFileManager.maximumNumberOfLogFiles = 5;
    
    [DDLog addLogger:fileLogger];
    
    CLogReport *logReport = [[[CLogReport alloc] initWithLogsDirectory:[logFileManager logsDirectory]] autorelease];
    [CLogReport setSharedLogReport:logReport];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    
    setupLoggerStatus = YES;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {

    /* 开始上报日志 */
    
    [[CLogReport sharedLogReport] fire];
}

#pragma mark - VdiskSession Life Circle

- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret appRoot:(NSString *)appRoot {
    
    return [self initWithAppKey:appKey appSecret:appSecret appRoot:appRoot sinaWeibo:nil];
}

- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret appRoot:(NSString *)appRoot sinaWeibo:(SinaWeibo *)sinaWeibo {

    if (self = [super init]) {
        
        _globalParams = [[NSMutableDictionary alloc] init];
        
        [self setupLogger];
        
        self.appKey = appKey;
        self.appSecret = appSecret;
        self.sinaWeibo = sinaWeibo;
        
        if ([appRoot isEqualToString:kVdiskRootAppFolder] || [appRoot isEqualToString:kVdiskRootBasic]) {
            
            self.appRoot = appRoot;
            
        } else {
            
            self.appRoot = [[kVdiskRootAppFolder copy] autorelease];
        }
        
        _sessionType = kVdiskSessionTypeDefault;
        _isUserExclusive = NO;
        
        [self readAuthorizeDataFromKeychain];
    }
    
    return self;
}

- (void)dealloc {
    
    [_globalParams release], _globalParams = nil;
    
    [_appKey release], _appKey = nil;
    [_appSecret release], _appSecret = nil;
    
    [_sinaUserID release], _sinaUserID = nil;
    [_userID release], _userID = nil;
    [_accessToken release], _accessToken = nil;
    [_refreshToken release], _refreshToken = nil;
    [_appRoot release], _appRoot = nil;
    [_redirectURI release], _redirectURI = nil;
    
    [_authorize setDelegate:nil];
    [_authorize release], _authorize = nil;
    
    [_sinaWeibo release], _sinaWeibo = nil;
    
    _delegate = nil;

    [_udid release], _udid = nil;
    
    [super dealloc];
}

- (NSString *)udid {

    if (_udid == nil) {
        
        _udid = [[[NSUserDefaults standardUserDefaults] stringForKey:kGUIDKeyName] retain];
        
        if (_udid == nil) {
            
            _udid = [[NSString GUIDString] retain];
            
            [[NSUserDefaults standardUserDefaults] setObject:_udid forKey:kGUIDKeyName];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    return _udid;
}

#pragma mark - VdiskSession Private Methods


- (NSString *)urlSchemeString {
    
    return [NSString stringWithFormat:@"%@%@", kVdiskURLSchemePrefix, _appKey];
}

- (void)saveAuthorizeDataToKeychain {
    
    /*
     
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
    
        return;
    }
     
     */
    
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kVdiskKeychainServiceNameSuffix];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:_sinaUserID forKey:kVdiskKeychainSinaUserID];
    [archiver encodeObject:_userID forKey:kVdiskKeychainUserID];
    [archiver encodeObject:_accessToken forKey:kVdiskKeychainAccessToken];
    [archiver encodeObject:_refreshToken forKey:kVdiskKeychainRefreshToken];    
    [archiver encodeDouble:_expireTime forKey:kVdiskKeychainExpireTime];
    [archiver encodeInt:_sessionType forKey:kVdiskKeychainSessionType];
    [archiver finishEncoding];
    
    [VdiskKeychain setPasswordData:data forService:serviceName account:kVdiskKeychainAccountIdentity];
    
    [data release];
    [archiver release];
    
}

- (void)readAuthorizeDataFromKeychain {
    
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kVdiskKeychainServiceNameSuffix];
    
    NSData *data = [VdiskKeychain passwordDataForService:serviceName account:kVdiskKeychainAccountIdentity];
    
    if (data == nil || [data length] == 0) {
        
        return;
    }
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    @try {
        
        self.sinaUserID = [unarchiver decodeObjectForKey:kVdiskKeychainSinaUserID];
        self.userID = [unarchiver decodeObjectForKey:kVdiskKeychainUserID];
        self.accessToken = [unarchiver decodeObjectForKey:kVdiskKeychainAccessToken];
        self.refreshToken = [unarchiver decodeObjectForKey:kVdiskKeychainRefreshToken];
        self.expireTime = [unarchiver decodeDoubleForKey:kVdiskKeychainExpireTime];
        _sessionType = [unarchiver decodeIntForKey:kVdiskKeychainSessionType];
        
    } @catch (NSException *exception) {
        
        [self deleteAuthorizeDataInKeychain];
        
    } @finally {
        
        
    }
    
    [unarchiver finishDecoding];
    [unarchiver release];
    
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        _sinaWeibo.accessToken = self.accessToken;
        _sinaWeibo.expirationDate = [NSDate dateWithTimeIntervalSince1970:self.expireTime];
        _sinaWeibo.userID = self.sinaUserID;
        _sinaWeibo.refreshToken = self.refreshToken;
    }
}

- (void)deleteAuthorizeDataInKeychain {
    
    self.sinaUserID = nil;
    self.accessToken = nil;
    self.refreshToken = nil;
    self.userID = nil;
    self.expireTime = 0.0f;
    
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
    
        _sinaWeibo.accessToken = nil;
        _sinaWeibo.expirationDate = nil;
        _sinaWeibo.userID = nil;
        _sinaWeibo.refreshToken = nil;
    }
    
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kVdiskKeychainServiceNameSuffix];
        
    [VdiskKeychain deletePasswordForService:serviceName account:kVdiskKeychainAccountIdentity];
}

#pragma - mark Authorization

- (void)linkWithSessionType:(VdiskSessionType)sessionType {

    _sessionType = sessionType;
    
    [self link];
}

- (void)linkUsingWeiboAccessToken:(NSString *)accessToken userID:(NSString *)userID expireTime:(NSTimeInterval)expireTime refreshToken:(NSString *)refreshToken {

    _sessionType = kVdiskSessionTypeWeiboAccessToken;
    
    self.sinaUserID = userID;
    self.userID = @"0";
    self.accessToken = accessToken;
    self.refreshToken = refreshToken;
    self.expireTime = [[NSDate dateWithTimeIntervalSinceNow:expireTime] timeIntervalSince1970];
    
    VdiskRestClient *restClient = [[VdiskRestClient alloc] initWithSession:self];
    restClient.delegate = self;
    [restClient loadAccountInfo];
}

- (void)link {
    
    /*
    
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        if (_weiboAccessToken != nil && [_weiboAccessToken length] > 0) {
        
            if ([_delegate respondsToSelector:@selector(sessionLinkedSuccess:)]) {
                
                [_delegate sessionLinkedSuccess:self];
            }
            
        } else {
            
            if ([_delegate respondsToSelector:@selector(sessionWeiboAccessTokenIsNull:)]) {
                
                [_delegate sessionWeiboAccessTokenIsNull:self];
            }
        }
        
        return;
    }
     
     */
    
    if (_sessionType == kVdiskSessionTypeDefault) {
        
        if ([self isLinked] && ![self isExpired]) {
            
            if ([_delegate respondsToSelector:@selector(sessionAlreadyLinked:)]) {
                
                [_delegate sessionAlreadyLinked:self];
            }
            
            if (_isUserExclusive) {
                
                return;
            }
        }
        
        VdiskAuthorize *auth = [[VdiskAuthorize alloc] initWithAppKey:_appKey appSecret:_appSecret udid:self.udid];
        [auth setDelegate:self];
        self.authorize = auth;
        [auth release];
        
        if ([_redirectURI length] > 0) {
            
            [_authorize setRedirectURI:_redirectURI];
            
        } else {
            
            [_authorize setRedirectURI:@"http://"];
        }
        
        [_authorize startAuthorize];
    
    
    } else if (_sessionType == kVdiskSessionTypeWeiboAccessToken && _sinaWeibo) {
        
        [_sinaWeibo logIn];
    }
}

- (void)refreshLink {
    
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        [_sinaWeibo reLogIn];
        
        return;
    }
    
    VdiskAuthorize *auth = [[VdiskAuthorize alloc] initWithAppKey:_appKey appSecret:_appSecret udid:self.udid];
    [auth setDelegate:self];
    self.authorize = auth;
    [auth release];
    
    [_authorize startAuthorizeUsingRefreshToken:_refreshToken];
}

- (void)linkUsingUsername:(NSString *)username password:(NSString *)password {
    
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        return;
    }
    
    if ([self isLinked]) {
        
        if ([_delegate respondsToSelector:@selector(sessionAlreadyLinked:)]) {
            
            [_delegate sessionAlreadyLinked:self];
            
        } if (_isUserExclusive) {
            
            return;
        }
    }
    
    VdiskAuthorize *auth = [[VdiskAuthorize alloc] initWithAppKey:_appKey appSecret:_appSecret udid:self.udid];
    [auth setDelegate:self];
    self.authorize = auth;
    [auth release];
    
    if ([_redirectURI length] > 0) {
        
        [_authorize setRedirectURI:_redirectURI];
        
    } else {
        
        [_authorize setRedirectURI:@"http://"];
    }
    
    [_authorize startAuthorizeUsingUsername:username password:password];
}

- (void)unlink {
    
    /*
    
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        self.weiboAccessToken = nil;
        
        if ([_delegate respondsToSelector:@selector(sessionUnlinkedSuccess:)]) {
            
            [_delegate sessionUnlinkedSuccess:self];
        }
        
        return;
    }
     
     */
    
    [self deleteAuthorizeDataInKeychain];
    
    if ([_delegate respondsToSelector:@selector(sessionUnlinkedSuccess:)]) {
        
        [_delegate sessionUnlinkedSuccess:self];
    }
}

- (BOOL)isLinked {
    
    /*
    
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        if (_weiboAccessToken != nil && [_weiboAccessToken length] > 0) {
            
            return YES;
            
        } else {
            
            return NO;
        }
    }
     
     */
    
    //return _accessToken && _refreshToken && (_expireTime > 0);
    
    return _sinaUserID && _userID && _accessToken && (_expireTime > 0);
}

- (BOOL)isExpired {
    
    /*
    
    if (_sessionType == kVdiskSessionTypeWeiboAccessToken) {
        
        if (_weiboAccessToken != nil && [_weiboAccessToken length] > 0) {
            
            return NO;
            
        } else {
            
            return YES;
        }
    }

     */
     
    if ([[NSDate date] timeIntervalSince1970] > _expireTime) {
        
        
        if (!_refreshToken) {
            
            [self deleteAuthorizeDataInKeychain]; // force to log out
        }
        
        return YES;
    }
    
    return NO;
}

/*

- (void)enabledAndSetExternalWeiboAccessToken:(NSString *)weiboAccessToken {

    _weiboAccessToken = [weiboAccessToken retain];
    _sessionType = kVdiskSessionTypeWeiboAccessToken;
}

- (void)enabledExternalWeiboAccessToken {

    _sessionType = kVdiskSessionTypeWeiboAccessToken;
}

- (void)disabledExternalWeiboAccessToken {

    self.weiboAccessToken = nil;
    _sessionType = kVdiskSessionTypeDefault;
}
 
 */

#pragma mark - VdiskAuthorizeDelegate Methods

- (void)authorize:(VdiskAuthorize *)authorize didSucceedWithAccessToken:(NSString *)accessToken refreshToken:(NSString *)refreshToken userID:(NSString *)userID expiresIn:(NSInteger)seconds {
    
    self.accessToken = accessToken;
    self.refreshToken = refreshToken;
    self.sinaUserID = [NSString stringWithFormat:@"%@", userID];
    self.userID = @"0";
    self.expireTime = seconds;
    
    /*
     
    [self saveAuthorizeDataToKeychain];
    
    if ([_delegate respondsToSelector:@selector(sessionLinkedSuccess:)]) {
        
        [_delegate sessionLinkedSuccess:self];
    }
     */
    
    VdiskRestClient *restClient = [[VdiskRestClient alloc] initWithSession:self];
    restClient.delegate = self;
    [restClient loadAccountInfo];
    //[restClient performSelector:@selector(loadAccountInfo) withObject:nil afterDelay:0.01];
}

- (void)authorize:(VdiskAuthorize *)authorize didFailWithError:(NSError *)error {
    
    if ([_delegate respondsToSelector:@selector(session:didFailToLinkWithError:)]) {
        
        [_delegate session:self didFailToLinkWithError:error];
    }
}

- (void)authorizeDidCancel:(VdiskAuthorize *)authorize {

    if ([_delegate respondsToSelector:@selector(sessionLinkDidCancel:)]) {
        
        [_delegate sessionLinkDidCancel:self];
    }
}

#pragma mark - VdiskRestClientDelegate


- (void)restClient:(VdiskRestClient *)client loadedAccountInfo:(VdiskAccountInfo *)info {

    self.userID = info.userId;
    
    [self saveAuthorizeDataToKeychain];
    
    if ([_delegate respondsToSelector:@selector(sessionLinkedSuccess:)]) {
        
        [_delegate sessionLinkedSuccess:self];
    }
    
    [client autorelease];
}


- (void)restClient:(VdiskRestClient *)client loadAccountInfoFailedWithError:(NSError *)error {

    if ([_delegate respondsToSelector:@selector(session:didFailToLinkWithError:)]) {
        
        [_delegate session:self didFailToLinkWithError:error];
    }
    
    [client autorelease];
}


@end
