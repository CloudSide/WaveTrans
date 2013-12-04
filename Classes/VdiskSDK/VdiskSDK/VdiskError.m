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

#import "VdiskError.h"

NSString *kVdiskErrorDomain = @"VdiskSDKErrorDomain";


kVdiskErrorLevel VdiskErrorParseErrorLevel(NSError *error) {

    NSInteger errorCode = VdiskErrorParseErrorCode(error);
    
    if ((errorCode >= 1000 && errorCode < 10000) || errorCode == 0) {
        
        return kVdiskErrorLevelLocal;
        
    } else if (errorCode >= 10000) {
        
        return kVdiskErrorLevelAPI;
        
    } else if (errorCode >= 100 && errorCode <= 600) {
        
        return kVdiskErrorLevelHTTP;
        
    } else if (errorCode < 100 && errorCode > 0) {
    
        return kVdiskErrorLevelNetwork;
        
    } else {
    
        return kVdiskErrorLevelUnknown;
    }
}


NSUInteger VdiskErrorParseErrorCode(NSError *error) {
    
    if (error) {
        
        if (error.code >= 100 && error.code <= 600) { //API ERROR
            
            NSString *errornoStr = [error.userInfo objectForKey:@"error_code"];
            
            if (errornoStr && [errornoStr integerValue] >= 10000) {
                
                return [errornoStr integerValue];
            }
            
            NSString *errorStr = [error.userInfo objectForKey:@"error"];
            
            if (!errorStr) errorStr = [error description];
            
            if (errorStr) {
                
                if ([errorStr rangeOfString:@": "].location != NSNotFound) {
                    
                    errorStr = [errorStr substringWithRange:NSMakeRange(0, [errorStr rangeOfString:@": "].location)];
                    
                    if (errorStr && [errorStr isKindOfClass:[NSString class]]) {
                        
                        return [errorStr integerValue];
                    }
                }
            }
        }
        
        return error.code;
    }
    
    return 0;
}


NSString *VdiskErrorMessageWithCode(NSError *error) {

    NSInteger errorCode = VdiskErrorParseErrorCode(error);
    
    NSString *message = nil;
    
    switch (errorCode) {
            
        case 1:
            message = @"网络连接失败, 请重试";
            break;
        case 2:
            message = @"请求超时, 请重试";
            break;
        case 3:
            message = @"认证失败, 正在重新登录";
            break;
        case 4:
            message = @"网络请求已经取消";
            break;
        case 5:
            message = @"请求失败(5)";
            break;
        case 6:
            message = @"网络连接失败(6)";
            break;
        case 7:
            message = @"网络连接失败(7)";
            break;
        case 8:
            message = @"下载失败(8)";
            break;
        case 9:
            message = @"网络错误(9)";
            break;
        case 10:
            message = @"网络错误(10)";
            break;
        case 11:
            message = @"网络错误(11)";
            break;
            
        case 1000:
            message = @"错误(1000)";
            break;
        case 1001:
            message = @"文件不存在.";
            break;
        case 1002:
            message = @"设备存储空间不足.";
            break;
        case 1003:
            message = @"上传的不是文件.";
            break;
        case 1004:
            message = @"服务器错误(1004)";
            break;
        case 1005:
            message = @"登录超时, 正在重新登陆.";
            break;
        case 1006:
            message = @"文件下载不完整(1006)";
            break;
        case 1007:
            message = @"文件不存在(1007)";
            break;
        case 1008:
            message = @"下载链接已失效(1008)";
            break;
            
        case 10009:
            message = @"任务过多, 系统繁忙";
            break;
        case 10010:
            message = @"任务超时";
            break;
        case 10012:
            message = @"非法请求";
            break;
        case 10013:
            message = @"不合法的微博用户";
            break;
        case 10018:
            message = @"请求长度超过限制";
            break;
        case 10022:
            message = @"IP请求频次超过上限";
            break;
        case 10023:
            message = @"用户请求频次超过上限";
            break;
        case 10024:
            message = @"用户请求频次超过上限";
            break;
        case 20003:
            message = @"用户不存在";
            break;
        case 20006:
            message = @"图片太大";
            break;
        case 20008:
            message = @"内容为空";
            break;
        case 20016:
            message = @"发布内容过于频繁";
            break;
        case 20017:
            message = @"提交相似的信息";
            break;
        case 20018:
            message = @"包含非法网址";
            break;
        case 20019:
            message = @"提交相同的信息";
            break;
        case 20020:
            message = @"包含广告信息";
            break;
        case 20021:
            message = @"包含非法内容";
            break;
        case 20031:
            message = @"需要验证码";
            break;
        case 20034:
            message = @"帐号处于锁定状态";
            break;
        case 20035:
            message = @"帐号未实名认证";
            break;
        case 20109:
            message = @"微博id为空";
            break;
        case 20111:
            message = @"不能发布相同的微博";
            break;
        case 20301:
            message = @"不能给不是你粉丝的人发私信";
            break;
        case 20302:
            message = @"不合法的私信";
            break;
        case 20306:
            message = @"不能发布相同的私信";
            break;
        case 20308:
            message = @"发私信太多";
            break;
        case 20311:
            message = @"很抱歉, 根据相关法规和政策, 你暂时无法发送任何内容的私信.";
            break;
        case 20403:
            message = @"屏蔽用户列表中存在此用户";
            break;
        case 20405:
            message = @"此用户不是您的好友";
            break;
        case 20407:
            message = @"没有合适的uid";
            break;
        case 20504:
            message = @"你不能关注自己";
            break;
        case 20505:
            message = @"加关注请求超过上限";
            break;
        case 20506:
            message = @"已经关注此用户";
            break;
        case 20507:
            message = @"需要输入验证码";
            break;
        case 20508:
            message = @"根据对方的设置, 你不能进行此操作";
            break;
        case 20509:
            message = @"悄悄关注个数到达上限";
            break;
        case 20510:
            message = @"不是悄悄关注人";
            break;
        case 20511:
            message = @"已经悄悄关注此用户";
            break;
        case 20512:
            message = @"你已经把此用户加入黑名单, 加关注前请先解除";
            break;
        case 20513:
            message = @"你的关注人数已达上限";
            break;
        case 20521:
            message = @"hi超人, 你今天已经关注很多喽";
            break;
        case 20522:
            message = @"还未关注此用户";
            break;
        case 20523:
            message = @"还不是粉丝";
            break;
        case 20524:
            message = @"hi超人, 你今天已经关注很多喽";
            break;
        case 22305:
            message = @"已是关注用户, 不能发送关注邀请";
            break;
         
    
        case 21327:
            message = @"登录超时, 请重新登录";
            break;
        case 21322:
            message = @"重定向地址不匹配(21322)";
            break;
        case 21323:
            message = @"请求不合法(21323)";
            break;
        case 21325:
            message = @"您的授权过期或已撤销, 请重新登录(21325)";
            break;
        case 21331:
            message = @"服务暂时无法访问，请稍后再试(21331)";
            break;
        case 21332:
            message = @"登录超时, 请重新登录(21332)";
            break;
        case 21334:
            message = @"帐号异常, 请先解除异常(21334)";
            break;
        case 21324:
            message = @"client_id或client_secret参数无效(21324)";
            break;
        case 21326:
            message = @"客户端没有权限(21326)";
            break;
        case 21328:
            message = @"不支持的 GrantType(21328)";
            break;
        case 21329:
            message = @"不支持的 ResponseType(21329)";
            break;
        case 21330:
            message = @"用户或授权服务器拒绝授予数据访问权限(21330)";
            break;
            
            
        case 40001:
            message = @"操作无效(40001)";
            break;
        case 40002:
            message = @"路径错误, 不能包含特殊字符, 或者路径过长.";
            break;
        case 40003:
            message = @"目标路径不存在.";
            break;
        case 40101:
            message = @"认证失败, 正在重新登录(40101)";
            break;
        case 40102:
            message = @"认证失败, 正在重新登录(40102)";
            break;
        case 40103:
            message = @"认证失败, 正在重新登录(40103)";
            break;
        case 40301:
            message = @"禁止访问. 没有足够的访问权限.";
            break;
        case 40302:
            message = @"在指定的路径下已有目录或文件.";
            break;
        case 40303:
            message = @"操作无效(40303).";
            break;
        case 40304:
            message = @"由于政策限制, 该文件(夹)不允许分享.";
            break;
        case 40305:
            message = @"不允许操作此文件";
            break;
        case 40306:
            message = @"此操作不可重复, 禁止操作.";
            break;
        case 40307:
            message = @"事件ID已过期, 禁止操作.";
            break;
        case 40308:
            message = @"操作过于频繁, 请稍后再试";
            break;
        case 40309:
            message = @"上传合并失败.";
            break;
        case 40310:
            message = @"上传MD5检测失败.";
            break;
        case 40311:
            message = @"Forbidden. Your IP is not permitted to access(40311).";
            break;
        case 40312:
            message = @"文件或目录没有被分享.";
            break;
        case 40313:
            message = @"分享操作涉及到文件或目录过多.";
            break;
        case 40315:
            message = @"目标文件夹已存在.";
            break;
        case 40317:
            message = @"帐号异常, 您可能没有开通微博或者帐号被屏蔽.";
            break;
        case 40401:
            message = @"用户不存在.";
            break;
        case 40402:
            message = @"上级目录不存在.";
            break;
        case 40403:
            message = @"指定目录中找不到该文件或文件夹.";
            break;
        case 40404:
            message = @"版本信息不存在.";
            break;
        case 40405:
            message = @"无法找到相关文件(40405).";
            break;
        case 40406:
            message = @"无法找到相关文件(40406).";
            break;
        case 40407:
            message = @"没有可用的文件流.";
            break;
        case 40410:
            message = @"分类不存在.";
            break;
        case 40411:
            message = @"没有可用的在线阅读文件.";
            break;
        case 40412:
            message = @"没有此页.";
            break;
        case 40601:
            message = @"该目录中目录数已达上限.";
            break;
        case 40602:
            message = @"该目录文件数已达上限.";
            break;
        case 40603:
            message = @"选中的文件或文件夹过多, 操作失败.";
            break;
        case 40604:
            message = @"本操作仅针对单个文件.";
            break;
        case 40605:
            message = @"本操作仅针对单个目录.";
            break;
        case 40606:
            message = @"该目录中成员数已达上限.";
            break;
        case 40607:
            message = @"该目录文件数已达上限.";
            break;
        case 40608:
            message = @"文件过大, 无法上传.";
            break;
        case 40609:
            message = @"该文件不支持所选的输出格式.";
            break;
        case 40610:
            message = @"只有分享的目录可以列出.";
            break;
        case 40611:
            message = @"指定的资源没有内容.";
            break;
        case 40612:
            message = @"操作过于频繁, 请稍后再试(40612)";
            break;
        case 40613:
            message = @"没有足够的访问权限.";
            break;
        case 40614:
            message = @"无操作记录.";
            break;
        case 40615:
            message = @"输入格式不支持此操作.";
            break;
        case 40616:
            message = @"版本信息已过期.";
            break;
        case 40617:
            message = @"文件或目录已分享.";
            break;
        case 40618:
            message = @"文件或目录总体积已达上限.";
            break;
        case 40619:
            message = @"文件或目录未分享.";
            break;
        case 40622:
            message = @"分享的文件或目录被屏蔽.";
            break;
        case 41001:
            message = @"文件上传失败.";
            break;
        case 41501:
            message = @"文件过大, 无法显示缩略图.";
            break;
        case 50001:
            message = @"系统错误(50001)";
            break;
        case 50002:
            message = @"文件上传失败.";
            break;
        case 50003:
            message = @"文件未保存.";
            break;
        case 50004:
            message = @"文件上传中断.";
            break;
        case 50401:
            message = @"请求API验证接口失败.";
            break;
        case 50402:
            message = @"请求API回调接口失败.";
            break;
        case 50403:
            message = @"系统错误(50403)";
            break;
        case 50701:
            message = @"空间已满(50701)";
            break;
            
            
        default:
        {
        
            if ([error localizedDescription] && [[error localizedDescription] length] > 0) {
                
                message = [NSString stringWithFormat:@"未知错误:%@(%d)", [error localizedDescription], errorCode];
                
            } else {
            
                message = [NSString stringWithFormat:@"未知错误(%d)", errorCode];
            }
        }
            
            break;
    }
    
    return message;
}
