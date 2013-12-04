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

/* This file contains error codes and the Vdisk error domain */

extern NSString *kVdiskErrorDomain;

// Error codes in the vdisk.weibo.com domain represent the HTTP status code if less than 1000
typedef enum {
    
    kVdiskErrorNone                         = 0,
    kVdiskErrorGenericError                 = 1000,
    kVdiskErrorFileNotFound                 = 1001,
    kVdiskErrorInsufficientDiskSpace        = 1002,
    kVdiskErrorIllegalFileType              = 1003,         // Error sent if you try to upload a directory
    kVdiskErrorInvalidResponse              = 1004,         // Sent when the client does not get valid JSON when it's expecting it, 或者json解析成功了，但是返回内容和文档不一致，或者缺少对应的字段
    kVdiskErrorSessionError                 = 1005,
    kVdiskErrorFileContentLengthNotMatch	= 1006,         // 下载文件的大小和http响应头Content-Length不一致
    kVdiskErrorGetFileAttributesFailure     = 1007,         // 获得文件属性失败
    kVdiskErrorS3URLExpired                 = 1008,         // S3下载链接过期
    kVdiskErrorMd5NotMatched                = 1009,         // 大文件分片上传一段文件后,服务器返回的该段文件md5和本地该段文件md5不匹配
    
} kVdiskErrorCode;



typedef enum {
    
    kVdiskErrorLevelUnknown                 = 0,
    kVdiskErrorLevelNetwork                 = 10,
    kVdiskErrorLevelHTTP                    = 100,
    kVdiskErrorLevelLocal                   = 1000,
    kVdiskErrorLevelAPI                     = 10000,
    
} kVdiskErrorLevel;


kVdiskErrorLevel VdiskErrorParseErrorLevel(NSError *error);
NSUInteger VdiskErrorParseErrorCode(NSError *error);
NSString *VdiskErrorMessageWithCode(NSError *error);
