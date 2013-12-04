//
//  PCMRender.m
//  PlayPCM
//
//  Created by hanchao on 13-11-22.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import "PCMRender.h"


#define SAMPLE_RATE             44100                                                    //采样频率
#define BB_SEMITONE 			1.05946311
#define BB_BASEFREQUENCY		1760
#define BB_BASEFREQUENCY_H		18000
#define BB_BASEFREQUENCY_IS_H	1
#define BB_CHARACTERS			"0123456789abcdefghijklmnopqrstuv"
//#define BB_THRESHOLD            16
#define BITS_PER_SAMPLE         16
#define BB_HEADER_0             17
#define BB_HEADER_1             19
#define DURATION				0.0872 // seconds 0.1744//
#define MAX_VOLUME              0.5
static float frequencies[32];

@implementation PCMRender

#pragma mark -

//wav文件格式详见：http://www-mmsp.ece.mcgill.ca/Documents../AudioFormats/WAVE/WAVE.html
//wav头的结构如下所示：
typedef   struct   {
    char         fccID[4];//"RIFF"标志
    unsigned   long       dwSize;//文件长度
    char         fccType[4];//"WAVE"标志
}HEADER;

typedef   struct   {
    char         fccID[4];//"fmt"标志
    unsigned   long       dwSize;//Chunk size: 16
    unsigned   short     wFormatTag;// 格式类别
    unsigned   short     wChannels;//声道数
    unsigned   long       dwSamplesPerSec;//采样频率
    unsigned   long       dwAvgBytesPerSec;//位速  sample_rate * 2 * chans//为什么乘2呢？因为此时是16位的PCM数据，一个采样占两个byte。
    unsigned   short     wBlockAlign;//一个采样多声道数据块大小
    unsigned   short     uiBitsPerSample;//一个采样占的bit数
}FMT;

typedef   struct   {
    char         fccID[4]; 	//数据标记符＂data＂
    unsigned   long       dwSize;//语音数据的长度，比文件长度小36
}DATA;

//添加wav头信息
int addWAVHeader(unsigned char *buffer, int sample_rate, int bytesPerSample, int channels, long dataByteSize)
{
    //以下是为了建立.wav头而准备的变量
    HEADER   pcmHEADER;
    FMT   pcmFMT;
    DATA   pcmDATA;
    
    //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
    strcpy(pcmHEADER.fccID,"RIFF");
    pcmHEADER.dwSize=44+dataByteSize;   //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
    memcpy(pcmHEADER.fccType, "WAVE", sizeof(char)*4);
    
    memcpy(buffer, &pcmHEADER, sizeof(pcmHEADER));
    
    //以上是创建wav头的HEADER;
    
    //以下是创建wav头的FMT;
    strcpy(pcmFMT.fccID,"fmt ");
    pcmFMT.dwSize=16;
    pcmFMT.wFormatTag=3;
    pcmFMT.wChannels=channels;
    pcmFMT.dwSamplesPerSec=sample_rate;
    pcmFMT.dwAvgBytesPerSec=sample_rate * bytesPerSample * channels;//F * M * Nc
    pcmFMT.wBlockAlign=bytesPerSample * channels;//M * Nc
    pcmFMT.uiBitsPerSample=ceil(8 * bytesPerSample);
    
    memcpy(buffer+sizeof(pcmHEADER), &pcmFMT, sizeof (pcmFMT));
    //以上是创建wav头的FMT;
    
    //以下是创建wav头的DATA;   但由于DATA.dwsize未知所以不能写入.wav文件
    strcpy(pcmDATA.fccID,"data");
    pcmDATA.dwSize=dataByteSize; //给pcmDATA.dwsize   0以便于下面给它赋值
    
    memcpy(buffer+sizeof(pcmHEADER)+sizeof(pcmFMT), &pcmDATA, sizeof(pcmDATA));
    
    return 0;
}

typedef   struct    {
    UInt32  mFileType;
    UInt16  mFileVersion;
    UInt16  mFileFlags;
}CAFFileHeader;

typedef   struct    {
    UInt32  mChunkType;
    SInt64  mChunkSize;
}CAFChunkHeader;

typedef   struct    {
    Float64 mSampleRate;
    UInt32  mFormatID;
    UInt32  mFormatFlags;
    UInt32  mBytesPerPacket;
    UInt32  mFramesPerPacket;
    UInt32  mChannelsPerFrame;
    UInt32  mBitsPerChannel;
}CAFAudioFormat;

////添加wav头信息
//int addCAFHeader(unsigned char *buffer, int sample_rate, int bytesPerSample, int channels, long dataByteSize)
//{
//    //以下是为了建立.wav头而准备的变量
//    CAFFileHeader   fileHEADER;
//    CAFChunkHeader   chunkHEADER;
//    CAFAudioFormat  audioFormatHEADER;
//    
//    
//    strcpy(fileHEADER.mFileType,"caff");
//    fileHEADER.mFileVersion = 1;
//    fileHEADER.mFileFlags = 0;
//    
//    strcpy(chunkHEADER.mChunkType,"desc");
//    chunkHEADER.mChunkSize = sizeof(CAFAudioFormat);
//    
//    audioFormatHEADER.mSampleRate = 44100;
//    strcpy(audioFormatHEADER.mFormatID,"lpcm");
//    audioFormatHEADER.mFormatFlags = (1L << 0);
//    audioFormatHEADER.mBytesPerPacket =
//    audioFormatHEADER
//    
//    
//    //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
//    strcpy(pcmHEADER.fccID,"RIFF");
//    pcmHEADER.dwSize=44+dataByteSize;   //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
//    memcpy(pcmHEADER.fccType, "WAVE", sizeof(char)*4);
//    
//    memcpy(buffer, &pcmHEADER, sizeof(pcmHEADER));
//    
//    //以上是创建wav头的HEADER;
//    
//    //以下是创建wav头的FMT;
//    strcpy(pcmFMT.fccID,"fmt ");
//    pcmFMT.dwSize=16;
//    pcmFMT.wFormatTag=3;
//    pcmFMT.wChannels=channels;
//    pcmFMT.dwSamplesPerSec=sample_rate;
//    pcmFMT.dwAvgBytesPerSec=sample_rate * bytesPerSample * channels;//F * M * Nc
//    pcmFMT.wBlockAlign=bytesPerSample * channels;//M * Nc
//    pcmFMT.uiBitsPerSample=ceil(8 * bytesPerSample);
//    
//    memcpy(buffer+sizeof(pcmHEADER), &pcmFMT, sizeof (pcmFMT));
//    //以上是创建wav头的FMT;
//    
//    //以下是创建wav头的DATA;   但由于DATA.dwsize未知所以不能写入.wav文件
//    strcpy(pcmDATA.fccID,"data");
//    pcmDATA.dwSize=dataByteSize; //给pcmDATA.dwsize   0以便于下面给它赋值
//    
//    memcpy(buffer+sizeof(pcmHEADER)+sizeof(pcmFMT), &pcmDATA, sizeof(pcmDATA));
//    
//    return 0;
//}


#pragma mark - 数字转频率

static int freq_init_flag = 0;
static int freq_init_is_high = 0;

void freq_init() {
	
	if (freq_init_flag) {
		
		return;
	}
    
	//printf("----------------------\n");
	
	int i, len;
	
    if (freq_init_is_high) {
        
        for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
            
            unsigned int freq = (unsigned int)(BB_BASEFREQUENCY_H + (i * 64));
            frequencies[i] = freq;
        }
        
    } else {
        
        for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
            
            unsigned int freq = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, i));
            frequencies[i] = freq;
            
        }
    }
    
    freq_init_flag = 1;
}


void switch_freq(int is_high) {
    
    if (is_high == 0 || is_high == 1) {
        
        freq_init_flag = 0;
        freq_init_is_high = is_high;
        
        freq_init();
    }
}

int num_to_freq(int n, unsigned int *f) {
    
    freq_init();
	
	if (f != NULL && n>=0 && n<32) {
		
		*f =  (unsigned int)floor(frequencies[n]);
		
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


void makeChirp(Float32 buffer[],int bufferLength,unsigned int freqArray[], int freqArrayLength, double duration_secs,
               long sample_rate, int bits_persample) {
    
    double theta = 0;
    int idx = 0;
    for (int i=0; i<freqArrayLength; i++) {
        
        double theta_increment = 2.0 * M_PI * freqArray[i] / sample_rate;
        
        // Generate the samples
        for (UInt32 frame = 0; frame < (duration_secs * sample_rate); frame++)
        {
            Float32 vol = MAX_VOLUME * sqrt( 1.0 - (pow(frame - ((duration_secs * sample_rate) / 2), 2)
                                                    / pow(((duration_secs * sample_rate) / 2), 2)));
            
            buffer[idx++] = vol * sin(theta);
            
            theta += theta_increment;
            if (theta > 2.0 * M_PI)
            {
                theta -= 2.0 * M_PI;
            }
        }
        
    }
}

+ (BOOL)isHighFreq {
    
    return !!freq_init_is_high;
}

+ (void)switchFreq:(BOOL)isHigh {

    int is_high = (isHigh ? 1 : 0);
    switch_freq(is_high);
}

+ (NSData *)renderChirpData:(NSString *)serializeStr {

    if (serializeStr && serializeStr.length > 0) {
    
        /*
         *  序列化字符串转频率
         */
        unichar *charArray = malloc(sizeof(unichar)*serializeStr.length);
        
        [serializeStr getCharacters:charArray];
        
        unsigned freqArray[serializeStr.length+2];//起始音17，19
        //memset(freqArray, 0, sizeof(unsigned) * (serializeStr.length+2));
        
        char_to_freq('h', freqArray);
        char_to_freq('j', freqArray+1);
        
        //freqArray[0] = 123;
        //freqArray[1] = 321;
        
        for (int i=0; i<serializeStr.length; i++) {
            
            //unsigned int freq = 0;
            char_to_freq(charArray[i], freqArray+i+2);
            //freqArray[i+2] = freq;
        }
        
        /*
        for (int i=0; i < 20; i++) {
            
            NSLog(@"%d", freqArray[i]);
        }
         */
        
        free(charArray);
        
        int sampleRate = SAMPLE_RATE;
        float duration = DURATION;
        int channels = 1;
        
        //定义buffer总长度
        long bufferLength = (long)(duration * sampleRate * (serializeStr.length+2));//所有频率总长度(包括17，19)
        Float32 buffer[bufferLength];
        memset(buffer, 0, sizeof(buffer));
        
        makeChirp(buffer, bufferLength, freqArray, serializeStr.length+2, duration, sampleRate, BITS_PER_SAMPLE);
        
        unsigned char wavHeaderByteArray[44];
        memset(wavHeaderByteArray, 0, sizeof(wavHeaderByteArray));
        
        addWAVHeader(wavHeaderByteArray, sampleRate, sizeof(Float32), channels, sizeof(buffer));
        
        NSMutableData *chirpData = [[NSMutableData alloc] initWithBytes:wavHeaderByteArray length:sizeof(wavHeaderByteArray)];
        [chirpData appendBytes:buffer length:sizeof(buffer)];
        
        return [chirpData autorelease];
        
    }
    
    return nil;
}



@end
