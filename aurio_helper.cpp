/*
 
     File: aurio_helper.cpp
 Abstract: Helper class for manipulating the remote i/o audio unit
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

#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
#include <stdio.h>

#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include "aurio_helper.h"

// This determines how slowly the oscilloscope lines fade away from the display. 
// Larger numbers = slower fade (and more strain on the graphics processing)
SInt8 *drawBuffers[kNumDrawBuffers];

int drawBufferIdx = 0;
int drawBufferLen = kDefaultDrawSamples;
int drawBufferLen_alloced = 0;

int SetupRemoteIO (AudioUnit& inRemoteIOUnit, AURenderCallbackStruct inRenderProc, CAStreamBasicDescription& outFormat)
{	
	try {		
		// Open the output unit
		AudioComponentDescription desc;
		desc.componentType = kAudioUnitType_Output;
		desc.componentSubType = kAudioUnitSubType_RemoteIO;
		desc.componentManufacturer = kAudioUnitManufacturer_Apple;
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		
		AudioComponent comp = AudioComponentFindNext(NULL, &desc);
		
		XThrowIfError(AudioComponentInstanceNew(comp, &inRemoteIOUnit), "couldn't open the remote I/O unit");
        
		UInt32 one = 1;
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)), "couldn't enable input on the remote I/O unit");
        
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &inRenderProc, sizeof(inRenderProc)), "couldn't set remote i/o render callback");
		
        // set our required format - LPCM non-interleaved 32 bit floating point
        outFormat = CAStreamBasicDescription(44100, kAudioFormatLinearPCM, 4, 1, 4, 2, 32, kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved);
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat)), "couldn't set the remote I/O unit's output client format");
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat)), "couldn't set the remote I/O unit's input client format");
        
		XThrowIfError(AudioUnitInitialize(inRemoteIOUnit), "couldn't initialize the remote I/O unit");
	}
	catch (CAXException &e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		return 1;
	}
	catch (...) {
		fprintf(stderr, "An unknown error occurred\n");
		return 1;
	}	
	
	return 0;
}

void SilenceData(AudioBufferList *inData)
{
	for (UInt32 i=0; i < inData->mNumberBuffers; i++)
		memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}


const Float32 DCRejectionFilter::kDefaultPoleDist = 0.975f;

DCRejectionFilter::DCRejectionFilter(Float32 poleDist)
{
	Reset();
}

void DCRejectionFilter::Reset()
{
	mY1 = mX1 = 0;	
}

void DCRejectionFilter::InplaceFilter(Float32* ioData, UInt32 numFrames)
{
	for (UInt32 i=0; i < numFrames; i++)
	{
        Float32 xCurr = ioData[i];
		ioData[i] = ioData[i] - mX1 + (kDefaultPoleDist * mY1);
        mX1 = xCurr;
        mY1 = ioData[i];
	}
}
