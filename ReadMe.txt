
aurioTouch2

===========================================================================
DESCRIPTION:

aurioTouch2 is a newer version of the aurioTouch sample. aurioTouch2 uses the Accelerate framework for the FFT (fast fourteen transform) routines. The audio chain is now also entirely in 32 bit floating point which is the native input and output format from iPhone 4/iOS 5.0 onwards.

aurioTouch2 demonstrates use of the remote i/o audio unit for handling audio input and output. The application can display the input audio in one of the forms, a regular time domain waveform, a frequency domain waveform (computed by performing a fast fourier transform on the incoming signal), and a sonogram view (a view displaying the frequency content of a signal over time, with the color signaling relative power, the y axis being frequency and the x as time). Tap the sonogram button to switch to a sonogram view, tap anywhere on the screen to return to the oscilloscope. Tap the FFT button to perform and display the input data after an FFT transform. Pinch in the oscilloscope view to expand and contract the scale for the x axis.

The code in aurioTouch2 uses the remote i/o audio unit (AURemoteIO) for input and output of audio, and OpenGL for display of the input waveform. The application also uses Audio Session Services to manage route changes (as described in Core Audio Overview).

This application shows how to:

	* Set up the remote i/o audio unit for input and output.
	* Use OpenGL for graphical display of audio waveforms.
	* Use touch events such as tapping and pinching for user interaction
	* Use Audio Session Services to handle route changes and reconfigure the unit in response.
	* Use Audio Session Services to set an audio session category for concurrent input and output.
	* Use Audio Session Services to play simple alert sounds.
	
aurioTouch2 does not demonstrate how to handle interruptions. 


===========================================================================
RELATED INFORMATION:

Core Audio Overview
WWDC 2010 video sessions and resources


===========================================================================
SPECIAL CONSIDERATIONS:

aurioTouch2 requires audio input, and so is not appropriate for the first generation iPod touch.


===========================================================================
BUILD REQUIREMENTS:

Mac OS X v10.6.8, Xcode 4.0, iOS 5.0, iOS SDK 5.0 or later


===========================================================================
RUNTIME REQUIREMENTS:

Simulator: Mac OS X v10.6.x, iOS SDK 5.0 or later
iPhone: iOS 5.0


===========================================================================
PACKAGING LIST:

EAGLView.h
EAGLView.m

This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.

aurio_helper.cpp
aurio_helper.h

Helper functions for manipulating the remote i/o audio unit, responsible for setting up the remote i/o.

aurioTouchAppDelegate.h
aurioTouchAppDelegate.mm


The application delegate for the aurioTouch2 app, responsible for handling touch events and drawing.

FFTBufferManager.cpp
FFTBufferManager.h

This class manages buffering and computation for FFT analysis on input audio data. The methods provided are used to grab the audio, buffer it, and perform the FFT when sufficient data is available.

CAMath.h

CAMath is a helper class for various math functions.

CADebugMacros.h
CADebugMacros.cpp

A helper class for printing debug messages.

CAXException.h
CAXException.cpp

A helper class for exception handling.

CAStreamBasicDescription.cpp
CAStreamBasicDescription.h

A helper class for AudioStreamBasicDescription handling and manipulation.

================================================================================
Copyright (C) 2008-2011 Apple Inc. All rights reserved.
