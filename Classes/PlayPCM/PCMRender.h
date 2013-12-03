//
//  PCMRender.h
//  PlayPCM
//
//  Created by hanchao on 13-11-22.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCMRender : NSObject

+ (NSData *)renderChirpData:(NSString *)serializeStr;
+ (void)switchFreq:(BOOL)isHigh;
+ (BOOL)isHighFreq;

@end
