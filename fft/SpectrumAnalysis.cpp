/*

    File: SpectrumAnalysis.cpp
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "rad2fft.h"
#include "SpectrumAnalysis.h"

#define Scale(e) powf(2.0,e)

#define kLog2TableLog2Size 8
#define kLog2TableSize (1<<kLog2TableLog2Size)

// scaling constant for the log2 to 10*log10 conversion (equals 3.0103, stored as Q2.13)
static const int16_t kLog2ToLog10ScaleFactor = (int16_t)((float)(1<<13)*10.0f*logf(2.0f)/logf(10.0f) + 0.5f);
static const int32_t kAdjust0dBLevel = (-32) << 26;


static const int kLog2Table[kLog2TableSize] =
{
	0x00000000, 0x00000000, 0x04000000, 0x06570068, 0x08000000, 0x0949a780, 0x0a570070, 0x0b3abb40, 
	0x0c000000, 0x0cae00d0, 0x0d49a780, 0x0dd67540, 0x0e570070, 0x0ecd4010, 0x0f3abb40, 0x0fa0a7f0, 
	0x10000000, 0x10598fe0, 0x10ae00e0, 0x10fde0c0, 0x1149a780, 0x1191bba0, 0x11d67540, 0x121820a0, 
	0x12570060, 0x12934f00, 0x12cd4020, 0x13050140, 0x133abb40, 0x136e92a0, 0x13a0a7e0, 0x13d118e0, 
	0x14000000, 0x142d75a0, 0x14598fe0, 0x148462c0, 0x14ae00e0, 0x14d67b00, 0x14fde0c0, 0x15244080, 
	0x1549a780, 0x156e2220, 0x1591bba0, 0x15b47ec0, 0x15d67540, 0x15f7a860, 0x161820a0, 0x1637e620, 
	0x16570060, 0x16757680, 0x16934f00, 0x16b09040, 0x16cd4020, 0x16e96400, 0x17050140, 0x17201cc0, 
	0x173abb40, 0x1754e120, 0x176e92a0, 0x1787d3a0, 0x17a0a7e0, 0x17b91340, 0x17d118e0, 0x17e8bc20, 
	0x18000000, 0x1816e7a0, 0x182d75a0, 0x1843ace0, 0x18598fe0, 0x186f2100, 0x188462c0, 0x18995740, 
	0x18ae00e0, 0x18c26160, 0x18d67b00, 0x18ea4f80, 0x18fde0c0, 0x19113080, 0x19244080, 0x19371240, 
	0x1949a780, 0x195c01a0, 0x196e2220, 0x19800a60, 0x1991bba0, 0x19a33760, 0x19b47ec0, 0x19c59300, 
	0x19d67540, 0x19e726a0, 0x19f7a860, 0x1a07fb60, 0x1a1820a0, 0x1a281940, 0x1a37e620, 0x1a478840, 
	0x1a570060, 0x1a664f80, 0x1a757680, 0x1a847600, 0x1a934f00, 0x1aa20240, 0x1ab09040, 0x1abefa00, 
	0x1acd4020, 0x1adb6320, 0x1ae96400, 0x1af74320, 0x1b050140, 0x1b129ee0, 0x1b201cc0, 0x1b2d7b60, 
	0x1b3abb40, 0x1b47dd00, 0x1b54e120, 0x1b61c820, 0x1b6e92a0, 0x1b7b40e0, 0x1b87d3a0, 0x1b944b20, 
	0x1ba0a7e0, 0x1bacea80, 0x1bb91340, 0x1bc52280, 0x1bd118e0, 0x1bdcf680, 0x1be8bc20, 0x1bf469c0, 
	0x1c000000, 0x1c0b7f20, 0x1c16e7a0, 0x1c2239a0, 0x1c2d75a0, 0x1c389c00, 0x1c43ace0, 0x1c4ea8c0, 
	0x1c598fe0, 0x1c646280, 0x1c6f2100, 0x1c79cbc0, 0x1c8462c0, 0x1c8ee680, 0x1c995740, 0x1ca3b540, 
	0x1cae00e0, 0x1cb83a20, 0x1cc26160, 0x1ccc76e0, 0x1cd67b00, 0x1ce06dc0, 0x1cea4f80, 0x1cf42060, 
	0x1cfde0c0, 0x1d0790a0, 0x1d113080, 0x1d1ac060, 0x1d244080, 0x1d2db100, 0x1d371240, 0x1d406460, 
	0x1d49a780, 0x1d52dbe0, 0x1d5c01a0, 0x1d651900, 0x1d6e2220, 0x1d771d20, 0x1d800a60, 0x1d88e9c0, 
	0x1d91bba0, 0x1d9a8020, 0x1da33760, 0x1dabe180, 0x1db47ec0, 0x1dbd0f20, 0x1dc59300, 0x1dce0a40, 
	0x1dd67540, 0x1dded400, 0x1de726a0, 0x1def6d60, 0x1df7a860, 0x1dffd7a0, 0x1e07fb60, 0x1e1013a0, 
	0x1e1820a0, 0x1e202280, 0x1e281940, 0x1e300520, 0x1e37e620, 0x1e3fbc80, 0x1e478840, 0x1e4f4980, 
	0x1e570060, 0x1e5ead00, 0x1e664f80, 0x1e6de800, 0x1e757680, 0x1e7cfb20, 0x1e847600, 0x1e8be760, 
	0x1e934f00, 0x1e9aad40, 0x1ea20240, 0x1ea94de0, 0x1eb09040, 0x1eb7c9a0, 0x1ebefa00, 0x1ec62180, 
	0x1ecd4020, 0x1ed45600, 0x1edb6320, 0x1ee267e0, 0x1ee96400, 0x1ef057c0, 0x1ef74320, 0x1efe2640, 
	0x1f050140, 0x1f0bd420, 0x1f129ee0, 0x1f1961c0, 0x1f201cc0, 0x1f26cfe0, 0x1f2d7b60, 0x1f341f20, 
	0x1f3abb40, 0x1f414fe0, 0x1f47dd00, 0x1f4e62c0, 0x1f54e120, 0x1f5b5840, 0x1f61c820, 0x1f6830e0, 
	0x1f6e92a0, 0x1f74ed40, 0x1f7b40e0, 0x1f818da0, 0x1f87d3a0, 0x1f8e12c0, 0x1f944b20, 0x1f9a7ce0, 
	0x1fa0a7e0, 0x1fa6cc80, 0x1facea80, 0x1fb30200, 0x1fb91340, 0x1fbf1e00, 0x1fc52280, 0x1fcb20c0, 
	0x1fd118e0, 0x1fd70ac0, 0x1fdcf680, 0x1fe2dc60, 0x1fe8bc20, 0x1fee95e0, 0x1ff469c0, 0x1ffa37c0
};

inline int log2Int(uint x)
{
	int y;
	if(x < kLog2TableSize)
	{
		y = kLog2Table[x];
	}
	else
	{
		int shiftArg = __builtin_clz(x);
		shiftArg = (32 - kLog2TableLog2Size) - shiftArg;
		y = (shiftArg<<26) + kLog2Table[x>>shiftArg];
	}
	return y;
}


#if defined __arm__
inline int mul32_16b(int32_t x, int32_t y) { int32_t z; asm volatile("smulwb %0, %1, %2" : "=r"(z) : "r"(x), "r"(y)); return z; }
inline int mul32_16t(int32_t x, int32_t y) { int32_t z; asm volatile("smulwt %0, %1, %2" : "=r"(z) : "r"(x), "r"(y)); return z; }
inline int32_t SquareMag(int32_t re, int32_t im)
{
	register int32_t z;
	asm volatile("smultt %0, %1, %2" : "=r"(z) : "r"(re), "r"(re));
	asm volatile("smlatt %0, %1, %2, %3" : "=r"(z) : "r"(im), "r"(im), "0"(z));
	return z;
}
#else
#define mul32_16b(a,b) ((int32_t)(((int64_t)(a) * (int64_t)((b) & 0x0000ffff))>>16))
#define mul32_16t(a,b) ((int32_t)(((int64_t)(a) * (int64_t)(((b) & 0xffff0000)>>16))>>16))
inline int32_t SquareMag(int32_t re, int32_t im) { return (re>>16)*(re>>16)+(im>>16)*(im>>16); }
#endif


struct SPECTRUM_ANALYSIS
{
	int32_t size;
	int16_t* weightingWindow;
	Int32Cplx* fftBuffer;
	PackedInt16Cplx* twiddleFactors;
};



H_SPECTRUM_ANALYSIS SpectrumAnalysisCreate(int32_t size)
{
	H_SPECTRUM_ANALYSIS p = (SPECTRUM_ANALYSIS*)malloc(sizeof(SPECTRUM_ANALYSIS));
	if(p)
	{
		p->size = size;
		
		p->weightingWindow = (int16_t*)malloc(sizeof(int16_t)*size);
		float nrg = 0.0f;
		for(int i = 0; i < size/2; ++i)
		{
			/* Hamming window */
			float w = 0.53836-0.46164*cosf(2.0*M_PI*i/(float)(size-1));
			nrg += 2.0*w*w;
			p->weightingWindow[i] = (int16_t)(powf(2.0, 15.0)*w);
			p->weightingWindow[size-i-1] = p->weightingWindow[i];
		}

		p->fftBuffer = (Int32Cplx*)malloc(sizeof(Int32Cplx)*size);
		memset(p->fftBuffer, 0, sizeof(Int32Cplx)*size);

		p->twiddleFactors = CreatePackedTwiddleFactors(size);
	}
	return p;
}

void SpectrumAnalysisDestroy(H_SPECTRUM_ANALYSIS p)
{
	if(p)
	{
		if(p->weightingWindow) free(p->weightingWindow);
		if(p->fftBuffer) free(p->fftBuffer);
		
		DisposePackedTwiddleFactors(p->twiddleFactors);

		free(p);
	}
}

void SpectrumAnalysisProcess(H_SPECTRUM_ANALYSIS p, const int32_t* inTimeSig, int32_t* outMagSpectrum, bool in_dB)
{
	if(p)
	{
		// Apply weigthing window
		for(uint i = 0; i < p->size; i += 2)
		{
			int32_t dualCoef = *((int32_t*)(p->weightingWindow + i));
			p->fftBuffer[i].real   = mul32_16b(inTimeSig[i] << 7, dualCoef) << 1;
			p->fftBuffer[i].imag   = 0;
			p->fftBuffer[i+1].real = mul32_16t(inTimeSig[i+1] << 7, dualCoef) << 1;
			p->fftBuffer[i+1].imag = 0;
		}

		Radix2IntCplxFFT(p->fftBuffer, p->size, p->twiddleFactors, 1);
		
		if(in_dB)
		{			
			// Calculate magnitude spectrum in dB
			for(uint i = 0; i < p->size/2; ++i)
			{
				// squared magnitude
				int32_t squaredMag = SquareMag(p->fftBuffer[i].real, p->fftBuffer[i].imag);
				
				// Avoid log(0)
				if(squaredMag)
				{
					// squared mag -> log2
					squaredMag = log2Int(squaredMag<<1) + kAdjust0dBLevel;
				}
				else
				{
					squaredMag = kAdjust0dBLevel;
				}

				// log2 -> 10*log10 conversion (Q5.26 x Q2.13)
				outMagSpectrum[i] = mul32_16b(squaredMag, kLog2ToLog10ScaleFactor) << 1;
			}
		}
		else
		{
			// Calculate squared magnitude spectrum
			for(uint i = 0; i < p->size/2; ++i)
			{
				// squared magnitude
				outMagSpectrum[i] = SquareMag(p->fftBuffer[i].real, p->fftBuffer[i].imag);
			}
		}
	}
}
