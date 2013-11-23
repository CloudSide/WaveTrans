/*

    File: SpectrumAnalysis.h
Abstract: Simple spectral analysis tool
 Version: 1.21

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

Copyright (C) 2010 Apple Inc. All Rights Reserved.


*/

#if !defined __SPECTRUM_ANALYSIS_H__
#define __SPECTRUM_ANALYSIS_H__

#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Forward declarations
 */
struct SPECTRUM_ANALYSIS;
typedef struct SPECTRUM_ANALYSIS* H_SPECTRUM_ANALYSIS;

	
/* 
 * Create a SpectrumAnalysis object. The block size argument must be a power of 2
 */
H_SPECTRUM_ANALYSIS SpectrumAnalysisCreate(int32_t blockSize);

	
/*
 * Dispose SpectrumAnalysis object
 */
void SpectrumAnalysisDestroy(H_SPECTRUM_ANALYSIS p);

/*
 * 
 * Inputs:
 *		p:				an opaque SpectrumAnalysis object handle
 *		inTimeSig:		pointer to a time signal of the same length as specified in SpectrumAnalysisCreate()
 *		outMagSpectrum:	pointer to a magnitude spectrum. Its length must at least be size/2
 *		in_dB:			flag indicating wether the magnitude spectrum should be calculated in dB
 *
 * Discussion:
 * 
 * the real valued time signal is first weighted with a Hamming window of the same size and then transformed
 * in the frequency domain. The squared magnitudes of the resulting complex spectrum are copied into the 
 * outMagSpectrum vector and then converted to dB if so requested. Since the input signal is real, the magnitude
 * spectrum is only half the size (note that the Nyquist term is discarded) as the input signal.
 *
 * Value ranges:
 *
 * the input signal is expected to be in a Q7.24 format in the range [-1, 1) which means that the integer parts should be zero
 * the ouput magnitude spectrum is in Q7.24 format with a range of [-128, 0) when calculated in dB.
 */
void SpectrumAnalysisProcess(H_SPECTRUM_ANALYSIS p, const int32_t* inTimeSig, int32_t* outMagSpectrum, bool in_dB);

#ifdef __cplusplus
}
#endif
		
#endif
