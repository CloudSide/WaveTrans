//
//  TablViewCellFactory.m
//  SoundTransform
//
//  Created by hanchao on 13-11-25.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import "TableViewCellFactory.h"
#import "MainTableViewCell.h"
#import "BinaryCell.h"
#import "TextCell.h"
#import "PhotoCell.h"
#import "AudioCell.h"
#import "VideoCell.h"

@implementation TableViewCellFactory

+(id)getTableViewCellByCellType:(MetaDataFileType)metaDataFileType
                                       tableView:(UITableView *)tableView
                                           owner:(id)owner
{
    NSString *identifier = nil;
    
    switch (metaDataFileType) {
        
        case MetaDataFileTypeBinary:
        identifier = @"BinaryCell";
        break;
        
        case MetaDataFileTypeText:
        identifier = @"TextCell";
        break;
        
        case MetaDataFileTypePhoto:
        identifier = @"PhotoCell";
        break;
        
        case MetaDataFileTypeAudio:
        identifier = @"AudioCell";
        break;
        
        case MetaDataFileTypeVideo:
        identifier = @"VideoCell";
        break;
        
        default:
        break;
    }
    
    if (identifier) {
        
        MainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:identifier owner:owner options:nil]
                                            objectAtIndex:0];
            cell.delegate = owner;
        }
        
        return cell;
    }
    
    return nil;
    
}

@end
