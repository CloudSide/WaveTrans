//
//  CLog.h
//  VDiskMobile
//
//  Created by dongni on 12-11-30.
//
//

#import <Foundation/Foundation.h>

@interface CLog : NSObject
{
    NSString  *_logVer;
    NSString  *_httpMethodAndUrl;
    NSString  *_httpResponseStatusCode;
    NSString  *_apiErroeCode;
    NSString  *_clientErrorCode;
    NSString  *_httpBytesUp;
    NSString  *_httpBytesDown;
    NSString  *_httpTimeRequest;
    NSString  *_httpTimeResponse;
    NSString  *_elapsed;
    NSString  *_customType;
    
    NSArray *_customKeys;
    NSArray *_customValues;
    
    @private
    NSTimeInterval _timePassedMs;
}

@property(nonatomic, retain) NSString  *httpMethodAndUrl;
@property(nonatomic, retain) NSString  *httpResponseStatusCode;
@property(nonatomic, retain) NSString  *apiErroeCode;
@property(nonatomic, retain) NSString  *clientErrorCode;
@property(nonatomic, retain) NSString  *httpBytesUp;
@property(nonatomic, retain) NSString  *httpBytesDown;
@property(nonatomic, retain) NSString  *httpTimeRequest;
@property(nonatomic, retain) NSString  *httpTimeResponse;
@property(nonatomic, retain) NSString  *elapsed;
@property(nonatomic, retain) NSString  *customType;

@property(nonatomic, retain) NSArray  *customKeys;
@property(nonatomic, retain) NSArray  *customValues;


+ (void)setSharedClientIp:(NSString *)ip;
- (void)setHttpMethod:(NSString *)method andUrl:(NSString *)url;
- (void)startRecordTime;
- (void)stopRecordTime;
- (void)logForHumman;
- (NSString *)clientIp;

- (void)setCustomKeys:(NSArray *)keys andValues:(NSArray *)values;

    
@end

/*
 
 用户行为日志的keys
 
 app_launched                                       √
 login_view_display                                 √ 
 vdisk_view_duration                                √
 favorites_view_duration                            √
 favorites_edit_view_display                        √
 upload_view_duration                               √
 upload_video_select_view_duration                  √
 upload_photo_select_view_duration                  √
 hot_share_view_duration                            √
 hot_share_detail_view_duration                     √
 more_view_duration                                 √
 login_weibo_button                                 √
 login_password_button                              √
 global_tab_vdisk                                   √
 global_tab_favorites                               √
 global_tab_upload                                  √
 global_tab_hot_share                               √
 global_tab_more                                    √
 vdisk_search                                       √
 vdisk_manage                                       √
 vdisk_edit_select_all                              √
 vdisk_edit_select_cancel                           √
 vdisk_edit_create_folder                           √
 vdisk_edit_rename                                  √
 vdisk_edit_delete                                  √
 favorites_edit                                     -
 favorites_edit_sort                                √
 favorites_edit_delete                              √
 favorites_edit_done                                -
 vdisk_long_press                                   √
 vdisk_long_press_delete                            √
 vdisk_long_press_share                             √
 vdisk_long_press_rename                            √
 upload_camera                                      √
 upload_photo                                       √
 upload_video                                       √
 upload_change_dir_cancel                           √
 upload_confirm                                     √
 upload_change_dir_create_folder                    √
 upload_change_dir_confirm                          √
 hot_share_search                                   √
 hot_share_recommend                                √
 hot_share_category                                 √
 hot_share_recommend_file                           √
 hot_share_file_save                                √
 hot_share_file_open                                √
 hot_share_file_open_success                        √             
 hot_share_weibo_switcher                           √
 hot_share_related_file_open                        √
 more_contact                                       √
 more_contact_backup                                √
 more_contact_restore                               √
 more_contact_backup_success                        √
 more_contact_restore_success                       √
 more_wifi_transfer                                 √
 more_wifi_transfer_success                         √
 push_notification_open                             √
 
*/