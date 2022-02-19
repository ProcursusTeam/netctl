#include <Foundation/Foundation.h>
#import <NetworkStatistics/NetworkStatistics.h>
#include <err.h>

static inline BOOL isTCP(NSString* provider) {
	return [provider isEqualToString:@"TCP"];
}

void (^description_block)(CFDictionaryRef) = ^(CFDictionaryRef cfDict) {
  NSDictionary* dict = (__bridge NSDictionary*)cfDict;

  NSNumber* pid = dict[kNStatSrcKeyPID];
  NSNumber* txcount = dict[kNStatSrcKeyTxBytes];
  NSNumber* rxcount = dict[kNStatSrcKeyRxBytes];

  NSString* pname = dict[kNStatSrcKeyProcessName];
  NSString* provider = dict[kNStatSrcKeyProvider];
  NSString* state = dict[kNStatSrcKeyTCPState];

  NSMutableString* outputstr = [NSMutableString string];

  [outputstr appendString:[NSString stringWithFormat:@"%@(%@): ", pname, pid]];
  if (isTCP(provider)) {
	  [outputstr
		  appendString:[NSString stringWithFormat:@"TCPSTATE: %@, ", state]];
  }

  [outputstr
	  appendString:[NSString stringWithFormat:@"TX: %@, RX: %@, PROV: %@",
											  txcount, rxcount, provider]];

  puts([outputstr UTF8String]);
};

void (^callback)(void*, void*) = ^(NStatSourceRef ref, void* arg2) {
  NStatSourceSetDescriptionBlock(ref, description_block);
  NStatSourceQueryDescription(ref);
};

int nctl_monitor(int argc, char** argv) {
	if (argc < 2) {
		errno = EINVAL;
		errx(1, "not enough args");
	}

	BOOL monitorTCP = NO;
	BOOL monitorUDP = NO;

	if (!strcmp(argv[1], "tcp")) {
		monitorTCP = YES;
	}
	if (!strcmp(argv[1], "udp")) {
		monitorUDP = YES;
	}
	if (!strcmp(argv[1], "all")) {
		monitorTCP = YES;
		monitorUDP = YES;
	}

	NStatManagerRef ref = NStatManagerCreate(
		kCFAllocatorDefault, dispatch_get_main_queue(), callback);

	if (monitorTCP) {
		NStatManagerAddAllTCPWithFilter(ref, 0, 0);
	}

	if (monitorUDP) {
		NStatManagerAddAllUDPWithFilter(ref, 0, 0);
	}

	NStatManagerSetFlags(ref, 0);

	NStatManagerAddAllTCPWithFilter(ref, 0, 0);

	dispatch_main();
}
