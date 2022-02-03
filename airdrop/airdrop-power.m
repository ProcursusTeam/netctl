#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Sharing/Sharing.h>
#include <stdio.h>

int airdroppower(char *action) {
	SFOperationRef operation = SFOperationCreate(kCFAllocatorDefault, kSFOperationKindController);

	if (action == NULL || !strcmp(action, "status")) {
		NSLog(@"%@", SFOperationCopyProperty(operation, kSFOperationDiscoverableModeKey));
		SFOperation
		return 0;
	} else if (!strcmp(action, "everyone") || !strcmp(action, "on")) {
		SFOperationSetProperty(operation, kSFOperationDiscoverableModeKey, kSFOperationDiscoverableModeEveryone);
		SFOperationResume(operation);
		return 0;
	} else if (!strcmp(action, "contacts")) {
		SFOperationSetProperty(operation, kSFOperationDiscoverableModeKey, kSFOperationDiscoverableModeContactsOnly);
		SFOperationResume(operation);
		return 0;
	} else if (!strcmp(action, "off")) {
		SFOperationSetProperty(operation, kSFOperationDiscoverableModeKey, kSFOperationDiscoverableModeOff);
		SFOperationResume(operation);
		return 0;
	}


	fprintf(stderr, "Usage: netctl airdrop power [status | everyone | contacts | off]\n");
	return 1;
}
