//
//  TablViewCellFactory.h
//  SoundTransform
//
//  Created by hanchao on 13-11-25.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainTableViewCell;
@class WaveTransMetadata;

typedef NS_ENUM(NSInteger, MetaDataFileType) {
    MetaDataFileTypeBinary,        //二进制文件
    MetaDataFileTypeText,          //文本文件
    MetaDataFileTypePhoto,         //图片
    MetaDataFileTypeAudio,         //音频
    MetaDataFileTypeVideo          //视频

};

@interface TableViewCellFactory : NSObject

+(id)getTableViewCellByCellType:(WaveTransMetadata *)metadataReader
                       tableView:(UITableView *)tableView
                           owner:(id)owner;

@end
