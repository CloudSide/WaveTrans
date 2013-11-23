/*

    File: rad2fft.h
Abstract: Radix 2 integer FFT
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

#ifndef __RAD2_FFT_H__
#define __RAD2_FFT_H__

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Struct for holding a 32 bit integer complex numbers
 */
struct Int32Cplx
{
	int real;
	int imag;
};
typedef struct Int32Cplx Int32Cplx;

/*
 * Packed complex type. The upper 16 bits correspond to the real part,
 * the lower 16 bit to imaginary part
 */
typedef int PackedInt16Cplx;


/*
 * Create a lookup table with "size" twiddle factors for the FFT.
 */
PackedInt16Cplx* CreatePackedTwiddleFactors(int size);

	
/* 
 * Dispose the twiddle factor table
 */
void DisposePackedTwiddleFactors(PackedInt16Cplx* cosSinTable);
	

/*
 * Inplace complex radix 2 FFT. The complex data vector must have the specified size and must be a power of 2.
 */
void Radix2IntCplxFFT(Int32Cplx* ioCplxData, int size, const PackedInt16Cplx* twiddleFactors, int twiddleFactorsStrides);


#ifdef __cplusplus
	}
#endif
		
#endif
