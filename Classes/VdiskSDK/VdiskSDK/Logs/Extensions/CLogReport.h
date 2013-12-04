//
//  CLogReport.h
//  VDiskMobile
//
//  Created by Bruce on 12-12-4.
//
//

#import <Foundation/Foundation.h>
#import "ASIFormDataRequest.h"

@interface CLogReport : NSObject <ASIHTTPRequestDelegate>


+ (id)sharedLogReport;
+ (void)setSharedLogReport:(CLogReport *)logReport;
- (void)fire;
- (id)initWithLogsDirectory:(NSString *)logsDirectory;

@end
