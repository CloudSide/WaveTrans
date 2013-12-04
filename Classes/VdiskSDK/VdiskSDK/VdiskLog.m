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

#import "VdiskLog.h"

static kVdiskLogLevel kLogLevel = kVdiskLogLevelWarning;
static VdiskLogCallback *kVdiskLogCallback = NULL;

NSString *VdiskStringFromLogLevel(kVdiskLogLevel logLevel) {
    
	switch (logLevel) {
	
        case kVdiskLogLevelInfo: return @"INFO";
		case kVdiskLogLevelAnalytics: return @"ANALYTICS";
		case kVdiskLogLevelWarning: return @"WARNING";
		case kVdiskLogLevelError: return @"ERROR";
		case kVdiskLogLevelFatal: return @"FATAL";
	}
    
	return @"";	
}

NSString *VdiskLogFilePath() {
    
	static NSString *logFilePath;
	
    if (logFilePath == nil)
		logFilePath = [[NSHomeDirectory() stringByAppendingFormat: @"/tmp/run.log"] retain];
	
    return logFilePath;
}

void VdiskSetupLogToFile() {
    
	freopen([VdiskLogFilePath() fileSystemRepresentation], "a", stderr);
}

static NSString *VdiskLogFormatPrefix(kVdiskLogLevel logLevel) {
    
	return [NSString stringWithFormat: @"[%@] ", VdiskStringFromLogLevel(logLevel)];
}

void VdiskLogSetLevel(kVdiskLogLevel logLevel) {
    
	kLogLevel = logLevel;
}

void VdiskLogSetCallback(VdiskLogCallback *aCallback) {
	
    kVdiskLogCallback = aCallback;
}

static void VdiskLogv(kVdiskLogLevel logLevel, NSString *format, va_list args) {
    
	if (logLevel >= kLogLevel) {
        
		format = [VdiskLogFormatPrefix(logLevel) stringByAppendingString:format];
		
        NSLogv(format, args);
        
        if (kVdiskLogCallback)
			kVdiskLogCallback(logLevel, format, args);
	}
}

void VdiskLog(kVdiskLogLevel logLevel, NSString *format, ...) {
    
	va_list argptr;
	va_start(argptr,format);
	VdiskLogv(logLevel, format, argptr);
	va_end(argptr);
}

void VdiskLogInfo(NSString *format, ...) {
    
	va_list argptr;
	va_start(argptr,format);
	VdiskLogv(kVdiskLogLevelInfo, format, argptr);
	va_end(argptr);
}

void VdiskLogWarning(NSString *format, ...) {
    
	va_list argptr;
	va_start(argptr,format);
	VdiskLogv(kVdiskLogLevelWarning, format, argptr);
	va_end(argptr);
}

void VdiskLogError(NSString *format, ...) {
    
	va_list argptr;
	va_start(argptr,format);
	VdiskLogv(kVdiskLogLevelError, format, argptr);
	va_end(argptr);
}

void VdiskLogFatal(NSString *format, ...) {
    
	va_list argptr;
	va_start(argptr,format);
	VdiskLogv(kVdiskLogLevelFatal, format, argptr);
	va_end(argptr);
}

