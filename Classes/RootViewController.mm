//
//  RootViewController.m
//  aurioTouch2
//
//  Created by Littlebox222 on 13-11-22.
//
//

#import "RootViewController.h"
#import "PCMRender.h"
#import "AppDelegate.h"
#import "WaveTransMetadata.h"
#import "VdiskJSON.h"
#import "ASIFormDataRequest.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface RootViewController () <ASIHTTPRequestDelegate, ASIProgressDelegate, AVAudioPlayerDelegate, GetWaveTransMetadataDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MBProgressHUDDelegate> {
    
}

@property (nonatomic, retain) ASIFormDataRequest *request;
@property (nonatomic,retain) AVAudioPlayer *audioPlayer;
@property (nonatomic, retain) NSData *pcmData;

@end

@implementation RootViewController

@synthesize audioPlayer = _audioPlayer;
@synthesize pcmData = _pcmData;
@synthesize request = _request;

- (NSString *)filePath: (NSString* )fileName {
    
    NSString *filePath  = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"cache/files/%@", fileName]];
    
    return filePath;
}

- (void)dealloc {
    
    [_audioPlayer release];
    [_pcmData release];
    
    [_request clearDelegatesAndCancel];
    [_request release];
    
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
	
    
#ifdef __IPHONE_7_0
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
    /*
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playButton.frame = CGRectMake(150, 350, 80, 40);
    playButton.backgroundColor = [UIColor redColor];
    playButton.titleLabel.text = @"play";
    [playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
     */
    
    UIButton *albumButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    albumButton.frame = CGRectMake(50, 350, 80, 40);
    albumButton.backgroundColor = [UIColor redColor];
    albumButton.titleLabel.text = @"album";
    [albumButton addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:albumButton];
    
    self.pcmData = [[[NSData alloc] init] autorelease];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openAlbum {
    
    [[AppDelegate sharedAppDelegate] setListenning:NO];
    
    UIActionSheet *chooseImageSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:@"Camera",@"Photo library", nil];
    [chooseImageSheet showInView:self.view];
}

/*
- (void)playAction:(id)sender
{
    [[AppDelegate sharedAppDelegate] setListenning:NO];
    
    self.pcmData = [PCMRender renderChirpData:@"hjs2tmj3qom9fa75v472"];
    
    NSError *error;
    
    if (self.audioPlayer != nil) {
        
        [self.audioPlayer prepareToPlay];
        
    }else {
        
        self.audioPlayer = [[[AVAudioPlayer alloc] initWithData:self.pcmData error:&error] autorelease];
    }
    
    
    if (error) {
        NSLog(@"error....%@",[error localizedDescription]);
    }else{
        
        self.audioPlayer.delegate = self;
        [self.audioPlayer prepareToPlay];
    }
    
    [self.audioPlayer play];
}
 */

- (void)playWithMetadata:(WaveTransMetadata *)metadata
{
    [[AppDelegate sharedAppDelegate] setListenning:NO];
    
    if (metadata == nil || metadata.sha1 == nil) {
        
        //TODO:数据错误，发声失败
        
        return;
    }
    
    // 测试直接用[WaveTransMetadata codeWithSha1:metadata.sha1]获取code发声
    self.pcmData = [PCMRender renderChirpData:[WaveTransMetadata codeWithSha1:metadata.sha1]];
    
    NSError *error;
    
    if (self.audioPlayer != nil) {
        
        [self.audioPlayer prepareToPlay];
        
    }else {
        
        self.audioPlayer = [[[AVAudioPlayer alloc] initWithData:self.pcmData error:&error] autorelease];
    }
    
    
    if (error) {
        NSLog(@"error....%@",[error localizedDescription]);
    }else{
        
        self.audioPlayer.delegate = self;
        [self.audioPlayer prepareToPlay];
    }
    
    [self.audioPlayer play];
}


#pragma mark - UIActionSheetDelegate Method
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
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
            
        default:
            
            // 取消时重新开启监听
            [[AppDelegate sharedAppDelegate] setListenning:YES];
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    
    if ([mediaType isEqualToString:@"public.image"]) {
        
        ALAssetsLibrary *assetLibrary=[[[ALAssetsLibrary alloc] init] autorelease];
        
        [assetLibrary assetForURL:(NSURL *)[info valueForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
            
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            
            NSString *mediaFile = [self filePath:[NSString stringWithFormat:@"%@.tmp", rep.filename]];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:mediaFile error:nil];
            
            if (![fileManager createDirectoryAtPath:[mediaFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil]) {
                
                //TODO:提示错误
                return;
            }
            
            
            
            NSMutableData *emptyData = [[NSMutableData alloc] initWithLength:0];
            [fileManager createFileAtPath:mediaFile contents:emptyData attributes:nil];
            [emptyData release];
            
            NSFileHandle *theFileHandle = [NSFileHandle fileHandleForWritingAtPath:mediaFile];
            
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
            
            
            NSString *sha1 = [VdiskUtil fileSHA1HashCreateWithPath:(CFStringRef)mediaFile ChunkSize:FileHashDefaultChunkSizeForReadingData];
            
            WaveTransMetadata *metadata = [[[WaveTransMetadata alloc] initWithDictionary:@{ @"sha1":sha1,
                                                                                            @"type":@"file",
                                                                                            @"size":[NSString stringWithFormat:@"%llu", theItemSize],
                                                                                            @"ctime":[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]}] autorelease];
            
            
            [metadata setFilename:rep.filename];
            NSString *cachePath = [metadata cachePath:YES];
            
            NSLog(@"%@", cachePath);
            
            NSError *error;
            if ([fileManager fileExistsAtPath:cachePath]) {
                
                // 如果有缓存，直接发声
                //[self playWithMetadata:metadata];
                
            }else if ([fileManager moveItemAtPath:mediaFile toPath:cachePath error:&error]) {
                
                // 如果没有，上传，收到code后发声
                [self uploadRequestWithMetadata:metadata];
                
            }else {
                
                // 没有缓存且移动文件失败，报错
                // TODO:错误提示
                NSLog(@"move file error: %@", error);
            }
            
        } failureBlock:^(NSError *err) {
            
            
            //TODO:提示错误
            
            NSLog(@"Error: %@",[err localizedDescription]);
            
            return;
        }];
        
    }else if ([mediaType isEqualToString:@"public.media"]) {
        
        //TODO:拷贝视频
        
        
        /*
        NSURL *url = [info valueForKey:UIImagePickerControllerMediaURL];
        [self uploadRequestWithURL:url];
         */
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

- (void)getWaveTransMetadataWithString:(NSString *)string {
    
    NSString *urlString = [NSString stringWithFormat:@"http://rest.sinaapp.com/api/get&code=%@", string];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    [_request clearDelegatesAndCancel];
    self.request = [ASIHTTPRequest requestWithURL:url];
    [_request setDelegate:self];
    [_request setDownloadProgressDelegate:self];
    [_request startAsynchronous];
}

- (void)uploadRequestWithMetadata:(WaveTransMetadata *)metadata {
    
    NSURL *url = [NSURL URLWithString:@"http://rest.sinaapp.com/api/post"];
    
    [_request clearDelegatesAndCancel];

    self.request = [ASIFormDataRequest requestWithURL:url];
    
    [_request setDelegate:self];
    [_request setRequestMethod:@"POST"];
    _request.userInfo = @{@"metadata" : metadata};
    
    [_request addFile:[metadata cachePath:NO] forKey:@"file"];
    [_request addPostValue:metadata.type forKey:@"type"];
    
    [_request setUploadProgressDelegate:self];
    
    [_request startAsynchronous];
}

#pragma mark - ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request {
    
    if ([request responseStatusCode] != 200) {
        
        NSLog(@"Error: listen error!");
        [[AppDelegate sharedAppDelegate] setListenning:YES];
        
    }else if ([[request requestMethod] isEqualToString:@"POST"]){
        
        // 上传结束后获取返回的数据，之后发声
        
        NSDictionary *dict = [[request responseString] JSONValue];
        
        if ([dict isKindOfClass:[NSDictionary class]]) {
            
            WaveTransMetadata *metadata = [[WaveTransMetadata alloc] initWithDictionary:dict];
            
            //WaveTransMetadata *metadataReceive = [_request.userInfo objectForKey:@"metadata"];
            
            NSLog(@"%@", metadata.code);
            NSLog(@"%@", metadata.sha1);
            NSLog(@"%@", metadata.type);
            NSLog(@"%@", metadata.ctime);
            NSLog(@"%@", metadata.content);
            NSLog(@"%@", metadata.size);
            
            //[self playWithMetadata:metadata];
            
        }else {
            
            NSLog(@"Error: return format error!");
            [[AppDelegate sharedAppDelegate] setListenning:YES];
            
        }
    }else if ([[request requestMethod] isEqualToString:@"GET"]) {
        
        NSDictionary *dict = [[request responseString] JSONValue];
        
        if ([dict isKindOfClass:[NSDictionary class]]) {
            
            WaveTransMetadata *metadataReceive = [[WaveTransMetadata alloc] initWithDictionary:dict];
            
            NSLog(@"%@", metadataReceive.code);
            NSLog(@"%@", metadataReceive.sha1);
            NSLog(@"%@", metadataReceive.type);
            NSLog(@"%@", metadataReceive.ctime);
            NSLog(@"%@", metadataReceive.content);
            NSLog(@"%@", metadataReceive.size);
            [[AppDelegate sharedAppDelegate] setListenning:YES];
            
        }else {
            
            NSLog(@"Error: return format error!");
            [[AppDelegate sharedAppDelegate] setListenning:YES];
        }
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    
    [[AppDelegate sharedAppDelegate] setListenning:YES];
    NSError *error = [request error];
    NSLog(@"%@", error);
}

- (void)setProgress:(float)newProgress {
    
    NSLog(@"%.2f%% ", newProgress * 100);
}

@end
