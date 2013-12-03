
#include "bb_freq_util.h"

#include "rscode.h"
#include "kiss_fastfir.h"


/*const */float frequencies[32] = BB_FREQUENCIES;
/*static */double theta = 0;

struct _bb_item_group {
	
	int item;
	int count;
};


/*
 static struct _freq_range {
 
 unsigned int start;
 unsigned int end;
 
 } freq_range[32];
 */


void freq_init() {
	
	static int flag = 0;
	
	if (flag) {
		
		return;
	}
    
	printf("----------------------\n");
	
	int i, len;
	
    /*
	for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
		
		unsigned int freq = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, i));
		frequencies[i] = freq;
        
	}
     */
    
    
#if BB_BASEFREQUENCY_IS_H
    
	for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
		
		unsigned int freq = (unsigned int)(BB_BASEFREQUENCY_H + (i * 64));
		frequencies[i] = freq;
	}
    
#else
    
    for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
		
		unsigned int freq = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, i));
		frequencies[i] = freq;
        
	}
    
#endif
    
    flag = 1;
}


int freq_to_num(unsigned int f, int *n) {
	
    /*
     frequencies[0] = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, 0));
     frequencies[31] = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, 31));
     
     
     if (n != NULL &&
     f >= frequencies[0]-BB_THRESHOLD*pow(BB_SEMITONE, 0) &&
     f <= frequencies[31]+BB_THRESHOLD*pow(BB_SEMITONE, 31)) {
     
     unsigned int i;
     
     for (i=0; i<32; i++) {
     
     unsigned int freq = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, i));
     frequencies[i] = freq;
     
     if (abs(frequencies[i] - f) <= BB_THRESHOLD*pow(BB_SEMITONE, i)) {
     //if (abs(frequencies[i] - f) <= BB_THRESHOLD) {
     *n = i;
     return 0;
     }
     }
     }
     */
    
    freq_init();
    
    
    if (n != NULL &&
        f >= frequencies[0]-BB_THRESHOLD &&
        f <= frequencies[31]+BB_THRESHOLD) {
        
        unsigned int i;
        
        for (i=0; i<32; i++) {
            
            if (abs(frequencies[i] - f) <= BB_THRESHOLD) {
                
                *n = i;
                return 0;
            }
        }
    }
    
	
    /*
     if (n!=NULL && f>freq_range[0].start && f<freq_range[31].end) {
     
     unsigned int i;
     
     for (i=0; i<32; i++) {
     
     if (f>freq_range[i].start && f<freq_range[i].end) {
     
     *n = i;
     return 0;
     }
     }
     }
     */
	
	return -1;
}

int num_to_char(int n, char *c) {
	
	if (c != NULL && n>=0 && n<32) {
		
		*c = BB_CHARACTERS[n];
		
		return 0;
	}
    
	return -1;
}

int char_to_num(char c, unsigned int *n) {
	
	if (n == NULL) return -1;
	
	*n = 0;
	
	if (c>=48 && c<=57) {
		
		*n = c - 48;
		
		return 0;
        
	} else if (c>=97 && c<=118) {
		
		*n = c - 87;
		
		return 0;
	}
	
	return -1;
}

int num_to_freq(int n, unsigned int *f) {
    
    freq_init();
	
	if (f != NULL && n>=0 && n<32) {
		
		//*f =  (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, n));
		*f =  (unsigned int)floor(frequencies[n]);
        
        
		return 0;
	}
	
	return -1;
}

int char_to_freq(char c, unsigned int *f) {
	
	unsigned int n;
	
	if (f != NULL && char_to_num(c, &n) == 0) {
		
		unsigned int ff;
		
		if (num_to_freq(n, &ff) == 0) {
			
			*f = ff;
			return 0;
		}
	}
	
	return -1;
}

int vote(int *src, int src_len, int *result) {
	
	if (src==NULL || src_len==0 || result==NULL) {
		
		return -1;
	}
    
	int i;
	int map[32] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	int max_value = 0;
	int max_key   = 0;
	int temp      = 0;
	
	for (i=0; i<src_len; i++) {
		
		if (src[i] >= 0 && src[i] < 32) {
			
            temp = ++map[src[i]];
            
            if (temp > max_value) {
                
                max_value = temp;
                max_key   = src[i];
            }
			
		} else if (src[i]==-1) {
            
        } else {
			return -1;
		}
	}
	
	*result = max_key;
    
	return max_value;
}

int multi_vote(int *src, int src_len, int *result, int res_len, int vote_res) {
	
	if (src==NULL || result==NULL || src_len==0 || res_len==0 || src_len<=res_len || vote_res==0) {
		
		return -1;
	}
	
	int step_len = src_len / res_len;
    
    if (step_len<vote_res) {
        
        return -1;
    }
	
	int i;
	int j = 0;
	
	for (i=0; i<src_len; i+=step_len) {
        
        int vote_count = vote(&src[i], step_len, &result[j++]);
        
        if (vote_count == -1) {
            
            return -1;
        }
        if (vote_res>0 && vote_count<vote_res) {
            
            return 1;
        }
	}
	
	return 0;
}

int multi_vote_accurate(int *src, int src_len, int *result, int res_len, int vote_res) {
	
	if (src==NULL || result==NULL || src_len==0 || res_len==0 || src_len<=res_len || vote_res==0) {
		
		return -1;
	}
	
	int step_len = src_len / res_len;
    
    if (step_len<vote_res) {
        
        return -1;
    }
	
	int i;
	int j = 0;
	
	for (i=0; i<src_len; i+=step_len) {
        
        int vote_count = vote(&src[i], step_len+1, &result[j++]);
        
        if (vote_count == -1) {
            
            return -1;
        }
        if (vote_res>0 && vote_count<vote_res) {
            
            return 1;
        }
	}
	
	return 0;
}

int statistics(int *src, int src_len, int *result, int res_len) {
    
    if (src==NULL || result==NULL || src_len==0 || res_len==0) {
        
        return -1;
    }
    
    // Littlebox-XXOO
    
    bb_item_group a[32*3]; // include -1
    bb_item_group b[32*3]; // without -1
    bb_item_group c[32*3];
    
    int i;
    int step = 0;
    
	int stat = set_group(src, src_len, a, 32) == 0 &&
    ++step &&
    process_group(a, 32) == 0 &&
    ++step &&
    get_group_data(a, 32, src, src_len) == 0 &&
    ++step &&
    set_group(src, src_len, b, 32) == 0 &&
    ++step &&
    post_process(b, 32, c, 32) == 0 &&
    ++step;
    
    /*
     printf("a:\n");
     
     for (i=0; i<32; i++) {
     
     printf("%d->%d\n", a[i].item, a[i].count);
     }
     
     printf("b:\n");
     
     for (i=0; i<32; i++) {
     
     printf("%d->%d\n", b[i].item, b[i].count);
     }
     
     printf("c:\n");
     
     for (i=0; i<32; i++) {
     
     printf("%d->%d\n", b[i].item, b[i].count);
     }
     */
	
    if (stat) {
        
        result[0] = c[0].item;
        result[1] = c[1].item;
        
        if (c[res_len].item != -2 && c[2].item == BB_HEADER_1 && c[res_len].item != c[res_len-1].item) {
            
            for (i=2; i<res_len; i++) {
                
                result[i] = c[i+1].item;
            }
            
        } else {
            
            for (i=2; i<res_len; i++) {
                
                if (c[i].item == -2) {
                    
                    result[i] = 0;
                    
                } else {
                    
                    result[i] = c[i].item;
                }
            }
        }
        
        printf("77777777777777777777777\n");
    }
    
    printf("step: %d\n", step);
    printf("888888888888888888888888\n");
    
    return stat ? -1 : 0;
}

int compose_statistics(int *src_vote, int *src_statics, int src_len, int *result, int res_len) {
	
	if (src_vote==NULL || src_statics==NULL || result==NULL || src_len==0 || res_len==0) {
        return -1;
	}
	
	int i;
	
	if (src_vote[0]==BB_HEADER_1) {
		
		if (src_statics[0]!=BB_HEADER_1) {
			
			for (i=0; i<src_len-1; i++) {
				src_vote[i] = src_vote[i+1];
			}
			src_vote[src_len-1] = 0;
		}
	}
	
	for (i=0; i<src_len; i++) {
		
		if (i==0) {
			
			result[0] = src_statics[0];
            
		} else {
			
			if (src_vote[i] != src_statics[i]) {
				
				if (src_vote[i] != result[i-1] && src_statics[i] != result[i-1]) {
                    result[i] = src_statics[i];
                } else if (src_vote[i] != result[i-1] && src_statics[i] == result[i-1]) {
					result[i] = src_vote[i];
				} else {
					result[i] = src_statics[i];
				}
			} else {
				result[i] = src_vote[i];
			}
		}
	}
	
	return 0;
}

int set_group(int *src, int src_len, bb_item_group *result, int res_len) {
	
	if (src==NULL || result==NULL || src_len <= 0 || res_len <= 0) {
        
		return -1;
	}
	
	int index = 0;
	int i;
	
	for (i=0; i<res_len; i++) {
        
		result[i].item = -2;
		result[i].count = 0;
	}
    
    src[0] = src[1] = src[2] = BB_HEADER_0;
    src[3] = src[4] = src[5] = BB_HEADER_1;
	
	result[0].item = src[0];
	result[0].count++;
	
	for (i=1; i<src_len; i++) {
		
		if (src[i] == src[i-1] && result[index].count < 4) {
			
			result[index].count++;
			
		} else {
            
			index++;
			result[index].item = src[i];
			result[index].count++;
		}
	}
    
	return 0;
}

int process_group(bb_item_group *src, int src_len) {
	
	if (src==NULL || src_len <= 0) {
		return -1;
	}
	
	int i;
	int twice = 1;
	
	while (twice<3) {
        
		for (i=0; i<src_len; i++) {
            
			if (src[i].count != 0 && src[i].item == -1 && src[i].count < 3) {
				
				if (i == 0) {
                    
					if (src[i+1].count<4) {
                        
						src[i+1].count++;
						src[i].count--;
					}
					
				} else if (src[i+1].item == -2) {
                    
					if (src[i-1].count<4) {
                        
						src[i+1].count++;
						src[i].count--;
					}
					
				} else {
                    
					if (src[i-1].count == 4 && src[i+1].count == 4) {
						
					} else if (src[i-1].count > src[i+1].count) {
                        
						src[i+1].count++;
						src[i].count--;
						
					} else {
						
						src[i-1].count++;
						src[i].count--;
					}
				}
			}
		}
		
		twice++;
	}
    
    
	return 0;
}

int get_group_data(bb_item_group *src, int src_len, int *result, int res_len) {
    
	if (src==NULL || result==NULL || res_len <= 0 || src_len <= 0) {
        
		return -1;
	}
	
	int i, j;
	int index = 0;
	
	for (i=0; i<src_len; i++) {
		
		for (j=0; j<src[i].count; j++) {
            
            if (index > res_len) {
                
                break;
            }
            
			result[index] = src[i].item;
			index++;
		}
	}
	
	return 0;
}

int post_process(bb_item_group *src, int src_len, bb_item_group *result, int res_len) {
	
	if (src==NULL || result==NULL || src_len <= 0 || res_len <= 0) {
		return -1;
	}
	
	int i;
	int index = 1;
	int x;
	
	for (i=0; i<res_len; i++) {
		result[i].item = -2;
		result[i].count = 0;
	}
	
	result[0].item = src[0].item;
	result[0].count = src[0].count;
	
	for (i=1; i<src_len-1; i++) {
		
		if (src[i].item == -1) {
            
            
            if (src[i].count == 4 && src[i+1].item == -1) {
				
				result[index].item = src[i].item = 0;
				index++;
				continue;
			}
			
			if (src[i-1].count + src[i].count + src[i+1].count >= 9) {
				
				result[index].item = 0;
				result[index].count = 4;
				result[index-1].count = src[i-1].count = 4;
				src[i+1].count = 4;
				index++;
				
			} else {
				
				x = src[i+1].count + src[i].count;
				src[i+1].count = x > 4 ? 4 : x;
			}
		} else {
			
			result[index].item = src[i].item;
			result[index].count = src[i].count;
			index++;
		}
	}
    
	return 0;
}


/////////////////////

// 一个频率对应的一组PCM的buffer
int encode_sound(unsigned int freq, float buffer[], size_t buffer_length) {
    
    
    const double amplitude = 0.25;
	double theta_increment = 2.0 * PI * freq / SAMPLE_RATE;
	int frame;
    
	for (frame = 0; frame < buffer_length; frame++) {
        
		buffer[frame] = sin(theta) * amplitude;
		theta += theta_increment;
		
        if (theta > 2.0 * PI) {
            
			theta -= 2.0 * PI;
		}
	}
    
    return 1;
}

int create_sending_code(unsigned char *src, unsigned char *result, int res_len) {
    
    if (src==NULL || result==NULL || res_len <= 2) {
        return -1;
    }
    
    int i;
    
    unsigned char data[RS_TOTAL_LEN];
    
    for (i=0; i<RS_TOTAL_LEN; i++) {
        
        if (i<RS_DATA_LEN) {
            char_to_num(src[i], (unsigned int *)(data+i));
        }else {
            data[i] = 0;
        }
    }
    
    unsigned char *code = data + RS_DATA_LEN;
    
    RS *rs = init_rs(RS_SYMSIZE, RS_GFPOLY, RS_FCR, RS_PRIM, RS_NROOTS, RS_PAD);
    encode_rs_char(rs, data, code);
    
    result[0] = BB_HEADER_0;
    result[1] = BB_HEADER_1;
    
    for (i=2; i<res_len; i++) {
        result[i] = data[i-2];
    }
    
    printf("code sending :  ");
    for (i=0; i<res_len; i++) {
        printf("%u-", result[i]);
    }
    printf("\n");
    
    return 0;
}


// 解码音频数据，返回所对应字符
int decode_sound(short *src, int fft_number)
{
    if (!src) {
        return 0;
    }
    
    // 计算fft
    
    int length_buff_per_turn = fft_number / 2;
    int res_temp[5] = {-1,-1,-1,-1,-1};
    int freq = 0;
    
    freq = fft((src+fft_number/8 + fft_number *3 / 4 / 8 * 0), length_buff_per_turn);
    freq_to_num(freq, res_temp + 0);
    
    freq = fft((src+fft_number/8 + fft_number *3 / 4 / 8 * 1), length_buff_per_turn);
    freq_to_num(freq, res_temp + 1);
    
    freq = fft((src+fft_number/8 + fft_number *3 / 4 / 8 * 2), length_buff_per_turn);
    freq_to_num(freq, res_temp + 2);
    
    freq = fft((src+fft_number/8 + fft_number *3 / 4 / 8 * 3), length_buff_per_turn);
    freq_to_num(freq, res_temp + 3);
    
    freq = fft((src+fft_number/8 + fft_number *3 / 4 / 8 * 4), length_buff_per_turn);
    freq_to_num(freq, res_temp + 4);
    
    //    freq = fft((src), length_buff_per_turn * 2);
    //    freq_to_num(freq, res_temp + 5);
    
    
    int sound_freq = 0;
    
    if (vote(res_temp, 5, &sound_freq) <= 0) {
        
        return 0;
    }
    
    /*
     if (sound_freq > 0) {
     
     int a = -1;
     freq_to_num(sound_freq, &a);
     printf("----%d---  %d\n", sound_freq, a);
     }
     */
    
    //freq_init();
    //    int num[1] = {-1};
    //    freq_to_num(sound_freq, num);
    
    return sound_freq;
}

// fft计算
int fft(void *src_data, int num)
{
    if (!src_data) {
        return 0;
    }
    
    if (num > BB_MAX_FFT_SIZE) {
        num = BB_MAX_FFT_SIZE;
    }
    
    kiss_fft_cpx in_data[BB_MAX_FFT_SIZE];
    kiss_fft_cpx out_data[BB_MAX_FFT_SIZE];
    
    int i;
    
    for (i=0; i<num; i++) {
        
        in_data[i].r = (double)((unsigned char *)src_data)[i];
        in_data[i].i = 0;
    }
    
    /*
     size_t nfft;
     
     kiss_fastfir_cfg fastfir_cfg = kiss_fastfir_alloc(in_data, num, &nfft, NULL, NULL);
     
     size_t offset;
     kiss_fft_cpx outbuf[BB_MAX_FFT_SIZE];
     
     size_t nffir = kiss_fastfir(fastfir_cfg, in_data, outbuf, num, &offset);
     
     KISS_FFT_FREE(fastfir_cfg);
     */
    
    
    kiss_fft_cfg fft_cfg = kiss_fft_alloc(num, 0, NULL, NULL);
    kiss_fft(fft_cfg, in_data, out_data);
    
    int size = num / 2;
    double maxFreq = 0.0;
    int maxIndx = 0;
    int maxEqual = 0;
    
    float bowl[32];
    int bowl_count[32];
    
    for (int i=0; i<32; i++) {
        bowl[i] = 0.0;
        bowl_count[i] = 0;
    }
    
    for (int i = 1; i<size*4/5; i++) {
        
        int n;
        float fff = (44100 / 2.0) * i / (size / 2);
        double out_data_item = sqrt(pow(out_data[i].r, 2) + pow(out_data[i].i, 2));
        
        if (freq_to_num(fff, &n) != -1) {
            
            float thresh_min = 0;
            float thresh_max = 5500000;
            
            if (out_data_item < thresh_min || out_data_item > thresh_max) {
                
                continue;
            }
            
            bowl[n] += out_data_item;
            bowl_count[n]++;
        }
    }
    
    for (i=0; i<32; i++) {
        
        float a = bowl[i]/ bowl_count[i];
        
        
        if (a > maxFreq)
        {
            maxFreq = a;
            maxIndx = i;
        }
        else if (a == maxFreq)
        {
            maxEqual++;
            
            if (maxFreq > 0.0)
            {
            }
        }
        else
        {
        }
    }
    
    KISS_FFT_FREE(fft_cfg);
    kiss_fft_cleanup();
    
    //    for (i=1; i<size*4/5; i++)
    //    {
    //
    //
    //        float ff;
    //        float fff = (44100 / 2.0) * i / (size / 2);
    //
    //        int n;
    //
    //        if (freq_to_num(fff, &n) == -1) {
    //
    //            continue;
    //
    //        } else {
    //
    //            ff = 19000;
    //
    //            if (n >= 13) {
    //
    //                ff = 14500;
    //
    //            } /*else if (n >= 20) {
    //
    //                ff = 12400;
    //            }*/
    //        }
    //
    //
    //
    //        double out_data_item = sqrt(pow(out_data[i].r, 2) + pow(out_data[i].i, 2));
    //
    //        //printf("%f\n", out_data_item);
    //
    //        if (out_data_item > maxFreq && out_data_item > ff)
    //        {
    //            maxFreq = out_data_item;
    //            maxIndx = i;
    //        }
    //        else if (out_data_item == maxFreq)
    //        {
    //            maxEqual++;
    //
    //            if (maxFreq > 0.0)
    //            {
    //            }
    //        }
    //        else
    //        {
    //        }
    //    }
    //
    
    ////
    
    if (maxFreq == 0) {
        return 0;
    }
    
    
    //double tmpFreq = (44100 / 2.0) * maxIndx / (size / 2);
    unsigned int intFreq;
    num_to_freq(maxIndx, &intFreq);
    
    //    for (int i=0; i<32; i++) {
    //        printf("%f ~ %d \n", bowl[i], i);
    //    }
    
    //printf("---%d\n", intFreq);
    
    /*
     if (intFreq > 40000 || 1) {
     
     printf("-----------------------------------------");
     for (i=0; i<num; i++) {
     
     double out_data_item = sqrt(pow(out_data[i].r, 2) + pow(out_data[i].i, 2));
     printf("%f---%d\n", out_data_item, i);
     }
     
     int aaaaaaa = 5;
     }
     */
    
    return intFreq;
}


////////

int statistics_2(int *src, int src_len, int *result, int res_len) {
    
    if (src==NULL || result==NULL || src_len==0 || res_len==0) {
        
        return -1;
    }
    
    // Littlebox-XXOO
    
    bb_item_group a[32*3];
    //    bb_item_group b[32*3];
    bb_item_group c[32*3];
    
    int i;
    int step = 0;
    
	int stat = set_group(src, src_len, a, 32) == 0 &&
    ++step &&
    process_group_2(a, 32) == 0 &&
    ++step &&
    post_process_2(a, 32, c, 32) == 0 &&
    ++step;
	
    if (stat) {
        
        result[0] = c[0].item;
        result[1] = c[1].item;
        
        
        if (c[res_len].item != -2 && c[2].item == BB_HEADER_1 && c[res_len].item != c[res_len-1].item) {
            
            for (i=2; i<res_len; i++) {
                
                result[i] = c[i+1].item;
            }
            
        } else {
            
            for (i=2; i<res_len; i++) {
                
                if (c[i].item == -2) {
                    
                    result[i] = 0;
                    
                } else {
                    
                    result[i] = c[i].item;
                }
            }
        }
    }
    
    printf("step: %d\n", step);
    
    return stat ? -1 : 0;
}

int process_group_2(bb_item_group *src, int src_len) {
	
	if (src==NULL || src_len <= 0) {
		return -1;
	}
	
	int i;
    
    for (i=1; i<src_len-2; i++) {
        
        if (src[i].count != 0 && src[i].count == 1 && src[i+1].count == 1 && src[i+2].count == 1) {
            
            if (src[i-1].count > src[i+3].count) {
                
                src[i].count = 0;
                src[i+1].count = 0;
                src[i+2].count = 2;
                
            } else {
                
                src[i].count = 2;
                src[i+1].count = 0;
                src[i+2].count = 0;
            }
            
        } else if (src[i].count != 0 && src[i].count == 1 && src[i+1].count == 1) {
            
            if (src[i-1].count + src[i+1].count + src[i].count <= 8) {
                
                src[i].count = 0;
                src[i+1].count = 0;
                
            } else {
                src[i].count = 0;
                src[i+1].count = 2;
            }
            
        } else if (src[i].count != 0 && src[i].count == 1) {
            
            if (src[i-1].count + src[i+1].count + src[i].count <= 8) {
                src[i].count = 0;
            } else {
                src[i].count = 2;
            }
        }
        
    }
    
	return 0;
}

int post_process_2(bb_item_group *src, int src_len, bb_item_group *result, int res_len) {
	
	if (src==NULL || result==NULL || src_len <= 0 || res_len <= 0) {
		return -1;
	}
	
	int i;
	int index = 1;
	
	for (i=0; i<res_len; i++) {
		result[i].item = -2;
		result[i].count = 0;
	}
	
	result[0].item = src[0].item;
	result[0].count = src[0].count;
	
	for (i=1; i<src_len-1; i++) {
		
		if (src[i].count == 0) {
            
            continue;
            
		} else {
			
			result[index].item = src[i].item;
			result[index].count = src[i].count;
			index++;
		}
	}
    
	return 0;
}

void _medianfilter(const element* signal, element* result, int N)
{
    //   Move window through all elements of the signal
    for (int i = 1; i < N - 1; ++i)
    {
        //   Pick up window elements
        element window[3];
        for (int j = 0; j < 3; ++j)
            window[j] = signal[i - 1 + j];
        //   Order elements (only half of them)
        for (int j = 0; j < 2; ++j)
        {
            //   Find position of minimum element
            int min = j;
            for (int k = j + 1; k < 3; ++k)
                if (window[k] < window[min])
                    min = k;
            //   Put found minimum element in its place
            const element temp = window[j];
            window[j] = window[min];
            window[min] = temp;
        }
        //   Get result - the middle element
        result[i] = window[1];
    }
	
	result[0] = signal[0];
}


////////////////// V2.0

int array_search(int num, int a[], int array_length) {
	
	if (array_length <= 0 || a == NULL) {
		return -2; // 数据异常
	}
	
	for (int i=0; i<array_length; i++) {
		
		if (num == a[i]) {
			return i;
		}
	}
	
	return -1; // 没找到
}

int isset_struct(struct_tmp tmp_x) {
	
	if (tmp_x.num != -1) {
		return 1;
	}else {
		return 0;
	}
}

int isset_num(int num) {
	
	if (num != -1) {
		return 1;
	}else {
		return 0;
	}
}

void unset(struct_tmp *const tmp_x) {
	
	tmp_x->num = -1;
	tmp_x->m = -1;
	tmp_x->r = -1;
	tmp_x->r_ = -1;
	tmp_x->l = -1;
	tmp_x->l_ = -1;
}

int partions(float l[],int low,int high)
{
	int prvotkey=l[low];
	l[0]=l[low];
	while (low<high)
	{
        while (low<high&&l[high]>=prvotkey)
            --high;
        l[low]=l[high];
        while (low<high&&l[low]<=prvotkey)
            ++low;
        l[high]=l[low];
	}
    
	l[low]=l[0];
	return low;
}

void qsort(float l[],int low,int high)
{
	int prvotloc;
	if(low<high)
	{
        prvotloc=partions(l,low,high);    //将第一次排序的结果作为枢轴
        qsort(l,low,prvotloc-1); //递归调用排序 由low 到prvotloc-1
        qsort(l,prvotloc+1,high); //递归调用排序 由 prvotloc+1到 high
        
	}
}

void quicksort(float l[],int n)
{
	qsort(l,1,n); //第一个作为枢轴 ，从第一个排到第n个
}

void generate_data(queue *que, int que_length, int *res, int *rrr, int res_length, float minValue, float maxValue) {
    
    float data[20][32] = {0};
    
    int type = 0;
    
    if (type == 1) {
        
        int counter = 0;
        int while_counter = 0;
        
        float step;
        
        if (minValue >= 0.5) {
            step = 1 - minValue;
        }else {
            step = minValue;
        }
        
        float thresh_hold = minValue;
        
        while ((counter > 70 || counter < 40) && while_counter < 10) {
            
            if (counter > 70) {
                
                step = step / 2;
                thresh_hold = thresh_hold + step;
                
            }else if (counter < 40 && thresh_hold < 0.1){
                
                step = step / 2;
                thresh_hold = thresh_hold - step;
            }
            
            counter = 0;
            while_counter++;
            
            //printf("\n~~~~~~~~~~~~~~ %d ~~~~~~~~~~~~~~~~\n", while_counter);
            for (int i = 0; i<32; i++) {
                
                for (int k = 0; k<20; k++) {
                    
                    queue *q = &que[i];
                    float currentValue = queue_item_at_index(q, k);
                    
                    if (currentValue <= thresh_hold) {
                        currentValue = 0.0;
                    }else {
                        counter++;
                    }
                    
                    data[k][i] = currentValue;
                    
                    //printf("%d,%d,%.4f]", i, k, currentValue);
                }
            }
        }
    }else if (type == 0) {
        
        
        for (int i = 0; i<32; i++) {
            
            for (int k = 0; k<20; k++) {
                
                queue *q = &que[i];
                float currentValue = queue_item_at_index(q, k);
                
                if (currentValue < 0 || currentValue > 1) {
                    currentValue = 0.0;
                }
                
                data[k][i] = currentValue;
                
                //printf("%d,%d,%.4f]", i, k, currentValue);
            }
        }
    }else if (type == 2) {
        
        int counter = 0;
        
        float step = 0.01;
        float thresh_hold = minValue;
        
        while ((counter > 70 || counter < 40) && thresh_hold < 1) {
            
            if (counter > 70) {
                thresh_hold += step;
            }else {
                thresh_hold -= step;
            }
            
            counter = 0;
            
            for (int i = 0; i<32; i++) {
                
                for (int k = 0; k<20; k++) {
                    
                    queue *q = &que[i];
                    float currentValue = queue_item_at_index(q, k);
                    
                    if (currentValue < thresh_hold) {
                        currentValue = 0.0;
                    }else {
                        counter++;
                    }
                    
                    data[k][i] = currentValue;
                }
            }
            //printf("%d,%d,%.4f]", i, k, currentValue);
        }
    }
    
    
    /////////////////////////
    
    float tempValue[80];
    for (int i=0; i<80; i++) {
        tempValue[i] = -1;
    }
    
    int sortData[20][4];
	float sortValue[20][4];
	
	for (int i=0; i<4; i++) {
		for (int j=0; j<20; j++) {
			sortData[j][i] = -1;
			sortValue[j][i] = -1;
		}
	}
    
	for (int i=0; i<20; i++) {
		for (int k=0; k<4; k++) {
			
			int tmp = -1;
			float tmpData = 0;
			int aa = 0;
			
			for (int j=0; j<32; j++) {
                
				if (data[i][j] > tmpData && data[i][j] != 0) {
					tmp = j;
					tmpData = data[i][j];
					aa = 1;
				}
			}
			
			if	(aa == 1) {
				
				sortValue[i][k] = data[i][tmp];
				data[i][tmp] = 0;
				sortData[i][k] = tmp;
				aa = 0;
			}
		}
	}
    
    // 加阈值
    /*
     for (int i=0; i<20; i++) {
     for (int j=0; j<4; j++) {
     
     tempValue[j * 20 + i] = sortValue[i][j];
     }
     }
     
     quicksort(tempValue, 80);
     
     float thresh_hold = fmin(tempValue[39], minValue);
     
     for (int i=0; i<20; i++) {
     for (int j=0; j<4; j++) {
     
     if (sortValue[i][j] < thresh_hold) {
     sortValue[i][j] = -1;
     sortData[i][j] = -1;
     }
     
     }
     }
     */
    //
    
    if (minValue < 0.3) {
        
    }else if (minValue > 0.6) {
        for (int i=0; i<20; i++) {
            for (int j=2; j<4; j++) {
                
                sortValue[i][j] = -1;
                sortData[i][j] = -1;
                
            }
        }
    }else {
        for (int i=0; i<20; i++) {
            for (int j=3; j<4; j++) {
                
                sortValue[i][j] = -1;
                sortData[i][j] = -1;
                
            }
        }
    }
    
	
    for (int i=0; i<res_length; i++) {
        res[i] = -1;
    }
	
	//printf("\n\n\n   ");
	for (int i=0; i<20; i++) {
		
		struct_tmp tmp_1; tmp_1.num = -1; tmp_1.m = -1; tmp_1.r = -1; tmp_1.r_ = -1; tmp_1.l = -1; tmp_1.l_ = -1;
		struct_tmp tmp_2; tmp_2.num = -1; tmp_2.m = -1; tmp_2.r = -1; tmp_2.r_ = -1; tmp_2.l = -1; tmp_2.l_ = -1;
		struct_tmp tmp_3; tmp_3.num = -1; tmp_3.m = -1; tmp_3.r = -1; tmp_3.r_ = -1; tmp_3.l = -1; tmp_3.l_ = -1;
		
		for (int j=0; j<4; j++) {
			
			int key = -1;
			int key_ = -1;
			
			if (sortData[i][j] != -1 && i<19 && (key = array_search(sortData[i][j], sortData[i+1], 4)) >= 0) {
				
				if (i < 18 && (key_ = array_search(sortData[i][j], sortData[i+2], 4)) >= 0) {
					
					if (!isset_struct(tmp_3)) {
						
						if (i > 0 && res[i-1] == sortData[i][j]) {} else {
                            
							tmp_3.num = sortData[i][j];
							tmp_3.m = j;
							tmp_3.r = key;
							tmp_3.r_ = key_;
						}
						
                        
					}else {
						
						int count_1 = tmp_3.m + tmp_3.r + tmp_3.r_;
						int count_2 = j + key + key_;
						
						if (count_2 < count_1) {
							
							if (i > 0 && res[i-1] == sortData[i][j]) {} else {
                                
								tmp_3.num = sortData[i][j];
								tmp_3.m = j;
								tmp_3.r = key;
								tmp_3.r_ = key_;
							}
						}
					}
				}else {
					
					if (!isset_struct(tmp_2)) {
						
						if (i > 0 && res[i-1] == sortData[i][j]) {} else {
							
							tmp_2.num = sortData[i][j];
							tmp_2.m = j;
							tmp_2.r = key;
						}
                        
					}else {
						
						int count_1 = tmp_2.m + tmp_2.r;
						int count_2 = j + key;
						
						if (count_2 < count_1) {
							
							if (i > 0 && res[i-1] == sortData[i][j]) {} else {
								
								tmp_2.num = sortData[i][j];
								tmp_2.m = j;
								tmp_2.r = key;
							}
						}
					}
				}
				
			}else if (sortData[i][j] != -1) {
				
				if (i == 0 || (i > 0 && res[i-1] != sortData[i][j])) {
					
					if (!isset_struct(tmp_1)) {
						
						tmp_1.num = sortData[i][j];
						tmp_1.m = j;
					}
				}
			}
		}
		
		if (isset_struct(tmp_1) && isset_struct(tmp_2)) {
			
			if ((tmp_1.m < tmp_2.m) && (tmp_1.m < tmp_2.r)) {
				
				float quotient_m = sortValue[i][tmp_1.m] / sortValue[i][tmp_2.m];
				float quotient_r = sortValue[i][tmp_1.m] / sortValue[i+1][tmp_2.r];
				
				if (quotient_m > 1.6 && quotient_r > 1.6) {
					
					unset(&tmp_2);
				}
			}
		}
		
		if (isset_struct(tmp_2) && !isset_num(res[i])) {
			
			res[i] = tmp_2.num;
		}
		
		if (isset_struct(tmp_3) && !isset_num(res[i])) {
			
			res[i] = tmp_3.num;
		}
		
		if (isset_struct(tmp_1) && !isset_num(res[i])) {
			
			res[i] = tmp_1.num;
		}
		
		if (!isset_num(res[i])) {
			
			res[i] = sortData[i][0];
			
			if (res[i] == -1) {
				res[i] = 0;
			}
		}
		
		//printf("%02d ", resultArray[i]);
	}
    
    /////////////////////////////////////////////////
    
    for (int i=0; i<res_length; i++) {
        rrr[i] = -1;
    }
    
    int sortData2[20][4];
    float sortValue2[20][4];
    
    for (int i=0; i<20; i++) {
        for (int j=0; j<4; j++) {
            
            sortValue2[i][j] = sortValue[19-i][j];
            sortData2[i][j] = sortData[19-i][j];
            
        }
    }
    
    for (int i=19; i>-1; i--) {
		
		struct_tmp tmp_1; tmp_1.num = -1; tmp_1.m = -1; tmp_1.r = -1; tmp_1.r_ = -1; tmp_1.l = -1; tmp_1.l_ = -1;
		struct_tmp tmp_2; tmp_2.num = -1; tmp_2.m = -1; tmp_2.r = -1; tmp_2.r_ = -1; tmp_2.l = -1; tmp_2.l_ = -1;
		struct_tmp tmp_3; tmp_3.num = -1; tmp_3.m = -1; tmp_3.r = -1; tmp_3.r_ = -1; tmp_3.l = -1; tmp_3.l_ = -1;
		
		for (int j=0; j<4; j++) {
			
			int key = -1;
			int key_ = -1;
			
			if (sortData[i][j] != -1 && i > 0 && (key = array_search(sortData[i][j], sortData[i-1], 4)) >= 0) {
				
				if (i > 1 && (key_ = array_search(sortData[i][j], sortData[i-2], 4)) >= 0) {
					
					if (!isset_struct(tmp_3)) {
						
						if (i < 19 && rrr[i+1] == sortData[i][j]) {} else {
                            
							tmp_3.num = sortData[i][j];
							tmp_3.m = j;
							tmp_3.l = key;
							tmp_3.l_ = key_;
						}
						
                        
					}else {
						
						int count_1 = tmp_3.m + tmp_3.l + tmp_3.l_;
						int count_2 = j + key + key_;
						
						if (count_2 < count_1) {
							
							if (i < 19 && rrr[i+1] == sortData[i][j]) {} else {
                                
								tmp_3.num = sortData[i][j];
								tmp_3.m = j;
								tmp_3.l = key;
								tmp_3.l_ = key_;
							}
						}
					}
				}else {
					
					if (!isset_struct(tmp_2)) {
						
						if (i < 19 && rrr[i+1] == sortData[i][j]) {} else {
							
							tmp_2.num = sortData[i][j];
							tmp_2.m = j;
							tmp_2.l = key;
						}
                        
					}else {
						
						int count_1 = tmp_2.m + tmp_2.l;
						int count_2 = j + key;
						
						if (count_2 < count_1) {
							
							if (i < 19 && rrr[i+1] == sortData[i][j]) {} else {
								
								tmp_2.num = sortData[i][j];
								tmp_2.m = j;
								tmp_2.l = key;
							}
						}
					}
				}
				
			}else if (sortData[i][j] != -1) {
				
				if (i == 19 || (i < 19 && rrr[i+1] != sortData[i][j])) {
					
					if (!isset_struct(tmp_1)) {
						
						tmp_1.num = sortData[i][j];
						tmp_1.m = j;
					}
				}
			}
		}
		
		if (isset_struct(tmp_1) && isset_struct(tmp_2)) {
			
			if ((tmp_1.m < tmp_2.m) && (tmp_1.m < tmp_2.l)) {
				
				float quotient_m = sortValue[i][tmp_1.m] / sortValue[i][tmp_2.m];
				float quotient_l = sortValue[i][tmp_1.m] / sortValue[i-1][tmp_2.l];
				
				if (quotient_m > 1.6 && quotient_l > 1.6) {
					
					unset(&tmp_2);
				}
			}
		}
		
		if (isset_struct(tmp_2) && !isset_num(rrr[i])) {
			
			rrr[i] = tmp_2.num;
		}
		
		if (isset_struct(tmp_3) && !isset_num(rrr[i])) {
			
			rrr[i] = tmp_3.num;
		}
		
		if (isset_struct(tmp_1) && !isset_num(rrr[i])) {
			
			rrr[i] = tmp_1.num;
		}
		
		if (!isset_num(rrr[i])) {
			
			rrr[i] = sortData[i][0];
			
			if (rrr[i] == -1) {
				rrr[i] = 0;
			}
		}
	}
    
    for (int i=0; i<10; i++) {
        int t;
        t = rrr[i];
        rrr[i] = rrr[19-i];
        rrr[19-i] = t;
    }
    
    
    ///////////////////////////////////////////////////
    
    //printf("\n\n");
    
    //printf("thresh_hold: %f\n\n", thresh_hold);
    
    // 打印排序数据
    
    /*
     for (int i=0; i<4; i++) {
     
     printf("%d: ", i);
     for (int j=0; j<20; j++) {
     if (sortData[j][i] != -1) {
     printf("%2d ", sortData[j][i]);
     }else {
     printf("   ");
     }
     }
     printf("\n");
     }
     printf("\n");
     
     for (int i=0; i<4; i++) {
     
     printf("%d: ", i);
     for (int j=0; j<20; j++) {
     if (sortValue[j][i] != -1) {
     printf("%.4f  ", sortValue[j][i]);
     }else {
     printf("        ");
     }
     }
     printf("\n");
     }
     
     printf("\n");
     */
}