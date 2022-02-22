#include <Foundation/Foundation.h>
#import <NetworkStatistics/NetworkStatistics.h>
#include <arpa/inet.h>
#include <err.h>
#include <netdb.h>
#include <sys/socket.h>

#include "SourceInfo.h"

void (^description_block)(CFDictionaryRef) = ^(CFDictionaryRef cfDict) {
  NSDictionary* dict = (__bridge NSDictionary*)cfDict;
  NCSourceInfo* info = [[NCSourceInfo alloc] initWithDict:dict];

  char localHostname[256] = {0};
  getnameinfo(info.localAddress, info.localAddress->sa_len, localHostname,
			  sizeof(localHostname), NULL, 0, NI_NUMERICHOST);

  char remoteHostname[256] = {0};
  getnameinfo(info.remoteAddress, info.remoteAddress->sa_len, remoteHostname,
			  sizeof(remoteHostname), NULL, 0, NI_NUMERICHOST);

  printf("%s\t%20s(%s)%30s\t%30s\ttx:%llu rx:%llu\t %s(%d)\n",
		 info.timeStamp.UTF8String, info.protocol.UTF8String,
		 info.TCPState.UTF8String, localHostname, remoteHostname,
		 info.dataProcessed.tx.unsignedLongLongValue,
		 info.dataProcessed.rx.unsignedLongLongValue,
		 info.processName.UTF8String, info.PID.intValue);
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
