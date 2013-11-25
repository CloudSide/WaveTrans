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

@interface RootViewController () <ASIHTTPRequestDelegate, ASIProgressDelegate, AVAudioPlayerDelegate, ReceiveRequestDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MBProgressHUDDelegate> {
    
    BOOL _cancelled;
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
        // Custom initialization
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
    
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playButton.frame = CGRectMake(150, 350, 80, 40);
    playButton.backgroundColor = [UIColor redColor];
    playButton.titleLabel.text = @"play";
    [playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
    
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
                                                         otherButtonTitles:@"Camera",@"Photo library", nil];
    [chooseImageSheet showInView:self.view];
}

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
        
        NSLog(@"%@", (NSURL *)[info valueForKey:UIImagePickerControllerReferenceURL]);
        
        [assetLibrary assetForURL:(NSURL *)[info valueForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
            
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            
            NSString *mediaFile = [self filePath:[NSString stringWithFormat:@"%@.tmp", rep.filename]];
            
            NSLog(@"%@", mediaFile);
            
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
            
            
            NSString *cachePath = [metadata cachePath:NO];
            
            if ([fileManager moveItemAtPath:mediaFile toPath:cachePath error:nil]) {
                
                [self uploadRequestWithFilePath:metadata];
            }
            
        } failureBlock:^(NSError *err) {
            
            NSLog(@"Error: %@",[err localizedDescription]);
            
            return;
        }];
        
    }else if ([mediaType isEqualToString:@"public.media"]) {
        
        NSURL *url = [info valueForKey:UIImagePickerControllerMediaURL];
        [self uploadRequestWithURL:url];
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

#pragma mark - ReceiveRequestDelegate <NSObject>

- (void)receiveRequestWithString:(NSString *)string {
    
    NSString *urlString = [NSString stringWithFormat:@"http://rest.sinaapp.com/api/get&code=%@", string];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    [_request clearDelegatesAndCancel];
    self.request = [ASIHTTPRequest requestWithURL:url];
    [_request setDelegate:self];
    [_request startAsynchronous];
}

- (void)uploadRequestWithFilePath:(WaveTransMetadata *)metadata {
    
    NSURL *url = [NSURL URLWithString:@"http://rest.sinaapp.com/api/post"];
    
    [_request clearDelegatesAndCancel];

    self.request = [ASIFormDataRequest requestWithURL:url];
    
    [_request setDelegate:self];
    [_request setRequestMethod:@"POST"];
    
    [_request addFile:[metadata cachePath:NO] forKey:@"file"];
    [_request addPostValue:metadata.type forKey:@"type"];
    
    [_request startAsynchronous];
}

- (void)uploadRequestWithURL:(NSURL *)url {
    
    /*
    NSString *urlString = [NSString stringWithFormat:@"http://rest.sinaapp.com/api/post&type=file"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    [_request clearDelegatesAndCancel];
    [_request appendPostDataFromFile:string];
    [_request setRequestMethod:@"POST"];
    self.request = [ASIFormDataRequest requestWithURL:url];
    [_request setDelegate:self];
    [_request startAsynchronous];
     */
}

#pragma mark - ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request {
    
    if ([request responseStatusCode] != 200) {
        
        NSLog(@"Error: listen error!");
        
    }else {
        
        NSDictionary *dict = [[request responseString] JSONValue];
        
        if ([dict isKindOfClass:[NSDictionary class]]) {
            
            WaveTransMetadata *metadataReceive = [[WaveTransMetadata alloc] initWithDictionary:dict];
            
            NSLog(@"%@", metadataReceive.code);
            NSLog(@"%@", metadataReceive.sha1);
            NSLog(@"%@", metadataReceive.type);
            NSLog(@"%@", metadataReceive.ctime);
            NSLog(@"%@", metadataReceive.content);
            NSLog(@"%@", metadataReceive.size);
            
        }else {
            
            NSLog(@"Error: return format error!");
        }
    }
    
    [[AppDelegate sharedAppDelegate] setListenning:YES];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    
    [[AppDelegate sharedAppDelegate] setListenning:YES];
    NSError *error = [request error];
    NSLog(@"%@", error);
}

@end
