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
#import "WaveTransMetadata.h"

#import "VdiskJSON.h"

@implementation TableViewCellFactory

+(id)getTableViewCellByCellType:(WaveTransMetadata *)metadata
                      tableView:(UITableView *)tableView
                          owner:(id)owner
{
    NSString *identifier = nil;
    
    if ([metadata.type isEqualToString:@"file"]) {//text | url | file
        
        if ([metadata.reader isEqualToString:@"image"]) {
            identifier = @"PhotoCell";
        }else if ([metadata.reader isEqualToString:@"sound"]){
            identifier = @"AudioCell";
        }else if ([metadata.reader isEqualToString:@"video"]){
            identifier = @"VideoCell";
        }else if ([metadata.reader isEqualToString:@"txt"] || [metadata.reader isEqualToString:@"code"]){
            identifier = @"TextCell";
        }else {
            identifier = @"BinaryCell";
        }
    }else if ([metadata.type isEqualToString:@"url"]){
        //字符串
        identifier = @"PureTextCell";
    }else if ([metadata.type isEqualToString:@"text"]){
        
        if(metadata.isJson){
            NSDictionary *jsonDict = [metadata.content JSONValue];
            
            if ([[jsonDict allKeys] containsObject:@"wave_weibo_card"]) {//weibo
                
                identifier = @"WeiboCell";

            }else if ([[jsonDict allKeys] containsObject:@"wave_people_card"]) {//weibo
                
                identifier = @"ContactsCell";
            }else{
                //TODO:其他
                identifier = @"PureTextCell";
            }
        }else{
            //字符串
            identifier = @"PureTextCell";
            
        }
        
    }else{
        //TODO:unknow type!!!
    }
    
    if (identifier) {
        
        MainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:identifier owner:owner options:nil]
                                            objectAtIndex:0];
        }
        
        cell.delegate = owner;
        
        cell.metadata = metadata;
//        //TODO:test
//        cell.downloadProgress = 0.74f;
        
        return cell;
    }
    
    return nil;
    
}

@end
