//
//  bb_freq_util.h
//  BBSDK
//
//  Created by Littlebox on 13-5-6.
//  Copyright (c) 2013年 Littlebox. All rights reserved.
//

#ifndef BBSDK_bb_freq_util_h
#define BBSDK_bb_freq_util_h




#include <complex>
#include <math.h>
#include <stdbool.h>
#include <float.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "_kiss_fft_guts.h"


#define PI                      3.1415926535897932384626433832795028841971               //定义圆周率值
#define SAMPLE_RATE             44100                                                    //采样频率

#define BB_SEMITONE 			1.05946311
#define BB_BASEFREQUENCY		1760
#define BB_CHARACTERS			"0123456789abcdefghijklmnopqrstuv"

#define BB_FREQUENCIES          {1765,1856,1986,2130,2211,2363,2492,2643,2799,2964,3243,3316,3482,3751,3987,4192,4430,4794,5000,5449,5598,5900,6262,6627,7004,7450,7881,8174,8906,9423,9948,10536}

#define BB_THRESHOLD            40

#define BB_HEADER_0             17
#define BB_HEADER_1             19

typedef struct _bb_item_group bb_item_group;

typedef float element;

//void freq_init();

int freq_to_num(unsigned int f, int *n);

int num_to_char(int n, char *c);

int char_to_num(char c, unsigned int *n);

int num_to_freq(int n, unsigned int *f);

int char_to_freq(char c, unsigned int *f);

int vote(int *src, int src_len, int *result);

int multi_vote(int *src, int src_len, int *result, int res_len, int vote_res);

int multi_vote_accurate(int *src, int src_len, int *result, int res_len, int vote_res);

int statistics(int *src, int src_len, int *result, int res_len);

int compose_statistics(int *src_vote, int *src_statics, int src_len, int *result, int res_len);

/////////
int set_group(int *src, int src_len, bb_item_group *result, int res_len);

int process_group(bb_item_group *src, int src_len);

int get_group_data(bb_item_group *src, int src_len, int *result, int res_len);

int post_process(bb_item_group *src, int src_len, bb_item_group *result, int res_len);

/////////
int encode_sound(unsigned int freq, float buffer[], size_t buffer_length);

int create_sending_code(unsigned char *src, unsigned char *result, int res_len);

int decode_sound(short *src, int fft_number);

int fft(void *src, int num);

/////////

int statistics_2(int *src, int src_len, int *result, int res_len);
int process_group_2(bb_item_group *src, int src_len);
int post_process_2(bb_item_group *src, int src_len, bb_item_group *result, int res_len);

void _medianfilter(const element* signal, element* result, int N);

#endif /* BBSDK_bb_freq_util_h */


