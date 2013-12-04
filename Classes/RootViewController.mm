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
#import "WaveTransModel.h"
#import "TextEditorViewController.h"

@interface RootViewController () <ASIHTTPRequestDelegate, ASIProgressDelegate, AVAudioPlayerDelegate, GetWaveTransMetadataDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MBProgressHUDDelegate> {
    
}

//@property (nonatomic, retain) ASIFormDataRequest *request;
@property (nonatomic,retain) AVAudioPlayer *audioPlayer;
@property (nonatomic, retain) NSData *pcmData;


@end

@implementation RootViewController

@synthesize audioPlayer = _audioPlayer;
@synthesize pcmData = _pcmData;
//@synthesize request = _request;

- (NSString *)fileTmpPath: (NSString* )fileName {
    
    NSString *filePath  = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"cache/files/%@", fileName]];
    
    return filePath;
}

- (void)dealloc {
    
    [_audioPlayer release];
    [_pcmData release];

    [[ASIHTTPRequest sharedQueue] cancelAllOperations];
    
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
    
    UIActionSheet *chooseImageSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:@"Camera",@"Photo library", @"Text", nil];
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
    self.pcmData = [PCMRender renderChirpData:metadata.rsCode];
    
    NSError *error = nil;
    
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
        
        case 2:
        {
            TextEditorViewController *textEditorViewController = [[[TextEditorViewController alloc] init] autorelease];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:textEditorViewController];
            [self presentViewController:navigationController animated:YES completion:^{}];
        }
            break;
        default:
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //[UIApplication sharedApplication].statusBarHidden = NO;
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];

    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([mediaType isEqualToString:@"public.image"] && ![info valueForKey:UIImagePickerControllerReferenceURL]) {
        
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
            
            //TODO:提示错误
            
            [picker dismissViewControllerAnimated:YES completion:^{
                
                
            }];
            
            return;
        }
        
        NSError *err;
        
        if ([fileManager moveItemAtURL:url toURL:[NSURL fileURLWithPath:tmpMediaFile] error:&err]) {
            
            [self prepareToUploadWithTmpPath:tmpMediaFile fileName:movieName fileManager:fileManager];
            
        } else {
            
            // TODO:错误提示
            
            NSLog(@"error: %@", err);
        }
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
    
    if ([fileManager moveItemAtPath:tmpMediaFile toPath:cachePath error:&error]) {
        
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
    
    NSString *urlString = [NSString stringWithFormat:@"http://rest.sinaapp.com/api/get&code=%@", metadata.code];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setDownloadProgressDelegate:self];
    request.userInfo = @{@"metadata" : metadata, @"apiName":@"api/get"};
    [request startAsynchronous];
}

- (void)uploadRequestWithMetadata:(WaveTransMetadata *)metadata {
    
    NSURL *url = [NSURL URLWithString:@"http://rest.sinaapp.com/api/post"];

    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
    [request setDelegate:self];
    [request setRequestMethod:@"POST"];
    request.userInfo = @{@"metadata" : metadata, @"apiName":@"api/post"};
    
    [request addFile:[metadata cachePath:NO] forKey:@"file"];
    [request addPostValue:metadata.type forKey:@"type"];
    [request setUploadProgressDelegate:self];
    [request startAsynchronous];
}

#pragma mark - ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request {
    
    if ([request responseStatusCode] != 200) {
        
        NSLog(@"Error: listen error!");
        [[AppDelegate sharedAppDelegate] setListenning:YES];
        
    }else if ([[request.userInfo objectForKey:@"apiName"] isEqualToString:@"api/post"]){
        
        // 上传结束后获取返回的数据，之后发声
        
        NSDictionary *dict = [[request responseString] JSONValue];
        
        if ([dict isKindOfClass:[NSDictionary class]]) {
            
            WaveTransMetadata *metadata = [[[WaveTransMetadata alloc] initWithDictionary:dict] autorelease];
            
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
    }else if ([[request.userInfo objectForKey:@"apiName"] isEqualToString:@"api/get"]) {
        
        NSDictionary *dict = [[request responseString] JSONValue];
        
        if ([dict isKindOfClass:[NSDictionary class]] && ![dict objectForKey:@"errno"]) {
            
            WaveTransMetadata *metadataReceive = [[[WaveTransMetadata alloc] initWithDictionary:dict] autorelease];
            
            NSLog(@"%@", metadataReceive.code);
            NSLog(@"%@", metadataReceive.sha1);
            NSLog(@"%@", metadataReceive.type);
            NSLog(@"%@", metadataReceive.ctime);
            NSLog(@"%@", metadataReceive.content);
            NSLog(@"%@", metadataReceive.size);
            
            metadataReceive.uploaded = YES;
            [metadataReceive save];
            
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

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    
    NSLog(@"download : %llu/%llu", request.totalBytesRead, request.contentLength);
}
- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes {
    
    NSLog(@"upload : %llu/%llu", request.totalBytesSent, request.postLength);
}

@end
