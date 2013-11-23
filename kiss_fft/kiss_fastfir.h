//
//  kiss_fastfir.h
//  BBSDK
//
//  Created by Bruce on 13-5-22.
//  Copyright (c) 2013年 Littlebox. All rights reserved.
//

#ifndef BBSDK_kiss_fastfir_h
#define BBSDK_kiss_fastfir_h













/*
 Some definitions that allow real or complex filtering
 */
#ifdef REAL_FASTFIR
#define MIN_FFT_LEN 2048
#include "kiss_fftr.h"

typedef kiss_fft_scalar kffsamp_t;
typedef kiss_fftr_cfg kfcfg_t;
#define FFT_ALLOC kiss_fftr_alloc
#define FFTFWD kiss_fftr
#define FFTINV kiss_fftri
#else
#define MIN_FFT_LEN 1024
typedef kiss_fft_cpx kffsamp_t;
typedef kiss_fft_cfg kfcfg_t;
#define FFT_ALLOC kiss_fft_alloc
#define FFTFWD kiss_fft
#define FFTINV kiss_fft
#endif

typedef struct kiss_fastfir_state *kiss_fastfir_cfg;



kiss_fastfir_cfg kiss_fastfir_alloc(const kffsamp_t * imp_resp,size_t n_imp_resp,
                                    size_t * nfft,void * mem,size_t*lenmem);

/* see do_file_filter for usage */
size_t kiss_fastfir( kiss_fastfir_cfg cfg, kffsamp_t * inbuf, kffsamp_t * outbuf, size_t n, size_t *offset);



















#endif
