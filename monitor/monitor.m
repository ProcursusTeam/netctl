#include <Foundation/Foundation.h>
#import <NetworkStatistics/NetworkStatistics.h>
#include <err.h>

void (^description_block)(CFDictionaryRef) = ^(CFDictionaryRef cfDict) {
  NSDictionary* dict = (__bridge NSDictionary*)cfDict;

  NSNumber* pid = dict[kNStatSrcKeyPID];
  NSNumber* txcount = dict[kNStatSrcKeyTxBytes];
  NSNumber* rxcount = dict[kNStatSrcKeyRxBytes];

  NSString* pname = dict[kNStatSrcKeyProcessName];
  NSString* provider = dict[kNStatSrcKeyProvider];

  printf("%s(%d): TX: %d, RX: %d, PROV: %s\n", [pname UTF8String],
		 [pid intValue], [txcount intValue], [rxcount intValue],
		 [provider UTF8String]);
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
