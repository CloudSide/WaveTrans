//
//  CLog.m
//  VDiskMobile
//
//  Created by dongni on 12-11-30.
//
//

#import "CLog.h"
#import "VdiskSession.h"
#import "Reachability.h"
#import "UIDevice-Hardware.h"

@implementation CLog
@synthesize httpMethodAndUrl =  _httpMethodAndUrl;
@synthesize httpResponseStatusCode = _httpResponseStatusCode;
@synthesize apiErroeCode = _apiErroeCode;
@synthesize clientErrorCode = _clientErrorCode;
@synthesize httpBytesUp = _httpBytesUp;
@synthesize httpBytesDown = _httpBytesDown;
@synthesize httpTimeRequest = _httpTimeRequest;
@synthesize httpTimeResponse = _httpTimeResponse;
@synthesize elapsed = _elapsed;
@synthesize customType = _customType;
@synthesize customKeys = _customKeys;
@synthesize customValues = _customValues;


static NSString *kSharedClientIp = nil;

- (id)init{
    
    if (self = [super init]) {
        
        _logVer = @"1";
        _timePassedMs = 0;
    }
    
    return self;
}

- (NSString *)description {
    
    NSMutableString *log = [[NSMutableString alloc] init];
    [log appendString:_logVer];
    [log appendString:@"\t"];    
    [log appendString:[VdiskSession sharedSession].appKey];
    [log appendString:@"\t"];
    [log appendFormat:@"\"%@\"", [self clientVer]];
    [log appendString:@"\t"];
    [log appendString:[self clientVerCode]];
    [log appendString:@"\t"];
    [log appendFormat:@"\"%@\"", [self osAndVer]];
    [log appendString:@"\t"];
    [log appendFormat:@"\"%@\"",[self device]];
    [log appendString:@"\t"];
    
    
    NSString *deviceUUid = [VdiskSession sharedSession].udid;
    if (nil != deviceUUid) {
        [log appendFormat:@"\"%@\"",deviceUUid];
        [log appendString:@"\t"];
    }
    else{
        [log appendString:@"-"];
        [log appendString:@"\t"];
    }
    
    [log appendString:[self netEnv]];
    [log appendString:@"\t"];
    
    if (nil != kSharedClientIp) {
        [log appendString:[NSString stringWithFormat:@"\"%@\"", kSharedClientIp]];
        [log appendString:@"\t"];
    }
    else{
        [log appendString:@"-"];
        [log appendString:@"\t"];
    }
    
    NSString *vdiskUid = [self vdiskUid];
    if (nil != vdiskUid) {
        [log appendString:vdiskUid];
        [log appendString:@"\t"];
    }
    else{
        [log appendString:@"-"];
        [log appendString:@"\t"];
    }
    
    NSString *sinaUid = [self sinaUid];
    if (nil != sinaUid) {
        [log appendString:sinaUid];
        [log appendString:@"\t"];
    }
    else{
        [log appendString:@"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _httpMethodAndUrl) {
        NSString *httpMethodAndUrl = [NSString stringWithFormat:@"\"%@\"", _httpMethodAndUrl];
        [log appendString:httpMethodAndUrl];
        [log appendString:@"\t"];
    }
    else{
        [log appendString:@"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _httpResponseStatusCode) {
        [log appendString:_httpResponseStatusCode];
        [log appendString:@"\t"];
    }
    else{
        [log appendString:@"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _apiErroeCode) {
        [log appendString:_apiErroeCode];
        [log appendString:@"\t"];
    }
    else{
        [log appendString:@"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _clientErrorCode) {
        [log appendString:_clientErrorCode];
        [log appendString:@"\t"];
    }
    else{
        [log appendString: @"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _httpBytesUp) {
        [log appendString:[NSString stringWithFormat:@"%@", _httpBytesUp]];
        [log appendString:@"\t"];
    }
    else{
        [log appendString: @"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _httpBytesDown) {
        [log appendString:[NSString stringWithFormat:@"%@",_httpBytesDown]];
        [log appendString:@"\t"];
    }
    else{
        [log appendString: @"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _httpTimeRequest) {
        [log appendString:[NSString stringWithFormat:@"%@", _httpTimeRequest]];
        [log appendString:@"\t"];
    }
    else{
        [log appendString: @"-"];
        [log appendString:@"\t"];
    }

    if (nil != _httpTimeResponse) {
        [log appendString:[NSString stringWithFormat:@"%@", _httpTimeResponse]];
        [log appendString:@"\t"];
    }
    else{
        [log appendString: @"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _elapsed) {
        [log appendFormat:@"\"%@\"",[NSString stringWithFormat:@"%@", _elapsed]];
        [log appendString:@"\t"];
    }
    else{
        [log appendString: @"-"];
        [log appendString:@"\t"];
    }
    
    if (nil != _customType) {
        [log appendString:[NSString stringWithFormat:@"%@", _customType]];
    }
    else{
        [log appendString: @"-"];        
    }
    
    
    NSInteger customKeysCount = [_customKeys count];
    NSInteger customValuesCount = [_customValues count];
    
    if (customKeysCount == customValuesCount && customKeysCount > 0) {
        
        [log appendString:@"\t"];
        
        NSMutableArray *customActionKeysAndValues = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < customKeysCount; i++) {
            
            NSString *customKey = [_customKeys objectAtIndex:i];
            NSString *customValue = [_customValues objectAtIndex:i];
            
            [customActionKeysAndValues addObject:[NSString stringWithFormat:@"\"%@\"\t\"%@\"", customKey, customValue]];
        }
        
        [log appendString:[customActionKeysAndValues componentsJoinedByString:@"\t"]];
        [customActionKeysAndValues release];
    }
    
    
    
    return [log autorelease];
}


- (NSString *)clientVer {
       
    return (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)clientVerCode {
        
    return (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)osAndVer{
    
    UIDevice *device = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"%@ %@", [device systemName], [device systemVersion]];
}

- (NSString *)device {
    
    UIDevice *device = [UIDevice currentDevice];
    return [device platformString];
}


+ (BOOL)isEnableWIFI {
    
    return [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable;
}

+ (BOOL)isEnable3G {
    
    return [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable;
}

- (NSString *)netEnv {
    
    NSString *netEnv;
    
    if ([CLog isEnableWIFI]) {
        
        netEnv = @"wifi";
    
    } else if ([CLog isEnable3G]) {
        
        netEnv = @"3g";
    
    } else {
        
        netEnv = @"no";
    }
    
    return netEnv;
}

+ (void)setSharedClientIp:(NSString *)ip {
    
    if (kSharedClientIp != nil) {
        
        [kSharedClientIp release];
    }
    
    kSharedClientIp = [ip copy];
}

- (void)setCustomKeys:(NSArray *)keys andValues:(NSArray *)values {

    self.customKeys = [[keys copy] autorelease];
    self.customValues = [[values copy] autorelease];
}

- (NSString *)clientIp {
    
    return kSharedClientIp;
}

- (NSString *)vdiskUid {
    
    return [VdiskSession sharedSession].userID;
}


- (NSString *)sinaUid {
    
    return [VdiskSession sharedSession].sinaUserID;
}

- (void)startRecordTime{
    
    NSDate *date = [NSDate date];
    _timePassedMs = [date timeIntervalSince1970];    
}

- (void)stopRecordTime{
    
    if (_timePassedMs <= 0.0f) {
        return;
    }
    double elapsed = [[NSDate date] timeIntervalSince1970] - _timePassedMs;
    self.elapsed = [NSString stringWithFormat:@"%f", elapsed * 1000];
    _timePassedMs = 0;
   
}

- (void)setHttpMethod:(NSString *)method andUrl:(NSString *)url{
    
    if (nil != method && nil != url) {
        
        self.httpMethodAndUrl = [NSString stringWithFormat:@"%@ %@", method, url];
    }
}

- (void)logForHumman {
    
    NSLog(@"logVer:%@", _logVer);
    NSLog(@"appKey:%@", [VdiskSession sharedSession].appKey);
    NSLog(@"clentVer:\"%@\"",[self clientVer]);
    NSLog(@"clientVerCode:%@",[self clientVerCode]);
    NSLog(@"os_and_ver:\"%@\"", [self osAndVer]);
    NSLog(@"device:\"%@\"", [self device]);
 
    NSString *deviceUUid = [VdiskSession sharedSession].udid;
    
    if (nil != deviceUUid) {
        
        NSLog(@"deviceUUid:\"%@\"", deviceUUid);
    
    } else{
    
        NSLog(@"deviceUUid:-");
    }
    
    NSLog(@"netEnv:%@", [self netEnv]);
    
    if (nil != kSharedClientIp) {
        
        NSLog(@"clientIp:%@", kSharedClientIp);
    
    } else{
        
        NSLog(@"clientIp:%@",@"-");
       
    }
    
    NSString *vdiskUid = [self vdiskUid];
    
    if (nil != vdiskUid) {
    
        NSLog(@"vdiskUid:%@",vdiskUid);
    
    } else {
        
       NSLog(@"vdiskUid:%@",@"-");
    }
    
    NSString *sinaUid = [self sinaUid];
    
    if (nil != sinaUid) {
    
        NSLog(@"sinaUid:%@",sinaUid);
    
    } else {
        
        NSLog(@"sinaUid:%@",@"-");
    }
    
    if (nil != _httpMethodAndUrl) {
        
        NSString *httpMethodAndUrl = [NSString stringWithFormat:@"\"%@\"", _httpMethodAndUrl];
        NSLog(@"httpMethodAndUrl:%@", httpMethodAndUrl);
    
    } else {

        NSLog(@"httpMethodAndUrl:%@", @"-");
    }
    
    if (nil != _httpResponseStatusCode) {
        
        NSLog(@"httpResponseStatusCode:%@", _httpResponseStatusCode);
    
    } else {
        
         NSLog(@"httpResponseStatusCode:%@", @"-");
    }
    
    if (nil != _apiErroeCode) {
        
        NSLog(@"apiErroeCode:%@", _apiErroeCode);
    
    } else {
        
        NSLog(@"apiErroeCode:%@", @"-");
    }
    
    if (nil != _clientErrorCode) {
        
        NSLog(@"clientErrorCode:%@", _clientErrorCode);
    
    } else {
        
        NSLog(@"clientErrorCode:%@", @"-");
    }
    
    if (nil != _httpBytesUp) {
        
        NSLog(@"httpBytesUp:%@", [NSString stringWithFormat:@"%@", _httpBytesUp]);
    
    } else {
        
         NSLog(@"httpBytesUp:%@", @"-");
    }
    
    if (nil != _httpBytesDown) {
        
        NSLog(@"httpBytesDown:%@", [NSString stringWithFormat:@"%@",_httpBytesDown]);
  
    } else {
        
        NSLog(@"httpBytesDown:%@", @"-");
    }
    
    if (nil != _httpTimeRequest) {
        
        NSLog(@"httpTimeRequest:%@", [NSString stringWithFormat:@"%@", _httpTimeRequest]);
    
    } else {
        
        NSLog(@"httpTimeRequest:%@", @"-");
    }
    
    if (nil != _httpTimeResponse) {
        
        NSLog(@"httpTimerResponse:%@", [NSString stringWithFormat:@"%@", _httpTimeResponse]);
    
    } else {
        
        NSLog(@"httpTimerResponse:%@", @"-");
    }
    
    if (nil != _elapsed) {
        
        NSLog(@"elapsed:\"%@\"",[NSString stringWithFormat:@"%@", _elapsed]);       
    
    } else {
        
        NSLog(@"elapsed:-");
    }
    
    if (nil != _customType) {
        
        NSLog(@"customType:%@",[NSString stringWithFormat:@"%@", _customType]);
   
    } else {
        
        NSLog(@"customType:%@", @"-");
    }
    
    NSInteger customKeysCount = [_customKeys count];
    NSInteger customValuesCount = [_customValues count];
    
    if (customKeysCount == customValuesCount && customKeysCount > 0) {
        
        for (int i = 0; i < customKeysCount; i++) {
            
            NSString *customKey = [_customKeys objectAtIndex:i];
            NSString *customValue = [_customValues objectAtIndex:i];
            
            NSLog(@"custom_key_%d:%@", i + 1, customKey);
            NSLog(@"custom_value_%d:%@", i + 1, customValue);
        }
    }
}

- (void)dealloc {
    
    self.httpMethodAndUrl = nil;
    self.httpResponseStatusCode = nil;
    self.apiErroeCode = nil;
    self.clientErrorCode = nil;
    self.httpBytesUp = nil;
    self.httpBytesDown = nil;
    self.httpTimeRequest = nil;
    self.httpTimeResponse = nil;
    self.elapsed = nil;
    self.customType = nil;
    self.customKeys = nil;
    self.customValues = nil;
    
    [super dealloc];
}


@end
