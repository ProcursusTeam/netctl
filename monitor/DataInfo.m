#import "DataInfo.h"

#import <Foundation/Foundation.h>
#import <NetworkStatistics/NetworkStatistics.h>

@implementation NCDataInfo

- (instancetype)initWithDict:(NSDictionary*)dict {
	self = [super init];

	self.tx = dict[kNStatSrcKeyTxBytes];
	self.txWiFi = dict[kNStatSrcKeyTxWiFiBytes];
	self.txCellular = dict[kNStatSrcKeyTxCellularBytes];

	self.rx = dict[kNStatSrcKeyRxBytes];
	self.rxWiFi = dict[kNStatSrcKeyRxWiFiBytes];
	self.rxCellular = dict[kNStatSrcKeyRxCellularBytes];

	return self;
}

@end