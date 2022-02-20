#include "SourceInfo.h"

#import <Foundation/Foundation.h>
#import <NetworkStatistics/NetworkStatistics.h>

#include "DataInfo.h"

static BOOL isTCP(NSString*);
static NSString* interfaceType(NSDictionary* sourceDict);

@implementation NCSourceInfo
- (instancetype)initWithDict:(NSDictionary*)dict {
	self = [super init];

	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"HH:mm:ss"];

	self.timeStamp = [formatter stringFromDate:[NSDate date]];
	self.protocol = dict[kNStatSrcKeyProvider];
	self.TCPState = nil;
	self.localAddress = (const struct sockaddr*)[dict[kNStatSrcKeyLocal] bytes];
	self.remoteAddress =
		(const struct sockaddr*)[dict[kNStatSrcKeyRemote] bytes];

	NCDataInfo* dataInfo = [[NCDataInfo alloc] initWithDict:dict];

	self.PID = dict[kNStatSrcKeyPID];
	self.processName = dict[kNStatSrcKeyProcessName];
	self.dataProcessed = dataInfo;

	if (isTCP(self.protocol)) {
		self.TCPState = dict[kNStatSrcKeyTCPState];
	}

	return self;
}
@end

static NSString* interfaceType(NSDictionary* sourceDict) {
	if (sourceDict[kNStatSrcKeyInterfaceTypeCellular]) {
		return @"Cellular";
	}

	if (sourceDict[kNStatSrcKeyInterfaceTypeLoopback]) {
		return @"Loopback";
	}

	if (sourceDict[kNStatSrcKeyInterfaceTypeUnknown]) {
		return @"Other";
	}

	if (sourceDict[kNStatSrcKeyInterfaceTypeWiFi]) {
		return @"WiFi";
	}

	if (sourceDict[kNStatSrcKeyInterfaceTypeWired]) {
		return @"Wired";
	}

	return @"Other";
}

static BOOL isTCP(NSString* provider) {
	return [provider isEqualToString:@"TCP"];
}