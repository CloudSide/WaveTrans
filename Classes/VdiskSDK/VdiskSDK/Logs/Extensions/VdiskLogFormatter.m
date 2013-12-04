//
//  VdiskLogFormatter.m
//  VDiskMobile
//
//  Created by Bruce on 12-11-30.
//
//

#import "VdiskLogFormatter.h"

@implementation VdiskLogFormatter

- (id)init {
    
	return [self initWithDateFormatter:nil];
}

- (id)initWithDateFormatter:(NSDateFormatter *)aDateFormatter {
    
	if ((self = [super init])) {
        
		if (aDateFormatter) {
            
			_dateFormatter = aDateFormatter;
		
        } else {
            
			_dateFormatter = [[NSDateFormatter alloc] init];
			[_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            [_dateFormatter setLocale:usLocale];
            [_dateFormatter setDateFormat:@"dd/MMM/yyyy:HH:mm:ss ZZZ"];
		}
	}
    
	return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    
	NSString *dateAndTime = [_dateFormatter stringFromDate:(logMessage->timestamp)];
	return [NSString stringWithFormat:@"[%@]\t%@", dateAndTime, logMessage->logMsg];
}


@end
