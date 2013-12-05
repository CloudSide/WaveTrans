/*
 
     File: aurioTouchAppDelegate.mm
 Abstract: n/a
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 
 */

#import "AppDelegate.h"
#import "AudioUnit/AudioUnit.h"
#import "CAXException.h"
#import "RootViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WaveTransMetadata.h"

#import "MainViewController.h"
#import "PCMRender.h"

@implementation AppDelegate

// value, a, r, g, b
GLfloat colorLevels[] = {
    0., 1., 0., 0., 0., 
    .333, 1., .7, 0., 0., 
    .667, 1., 0., 0., 1., 
    1., 1., 0., 1., 1., 
};

@synthesize window;
@synthesize view;

@synthesize rioUnit;
@synthesize unitIsRunning;
@synthesize unitHasBeenCreated;
@synthesize displayMode;
@synthesize fftBufferManager;
@synthesize mute;
@synthesize inputProc;
@synthesize interruption;

@synthesize getWaveTransMetadataDelegate = _getWaveTransMetadataDelegate;

#pragma mark-

CGPathRef CreateRoundedRectPath(CGRect RECT, CGFloat cornerRadius)
{
	CGMutablePathRef		path;
	path = CGPathCreateMutable();
	
	double		maxRad = MAX(CGRectGetHeight(RECT) / 2., CGRectGetWidth(RECT) / 2.);
	
	if (cornerRadius > maxRad) cornerRadius = maxRad;
	
	CGPoint		bl, tl, tr, br;
	
	bl = tl = tr = br = RECT.origin;
	tl.y += RECT.size.height;
	tr.y += RECT.size.height;
	tr.x += RECT.size.width;
	br.x += RECT.size.width;
	
	CGPathMoveToPoint(path, NULL, bl.x + cornerRadius, bl.y);
	CGPathAddArcToPoint(path, NULL, bl.x, bl.y, bl.x, bl.y + cornerRadius, cornerRadius);
	CGPathAddLineToPoint(path, NULL, tl.x, tl.y - cornerRadius);
	CGPathAddArcToPoint(path, NULL, tl.x, tl.y, tl.x + cornerRadius, tl.y, cornerRadius);
	CGPathAddLineToPoint(path, NULL, tr.x - cornerRadius, tr.y);
	CGPathAddArcToPoint(path, NULL, tr.x, tr.y, tr.x, tr.y - cornerRadius, cornerRadius);
	CGPathAddLineToPoint(path, NULL, br.x, br.y + cornerRadius);
	CGPathAddArcToPoint(path, NULL, br.x, br.y, br.x - cornerRadius, br.y, cornerRadius);
	
	CGPathCloseSubpath(path);
	
	CGPathRef				ret;
	ret = CGPathCreateCopy(path);
	CGPathRelease(path);
	return ret;
}

void cycleOscilloscopeLines()
{
	// Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
	int drawBuffer_i;
	for (drawBuffer_i=(kNumDrawBuffers - 2); drawBuffer_i>=0; drawBuffer_i--)
		memmove(drawBuffers[drawBuffer_i + 1], drawBuffers[drawBuffer_i], drawBufferLen);
}

#pragma mark -Audio Session Interruption Listener

void rioInterruptionListener(void *inClientData, UInt32 inInterruption)
{
    try {
        printf("Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
        
        AppDelegate *THIS = (AppDelegate *)inClientData;
        
        if (inInterruption == kAudioSessionEndInterruption) {
            // make sure we are again the active session
            XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active");
            XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
            
            THIS->interruption = NO;
        }
        
        if (inInterruption == kAudioSessionBeginInterruption) {
            
            THIS->interruption = YES;
            
            XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
        }
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
}

#pragma mark -Audio Session Property Listener

void propListener(	void *                  inClientData,
                  AudioSessionPropertyID	inID,
                  UInt32                  inDataSize,
                  const void *            inData)
{
	AppDelegate *THIS = (AppDelegate*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		try {
            UInt32 isAudioInputAvailable; 
            UInt32 size = sizeof(isAudioInputAvailable);
            XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &isAudioInputAvailable), "couldn't get AudioSession AudioInputAvailable property value");
            
            if(THIS->unitIsRunning && !isAudioInputAvailable)
            {
                XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
                THIS->unitIsRunning = false;
            }
            
            else if(!THIS->unitIsRunning && isAudioInputAvailable)
            {
                XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
                
                if (!THIS->unitHasBeenCreated)	// the rio unit is being created for the first time
                {
                    XThrowIfError(SetupRemoteIO(THIS->rioUnit, THIS->inputProc, THIS->thruFormat), "couldn't setup remote i/o unit");
                    THIS->unitHasBeenCreated = true;
                    
                    THIS->dcFilter = new DCRejectionFilter[THIS->thruFormat.NumberChannels()];
                    
                    UInt32 maxFPS;
                    size = sizeof(maxFPS);
                    XThrowIfError(AudioUnitGetProperty(THIS->rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
                    
                    THIS->fftBufferManager = new FFTBufferManager(maxFPS);
                    THIS->l_fftData = new int32_t[maxFPS/2];
                    
                    THIS->oscilLine = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
                }
                
                XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
                THIS->unitIsRunning = true;
            }
            
			// we need to rescale the sonogram view's color thresholds for different input
			CFStringRef newRoute;
			size = sizeof(CFStringRef);
			XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute), "couldn't get new audio route");
			if (newRoute)
			{	
				CFShow(newRoute);
				if (CFStringCompare(newRoute, CFSTR("Headset"), NULL) == kCFCompareEqualTo) // headset plugged in
				{
					colorLevels[0] = .3;				
					colorLevels[5] = .5;
				}
				else if (CFStringCompare(newRoute, CFSTR("Receiver"), NULL) == kCFCompareEqualTo) // headset plugged in
				{
					colorLevels[0] = 0;
					colorLevels[5] = .333;
					colorLevels[10] = .667;
					colorLevels[15] = 1.0;
					
				}			
				else
				{
					colorLevels[0] = 0;
					colorLevels[5] = .333;
					colorLevels[10] = .667;
					colorLevels[15] = 1.0;
					
				}
			}
		} catch (CAXException e) {
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
		
	}
}

#pragma mark -RIO Render Callback

static OSStatus	PerformThru(
							void						*inRefCon, 
							AudioUnitRenderActionFlags 	*ioActionFlags, 
							const AudioTimeStamp 		*inTimeStamp, 
							UInt32 						inBusNumber, 
							UInt32 						inNumberFrames, 
							AudioBufferList 			*ioData)
{
	AppDelegate *THIS = (AppDelegate *)inRefCon;
	OSStatus err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) { printf("PerformThru: error %d\n", (int)err); return err; }
	
	// Remove DC component
	for(UInt32 i = 0; i < ioData->mNumberBuffers; ++i)
		THIS->dcFilter[i].InplaceFilter((Float32*)(ioData->mBuffers[i].mData), inNumberFrames);
	
	if (THIS->displayMode == aurioTouchDisplayModeOscilloscopeWaveform)
	{
		// The draw buffer is used to hold a copy of the most recent PCM data to be drawn on the oscilloscope
		if (drawBufferLen != drawBufferLen_alloced)
		{
			int drawBuffer_i;
			
			// Allocate our draw buffer if needed
			if (drawBufferLen_alloced == 0)
				for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
					drawBuffers[drawBuffer_i] = NULL;
			
			// Fill the first element in the draw buffer with PCM data
			for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
			{
				drawBuffers[drawBuffer_i] = (SInt8 *)realloc(drawBuffers[drawBuffer_i], drawBufferLen);
				bzero(drawBuffers[drawBuffer_i], drawBufferLen);
			}
			
			drawBufferLen_alloced = drawBufferLen;
		}
		
		int i;
		
        //Convert the floating point audio data to integer (Q7.24)
        err = AudioConverterConvertComplexBuffer(THIS->audioConverter, inNumberFrames, ioData, THIS->drawABL);
        if (err) { printf("AudioConverterConvertComplexBuffer: error %d\n", (int)err); return err; }
        
		SInt8 *data_ptr = (SInt8 *)(THIS->drawABL->mBuffers[0].mData);
		for (i=0; i<inNumberFrames; i++)
		{
			if ((i+drawBufferIdx) >= drawBufferLen)
			{
				cycleOscilloscopeLines();
				drawBufferIdx = -i;
			}
			drawBuffers[0][i + drawBufferIdx] = data_ptr[2];
			data_ptr += 4;
		}
		drawBufferIdx += inNumberFrames;
        
        if (THIS->fftBufferManager == NULL) return noErr;
		
		if (THIS->fftBufferManager->NeedsNewAudioData())
			THIS->fftBufferManager->GrabAudioData(ioData);
	}
	
	else if ((THIS->displayMode == aurioTouchDisplayModeSpectrum) || (THIS->displayMode == aurioTouchDisplayModeOscilloscopeFFT))
	{
		if (THIS->fftBufferManager == NULL) return noErr;
		
		if (THIS->fftBufferManager->NeedsNewAudioData())
			THIS->fftBufferManager->GrabAudioData(ioData); 
	}
	if (THIS->mute == YES) { SilenceData(ioData); }
	
	return err;
}

#pragma mark-

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    [self __applicationDidFinishLaunching:application];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)setupListening {

    
	CFURLRef url = NULL;
	try {
        //		url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFStringRef([[NSBundle mainBundle] pathForResource:@"button_press" ofType:@"caf"]), kCFURLPOSIXPathStyle, false);
        //		XThrowIfError(AudioServicesCreateSystemSoundID(url, &buttonPressSound), "couldn't create button tap alert sound");
        //		CFRelease(url);
		
		// Initialize and configure the audio session
		XThrowIfError(AudioSessionInitialize(NULL, NULL, rioInterruptionListener, self), "couldn't initialize audio session");
        self.interruption = NO;
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set audio category");
		XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self), "couldn't set property listener");
        
		//Float32 preferredBufferSize = .0872;
        Float32 preferredBufferSize = .0873;
        
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "couldn't set i/o buffer duration");
		
		UInt32 size = sizeof(hwSampleRate);
		XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get hw sample rate");
		
		XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
        
		XThrowIfError(SetupRemoteIO(rioUnit, inputProc, thruFormat), "couldn't setup remote i/o unit");
		unitHasBeenCreated = true;
        
        drawFormat.SetAUCanonical(2, false);
        drawFormat.mSampleRate = 44100;
        
        XThrowIfError(AudioConverterNew(&thruFormat, &drawFormat, &audioConverter), "couldn't setup AudioConverter");
		
		dcFilter = new DCRejectionFilter[thruFormat.NumberChannels()];
        
		UInt32 maxFPS;
		size = sizeof(maxFPS);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
		
		fftBufferManager = new FFTBufferManager(maxFPS);
		l_fftData = new int32_t[maxFPS/2];
        
        drawABL = (AudioBufferList*) malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer));
        drawABL->mNumberBuffers = 2;
        for (UInt32 i=0; i<drawABL->mNumberBuffers; ++i)
        {
            drawABL->mBuffers[i].mData = (SInt32*) calloc(maxFPS, sizeof(SInt32));
            drawABL->mBuffers[i].mDataByteSize = maxFPS * sizeof(SInt32);
            drawABL->mBuffers[i].mNumberChannels = 1;
        }
		
		oscilLine = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
        
		XThrowIfError(AudioOutputUnitStart(rioUnit), "couldn't start remote i/o unit");
        
		size = sizeof(thruFormat);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &thruFormat, &size), "couldn't get the remote I/O unit's output client format");
		
		unitIsRunning = 1;
	}
	catch (CAXException &e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		unitIsRunning = 0;
		if (dcFilter) delete[] dcFilter;
        if (drawABL)
        {
            for (UInt32 i=0; i<drawABL->mNumberBuffers; ++i)
                free(drawABL->mBuffers[i].mData);
            free(drawABL);
            drawABL = NULL;
        }
		if (url) CFRelease(url);
	}
	catch (...) {
		fprintf(stderr, "An unknown error occurred\n");
		unitIsRunning = 0;
		if (dcFilter) delete[] dcFilter;
        if (drawABL)
        {
            for (UInt32 i=0; i<drawABL->mNumberBuffers; ++i)
                free(drawABL->mBuffers[i].mData);
            free(drawABL);
            drawABL = NULL;
        }
		if (url) CFRelease(url);
	}
}


- (void)__applicationDidFinishLaunching:(UIApplication *)application
{
    
    self.view = [[[EAGLView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 64.0)] autorelease];
    
//    RootViewController *rootViewController = [[[RootViewController alloc] init] autorelease];
//    self.window.rootViewController = rootViewController;
//    [rootViewController.view setBackgroundColor:[UIColor clearColor]];
//    [rootViewController.view addSubview:self.view];
    
    MainViewController *mMainViewController = [[[MainViewController alloc] init] autorelease];
    self.window.rootViewController = mMainViewController;
    
    _isListenning = YES;
    
#ifdef __IPHONE_8_0
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            
            if (!granted) {
            
                UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"没有开启麦克风" message:@"请到[设置]->[隐私]->[麦克风]中开启" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] autorelease];
                [alertView show];
            }
            
        }];
    }
#endif

	// Turn off the idle timer, since this app doesn't rely on constant touch input
	application.idleTimerDisabled = YES;
	
	// mute should be on at launch
	self.mute = YES;
	displayMode = aurioTouchDisplayModeOscilloscopeWaveform;
	
	// Initialize our remote i/o unit
	
	inputProc.inputProc = PerformThru;
	inputProc.inputProcRefCon = self;
    
    
    
    ////////
    [self setupListening];
    ////////
    
    
	
	// Set ourself as the delegate for the EAGLView so that we get drawing and touch events
	view.delegate = self;
	
	// Enable multi touch so we can handle pinch and zoom in the oscilloscope
	view.multipleTouchEnabled = YES;
	
    
	// Set up our overlay view that pops up when we are pinching/zooming the oscilloscope
	UIImage *img_ui = nil;
	{
		// Draw the rounded rect for the bg path using this convenience function
		CGPathRef bgPath = CreateRoundedRectPath(CGRectMake(0, 0, 110, 234), 15.);
		
		CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
		// Create the bitmap context into which we will draw
		CGContextRef cxt = CGBitmapContextCreate(NULL, 110, 234, 8, 4*110, cs, kCGImageAlphaPremultipliedFirst);
		CGContextSetFillColorSpace(cxt, cs);
		CGFloat fillClr[] = {0., 0., 0., 0.7};
		CGContextSetFillColor(cxt, fillClr);
		// Add the rounded rect to the context...
		CGContextAddPath(cxt, bgPath);
		// ... and fill it.
		CGContextFillPath(cxt);
		
		// Make a CGImage out of the context
		CGImageRef img_cg = CGBitmapContextCreateImage(cxt);
		// Make a UIImage out of the CGImage
		img_ui = [UIImage imageWithCGImage:img_cg];
		
		// Clean up
		CGImageRelease(img_cg);
		CGColorSpaceRelease(cs);
		CGContextRelease(cxt);
		CGPathRelease(bgPath);
	}
	
	// Create the image view to hold the background rounded rect which we just drew
	sampleSizeOverlay = [[UIImageView alloc] initWithImage:img_ui];
	sampleSizeOverlay.frame = CGRectMake(190, 124, 110, 234);
	
	// Create the text view which shows the size of our oscilloscope window as we pinch/zoom
	sampleSizeText = [[UILabel alloc] initWithFrame:CGRectMake(-62, 0, 234, 234)];
	sampleSizeText.textAlignment = NSTextAlignmentCenter;
	sampleSizeText.textColor = [UIColor whiteColor];
	sampleSizeText.text = @"0000 ms";
	sampleSizeText.font = [UIFont boldSystemFontOfSize:36.];
	// Rotate the text view since we want the text to draw top to bottom (when the device is oriented vertically)
	sampleSizeText.transform = CGAffineTransformMakeRotation(M_PI_2);
	sampleSizeText.backgroundColor = [UIColor clearColor];
	
	// Add the text view as a subview of the overlay BG
	[sampleSizeOverlay addSubview:sampleSizeText];
	// Text view was retained by the above line, so we can release it now
	[sampleSizeText release];
	
	// We don't add sampleSizeOverlay to our main view yet. We just hang on to it for now, and add it when we
	// need to display it, i.e. when a user starts a pinch/zoom.
	
	// Set up the view to refresh at 20 hz
	[view setAnimationInterval:1./20.];
	[view startAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	//start animation now that we're in the foreground
    view.applicationResignedActive = NO;
	[view startAnimation];
	AudioSessionSetActive(true);
}

- (void)applicationWillResignActive:(UIApplication *)application {
	//stop animation before going into background
    view.applicationResignedActive = YES;
    [view stopAnimation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSString *scheme = [url scheme];
    //NSString *host = [url host];
    //NSString *query = [url query];
    //NSDictionary *params = [self parseQueryString:query];
    
    if([scheme caseInsensitiveCompare:[NSString stringWithFormat:@"sinaweibosso.%@", kWeiboAppKey]] == NSOrderedSame || [scheme caseInsensitiveCompare:[NSString stringWithFormat:@"sinavdsiksso.%@", kWeiboAppKey]] == NSOrderedSame) {
        
        [[VdiskSession sharedSession].sinaWeibo handleOpenURL:url];
        
    }
    
    return YES;
}


- (void)dealloc
{	
	delete[] dcFilter;
	delete fftBufferManager;
    if (drawABL)
    {
        for (UInt32 i=0; i<drawABL->mNumberBuffers; ++i)
            free(drawABL->mBuffers[i].mData);
        free(drawABL);
        drawABL = NULL;
    }
	[view release];
	[window release];
	
	free(oscilLine);
    
    _getWaveTransMetadataDelegate = nil;
    
	[super dealloc];
}


- (void)setFFTData:(int32_t *)FFTDATA length:(NSUInteger)LENGTH
{
	if (LENGTH != fftLength)
	{
		fftLength = LENGTH;
		fftData = (SInt32 *)(realloc(fftData, LENGTH * sizeof(SInt32)));
	}
	memmove(fftData, FFTDATA, fftLength * sizeof(Float32));
	hasNewFFTData = YES;
}


- (void)createGLTexture:(GLuint *)texName fromCGImage:(CGImageRef)img
{
	GLubyte *spriteData = NULL;
	CGContextRef spriteContext;
	GLuint imgW, imgH, texW, texH;
	
	imgW = CGImageGetWidth(img);
	imgH = CGImageGetHeight(img);
	
	// Find smallest possible powers of 2 for our texture dimensions
	for (texW = 1; texW < imgW; texW *= 2) ;
	for (texH = 1; texH < imgH; texH *= 2) ;
	
	// Allocated memory needed for the bitmap context
	spriteData = (GLubyte *) calloc(texH, texW * 4);
	// Uses the bitmatp creation function provided by the Core Graphics framework. 
	spriteContext = CGBitmapContextCreate(spriteData, texW, texH, 8, texW * 4, CGImageGetColorSpace(img), kCGImageAlphaPremultipliedLast);
	
	// Translate and scale the context to draw the image upside-down (conflict in flipped-ness between GL textures and CG contexts)
	CGContextTranslateCTM(spriteContext, 0., texH);
	CGContextScaleCTM(spriteContext, 1., -1.);
	
	// After you create the context, you can draw the sprite image to the context.
	CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, imgW, imgH), img);
	// You don't need the context at this point, so you need to release it to avoid memory leaks.
	CGContextRelease(spriteContext);
	
	// Use OpenGL ES to generate a name for the texture.
	glGenTextures(1, texName);
	// Bind the texture name. 
	glBindTexture(GL_TEXTURE_2D, *texName);
	// Speidfy a 2D texture image, provideing the a pointer to the image data in memory
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texW, texH, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
	// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	
	// Enable use of the texture
	glEnable(GL_TEXTURE_2D);
	// Set a blending function to use
	glBlendFunc(GL_SRC_ALPHA,GL_ONE);
	//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	// Enable blending
	glEnable(GL_BLEND);
	
	free(spriteData);
}


- (void)setupViewForOscilloscope
{
    // 下面这些图被删了，所以log会报一堆错
    
    
	CGImageRef img;
	
	// Load our GL textures
	
	img = [UIImage imageNamed:@"top_gb.png"].CGImage;
	[self createGLTexture:&bgTexture fromCGImage:img];
    
	/*
	img = [UIImage imageNamed:@"fft_off.png"].CGImage;
	[self createGLTexture:&fftOffTexture fromCGImage:img];
	
	img = [UIImage imageNamed:@"fft_on.png"].CGImage;
	[self createGLTexture:&fftOnTexture fromCGImage:img];
	
	img = [UIImage imageNamed:@"mute_off.png"].CGImage;
	[self createGLTexture:&muteOffTexture fromCGImage:img];
	
	img = [UIImage imageNamed:@"mute_on.png"].CGImage;
	[self createGLTexture:&muteOnTexture fromCGImage:img];
    
	img = [UIImage imageNamed:@"sonogram.png"].CGImage;
	[self createGLTexture:&sonoTexture fromCGImage:img];
     */
    
	initted_oscilloscope = YES;
}


- (void)clearTextures
{
	bzero(texBitBuffer, sizeof(UInt32) * 512);
	SpectrumLinkedTexture *curTex;
	
	for (curTex = firstTex; curTex; curTex = curTex->nextTex)
	{
		glBindTexture(GL_TEXTURE_2D, curTex->texName);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBitBuffer);
	}
}


- (void)setupViewForSpectrum
{
	glClearColor(0., 0., 0., 0.);
	
	spectrumRect = CGRectMake(10., 10., 460., 300.);
	
	// The bit buffer for the texture needs to be 512 pixels, because OpenGL textures are powers of 
	// two in either dimensions. Our texture is drawing a strip of 300 vertical pixels on the screen, 
	// so we need to step up to 512 (the nearest power of 2 greater than 300).
	texBitBuffer = (UInt32 *)(malloc(sizeof(UInt32) * 512));
	
	// Clears the view with black
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);	
	
	NSUInteger texCount = ceil(CGRectGetWidth(spectrumRect) / (CGFloat)SPECTRUM_BAR_WIDTH);
	GLuint *texNames;
	
	texNames = (GLuint *)(malloc(sizeof(GLuint) * texCount));
	glGenTextures(texCount, texNames);
	
	int i;
	SpectrumLinkedTexture *curTex = NULL;
	firstTex = (SpectrumLinkedTexture *)(calloc(1, sizeof(SpectrumLinkedTexture)));
	firstTex->texName = texNames[0];
	curTex = firstTex;
	
	bzero(texBitBuffer, sizeof(UInt32) * 512);
	
	glBindTexture(GL_TEXTURE_2D, curTex->texName);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	
	for (i=1; i<texCount; i++)
	{
		curTex->nextTex = (SpectrumLinkedTexture *)(calloc(1, sizeof(SpectrumLinkedTexture)));
		curTex = curTex->nextTex;
		curTex->texName = texNames[i];
		
		glBindTexture(GL_TEXTURE_2D, curTex->texName);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	}
	
	// Enable use of the texture
	glEnable(GL_TEXTURE_2D);
	// Set a blending function to use
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	// Enable blending
	glEnable(GL_BLEND);
	
	initted_spectrum = YES;
	
	free(texNames);
	
}

- (void)computeWave {

    if (_isListenning == YES && fftBufferManager->HasNewAudioData()) {
        
        if (fftBufferManager->ComputeFFT(l_fftData)) {
            
            [self setFFTData:l_fftData length:fftBufferManager->GetNumberFrames() / 2];
            
            int i;
            for (i=0; i<32; i++) {
                
                unsigned int freq;
                int fftIdx;
                
                num_to_freq(i, &freq);
                fftIdx = freq / (drawFormat.mSampleRate / 2.0) * fftLength;
                
                double fftIdx_i, fftIdx_f;
                fftIdx_f = modf(fftIdx, &fftIdx_i);
                
                SInt8 fft_l, fft_r;
                CGFloat fft_l_fl, fft_r_fl;
                CGFloat interpVal;
                
                fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
                fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
                fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
                fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
                interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
                
                interpVal = sqrt(CLAMP(0., interpVal, 1.));
                
                //////////////////////////////////////////////////////////////////
                //////////////////////////////////////////////////////////////////
                //////////////////////////////////////////////////////////////////
                [self helper:fftIdx interpVal:interpVal timeSlice:6];///////////
                //////////////////////////////////////////////////////////////////
                //////////////////////////////////////////////////////////////////
                
            }
            
            //////////////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////////////
            [self helperResultWithTimeSlice:6];///////////////////////////////
            //////////////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////////////
        }
        else
            hasNewFFTData = NO;
    }
}


- (void)drawOscilloscope
{
	// Clear the view
	glClear(GL_COLOR_BUFFER_BIT);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	
	glColor4f(1., 1., 1., 1.);
	
	glPushMatrix();
	
	glTranslatef(0., 0., 0.);
	glRotatef(0., 0., 0., 1.);
	
	
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
    
	{
		// Draw our background oscilloscope screen
		const GLfloat vertices[] = {
			0., 0.,
			512., 0.,
			0.,  64.,
			512.,  64.,
		};
		const GLshort texCoords[] = {
			0, 0,
			1, 0,
			0, 1,
			1, 1,
		};
		
		
		glBindTexture(GL_TEXTURE_2D, bgTexture);
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_SHORT, 0, texCoords);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	/*
	{
		// Draw our buttons
		const GLfloat vertices[] = {
			0., 0.,
			112, 0., 
			0.,  64,
			112,  64,
		};
		const GLshort texCoords[] = {
			0, 0,
			1, 0,
			0, 1,
			1, 1,
		};
		
		glPushMatrix();
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_SHORT, 0, texCoords);
        
		glTranslatef(5, 0, 0);
		glBindTexture(GL_TEXTURE_2D, sonoTexture);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glTranslatef(99, 0, 0);
		glBindTexture(GL_TEXTURE_2D, mute ? muteOnTexture : muteOffTexture);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glTranslatef(99, 0, 0);
		glBindTexture(GL_TEXTURE_2D, (displayMode == aurioTouchDisplayModeOscilloscopeFFT) ? fftOnTexture : fftOffTexture);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glPopMatrix();
		
	}
	*/
	
	
//	if (displayMode == aurioTouchDisplayModeOscilloscopeFFT)
//	{			
		
        
//		if (hasNewFFTData)
//		{
//            
//			int y, maxY;
//			maxY = drawBufferLen;
//			for (y=0; y<maxY; y++)
//			{
//				CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
//				CGFloat fftIdx = yFract * ((CGFloat)fftLength);
//				
//				double fftIdx_i, fftIdx_f;
//				fftIdx_f = modf(fftIdx, &fftIdx_i);
//				
//				SInt8 fft_l, fft_r;
//				CGFloat fft_l_fl, fft_r_fl;
//				CGFloat interpVal;
//				
//				fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
//				fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
//				fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
//				fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
//				interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
//				
//				interpVal = CLAMP(0., interpVal, 1.);
//                
//				drawBuffers[0][y] = (interpVal * 120);
//				
//			}
//			cycleOscilloscopeLines();
//			
//		}
//		
//	}
	
	
    [self computeWave];
    
	
	GLfloat *oscilLine_ptr;
	GLfloat max = drawBufferLen / 4 * self.view.frame.size.width / 320;
	SInt8 *drawBuffer_ptr;
	
	// Alloc an array for our oscilloscope line vertices
	if (resetOscilLine) {
		oscilLine = (GLfloat*)realloc(oscilLine, drawBufferLen * 2 * sizeof(GLfloat) / 4 * self.view.frame.size.width / 320);
		resetOscilLine = NO;
	}
	
	glPushMatrix();
	
	// Translate to the left side and vertical center of the screen, and scale so that the screen coordinates
	// go from 0 to 1 along the X, and -1 to 1 along the Y
	glTranslatef(0., self.view.frame.size.height / 2.0, 0.);
	//glScalef(self.view.frame.size.width - 48., self.view.frame.size.height, 1.);
	glScalef(self.view.frame.size.width - 88., self.view.frame.size.height, 1.);
	
	// Set up some GL state for our oscilloscope lines
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisable(GL_LINE_SMOOTH);
	glLineWidth(2.);
	
	int drawBuffer_i;
	// Draw a line for each stored line in our buffer (the lines are stored and fade over time)
	for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
	{
		if (!drawBuffers[drawBuffer_i]) continue;
		
		oscilLine_ptr = oscilLine;
		drawBuffer_ptr = drawBuffers[drawBuffer_i];
		
		GLfloat i;
		// Fill our vertex array with points
		for (i=0.; i<max; i=i+1.)
		{
			*oscilLine_ptr++ = i/max;
            
            /*
            if (abs((int)(*drawBuffer_ptr)) < self.view.frame.size.height / 3.0) {
                
                *oscilLine_ptr++ = (Float32)(*drawBuffer_ptr) / 64.;
                
            } else {
                
                *oscilLine_ptr++ = (Float32)(*drawBuffer_ptr) / 256.;
            }
             */
            
            *oscilLine_ptr++ = (Float32)(*drawBuffer_ptr) / 128.;
            //NSLog(@"%f", (Float32)(*drawBuffer_ptr));
            
            drawBuffer_ptr += 4;
		}
		
		// If we're drawing the newest line, draw it in solid green. Otherwise, draw it in a faded green.
        
        if ([PCMRender isHighFreq]) {
            
            if (drawBuffer_i == 0)
                glColor4f(1., 0., 0., 1.);
            else
                glColor4f(1., 0., 0., (.24 * (1. - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers))));
            
        } else {
        
            if (drawBuffer_i == 0)
                glColor4f(.8, .8, .8, 1.);
            else
                glColor4f(.8, .8, .8, (.24 * (1. - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers))));
        }
        
		
		
		// Set up vertex pointer,
		glVertexPointer(2, GL_FLOAT, 0, oscilLine);
		
		// and draw the line.
		glDrawArrays(GL_LINE_STRIP, 0, drawBufferLen / 4 * self.view.frame.size.width / 320);
		
	}
	
	glPopMatrix();
    
	glPopMatrix();
}


- (void)cycleSpectrum
{
	SpectrumLinkedTexture *newFirst;
	newFirst = (SpectrumLinkedTexture *)calloc(1, sizeof(SpectrumLinkedTexture));
	newFirst->nextTex = firstTex;
	firstTex = newFirst;
	
	SpectrumLinkedTexture *thisTex = firstTex;
	do {
		if (!(thisTex->nextTex->nextTex))
		{
			firstTex->texName = thisTex->nextTex->texName;
			free(thisTex->nextTex);
			thisTex->nextTex = NULL;
		} 
		thisTex = thisTex->nextTex;
	} while (thisTex);
}


static queue   _savedBuffer[32];
//static int     _indexBufferX;

- (void)setupQueue {

    static BOOL flag = NO;
    
    if (!flag) {
        
        for (int i=0; i<32; i++) {
            
            queue q;
            _savedBuffer[i] = q;
            init_queue(&_savedBuffer[i], 20);
        }
     
        flag = YES;
    }
}


- (void)helper:(double)fftIdx_i interpVal:(CGFloat)interpVal timeSlice:(int)length {

    [self setupQueue];
    
    float fff = (drawFormat.mSampleRate / 2.0) * (int)fftIdx_i / (fftLength);
    
    int code = -1;
    
    if (freq_to_num(fff, &code) == 0 && code >= 0 && code < 32) {
        
        //enqueue_adv(&_savedBuffer[code], interpVal);
        
        enqueue(&_savedBuffer[code], interpVal);
        
        //NSLog(@"%d", code);
    }
}

//static int maxTable[100][32] ={0};

- (void)helperResultWithTimeSlice:(int)length {
    
    queue *q17 = &_savedBuffer[17];
    queue *q19 = &_savedBuffer[19];
    
    if (queue_item_at_index(q17, 0) > 0.0 &&
        queue_item_at_index(q17, 1) > 0.0 &&
        queue_item_at_index(q19, 1) > 0.0 &&
        queue_item_at_index(q19, 2) > 0.0) {
        
        
        float minValue = fmin(queue_item_at_index(q17, 2), queue_item_at_index(q19, 3));
        minValue = fmax(minValue, queue_item_at_index(q17, 0) * 0.7);
        
//        float minValue_17 = fmin(queue_item_at_index(q17, 0), queue_item_at_index(q17, 1));
//        float minValue_19 = fmin(queue_item_at_index(q19, 1), queue_item_at_index(q19, 2));
//        
//        minValue = fmin(minValue_17,minValue_19) * 0.75;
        
        
        float maxValue = fmax(queue_item_at_index(q17, 0), queue_item_at_index(q19, 1)) * 1.85;
        
//        minValue = 0.0;
//        maxValue = 1.0;
        

        int res[20];
        int rrr[20];
        generate_data(_savedBuffer, 32, res, rrr, 20, minValue, maxValue);
        
        /*
        if (res[0] != 17 || res[1] != 19) {
            return;
        }else {
            _isListenning = NO;
        }
         */
        
        printf("\n================= start:(19[0]=%f), (17[2]=%f), (19[3]=%f), (17[0]*0.7=%f), (minValue=%f) ==================\n\n", queue_item_at_index(q19, 0), queue_item_at_index(q17, 2), queue_item_at_index(q19, 3), queue_item_at_index(q17, 0) * 0.7, minValue);
        
        for (int i=0; i<20; i++) {
            printf("%02d ", res[i]);
        }
        
        for (int i=0; i<10; i++) {
            
            int temp;
            
            temp = rrr[i];
            rrr[i] = rrr[19-i];
            rrr[19-i] = temp;
        }
        
        printf("\n");
        
        for (int i=0; i<20; i++) {
            printf("%02d ", rrr[i]);
        }
        
        printf("\n\n");
        
        
        //////////////  RS
        
        int temp[18];
        int result[18][18];
        int counter = 0;
        
        for (int i=0; i<18; i++) {
            for (int j=0; j<18; j++) {
                
                result[i][j] = -1;
            }
        }
        
        for (int k = 2; k < 20; k++) {
            
            printf("~~~~~~~ %02d :17 19 ", k);
            
            for (int i=2, j=0; i<20; i++, j++) {
                
                if (i <= k) {
                    temp[j] = res[i];
                }else {
                    temp[j] = rrr[i];
                }
                
                printf("%02d ", temp[j]);
            }
            
            printf(" ~~~~~~~ ");
            
            RS *rs = init_rs(RS_SYMSIZE, RS_GFPOLY, RS_FCR, RS_PRIM, RS_NROOTS, RS_PAD);
            int eras_pos[RS_TOTAL_LEN] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            
            unsigned char data1[RS_TOTAL_LEN];
            
            for (int i=0; i<RS_TOTAL_LEN; i++) {
                data1[i] = temp[i];
            }
            
            int count = decode_rs_char(rs, data1, eras_pos, 0);
            
            /////////////////
            
            if (count >= 0) {
                
                for (int m = 0; m<18; m++) {
                    
                    result[m][counter] = data1[m];
                }
                
                counter++;
            }
            
            printf("17 19 ");
            for (int i=0; i<18; i++) {
                printf("%02d ", data1[i]);
            }
            printf("    %d\n", count);
        }
        
        int temp_vote[18] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
        int final_result[20] = {17, 19, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
        
        for (int i=0; i<18; i++) {
            
            for (int j=0; j<18; j++) {
                
                temp_vote[j] = result[i][j];
            }
            
            vote(temp_vote, 18, &final_result[i+2]);
        }
        
        printf("\n ================== final result ================== \n\n");
        
        //printf("17-19-00-30-19-13-05-22-12-10-02-02-27-00-20-08-09-21-26-29-\n");
        
        if (counter == 0) {
            
            printf("fail!");
            
        }else {
            
            NSMutableString *string = [NSMutableString stringWithFormat:@""];
            
            for (int i=0; i<20; i++) {
                
                printf("%02d ", final_result[i]);
                
                if (i>=2 && i<=11) {
                    
                    char res_char;
                    num_to_char(final_result[i], &res_char);
                    
                    [string appendFormat:@"%c", res_char];
                }
                
            }
            
            _isListenning = NO;
            
            //请求
            
            if (self.getWaveTransMetadataDelegate != nil && [self.getWaveTransMetadataDelegate respondsToSelector:@selector(getWaveTransMetadata:)]) {
                
                WaveTransMetadata *metadata = [[[WaveTransMetadata alloc] initWithDictionary:@{@"code":string}] autorelease];
                
                [self.getWaveTransMetadataDelegate getWaveTransMetadata:metadata];
                
            }else {
                
                _isListenning = YES;
            }
        }
        
        /*
        RS *rs = init_rs(RS_SYMSIZE, RS_GFPOLY, RS_FCR, RS_PRIM, RS_NROOTS, RS_PAD);
        int eras_pos[RS_TOTAL_LEN] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        
        unsigned char data1[RS_TOTAL_LEN];
        
        for (int i=0; i<RS_TOTAL_LEN; i++) {
            data1[i] = res[i+2];
        }
        
        int count = decode_rs_char(rs, data1, eras_pos, 0);
        
        /////////////////
        
        printf("17 19 ");
        for (int i=0; i<18; i++) {
            printf("%02d ", data1[i]);
        }
        printf("    %d\n", count);
         */

        /*
        for (int i = 0; i<32; i++) {
            
            for (int k = 0; k<20; k++) {
                
                queue *q = &_savedBuffer[i];
                float currentValue = queue_item_at_index(q, k);
                
                if (currentValue <= minValue || currentValue >= maxValue) {
                    
                    currentValue = 0.0;
                }
                
                printf("%d,%d,%.4f]", i, k, currentValue);
            }
        }
         */
        
        printf("\n\n================  end  ==================\n");
        
        //printf("\n");
    }
}


- (void)renderFFTToTex
{
	[self cycleSpectrum];
	
	UInt32 *texBitBuffer_ptr = texBitBuffer;
	
	static int numLevels = sizeof(colorLevels) / sizeof(GLfloat) / 5;
	
    int i;
    for (i=0; i<32; i++) {
        
        unsigned int freq;
        int fftIdx;
        
        num_to_freq(i, &freq);
        fftIdx = freq / (drawFormat.mSampleRate / 2.0) * fftLength;
        
        double fftIdx_i, fftIdx_f;
		fftIdx_f = modf(fftIdx, &fftIdx_i);
		
		SInt8 fft_l, fft_r;
		CGFloat fft_l_fl, fft_r_fl;
		CGFloat interpVal;
		
		fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
		fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
		fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
		fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
		interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
		
		interpVal = sqrt(CLAMP(0., interpVal, 1.));
        
        //////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////
        [self helper:fftIdx interpVal:interpVal timeSlice:6];///////////
        //////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////
        
    }
    
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    [self helperResultWithTimeSlice:6];///////////////////////////////
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    
    
    
	int y, maxY;
	maxY = CGRectGetHeight(spectrumRect);
	for (y=0; y<maxY; y++)
	{
		CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
		CGFloat fftIdx = yFract * ((CGFloat)fftLength-1);
        
		double fftIdx_i, fftIdx_f;
		fftIdx_f = modf(fftIdx, &fftIdx_i);
		
		SInt8 fft_l, fft_r;
		CGFloat fft_l_fl, fft_r_fl;
		CGFloat interpVal;
		
		fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
		fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
		fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
		fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
		interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
		
		interpVal = sqrt(CLAMP(0., interpVal, 1.));
        
        
		UInt32 newPx = 0xFF000000;
		
		int level_i;
		const GLfloat *thisLevel = colorLevels;
		const GLfloat *nextLevel = colorLevels + 5;
		for (level_i=0; level_i<(numLevels-1); level_i++)
		{
			if ( (*thisLevel <= interpVal) && (*nextLevel >= interpVal) )
			{
				double fract = (interpVal - *thisLevel) / (*nextLevel - *thisLevel);
				newPx = 
				((UInt8)(255. * linearInterp(thisLevel[1], nextLevel[1], fract)) << 24)
				|
				((UInt8)(255. * linearInterp(thisLevel[2], nextLevel[2], fract)) << 16)
				|
				((UInt8)(255. * linearInterp(thisLevel[3], nextLevel[3], fract)) << 8)
				|
				(UInt8)(255. * linearInterp(thisLevel[4], nextLevel[4], fract))
				;
				break;
			}
			
			thisLevel+=5;
			nextLevel+=5;
		}
		
		*texBitBuffer_ptr++ = newPx;
	}
    

	glBindTexture(GL_TEXTURE_2D, firstTex->texName);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBitBuffer);
	
	hasNewFFTData = NO;
}



- (void)drawSpectrum
{
	// Clear the view
	glClear(GL_COLOR_BUFFER_BIT);
	
	if (fftBufferManager->HasNewAudioData())
	{
		if (fftBufferManager->ComputeFFT(l_fftData))
		{
			[self setFFTData:l_fftData length:fftBufferManager->GetNumberFrames() / 2];
		}
		else
			hasNewFFTData = NO;
	}
	
	if (hasNewFFTData) [self renderFFTToTex];
	
	glClear(GL_COLOR_BUFFER_BIT);
	
	glEnable(GL_TEXTURE);
	glEnable(GL_TEXTURE_2D);
	
	glPushMatrix();
	glTranslatef(0., 480., 0.);
	glRotatef(-90., 0., 0., 1.);
	glTranslatef(spectrumRect.origin.x + spectrumRect.size.width, spectrumRect.origin.y, 0.);
	
	GLfloat quadCoords[] = {
		0., 0., 
		SPECTRUM_BAR_WIDTH, 0., 
		0., 512., 
		SPECTRUM_BAR_WIDTH, 512., 
	};
	
	GLshort texCoords[] = {
		0, 0, 
		1, 0, 
		0, 1,
		1, 1, 
	};
	
	glVertexPointer(2, GL_FLOAT, 0, quadCoords);
	glEnableClientState(GL_VERTEX_ARRAY);
	glTexCoordPointer(2, GL_SHORT, 0, texCoords);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);	
	
	glColor4f(1., 1., 1., 1.);
	
	SpectrumLinkedTexture *thisTex;
	glPushMatrix();
	for (thisTex = firstTex; thisTex; thisTex = thisTex->nextTex)
	{
		glTranslatef(-(SPECTRUM_BAR_WIDTH), 0., 0.);
		glBindTexture(GL_TEXTURE_2D, thisTex->texName);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	glPopMatrix();
	glPopMatrix();
	
	glFlush();
	
}

- (void)drawView:(id)sender forTime:(NSTimeInterval)time
{
	if ((displayMode == aurioTouchDisplayModeOscilloscopeWaveform) || (displayMode == aurioTouchDisplayModeOscilloscopeFFT))
	{
		if (!initted_oscilloscope) [self setupViewForOscilloscope];
		[self drawOscilloscope];
	} else if (displayMode == aurioTouchDisplayModeSpectrum) {
		if (!initted_spectrum) [self setupViewForSpectrum];
		[self drawSpectrum];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// If we're if waveform mode and not currently in a pinch event, and we've got two touches, start a pinch event
	if ((!pinchEvent) && ([[event allTouches] count] == 2) && (self.displayMode == aurioTouchDisplayModeOscilloscopeWaveform))
	{
        return;
		pinchEvent = event;
		NSArray *t = [[event allTouches] allObjects];
		lastPinchDist = fabs([[t objectAtIndex:0] locationInView:view].x - [[t objectAtIndex:1] locationInView:view].x);
		
		sampleSizeText.text = [NSString stringWithFormat:@"%i ms", drawBufferLen / (int)(hwSampleRate / 1000.)];
		[view addSubview:sampleSizeOverlay];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	// If we are in a pinch event...
	if ((event == pinchEvent) && ([[event allTouches] count] == 2))
	{
        return;
		CGFloat thisPinchDist, pinchDiff;
		NSArray *t = [[event allTouches] allObjects];
		thisPinchDist = fabs([[t objectAtIndex:0] locationInView:view].x - [[t objectAtIndex:1] locationInView:view].x);
		
		// Find out how far we traveled since the last event
		pinchDiff = thisPinchDist - lastPinchDist;
		// Adjust our draw buffer length accordingly,
		drawBufferLen -= 12 * (int)pinchDiff;
		drawBufferLen = CLAMP(kMinDrawSamples, drawBufferLen, kMaxDrawSamples);
		resetOscilLine = YES;
		
		// and display the size of our oscilloscope window in our overlay view
		sampleSizeText.text = [NSString stringWithFormat:@"%i ms", drawBufferLen / (int)(hwSampleRate / 1000.)];
		
		lastPinchDist = thisPinchDist;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (event == pinchEvent)
	{
		// If our pinch/zoom has ended, nil out the pinchEvent and remove the overlay view
		[sampleSizeOverlay removeFromSuperview];
		pinchEvent = nil;
		return;
	}
    
	// any tap in sonogram view will exit back to the waveform
	if (self.displayMode == aurioTouchDisplayModeSpectrum)
	{
		AudioServicesPlaySystemSound(buttonPressSound);
		self.displayMode = aurioTouchDisplayModeOscilloscopeWaveform;
		return;
	}
	
	UITouch *touch = [touches anyObject];
	if (unitIsRunning)
	{
		if (CGRectContainsPoint(CGRectMake(0., 5., 52., 99.), [touch locationInView:view])) // The Sonogram button was touched
		{
			AudioServicesPlaySystemSound(buttonPressSound);
			if ((self.displayMode == aurioTouchDisplayModeOscilloscopeWaveform) || (self.displayMode == aurioTouchDisplayModeOscilloscopeFFT))
			{
				if (!initted_spectrum) [self setupViewForSpectrum];
				[self clearTextures];
				self.displayMode = aurioTouchDisplayModeSpectrum;
			}
		}
		else if (CGRectContainsPoint(CGRectMake(0., 104., 52., 99.), [touch locationInView:view])) // The Mute button was touched
		{
			AudioServicesPlaySystemSound(buttonPressSound);
			self.mute = !(self.mute);
			return;
		}
		else if (CGRectContainsPoint(CGRectMake(0., 203, 52., 99.), [touch locationInView:view])) // The FFT button was touched
		{
			AudioServicesPlaySystemSound(buttonPressSound);
			self.displayMode = (self.displayMode == aurioTouchDisplayModeOscilloscopeWaveform) ?  aurioTouchDisplayModeOscilloscopeFFT :
            aurioTouchDisplayModeOscilloscopeWaveform;
			return;
		}
	}
}

#pragma mark -


+ (AppDelegate *)sharedAppDelegate {
    
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)setListenning:(BOOL)state {
    
    _isListenning = state;
}

@end
