#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Sharing/Sharing.h>
#include <err.h>
#include <getopt.h>
#include <stdio.h>
#include <string.h>

#include "../include/output.h"

CFMutableArrayRef discovered;

NSMutableArray* devices;

void airdropBrowserCallBack(SFBrowserRef browser, SFNodeRef node, CFStringRef protocol, SFBrowserFlags flags, SFBrowserError error, void *info) {
	CFArrayRef children = SFBrowserCopyChildren(browser, node);

	for (int i = 0; i < CFArrayGetCount(children); i++) {
		SFNodeRef node = (SFNodeRef)CFArrayGetValueAtIndex(children, i);
		if (![(__bridge NSArray *)discovered
				containsObject:(__bridge id)node]) {

			NSString* name = (__bridge_transfer NSString *)SFNodeCopyComputerName(node);
			NSString* ident = (__bridge_transfer NSString *)SFNodeCopyRealName(node);

			[devices addObjectsFromArray:@[
				@{ @"name" : name},
				@{ @"id" : ident}
			]];

			CFArrayAppendValue(discovered, node);
		}
	}
	CFRelease(children);
}

int airdropscan(int argc, char **argv) {
	int ch, index;
	int timeout = 30;
	const char *errstr;

	devices = [NSMutableArray array];

	struct option opts[] = {
		{ "timeout", required_argument, 0, 't' },
		{ NULL, 0, NULL, 0 }
	};

	while ((ch = getopt_long(argc, argv, "t:", opts, &index)) != -1) {
		switch (ch) {
			case 't':
				timeout = strtonum(optarg, 0, INT_MAX, &errstr);
				if (errstr != NULL)
					err(1, "%s", optarg);
				break;
		}
	}
	argc -= optind;
	argv += optind;

	discovered = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	SFBrowserRef browser = SFBrowserCreate(kCFAllocatorDefault, kSFBrowserKindAirDrop);
	SFBrowserSetDispatchQueue(browser, dispatch_get_main_queue());
	SFBrowserContext context = {};

	SFBrowserSetClient(browser, airdropBrowserCallBack, &context);
	SFBrowserOpenNode(browser, 0, 0, 0);

	fprintf(stderr, "scanning... timeout set for %d seconds\n", timeout);

	CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeout, false);

	CFRelease(discovered);
	SFBrowserInvalidate(browser);

	[NCOutput printArray:devices withJSON:YES];

	return 0;
}
