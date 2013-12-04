//
//  VdiskLogFormatter.h
//  VDiskMobile
//
//  Created by Bruce on 12-11-30.
//
//

#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "DDFileLogger.h"

@interface VdiskLogFormatter : NSObject <DDLogFormatter> {
    
	NSDateFormatter *_dateFormatter;
}

- (id)init;
- (id)initWithDateFormatter:(NSDateFormatter *)dateFormatter;


@end
