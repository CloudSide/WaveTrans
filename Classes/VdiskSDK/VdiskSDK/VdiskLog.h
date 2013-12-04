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

#import <Foundation/Foundation.h>

#if !defined(NS_FORMAT_FUNCTION)
#define NS_FORMAT_FUNCTION(F, A)
#endif

typedef enum {
    
	kVdiskLogLevelInfo = 0,
	kVdiskLogLevelAnalytics,
	kVdiskLogLevelWarning,
	kVdiskLogLevelError,
	kVdiskLogLevelFatal

} kVdiskLogLevel;

typedef void VdiskLogCallback(kVdiskLogLevel logLevel, NSString *format, va_list args);

NSString *VdiskLogFilePath(void);
void VdiskSetupLogToFile(void);

NSString *VdiskStringFromLogLevel(kVdiskLogLevel logLevel);


void VdiskLogSetLevel(kVdiskLogLevel logLevel);
void VdiskLogSetCallback(VdiskLogCallback *callback);

void VdiskLog(kVdiskLogLevel logLevel, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
void VdiskLogInfo(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
void VdiskLogWarning(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
void VdiskLogError(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
void VdiskLogFatal(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);