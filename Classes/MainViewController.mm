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
#import "PhotoCell.h"


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



@interface MainViewController ()<UITableViewDataSource, UITableViewDelegate, MSCMoreOptionTableViewCellDelegate, UIActionSheetDelegate, ASIHTTPRequestDelegate, ASIProgressDelegate, AVAudioPlayerDelegate, GetWaveTransMetadataDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MBProgressHUDDelegate, PostWaveTransMetadataDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, retain) UITableView *mTableView;
@property (nonatomic, retain) NSMutableArray *metadataList;
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;

@property (nonatomic, retain) MBProgressHUD *hud;

@end

@implementation MainViewController

@synthesize audioPlayer = _audioPlayer;
@synthesize hud = _hud;


- (NSString *)fileTmpPath:(NSString *)fileName {
    
    NSString *filePath  = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"cache/files/%@", fileName]];
    
    return filePath;
}

- (void)dealloc {
    
    [_audioPlayer release];
    
    [[ASIHTTPRequest sharedQueue] cancelAllOperations];
    
    _hud.delegate = nil;
    [_hud release];
    
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        [[AppDelegate sharedAppDelegate] setGetWaveTransMetadataDelegate:self];
    }
    return self;
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
    
    
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    //addButton.backgroundColor = [UIColor redColor];
    [addButton setFrame:CGRectMake(320-50, 20.0, 50, 40)];
    addButton.titleLabel.text = @"添加";
    [addButton addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addButton];
    
#ifdef __IPHONE_7_0
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
}


- (void)openAlbum {
    
    UIActionSheet *chooseImageSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"取消"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:@"拍照", @"相册", @"文本", nil];
    chooseImageSheet.userinfo = @{@"type" : @"addFile"};
    
    [chooseImageSheet showInView:self.view];
    
    [chooseImageSheet release];
    
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
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof(audioRouteOverride), &audioRouteOverride);
        
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
    
    self.hud = [[[MBProgressHUD alloc] initWithView:[[AppDelegate sharedAppDelegate] window]] autorelease];
    [picker.view addSubview:_hud];
    _hud.dimBackground = YES;
    _hud.delegate = self;
    _hud.labelText = @"正在处理...";
    [_hud setHidden:NO];
    [_hud show:YES];
    
    if ([mediaType isEqualToString:@"public.image"] && ![info valueForKey:UIImagePickerControllerReferenceURL]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
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
            
            if (_hud != nil) {
                
                [_hud show:NO];
                [_hud setHidden:YES];
            }
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
            if (_hud != nil) {
                
                [_hud show:NO];
                [_hud setHidden:YES];
            }
            
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
            
            if (_hud != nil) {
                
                [_hud show:NO];
                [_hud setHidden:YES];
            }
        });
    }
    
    if (_hud != nil) {
        
        [_hud show:NO];
        [_hud setHidden:YES];
    }
    
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
    
    if (md) {
        
        md.uploaded = YES;
        [md save];
        [self refreshMetadataList];
    
    }else {
        
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
    
    [self uploadRequestWithMetadata:metadata];
}


- (void)uploadRequestWithMetadata:(WaveTransMetadata *)metadata {
    
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
            
            WaveTransMetadata *metadata = [[WaveTransMetadata alloc] initWithDictionary:dict];
            
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
            
            WaveTransMetadata *metadataReceive = [[WaveTransMetadata alloc] initWithDictionary:dict];
            
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
                
                ASIHTTPRequest *filerequest = [ASIHTTPRequest requestWithURL:metadataReceive.fileURL];
                [filerequest setDownloadDestinationPath:[metadataReceive cachePath:YES]];
                [filerequest setTemporaryFileDownloadPath:[NSString stringWithFormat:@"%@.tmp",[metadataReceive cachePath:NO]]];
                filerequest.delegate = self;
                filerequest.downloadProgressDelegate = self;
                filerequest.userInfo = @{@"metadata":metadataReceive,@"is_download_file":@"YES"};
                [filerequest startAsynchronous];
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

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    
}



#pragma mark - MSCMoreOptionTableViewCellDelegate
- (void)tableView:(UITableView *)tableView moreOptionButtonPressedInRowAtIndexPath:(NSIndexPath *)indexPath {
    // Called when "MORE" button is pushed.
    NSLog(@"MORE button pushed in row at: %@", indexPath.description);
    [self showMoreActionSheet:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForMoreOptionButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"More";
}

-(UIColor *)tableView:(UITableView *)tableView backgroundColorForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UIColor colorWithRed:0.18f green:0.67f blue:0.84f alpha:1.0f];
}

#pragma mark - actionSheet
- (void)showMoreActionSheet:(NSIndexPath *)indexPath {
    
    if (![_metadataList objectAtIndex:indexPath.row]) {
        
        return;
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"取消"
                                               destructiveButtonTitle:@"删除"
                                                    otherButtonTitles:@"用其他应用打开", @"分享"/*, @"详细"*/, nil];
    
    actionSheet.userinfo = @{@"type" : @"more", @"metadata" : [_metadataList objectAtIndex:indexPath.row]};
    
    [actionSheet showInView:self.view];
    [actionSheet release];
}

#pragma mark - UIActionSheetDelegate <NSObject>

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"addFile"]) {
        
        UIImagePickerController * picker = [[[UIImagePickerController alloc] init] autorelease];
        picker.delegate = self;
        
        switch (buttonIndex) {
            case 0://Take picture
                
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    
                }else{
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
            default:
                break;
        }
    
    
    } else if (actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"more"]) {
    
        WaveTransMetadata *md = [actionSheet.userinfo objectForKey:@"metadata"];
        
        if (md && [md isKindOfClass:[WaveTransMetadata class]]) {
            
            
            switch (buttonIndex) {
                case 0:
                {
                    NSLog(@"删除");
                }
                    break;
                    
                case 1:
                {
                    NSLog(@"用其他应用打开");
                }
                    break;
                    
                case 2:
                {
                    NSLog(@"分享");
                }
                    break;
                    
                case 3:
                {
                    NSLog(@"详细");
                }
                    break;
                    
                default:
                    break;
            }
        }
    }
}

#pragma mark - private method

/*
- (UIDocumentInteractionController *)docControllerForFile:(NSURL *)fileURL {
	
	UIDocumentInteractionController *docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    docController.delegate = self;
    
	return docController;
}
 */

- (void)presentOptionsMenu:(WaveTransMetadata *)metadata {
    
    if ([metadata hasCache]) {
        
        UIDocumentInteractionController *docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:[metadata cachePath:NO]]];
        
        [docController setName:metadata.filename];
        
        
        if (![docController presentPreviewAnimated:YES]) {
            
           
        }
        
    } else {
        
        
    }
}


//更新数据
-(void)refreshMetadataList
{
    self.metadataList = [WaveTransModel metadataList];
    [self.mTableView reloadData];
}



#pragma mark - UIDocumentInteractionController


- (void)documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller {
    

}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    

}


@end
