//
//  VdiskLogFormatter.m
//  VDiskMobile
//
//  Created by Bruce on 12-11-30.
//
//

#import "VdiskLogDebugFormatter.h"

@implementation VdiskLogDebugFormatter

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
    
    NSArray *logKeys = @[
    @"create_time",
    @"log_ver",
    @"appkey",
    @"client_ver",
    @"client_ver_code",
    @"os_and_ver",
    @"device",
    @"device_uuid",
    @"net_env",
    @"client_ip",
    @"vdisk_uid",
    @"sina_uid",
    @"http_method_and_url",
    @"http_response_status_code",
    @"api_error_code",
    @"client_error_code",
    @"http_bytes_up",
    @"http_bytes_down",
    @"http_time_request",
    @"http_time_response",
    @"elapsed",
    @"custom_type",
    @"custom_key_1",
    @"custom_value_1",
    @"custom_key_2",
    @"custom_value_2",
    @"custom_key_3",
    @"custom_value_3",
    @"custom_key_4",
    @"custom_value_4"];
    
    NSArray *logArray = [logMessage->logMsg componentsSeparatedByString:@"\t"];
    
    NSString *log = [NSString stringWithFormat:@"[%@] : [%@]\n", [logKeys objectAtIndex:0], dateAndTime];
    
    int i = 1;
    
    for (NSString *item in logArray) {
                
        log = [log stringByAppendingFormat:@"[%@] : %@\n", [logKeys objectAtIndex:i], item];
        i++;
    }
        
	return [NSString stringWithFormat:@"------ [LOG_START] ------\n%@------ [LOG_END] ------", log];
}


@end
