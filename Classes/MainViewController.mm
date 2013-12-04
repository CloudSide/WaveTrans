//
//  MainViewController.m
//  WaveTrans
//
//  Created by hanchao on 13-11-26.
//
//

#import "MainViewController.h"
#import "MainTableViewCell.h"
#import "TableViewCellFactory.h"
#import "MSCMoreOptionTableViewCell.h"
#import "WaveTransMetadata.h"
#import "PCMRender.h"
#import "AppDelegate.h"
#import "WaveTransMetadata.h"
#import "VdiskJSON.h"
#import "ASIFormDataRequest.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "WaveTransModel.h"
#import "TextEditorViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/message.h>
#import "WaveTransModel.h"
#import "CAXException.h"
#import "PhotoCell.h"
#import "TextViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#import "ChoosePeopleViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>


@interface UIActionSheet (userinfo)

@property (nonatomic, retain) NSDictionary *userinfo;

@end

@implementation UIActionSheet (userinfo)

static char actionSheetUserinfoKey;

- (NSDictionary *)userinfo {

    return objc_getAssociatedObject(self, &actionSheetUserinfoKey);
}

- (void)setUserinfo:(NSDictionary *)userinfo {

    objc_setAssociatedObject(self, &actionSheetUserinfoKey, userinfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end



#pragma mark -


@interface UIAlertView (userinfo)

@property (nonatomic, retain) NSDictionary *userinfo;

@end

@implementation UIAlertView (userinfo)

static char alertViewUserinfoKey;

- (NSDictionary *)userinfo {
    
    return objc_getAssociatedObject(self, &alertViewUserinfoKey);
}

- (void)setUserinfo:(NSDictionary *)userinfo {
    
    objc_setAssociatedObject(self, &alertViewUserinfoKey, userinfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end



#pragma mark -



@interface MainViewController ()<UITableViewDataSource, UITableViewDelegate, MSCMoreOptionTableViewCellDelegate, UIActionSheetDelegate, ASIHTTPRequestDelegate, ASIProgressDelegate, AVAudioPlayerDelegate, GetWaveTransMetadataDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MBProgressHUDDelegate, PostWaveTransMetadataDelegate, UIDocumentInteractionControllerDelegate,ABPeoplePickerNavigationControllerDelegate, VdiskSessionDelegate, SinaWeiboDelegate, VdiskRestClientDelegate>

@property (nonatomic, retain) UITableView *mTableView;
@property (nonatomic, retain) NSMutableArray *metadataList;
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;

@property (nonatomic, retain) MBProgressHUD *hud;

@property (nonatomic,retain) AVAudioPlayer *successPlayer;
@property (nonatomic,retain) AVAudioPlayer *errorPlayer;

@property (nonatomic,retain) ABPeoplePickerNavigationController *peoplePicker;

@property (nonatomic,retain) VdiskRestClient *restClient;

@end

@implementation MainViewController

@synthesize audioPlayer = _audioPlayer;
@synthesize hud = _hud;


- (void)loadMyWeibo {
    
    [self.restClient cancelAllRequests];
    self.restClient = [[[VdiskRestClient alloc] initWithSession:[VdiskSession sharedSession]] autorelease];
    self.restClient.delegate = self;
    
    [_restClient callWeiboAPI:@"/users/show" params:[NSDictionary dictionaryWithObjectsAndKeys:[VdiskSession sharedSession].sinaUserID, @"uid", nil] method:@"GET" responseType:[NSDictionary class]];
}

- (void)playSuccessSound {
    
    if (self.successPlayer == nil) {
        
        NSError *error = nil;
        self.successPlayer = [[[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"success_1" withExtension:@"wav"] error:&error] autorelease];
        
        [self.successPlayer setVolume:1.0];
        
        if (error) {
            
            NSLog(@"successPlayer init error....%@",[error localizedDescription]);
            
        } else {
            
            self.successPlayer.delegate = self;
            
            
            if ([self isAirPlayActive]) {
                
                UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
                AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride), &audioRouteOverride);
                
            } else {
                
                UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
                AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride), &audioRouteOverride);
            }
            
            [self.successPlayer prepareToPlay];
        }
    }
    
    [self.successPlayer play];
}

- (void)playErrorSound {
    
    /*
    return;
    
    if (self.errorPlayer == nil) {
        
        NSError *error = nil;
        self.errorPlayer = [[[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"error" withExtension:@"wav"] error:&error] autorelease];
        
        [self.errorPlayer setVolume:1.0];
        
        if (error) {
            
            NSLog(@"errorPlayer init error....%@",[error localizedDescription]);
            
        } else {
            
            self.errorPlayer.delegate = self;
            
            UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
            AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride), &audioRouteOverride);
            
            [self.errorPlayer prepareToPlay];
        }
        
    }
    
    [self.errorPlayer play];
     */
}


- (NSString *)fileTmpPath:(NSString *)fileName {
    
    NSString *filePath  = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"cache/files/%@", fileName]];
    
    return filePath;
}

- (void)dealloc {
    
    [_restClient cancelAllRequests];
    [_restClient release], _restClient = nil;
    
    [_audioPlayer release];
    
    [[ASIHTTPRequest sharedQueue] cancelAllOperations];
    
    _hud.delegate = nil;
    [_hud release];
    
    [self.successPlayer stop];
    self.successPlayer = nil;
    
    [self.errorPlayer stop];
    self.errorPlayer = nil;
    
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        [[AppDelegate sharedAppDelegate] setGetWaveTransMetadataDelegate:self];
        
        
        SinaWeibo *sinaWeibo = [[SinaWeibo alloc] initWithAppKey:kWeiboAppKey appSecret:kWeiboAppSecret appRedirectURI:kWeiboAppRedirectURI andDelegate:self];
        VdiskSession *session = [[VdiskSession alloc] initWithAppKey:kVdiskAppKey appSecret:kVdiskAppSecret appRoot:@"basic" sinaWeibo:[sinaWeibo autorelease]];
        session.delegate = self;
        [session setRedirectURI:kVdiskAppRedirectURI];
        [VdiskSession setSharedSession:[session autorelease]];
        
    }
    
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.metadataList = [WaveTransModel metadataList];
    
//    if (self.metadataList.count ==0) {
//        
//        for (int i = 0; i<10; i++) {
//            WaveTransMetadata *wt = [[WaveTransMetadata alloc] initWithSha1:[NSString stringWithFormat:@"356a192b7913b04c54574d18c28d46e6395428a%d",i]
//                                                                       type:@"file"
//                                                                    content:@"http://sdfsdf"
//                                                                       size:1212
//                                                                   filename:@"av.mp3"];
//            [wt save];
//            [wt release];
//        }
//        self.metadataList = [WaveTransModel metadataList];
//    }
    
    
    [self.view addSubview:[AppDelegate sharedAppDelegate].view];
    
    self.mTableView = [[[UITableView alloc] initWithFrame:CGRectMake(0.0f, [AppDelegate sharedAppDelegate].view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - [AppDelegate sharedAppDelegate].view.frame.size.height)] autorelease];
    self.mTableView.delegate = self;
    self.mTableView.dataSource = self;
    [self.mTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    [self.view addSubview:self.mTableView];
    
    
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addButton setImage:[UIImage imageNamed:@"sent_btn"] forState:UIControlStateNormal];
    [addButton setShowsTouchWhenHighlighted:YES];
    [addButton setExclusiveTouch:YES];
    //addButton.backgroundColor = [UIColor redColor];
    [addButton setFrame:CGRectMake(320-50, 20.0, 50, 40)];
    addButton.titleLabel.text = @"添加";
    [addButton addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addButton];
    
    
    UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //[settingButton setImage:[UIImage imageNamed:@"sent_btn"] forState:UIControlStateNormal];
    [settingButton setShowsTouchWhenHighlighted:YES];
    [settingButton setExclusiveTouch:YES];
    //addButton.backgroundColor = [UIColor redColor];
    [settingButton setFrame:CGRectMake(320-80, 18.0, 40, 40)];
    [settingButton setTitle:@"设置" forState:UIControlStateNormal];
    [settingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [settingButton addTarget:self action:@selector(settingAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:settingButton];
    
    
    
    [self.mTableView setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1.]];
    
#ifdef __IPHONE_7_0
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
}

- (void)settingAction {

    
    UIActionSheet *chooseImageSheet;
    
    if ([PCMRender isHighFreq]) {
        
        chooseImageSheet = [[UIActionSheet alloc] initWithTitle:@"设置"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"√ 切换为高频模式", @"  切换为低频模式", @"  绑定/切换微博账号", nil];
    
    } else {
    
        chooseImageSheet = [[UIActionSheet alloc] initWithTitle:@"设置"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"  切换为高频模式", @"√ 切换为低频模式", @"  绑定/切换微博账号", nil];
    }
    
    
    chooseImageSheet.userinfo = @{@"type" : @"switchFreq"};
    
    [chooseImageSheet showInView:self.view];
    
    [chooseImageSheet release];
}

- (void)openAlbum {
    
    UIActionSheet *chooseImageSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"取消"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:@"拍照",@"相册", @"文本", @"联系人", @"微博名片", nil];
    chooseImageSheet.userinfo = @{@"type" : @"addFile"};
    
    [chooseImageSheet showInView:self.view];
    
    [chooseImageSheet release];
    
}

- (BOOL)isAirPlayActive{
    CFDictionaryRef currentRouteDescriptionDictionary = nil;
    UInt32 dataSize = sizeof(currentRouteDescriptionDictionary);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRouteDescription, &dataSize, &currentRouteDescriptionDictionary);
    if (currentRouteDescriptionDictionary) {
        CFArrayRef outputs = (CFArrayRef)CFDictionaryGetValue(currentRouteDescriptionDictionary, kAudioSession_AudioRouteKey_Outputs);
        if(CFArrayGetCount(outputs) > 0) {
            CFDictionaryRef currentOutput = (CFDictionaryRef)CFArrayGetValueAtIndex(outputs, 0);
            CFStringRef outputType = (CFStringRef)CFDictionaryGetValue(currentOutput, kAudioSession_AudioRouteKey_Type);
            return (CFStringCompare(outputType, kAudioSessionOutputRoute_AirPlay, 0) == kCFCompareEqualTo);
        }
    }
    
    return NO;
}

- (void)playWithMetadata:(WaveTransMetadata *)metadata
{
    [[AppDelegate sharedAppDelegate] setListenning:NO];
    
    if (metadata == nil || metadata.sha1 == nil) {
        
        //TODO:数据错误，发声失败
        
        return;
    }
    
    // 测试直接用[WaveTransMetadata codeWithSha1:metadata.sha1]获取code发声
    NSData *pcmData = [PCMRender renderChirpData:metadata.rsCode];
    
    NSLog(@"%@", metadata.rsCode);
    
    NSError *error = nil;
    
    
    self.audioPlayer = [[[AVAudioPlayer alloc] initWithData:pcmData error:&error] autorelease];
    [self.audioPlayer setVolume:1.0];
    
    if (error) {
       
        NSLog(@"error....%@",[error localizedDescription]);
    
    } else {
        
        self.audioPlayer.delegate = self;
        
        //UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
        //AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
        
        if ([self isAirPlayActive]) {
            
            UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None; //kAudioSessionProperty_OverrideCategoryDefaultToSpeaker
            AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride), &audioRouteOverride);
        
        } else {
         
            UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker; //kAudioSessionProperty_OverrideCategoryDefaultToSpeaker
            AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride), &audioRouteOverride);
        }
        
        
        [self.audioPlayer prepareToPlay];
    }
    
    [self.audioPlayer play];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //[UIApplication sharedApplication].statusBarHidden = NO;
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    /*
    self.hud = [[[MBProgressHUD alloc] initWithView:[[AppDelegate sharedAppDelegate] window]] autorelease];
    [picker.view addSubview:_hud];
    _hud.dimBackground = YES;
    _hud.delegate = self;
    _hud.labelText = @"正在处理...";
    [_hud setHidden:NO];
    [_hud show:YES];
     */
    
    if ([mediaType isEqualToString:@"public.image"] && ![info valueForKey:UIImagePickerControllerReferenceURL]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            UIImage *capturedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
            
            NSData *imgData = UIImageJPEGRepresentation(capturedImage, 0.5);
            
            NSString *fileName = [NSString stringWithFormat:@"%lu.jpg", (long)[[NSDate date] timeIntervalSince1970]];
            
            NSString *sha1 = [imgData SHA1EncodedString];
            
            WaveTransMetadata *metadata = [[[WaveTransMetadata alloc] initWithSha1:sha1 type:@"file" content:nil size:[imgData length] filename:fileName] autorelease];
            metadata.uploaded = NO;
            
            if ([imgData writeToFile:[metadata cachePath:YES] atomically:YES]) {
                
                [metadata save];
                [self uploadRequestWithMetadata:metadata];
            }
            
            /*
            if (_hud != nil) {
                
                [_hud show:NO];
                [_hud setHidden:YES];
            }
             */
        });
        
    } else if ([mediaType isEqualToString:@"public.image"] && [info valueForKey:UIImagePickerControllerReferenceURL]) {
        
        ALAssetsLibrary *assetLibrary=[[[ALAssetsLibrary alloc] init] autorelease];
        
        [assetLibrary assetForURL:(NSURL *)[info valueForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
            
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            
            NSString *tmpMediaFile = [self fileTmpPath:[NSString stringWithFormat:@"%@.tmp", rep.filename]];
            
            
            [fileManager removeItemAtPath:tmpMediaFile error:nil];
            
            if (![fileManager createDirectoryAtPath:[tmpMediaFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil]) {
                
                //TODO:提示错误
                
                [picker dismissViewControllerAnimated:YES completion:^{
                    
                    
                }];
                
                return;
            }
            
            
            NSMutableData *emptyData = [[NSMutableData alloc] initWithLength:0];
            [fileManager createFileAtPath:tmpMediaFile contents:emptyData attributes:nil];
            [emptyData release];
            
            NSFileHandle *theFileHandle = [NSFileHandle fileHandleForWritingAtPath:tmpMediaFile];
            
            unsigned long long offset = 0;
            unsigned long long length;
            
            long long theItemSize = [[asset defaultRepresentation] size];
            
            long long bufferLength = 16384;
            
            if (theItemSize > 262144) {
                
                bufferLength = 262144;
                
            } else if (theItemSize > 65536) {
                
                bufferLength = 65536;
            }
            
            NSError *err = nil;
            uint8_t *buffer = (uint8_t *)malloc(bufferLength);
            
            while ((length = [[asset defaultRepresentation] getBytes:buffer fromOffset:offset length:bufferLength error:&err]) > 0 && err == nil) {
                
                NSData *data = [[NSData alloc] initWithBytes:buffer length:length];
                [theFileHandle writeData:data];
                [data release];
                offset += length;
            }
            
            free(buffer);
            [theFileHandle closeFile];
            
            [self prepareToUploadWithTmpPath:tmpMediaFile fileName:rep.filename fileManager:fileManager];
            
        } failureBlock:^(NSError *err) {
            
            
            //TODO:提示错误
            
            NSLog(@"Error: %@",[err localizedDescription]);
            
        }];
        
    } else if ([mediaType isEqualToString:@"public.movie"]) {
        
        //TODO:拷贝视频
        
        NSURL *url = [info valueForKey:UIImagePickerControllerMediaURL];
        
        NSString *movieName = [url lastPathComponent];
        NSString *tmpMediaFile = [self fileTmpPath:[NSString stringWithFormat:@"%@.tmp", movieName]];
        
        if (![fileManager createDirectoryAtPath:[tmpMediaFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil]) {
            
            //TODO:提示错误 V
            /*
            if (_hud != nil) {
                
                [_hud show:NO];
                [_hud setHidden:YES];
            }
             */
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频路径创建失败"
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil,nil];
            [alertView show];
            [alertView release];
            
            
            [picker dismissViewControllerAnimated:YES completion:^{
                
                
            }];
            
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            NSError *err;
            
            if ([fileManager moveItemAtURL:url toURL:[NSURL fileURLWithPath:tmpMediaFile] error:&err]) {
                
                [self prepareToUploadWithTmpPath:tmpMediaFile fileName:movieName fileManager:fileManager];
                
            } else {
                
                // TODO:错误提示 V
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频拷贝失败"
                                                                    message:nil
                                                                   delegate:self
                                                          cancelButtonTitle:@"确定"
                                                          otherButtonTitles:nil,nil];
                [alertView show];
                [alertView release];
                
                NSLog(@"error: %@", err);
            }
            
            /*
            if (_hud != nil) {
                
                [_hud show:NO];
                [_hud setHidden:YES];
            }
             */
        });
    }
    
    /*
    if (_hud != nil) {
        
        [_hud show:NO];
        [_hud setHidden:YES];
    }
     */
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        
    }];
}

- (void)prepareToUploadWithTmpPath:(NSString *)tmpMediaFile fileName:(NSString *)fileName fileManager:(NSFileManager *)fileManager {
    
    NSString *sha1 = [VdiskUtil fileSHA1HashCreateWithPath:(CFStringRef)tmpMediaFile ChunkSize:FileHashDefaultChunkSizeForReadingData];
    
    unsigned long long fileSize = [[fileManager attributesOfItemAtPath:tmpMediaFile error:nil] fileSize];
    
    
    WaveTransMetadata *metadata = [[[WaveTransMetadata alloc] initWithSha1:sha1 type:@"file" content:nil size:fileSize filename:fileName] autorelease];
    metadata.uploaded = NO;
    
    NSString *cachePath = [metadata cachePath:YES];
    NSLog(@"%@", cachePath);
    
    NSError *error;
    
    BOOL isDir;
    
    if (([fileManager fileExistsAtPath:cachePath isDirectory:&isDir] && !isDir) || [fileManager moveItemAtPath:tmpMediaFile toPath:cachePath error:&error]) {
        
        WaveTransMetadata *meta = [WaveTransModel metadata:metadata];
        
        if (meta != nil && !meta.uploaded) {
            
            [self uploadRequestWithMetadata:meta];
            
        } else if (meta == nil) {
            
            [metadata save];
            [self uploadRequestWithMetadata:metadata];
            
        } else {
            
            [metadata save];
        }
    } else {
        
        // TODO:错误提示
        NSLog(@"move file error: %@", error);
    }
}

#pragma mark - AVAudioPlayerDelegate <NSObject>

/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [[AppDelegate sharedAppDelegate] setListenning:YES];
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    [[AppDelegate sharedAppDelegate] setListenning:YES];
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    [[AppDelegate sharedAppDelegate] setListenning:YES];
}

/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    [[AppDelegate sharedAppDelegate] setListenning:YES];
}

#pragma mark - GetWaveTransMetadataDelegate <NSObject>

- (void)getWaveTransMetadata:(WaveTransMetadata *)metadata {
    
    WaveTransMetadata *md = [WaveTransModel metadataWithCode:metadata.code];
    
    if (md && [md.type isEqualToString:@"file"] && md.hasCache) {
        
        md.uploaded = YES;
        [md save];
        [self refreshMetadataList];
        //播放成功声音
        [self playSuccessSound];
    
    } else if (md && ![md.type isEqualToString:@"file"]) {
        
        md.uploaded = YES;
        [md save];
        [self refreshMetadataList];
        //播放成功声音
        [self playSuccessSound];
    
    } else {
        
        NSString *urlString = [NSString stringWithFormat:@"http://rest.sinaapp.com/api/get&code=%@", metadata.code];
        NSURL *url = [NSURL URLWithString:urlString];
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setDelegate:self];
        [request setDownloadProgressDelegate:self];
        request.userInfo = @{@"metadata" : metadata, @"apiName":@"api/get"};
        [request startAsynchronous];
    }
    
    [[AppDelegate sharedAppDelegate] setListenning:YES];
}


#pragma mark - PostWaveTransMetadataDelegate <NSObject>

- (void)postWaveTransMetadata:(WaveTransMetadata *)metadata {
    
    [self refreshMetadataList];
    
    [self.mTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    [self uploadRequestWithMetadata:metadata];
}


- (void)uploadRequestWithMetadata:(WaveTransMetadata *)metadata {
    
    [self.mTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    [self refreshMetadataList];
    
    NSURL *url = [NSURL URLWithString:@"http://rest.sinaapp.com/api/post"];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setDelegate:self];
    [request setRequestMethod:@"POST"];
    request.userInfo = @{@"metadata" : metadata, @"apiName":@"api/post"};
    [request setUploadProgressDelegate:self];
    
    if ([metadata.type isEqualToString:@"file"]) {
        
        [request addFile:[metadata cachePath:NO] forKey:@"file"];
        [request addPostValue:metadata.type forKey:@"type"];
        
    } else if ([metadata.type isEqualToString:@"text"] || [metadata.type isEqualToString:@"url"]) {
        
        [request addPostValue:metadata.type forKey:@"type"];
        [request addPostValue:metadata.content forKey:@"content"];
    }
    
    
    [request startAsynchronous];
}

#pragma mark - ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request {
    
    if ([request responseStatusCode] != 200) {
        
        NSLog(@"Error: listen error!");
        
    }else if ([[request.userInfo objectForKey:@"apiName"] isEqualToString:@"api/post"]){
        
        NSDictionary *dict = [[request responseString] JSONValue];
        
        if ([dict isKindOfClass:[NSDictionary class]] && ![dict objectForKey:@"errno"]) {
            
            //上传成功
            
            WaveTransMetadata *metadata = [[[WaveTransMetadata alloc] initWithDictionary:dict] autorelease];
            
            //WaveTransMetadata *metadataReceive = [_request.userInfo objectForKey:@"metadata"];
            
            NSLog(@"%@", metadata.code);
            NSLog(@"%@", metadata.sha1);
            NSLog(@"%@", metadata.type);
            NSLog(@"%@", metadata.ctime);
            NSLog(@"%@", metadata.content);
            NSLog(@"%@", metadata.size);
            
            //[self playWithMetadata:metadata];
            
            WaveTransMetadata *metadataReceive = [request.userInfo objectForKey:@"metadata"];
            [metadataReceive setUploaded:YES];
            [metadataReceive save];
            
            [self refreshMetadataList];
            
        }else {
            
            NSLog(@"Error: return format error!");
        }
    }else if ([[request.userInfo objectForKey:@"apiName"] isEqualToString:@"api/get"]) {
        
        NSDictionary *dict = [[request responseString] JSONValue];
        
        if ([dict isKindOfClass:[NSDictionary class]] && ![dict objectForKey:@"errno"]) {
            
            //接收成功
            
            //播放成功声音
            [self playSuccessSound];
            
            WaveTransMetadata *metadataReceive = [[[WaveTransMetadata alloc] initWithDictionary:dict] autorelease];
            
            NSLog(@"%@", metadataReceive.code);
            NSLog(@"%@", metadataReceive.sha1);
            NSLog(@"%@", metadataReceive.type);
            NSLog(@"%@", metadataReceive.ctime);
            NSLog(@"%@", metadataReceive.content);
            NSLog(@"%@", metadataReceive.size);
            
            metadataReceive.uploaded = YES;
            [metadataReceive save];
            [self refreshMetadataList];
            
            if ([metadataReceive.type isEqualToString:@"file"]) {
                
                BOOL flag = YES;
                
                NSArray *requestArray = [[ASIHTTPRequest sharedQueue] operations];
                for(ASIHTTPRequest *request in requestArray) {
                    
                    WaveTransMetadata *metadata = [request.userInfo objectForKey:@"metadata"];
                    
                    if ([metadataReceive isEqual:metadata]) {
                        
                        flag = NO;
                        break;
                    }
                }
                
                if (flag) {
                    ASIHTTPRequest *filerequest = [ASIHTTPRequest requestWithURL:metadataReceive.fileURL];
                    [filerequest setUseCookiePersistence:NO];
                    [filerequest setUseSessionPersistence:NO];
                    [filerequest setValidatesSecureCertificate:NO];
                    [filerequest setShouldRedirect:NO];
                    [filerequest setAllowCompressedResponse:YES];
                    [filerequest setShouldWaitToInflateCompressedResponses:NO];
                    [filerequest setShouldAttemptPersistentConnection:YES];
                    [filerequest setNumberOfTimesToRetryOnTimeout:3];
                    [filerequest setShouldAttemptPersistentConnection:YES];
                    [filerequest setTimeOutSeconds:16.0];
                    [filerequest setPersistentConnectionTimeoutSeconds:30.0];
                    [filerequest setDownloadDestinationPath:[metadataReceive cachePath:YES]];
                    [filerequest setTemporaryFileDownloadPath:[NSString stringWithFormat:@"%@.tmp",[metadataReceive cachePath:NO]]];
                    filerequest.delegate = self;
                    filerequest.downloadProgressDelegate = self;
                    filerequest.userInfo = @{@"metadata":metadataReceive,@"is_download_file":@"YES"};
                    [filerequest startAsynchronous];
                }
            }
            
        }else {
            
            NSLog(@"Error: return format error!");
        }
    }else if ([[request.userInfo objectForKey:@"is_download_file"] isEqualToString:@"YES"]) {//下载文件完成
        [self refreshMetadataList];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    
    NSError *error = [request error];
    NSLog(@"%@", error);
    
    [self playErrorSound];
}

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    
    NSLog(@"download : %llu/%llu", request.totalBytesRead, request.contentLength);
    
    if ([request.userInfo objectForKey:@"is_download_file"] != nil) {
        
        CGFloat progress = (CGFloat)request.totalBytesRead/request.contentLength;
        
        NSArray *visibleCells = [self.mTableView visibleCells];
        for(MainTableViewCell *cell in visibleCells){
            [cell updateDownloadProgress:progress byMetadata:[request.userInfo objectForKey:@"metadata"]];
        }
    }
    
}
- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes {
    
    NSLog(@"upload : %llu/%llu", request.totalBytesSent, request.postLength);
    
    CGFloat progress = (CGFloat)request.totalBytesSent/request.postLength;
    
    NSArray *visibleCells = [self.mTableView visibleCells];
    for(MainTableViewCell *cell in visibleCells){
        [cell updateDownloadProgress:progress byMetadata:[request.userInfo objectForKey:@"metadata"]];
    }
}

#pragma mark - UITableViewDataSource<NSObject>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.metadataList.count;
}

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 4;
//}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Called when "DELETE" button is pushed.
    NSLog(@"DELETE button pushed in row at: %@", indexPath.description);
    //TODO:删除按钮
    
    [WaveTransModel deleteMetadata:[self.metadataList objectAtIndex:indexPath.row]];
    [self refreshMetadataList];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WaveTransMetadata *wt =[self.metadataList objectAtIndex:indexPath.row];
    
    MainTableViewCell *cell = [TableViewCellFactory getTableViewCellByCellType:wt
                                                                     tableView:tableView owner:self];
    
    return cell;
}

//-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    switch (section) {
//        case 0:
//        return @"今天";
//        case 1:
//        return @"昨天";
//        case 2:
//        return @"前天";
//        case 3:
//        return @"星期四";
//    }
//    
//    return @"一周前";
//}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)] autorelease];
//    header.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
//    
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 100, 20)];
//    [header addSubview:titleLabel];
//    
//    switch (section) {
//        case 0:
//        titleLabel.text = @"今天";
//        break;
//        
//        case 1:
//        titleLabel.text = @"昨天";
//        break;
//        
//        case 2:
//        titleLabel.text = @"前天";
//        break;
//        
//        case 3:
//        titleLabel.text = @"星期四";
//        break;
//        
//        //TODO:......
//        
//        default:
//        titleLabel.text = @"一周以前";
//        break;
//    }
//    
//    return header;
//}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     *  若当前cell为未上传、下载完成的对象
     */
    
    NSArray *requestArray = [[ASIHTTPRequest sharedQueue] operations];
    
    WaveTransMetadata *metadata = [self.metadataList objectAtIndex:indexPath.row];
    
    if ([metadata.type isEqualToString:@"file"] && [metadata hasCache] && !metadata.uploaded) {//上传
        
        BOOL flag = YES;
        
        for(ASIHTTPRequest *request in requestArray) {
            
            WaveTransMetadata *metadataReceive = [request.userInfo objectForKey:@"metadata"];
            
            if ([metadataReceive isEqual:metadata]) {
            
                flag = NO;
                break;
            }
        }
        
        if (flag) {
            
            [self postWaveTransMetadata:metadata];
        }
        
    } else if ([metadata.type isEqualToString:@"file"] && ![metadata hasCache] && metadata.uploaded){//下载
        
        BOOL flag = YES;
        
        for(ASIHTTPRequest *request in requestArray){
            
            WaveTransMetadata *metadataReceive = [request.userInfo objectForKey:@"metadata"];
            
            if ([metadataReceive isEqual:metadata] && [[request.userInfo objectForKey:@"is_download_file"] isEqualToString:@"YES"]) {
            
                flag = NO;
                break;
            }
        }
        
        if (flag) {
            
            ASIHTTPRequest *filerequest = [ASIHTTPRequest requestWithURL:metadata.fileURL];
            [filerequest setUseCookiePersistence:NO];
            [filerequest setUseSessionPersistence:NO];
            [filerequest setValidatesSecureCertificate:NO];
            [filerequest setShouldRedirect:NO];
            [filerequest setAllowCompressedResponse:YES];
            [filerequest setShouldWaitToInflateCompressedResponses:NO];
            [filerequest setShouldAttemptPersistentConnection:YES];
            [filerequest setNumberOfTimesToRetryOnTimeout:3];
            [filerequest setShouldAttemptPersistentConnection:YES];
            [filerequest setTimeOutSeconds:16.0];
            [filerequest setPersistentConnectionTimeoutSeconds:30.0];
            [filerequest setDownloadDestinationPath:[metadata cachePath:YES]];
            [filerequest setTemporaryFileDownloadPath:[NSString stringWithFormat:@"%@.tmp",[metadata cachePath:NO]]];
            filerequest.delegate = self;
            filerequest.downloadProgressDelegate = self;
            filerequest.userInfo = @{@"metadata":metadata,@"is_download_file":@"YES"};
            [filerequest startAsynchronous];
        }
        
    } else {
    
        [self presentOptionsMenu:metadata];
    }
}



#pragma mark - MSCMoreOptionTableViewCellDelegate
- (void)tableView:(UITableView *)tableView moreOptionButtonPressedInRowAtIndexPath:(NSIndexPath *)indexPath {
    // Called when "MORE" button is pushed.
    NSLog(@"MORE button pushed in row at: %@", indexPath.description);
    [self showMoreActionSheet:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForMoreOptionButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return @"更多";
    //return @"More";
}

- (UIColor *)tableView:(UITableView *)tableView backgroundColorForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [UIColor colorWithRed:0.18f green:0.67f blue:0.84f alpha:1.0f];
}

#pragma mark - actionSheet

- (void)showMoreActionSheet:(NSIndexPath *)indexPath {
    
    
     WaveTransMetadata *md = [_metadataList objectAtIndex:indexPath.row];
    
    if (!md) {
        
        return;
    }
    
    
    UIActionSheet *actionSheet;
    
    if ([md.type isEqualToString:@"file"]) {
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                    destructiveButtonTitle:@"删除"
                                         otherButtonTitles:@"打开", nil];
    
    
    } else {
    
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                    destructiveButtonTitle:@"删除"
                                         otherButtonTitles:@"复制", nil];
    }
    
    
    actionSheet.userinfo = @{@"type" : @"more", @"metadata" : md};
    
    [actionSheet showInView:self.view];
    [actionSheet release];
}

#pragma mark - UIActionSheetDelegate <NSObject>


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {

    if (alertView.userinfo && [[alertView.userinfo objectForKey:@"type"] isEqualToString:@"linkWeibo"]) {
    
        switch (buttonIndex) {
            case 0:
            {

            }
                break;
                
            case 1:
            {
                [self performSelector:@selector(linkWeibo) withObject:nil afterDelay:0.1];
            }
                break;
                
            default:
                break;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {

    if (actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"switchFreq"]) {
        
        switch (buttonIndex) {
            case 0:
            {
                [PCMRender switchFreq:YES];
                switch_freq(1);
            }
                break;
            case 1:
            {
                [PCMRender switchFreq:NO];
                switch_freq(0);
            }
                break;
            case 2:
            {
                [[VdiskSession sharedSession] unlink];
                [self performSelector:@selector(linkWeibo) withObject:nil afterDelay:0.1];
            }
                break;
            default:
                break;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"addFile"]) {
        
        UIImagePickerController * picker = [[[UIImagePickerController alloc] init] autorelease];
        picker.delegate = self;
        
        switch (buttonIndex) {
                
            case 0://Take picture
                
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    
                } else {
                    
                    NSLog(@"模拟器无法打开相机");
                }
                
                [self presentViewController:picker animated:YES completion:^{}];
                break;
                
            case 1://From album
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                picker.mediaTypes = [[[NSArray alloc] initWithObjects:@"public.image", @"public.movie", nil] autorelease];
                [self presentViewController:picker animated:YES completion:^{}];
                break;
                
            case 2:
            {
                TextEditorViewController *textEditorViewController = [[[TextEditorViewController alloc] init] autorelease];
                textEditorViewController.postWaveTransMetadataDelegate = self;
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:textEditorViewController];
                [self presentViewController:navigationController animated:YES completion:^{}];
            }
                break;
            case 3:
            {
                
//                ChoosePeopleViewController *cpvc = [[[ChoosePeopleViewController alloc] init] autorelease];
//                UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:cpvc] autorelease];
//                [self presentViewController:navigationController animated:YES completion:^{}];

                
                if(!self.peoplePicker){
                    
                    self.peoplePicker = [[[ABPeoplePickerNavigationController alloc] init] autorelease];
                    
                    // place the delegate of the picker to the controll
                    
                    self.peoplePicker.peoplePickerDelegate = self;
                    
                }
                
                // showing the picker
                [self presentViewController:self.peoplePicker animated:YES completion:^{}];

            }
                break;
            case 4:
            {
                if ([[VdiskSession sharedSession] isLinked] && ![[VdiskSession sharedSession] isExpired]) {
                    
                    [self loadMyWeibo];
                    [self loading:@"正在获取微博信息"];
                    
                } else {
                
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您还没有绑定微博账号或者已经过期,是否绑定?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                    alert.userinfo = @{@"type" : @"linkWeibo"};
                    [alert show];
                    [alert release];
                }
            }
                break;
            default:
                break;
        }
    
    
    } else if (actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"more"]) {
    
        WaveTransMetadata *md = [actionSheet.userinfo objectForKey:@"metadata"];
        
        if (md && [md isKindOfClass:[WaveTransMetadata class]]) {
            
            
            
            if ([md.type isEqualToString:@"file"]) {
                
                
                switch (buttonIndex) {
                    case 0:
                    {
                        //NSLog(@"删除");
                        [WaveTransModel deleteMetadata:md];
                        [self refreshMetadataList];
                    }
                        break;
                        
                    case 1:
                    {
                        //NSLog(@"打开");
                        [self presentOptionsMenu:md];
                    }
                        break;
                        
                    default:
                        break;
                }
                
                
                
            } else {
                                
                
                switch (buttonIndex) {
                    case 0:
                    {
                        //NSLog(@"删除");
                        [WaveTransModel deleteMetadata:md];
                        [self refreshMetadataList];
                    }
                        break;
                        
                    case 1:
                    {
                        
                        NSString *contentText = md.content;
                        
                        if ([md.type isEqualToString:@"text"]) {
                            
                            if (md.isJson) {
                                
                                NSDictionary *jsonDict = [md.content JSONValue];
                                
                                if ([[jsonDict allKeys] containsObject:@"wave_weibo_card"]) {
                                    
                                    contentText = [NSString stringWithFormat:@"http://rest.sinaapp.com/?a=weibo_user_info&code=%@", md.code];
                                }
                            }
                        }
                        
                        //NSLog(@"复制");
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        [pasteboard setString:contentText];
                    }
                        break;
                        
                    default:
                        break;
                }
                
            }
            
            
            
        }
    
    } else if (actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"openURL"]) {
    
        switch (buttonIndex) {
        case 0:
            {
                [[UIApplication sharedApplication] openURL:[actionSheet.userinfo objectForKey:@"url"]];
            }
            break;
            
        default:
            break;
        }
        
        
    } else if (actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"weiboCard"]) {
    
        switch (buttonIndex) {
            case 0:
            {
                [[UIApplication sharedApplication] openURL:[actionSheet.userinfo objectForKey:@"url"]];
            }
                break;
            case 1:
            {
                if ([[VdiskSession sharedSession] isLinked] && ![[VdiskSession sharedSession] isExpired]) {
                    
                    NSDictionary *weiboInfo = [actionSheet.userinfo objectForKey:@"weiboInfo"];
                    [self.restClient cancelAllRequests];
                    self.restClient = [[[VdiskRestClient alloc] initWithSession:[VdiskSession sharedSession]] autorelease];
                    _restClient.delegate = self;
                    
                    [self loading:@"正在关注"];
                    
                    [_restClient callWeiboAPI:@"/friendships/create" params:@{@"screen_name":[weiboInfo objectForKey:@"screen_name"], @"uid":[weiboInfo objectForKey:@"id"]} method:@"POST" responseType:[NSDictionary class]];
                    
                } else {
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您还没有绑定微博账号或者已经过期,是否绑定?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                    alert.userinfo = @{@"type" : @"linkWeibo"};
                    [alert show];
                    [alert release];
                }
            }
                break;
                
            default:
                break;
        }
        
    } else if(actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"contact"]){
    
        WaveTransMetadata *metadata = [actionSheet.userinfo objectForKey:@"metadata"];
        NSDictionary *jsonDict = [[metadata content] JSONValue];
        switch (buttonIndex) {
            case 0:
            {
                CFErrorRef error = NULL;
                // create addressBook
                ABAddressBookRef iPhoneAddressBook = ABAddressBookCreate();
                
                //// Creating a person
                // create a new person --------------------
                ABRecordRef newPerson = ABPersonCreate();
                // set the first name for person
                ABRecordSetValue(newPerson, kABPersonFirstNameProperty, [jsonDict objectForKey:@"name"], &error);
                // set the last name
//                ABRecordSetValue(newPerson, kABPersonLastNameProperty, @"SugarTin.info", &error);
                // set the company name
//                ABRecordSetValue(newPerson, kABPersonOrganizationProperty, @"Apple Inc.", &error);
                // set the job-title
//                ABRecordSetValue(newPerson, kABPersonJobTitleProperty, @"Senior Developer", &error);
                // --------------------------------------------------------------------------------
                
                //// Adding Phone details
                // create a new phone --------------------
                ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                // set the main phone number
                ABMultiValueAddValueAndLabel(multiPhone, [jsonDict objectForKey:@"phone"], kABPersonPhoneMainLabel, NULL);
//                // set the mobile number
//                ABMultiValueAddValueAndLabel(multiPhone, @"1-123-456-7890", kABPersonPhoneMobileLabel, NULL);
//                // set the other number
//                ABMultiValueAddValueAndLabel(multiPhone, @"1-987-654-3210", kABOtherLabel, NULL);
//                // add phone details to person
                ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone,nil);
                // release phone object
                CFRelease(multiPhone);
                // --------------------------------------------------------------------------------
                
//                //// Adding email details
//                // create new email-ref
//                ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//                // set the work mail
//                ABMultiValueAddValueAndLabel(multiEmail, @"johndoe@modelmetrics.com", kABWorkLabel, NULL);
//                // add the mail to person
//                ABRecordSetValue(newPerson, kABPersonEmailProperty, multiEmail, &error);
//                // release mail object
//                CFRelease(multiEmail);
//                // --------------------------------------------------------------------------------
//                
//                //// adding address details
//                // create address object
//                ABMutableMultiValueRef multiAddress = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
//                // create a new dictionary
//                NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
//                // set the address line to new dictionary object
//                [addressDictionary setObject:@"Some Complete Address" forKey:(NSString *) kABPersonAddressStreetKey];
//                // set the city to new dictionary object
//                [addressDictionary setObject:@"Bengaluru" forKey:(NSString *)kABPersonAddressCityKey];
//                // set the state to new dictionary object
//                [addressDictionary setObject:@"Karnataka" forKey:(NSString *)kABPersonAddressStateKey];
//                // set the zip/pin to new dictionary object
//                [addressDictionary setObject:@"560068 " forKey:(NSString *)kABPersonAddressZIPKey];
//                // retain the dictionary
//                CFTypeRef ctr = CFBridgingRetain(addressDictionary);
//                // copy all key-values from ctr to Address object
//                ABMultiValueAddValueAndLabel(multiAddress,ctr, kABWorkLabel, NULL);
//                // add address object to person
//                ABRecordSetValue(newPerson, kABPersonAddressProperty, multiAddress,&error);
//                // release address object
//                CFRelease(multiAddress);
                // --------------------------------------------------------------------------------
                
                //// adding entry to contact-book
                // add person to addressbook
                ABAddressBookAddRecord(iPhoneAddressBook, newPerson, &error);
                // save/commit entry
                ABAddressBookSave(iPhoneAddressBook, &error);
                
                if (error != NULL) {
                    NSLog(@"Kaa boom ! couldn't save");
                }
            }
                break;
            case 1:
            {
                NSString *num = [[NSString alloc] initWithFormat:@"tel://%@",[jsonDict objectForKey:@"phone"]];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:num]]; //拨号
            }
                break;
            default:
                break;
        }
    
    }
}

#pragma mark - private method

- (void)linkWeibo {

    [self loading:@"正在绑定"];
    [[VdiskSession sharedSession] linkWithSessionType:kVdiskSessionTypeWeiboAccessToken];
}

/*
- (UIDocumentInteractionController *)docControllerForFile:(NSURL *)fileURL {
	
	UIDocumentInteractionController *docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    docController.delegate = self;
    
	return docController;
}
 */


- (void)viewText:(WaveTransMetadata *)metadata {

    TextViewController *textViewController = [[[TextViewController alloc] init] autorelease];
    textViewController.contentText = metadata.content;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:textViewController];
    [self presentViewController:navigationController animated:YES completion:^{}];
}

- (void)presentOptionsMenu:(WaveTransMetadata *)metadata {
    
    if ([metadata.type isEqualToString:@"text"]) {
        
        
        if(metadata.isJson) {
            
            NSDictionary *jsonDict = [metadata.content JSONValue];
            
            if ([[jsonDict allKeys] containsObject:@"wave_weibo_card"]) {
                
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                         delegate:self
                                                                cancelButtonTitle:@"取消"
                                                           destructiveButtonTitle:nil
                                                                otherButtonTitles:@"访问微博主页", @"关注TA", nil];
                
                actionSheet.userinfo = @{@"type" : @"weiboCard", @"weiboInfo" : jsonDict, @"url" : [NSURL URLWithString:[NSString stringWithFormat:@"http://rest.sinaapp.com/?a=weibo_user_info&code=%@", metadata.code]]};
                [actionSheet showInView:self.view];
                [actionSheet release];
            
            } else if([[jsonDict allKeys] containsObject:@"wave_people_card"]){
                
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                         delegate:self
                                                                cancelButtonTitle:@"取消"
                                                           destructiveButtonTitle:nil
                                                                otherButtonTitles:@"添加到通讯录", @"拨号", nil];
                
                actionSheet.userinfo = @{@"type" : @"contact", @"metadata" : metadata};
                [actionSheet showInView:self.view];
                [actionSheet release];
                
            } else{
            
                [self viewText:metadata];
            }
            
        } else {

            [self viewText:metadata];
        }
        
        
    } else if ([metadata.type isEqualToString:@"url"]) {
    
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"取消"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"打开链接", nil];
        
        actionSheet.userinfo = @{@"type" : @"openURL", @"url" : [NSURL URLWithString:metadata.content]};
        [actionSheet showInView:self.view];
        [actionSheet release];
        
    } else if ([metadata.type isEqualToString:@"file"]) {
    
        if ([metadata hasCache]) {
            
            UIDocumentInteractionController *docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:[metadata cachePath:NO]]];
            docController.delegate = self;
            [docController setName:metadata.filename];
            
            if (![docController presentPreviewAnimated:YES]) {
                
                
            }
            
        } else {
            
            
        }
    }
}


//更新数据
-(void)refreshMetadataList
{
    self.metadataList = [WaveTransModel metadataList];
    [self.mTableView reloadData];
}



#pragma mark - UIDocumentInteractionController

- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller {

}


- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    
    //if ([AppDelegate sharedAppDelegate].interruption) {
        
        try {
            
            AudioSessionSetActive(true);
            AudioOutputUnitStart([AppDelegate sharedAppDelegate].rioUnit);
            
        } catch (CAXException e) {
            
            
        }
    //}
}


- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {

    return self;
}

- (void)documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller {
    

}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    

}

#pragma mark - 
- (BOOL)peoplePickerNavigationController: (ABPeoplePickerNavigationController *)peoplePicker

      shouldContinueAfterSelectingPerson:(ABRecordRef)person

{
    
    return YES;
    
}

- (BOOL)peoplePickerNavigationController: (ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier

{
    
    if (property == kABPersonPhoneProperty) {
        
        ABMutableMultiValueRef phoneMulti = ABRecordCopyValue(person, property);
        
        int index = ABMultiValueGetIndexForIdentifier(phoneMulti,identifier);
        
        NSString *phone = (NSString*)ABMultiValueCopyValueAtIndex(phoneMulti, index);
        
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        firstName = firstName != nil?firstName:@"";
        NSString *lastName =  CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
        lastName = lastName != nil?lastName:@"";
        NSString *name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
        
        NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"wave_people_card",name,@"name",phone,@"phone", nil];
        NSString *json = [jsonDict JSONRepresentation];
        
        WaveTransMetadata *metadata = [[[WaveTransMetadata alloc] initWithSha1:[json SHA1EncodedString]
                                                                          type:@"text"
                                                                       content:json
                                                                          size:[json lengthOfBytesUsingEncoding:NSUTF8StringEncoding]
                                                                      filename:nil] autorelease];
        metadata.uploaded = NO;
        [metadata save];
        
        [self postWaveTransMetadata:metadata];

        
        
        [phone release];
        
        
        [self.peoplePicker dismissViewControllerAnimated:YES completion:nil];
        
        
        
    }
    
    return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker

{
    
    // assigning control back to the main controller
    
    [self.peoplePicker dismissViewControllerAnimated:YES completion:nil];
    
}



#pragma mark -
#pragma mark VdiskSessionDelegate methods

static BOOL kIsRefreshLinking = NO;

- (void)sessionAlreadyLinked:(VdiskSession *)session {
    
    NSLog(@"sessionAlreadyLinked");
}

// Log in successfully.
- (void)sessionLinkedSuccess:(VdiskSession *)session {
    
    NSLog(@"sessionLinkedSuccess");
    [self loadedSuccess:@"绑定成功"];
}

//log fail

- (void)session:(VdiskSession *)session didFailToLinkWithError:(NSError *)error {
    
    NSLog(@"session:didFailToLinkWithError:");
    
    [self handleErrors:error title:@"绑定失败"];
}

// Log out successfully.

- (void)sessionUnlinkedSuccess:(VdiskSession *)session {
    
    if (kIsRefreshLinking) {
        
        kIsRefreshLinking = NO;
    }
    
    NSLog(@"sessionUnlinkedSuccess");
}

// When you use the VdiskSession's request methods,
// you may receive the following four callbacks.
- (void)sessionNotLink:(VdiskSession *)session {
    
    if (kIsRefreshLinking) {
        
        kIsRefreshLinking = NO;
    }
    
    NSLog(@"sessionNotLink");
}


- (void)sessionExpired:(VdiskSession *)session {
    
    @synchronized(self) {
        
        NSLog(@"sessionExpired");
        
        if (!kIsRefreshLinking) {
            
            //[MBProgressHUD showHUDAddedTo:kKeyWindow animated:YES].labelText = @"正在重新登录...";
            
            kIsRefreshLinking = YES;
            [session performSelectorOnMainThread:@selector(refreshLink) withObject:nil waitUntilDone:YES];
            
            NSLog(@"startRefreshLinking");
        }
    }
}

- (void)sessionLinkDidCancel:(VdiskSession *)session {
    
    NSLog(@"sessionLinkDidCancel:");
    
    if (self.hud) {
        
        [_hud hide:NO];
    }
}


#pragma mark - SinaWeibo Delegate

- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo {
    
    NSLog(@"sinaweiboDidLogIn userID = %@ accesstoken = %@ expirationDate = %@ refresh_token = %@", sinaweibo.userID, sinaweibo.accessToken, sinaweibo.expirationDate,sinaweibo.refreshToken);
}

- (void)sinaweiboDidLogOut:(SinaWeibo *)sinaweibo {
    
    NSLog(@"sinaweiboDidLogOut");
    
}

- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo {
    
    NSLog(@"sinaweiboLogInDidCancel");
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error {
    
    NSLog(@"sinaweibo logInDidFailWithError %@", error);
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo accessTokenInvalidOrExpired:(NSError *)error {
    
    NSLog(@"sinaweiboAccessTokenInvalidOrExpired %@", error);
    
}

#pragma mark - VdiskRestClient

- (void)restClient:(VdiskRestClient *)client calledWeiboAPI:(NSString *)apiName result:(id)result {
    
    if ([apiName isEqualToString:@"/users/show"]){
        
        [self loadedSuccess:@"获取成功"];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict addEntriesFromDictionary:result];
        [dict setValue:@"wave_weibo_card" forKey:@"wave_weibo_card"];
        NSString *content = [dict JSONFragment];
        WaveTransMetadata *md = [[[WaveTransMetadata alloc] initWithSha1:[content SHA1EncodedString] type:@"text" content:content size:[content lengthOfBytesUsingEncoding:NSUTF8StringEncoding] filename:nil] autorelease];
        [md setUploaded:NO];
        [md save];
        
        [self postWaveTransMetadata:md];
        
        
    } else if ([apiName isEqualToString:@"/friendships/create"]) {
        
        [self loadedSuccess:@"关注成功"];
    }
}

- (void)restClient:(VdiskRestClient *)client callWeiboAPIFailedWithError:(NSError *)error apiName:(NSString *)apiName {
    
    if ([apiName isEqualToString:@"/users/show"]) {
        
        [self handleErrors:error title:@"获取失败"];
        
    } else if ([apiName isEqualToString:@"/friendships/create"]) {
        
        [self handleErrors:error title:@"关注失败"];
    }
}

#pragma - handleErrors && loading

- (void)loadedSuccess:(NSString *)text {
    
    _hud.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]] autorelease];
    _hud.mode = MBProgressHUDModeCustomView;
    _hud.labelText = text;
    [_hud hide:YES afterDelay:1.5];
}

- (void)loading:(NSString *)text {
    
    [_hud hide:NO];
    
    self.hud = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    [self.view addSubview:_hud];
    
    _hud.dimBackground = YES;
    _hud.delegate = self;
    _hud.labelText = text;
    [_hud show:NO];
}

- (void)handleErrors:(NSError *)error title:(NSString *)title {
    
    [_hud hide:NO];
    
    self.hud = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    [self.view addSubview:_hud];
    
    _hud.dimBackground = YES;
    _hud.delegate = self;
    
    _hud.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"X.png"]] autorelease];
    _hud.mode = MBProgressHUDModeCustomView;
    _hud.labelText = title;
    
    _hud.detailsLabelText = VdiskErrorMessageWithCode__(error);
    
    [_hud show:NO];
    [_hud hide:YES afterDelay:1.5];
}

- (void)handleErrors:(NSError *)error {
    
    [self handleErrors:error title:@"加载失败"];
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    
	[_hud removeFromSuperview];
}


@end
