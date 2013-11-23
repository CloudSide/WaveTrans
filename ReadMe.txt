WaveTrans

===========================================================================
Let's teach the machines to sing

Try 声波传输!  --- 用声音传输数据

   采用仿生学技术，利用声音实现文件的快速传输。采用跨平台的技术，实现手机与PC之间，或者手机之间的图片、文字、链接的传输, 以及设备间配对等。一键操作，2秒钟搞定。

   同时社交功能实现了微博互粉、近距离广播、电子名片交换等功能, 将来可以实现开放协议的便捷电子支付功能。


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
