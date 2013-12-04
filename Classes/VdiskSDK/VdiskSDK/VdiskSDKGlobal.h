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

#import "DDLog.h"
#import "CLog.h"
#import "VdiskLogFormatter.h"
#import "VdiskLogDebugFormatter.h"
#import "CompressingLogFileManager.h"
#import "CLogReport.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "VdiskSharesCategory.h"

/*
#define kVdiskSDKErrorDomain           @"VdiskSDKErrorDomain"
#define kVdiskSDKErrorCodeKey          @"VdiskSDKErrorCodeKey"
*/

/*
#define kVdiskSDKAPIDomain             @"https://api.weipan.cn/2/"
*/

/*
typedef enum {
    
    kVdiskErrorCodeInterface            = 100,
	kVdiskErrorCodeSDK                  = 101,

} VdiskErrorCode;

typedef enum {
    
	kVdiskSDKErrorCodeParseError        = 200,
	kVdiskSDKErrorCodeRequestError      = 201,
	kVdiskSDKErrorCodeAccessError       = 202,
	kVdiskSDKErrorCodeAuthorizeError	= 203,
    
} VdiskSDKErrorCode;
 */

/*
typedef enum {
    
    kVdiskErrorCodeInterface            = 30,
	kVdiskErrorCodeSDK                  = 31,
    
} VdiskErrorCode;

typedef enum {
    
	kVdiskSDKErrorCodeParseError        = 2000,
	kVdiskSDKErrorCodeRequestError      = 2001,
	kVdiskSDKErrorCodeAccessError       = 2002,
	kVdiskSDKErrorCodeAuthorizeError	= 2003,
    
} VdiskSDKErrorCode;

 */

/*
 
 ApiName: {
 
 /recommend/list_for_user,
 /recommend/list_for_file,
 /share/list,
 /share/search,
 //以上返回值一样，都是数组，数组里面是VdiskSharesMetadata, VdiskSharesMetadata属性以"/recommend/list_for_user"的返回值为准，是Metadata的超级
 
 /category/get, //返回一个数组，数组里面的对象未定义
 /share/get  //直接返回一个VdiskSharesMetadata
 }
 
 */


#ifndef DEBUG_CURL_LOG
    #define DEBUG_CURL_LOG                      0
#endif

#ifndef DEBUG_REQUEST_LOG
    #define DEBUG_REQUEST_LOG                   0
#endif

#define kVdiskShareListRecommendListForUser     @"/recommend/list_for_user"
#define kVdiskShareListRecommendListForFile     @"/recommend/list_for_file"
#define kVdiskShareListShareList                @"/share/list"
#define kVdiskShareListShareListAll             @"/share/list_all"
#define kVdiskShareListShareSearch              @"/share/search"

#define kVdiskAuthorizeURL                      @"https://auth.sina.com.cn/oauth2/authorize"
#define kVdiskAccessTokenURL                    @"https://auth.sina.com.cn/oauth2/access_token"
#define kVdiskLogsReportURL                     @"http://content.weipan.cn/2/report/new"             //@"http://test.php.weipan.cn/2/report/new"

#define kVdiskSDKVersion                        @"1.2.1"                                            //TODO: parameterize from build system
#define kVdiskAPIHost                           @"api.weipan.cn"
//#define kVdiskAPIHost                           @"5.vdiskapi.appsina.com"                          /* [Cloud Mario] ... */
//#define kVdiskAPIContentSafeHost                @"upload-vdisk.sina.com.cn:4443"
#define kVdiskAPIContentSafeHost                @"upload-vdisk.sina.com.cn"
#define kVdiskAPIContentHost                    @"upload-vdisk.sina.com.cn"
#define kVdiskAPIVersion                        @"2"
#define kVdiskRootBasic                         @"basic"
#define kVdiskRootAppFolder                     @"sandbox"
#define kVdiskProtocolHTTPS                     @"https"
#define kVdiskProtocolHTTP                      @"http"
#define kVdiskUnknownUserId                     @"unknown"


#define kVdiskURLSchemePrefix                   @"vdisk_"
#define kVdiskKeychainServiceNameSuffix         @"_VdiskServiceName"


#define kVdiskKeychainAccountIdentity           @"VdiskKeychainAccountIdentity"

#define kVdiskKeychainSinaUserID                @"VdiskSinaUserID"
#define kVdiskKeychainUserID                    @"VdiskUserID"
#define kVdiskKeychainAccessToken               @"VdiskAccessToken"
#define kVdiskKeychainRefreshToken              @"VdiskRefreshToken"
#define kVdiskKeychainExpireTime                @"VdiskExpireTime"
#define kVdiskKeychainSessionType               @"VdiskSessionType"

#define kGUIDKeyName                            @"vdiskPushUuid"



extern int ddLogLevel;



