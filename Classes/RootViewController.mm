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
#import "MetadataReceive.h"
#import "VdiskJSON.h"
#import "ASIFormDataRequest.h"
#import "AppDelegate.h"

@interface RootViewController () <ASIHTTPRequestDelegate, ASIProgressDelegate, AVAudioPlayerDelegate, ReceiveRequestDelegate> {

}

@property (nonatomic, retain) ASIFormDataRequest *request;
@property (nonatomic,retain) AVAudioPlayer *audioPlayer;
@property (nonatomic, retain) NSData *pcmData;

@end

@implementation RootViewController

@synthesize audioPlayer = _audioPlayer;
@synthesize pcmData = _pcmData;
@synthesize request = _request;

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
    [albumButton addTarget:self action:@selector(openAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
    
    self.pcmData = [[[NSData alloc] init] autorelease];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


#pragma mark - ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request {
    
    if ([request responseStatusCode] != 200) {
        
        NSLog(@"Error: listen error!");
        
    }else {
        
        NSDictionary *dict = [[request responseString] JSONValue];
        
        if ([dict isKindOfClass:[NSDictionary class]]) {
            
            MetadataReceive *metadataReceive = [[MetadataReceive alloc] initWithDictionary:dict];
            
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
