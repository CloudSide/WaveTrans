/*
 
     File: aurioTouchAppDelegate.h
 Abstract: App delegate
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

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#include <libkern/OSAtomic.h>
#include <CoreFoundation/CFURL.h>

#import "EAGLView.h"
#import "FFTBufferManager.h"
#import "aurio_helper.h"
#import "CAStreamBasicDescription.h"
#import "bb_header.h"
#import "queue.h"

#define SPECTRUM_BAR_WIDTH 4

#ifndef CLAMP
#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif

@protocol ReceiveRequestDelegate;

typedef enum aurioTouchDisplayMode {
	aurioTouchDisplayModeOscilloscopeWaveform, 
	aurioTouchDisplayModeOscilloscopeFFT, 
	aurioTouchDisplayModeSpectrum 
} aurioTouchDisplayMode;

typedef struct SpectrumLinkedTexture {
	GLuint							texName; 
	struct SpectrumLinkedTexture	*nextTex;
} SpectrumLinkedTexture;

inline double linearInterp(double valA, double valB, double fract)
{
	return valA + ((valB - valA) * fract);
}

@interface AppDelegate : NSObject <UIApplicationDelegate, EAGLViewDelegate> {
    UIWindow*			window;
    EAGLView*			view;
	
	UIImageView*				sampleSizeOverlay;
	UILabel*					sampleSizeText;
	
	SInt32*						fftData;
	NSUInteger					fftLength;
	BOOL						hasNewFFTData;
	
	AudioUnit					rioUnit;
	BOOL						unitIsRunning;
	BOOL						unitHasBeenCreated;
	
	BOOL						initted_oscilloscope, initted_spectrum;
	UInt32*						texBitBuffer;
	CGRect						spectrumRect;
	
	GLuint						bgTexture;
	GLuint						muteOffTexture, muteOnTexture;
	GLuint						fftOffTexture, fftOnTexture;
	GLuint						sonoTexture;
	
	aurioTouchDisplayMode		displayMode;
	
	BOOL						mute;
	
	SpectrumLinkedTexture*		firstTex;
	FFTBufferManager*			fftBufferManager;
	DCRejectionFilter*			dcFilter;
	CAStreamBasicDescription	thruFormat;
    CAStreamBasicDescription    drawFormat;
    AudioBufferList*            drawABL;
	Float64						hwSampleRate;
    
    AudioConverterRef           audioConverter;
	
	UIEvent*					pinchEvent;
	CGFloat						lastPinchDist;
	
	AURenderCallbackStruct		inputProc;
    
	SystemSoundID				buttonPressSound;
	
	int32_t*					l_fftData;
    
	GLfloat*					oscilLine;
	BOOL						resetOscilLine;
    
    BOOL                        _isListenning;
}

@property (nonatomic, retain)	UIWindow*				window;
@property (nonatomic, retain)	EAGLView*				view;

@property (assign)				aurioTouchDisplayMode	displayMode;
@property						FFTBufferManager*		fftBufferManager;

@property (nonatomic, assign)	AudioUnit				rioUnit;
@property (nonatomic, assign)	BOOL					unitIsRunning;
@property (nonatomic, assign)	BOOL					unitHasBeenCreated;
@property (nonatomic, assign)	BOOL					mute;
@property (nonatomic, assign)	AURenderCallbackStruct	inputProc;

@property (nonatomic, assign)   id<ReceiveRequestDelegate> receiveRequestDelegate;

+ (AppDelegate *)sharedAppDelegate;

- (void)setListenning:(BOOL)state;

@end

@protocol ReceiveRequestDelegate <NSObject>

- (void)receiveRequestWithString:(NSString *)string;

@end

