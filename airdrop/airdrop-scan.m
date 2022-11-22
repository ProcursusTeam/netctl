#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Sharing/Sharing.h>
#include <err.h>
#include <getopt.h>
#include <stdio.h>
#include <string.h>

#include "output.h"
#include "netctl.h"

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

int airdropscan(netctl_options *op, int argc, char **argv) {
	devices = [NSMutableArray array];

	discovered = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	SFBrowserRef browser = SFBrowserCreate(kCFAllocatorDefault, kSFBrowserKindAirDrop);
	SFBrowserSetDispatchQueue(browser, dispatch_get_main_queue());
	SFBrowserContext context = {};

	SFBrowserSetClient(browser, airdropBrowserCallBack, &context);
	SFBrowserOpenNode(browser, 0, 0, 0);

	fprintf(stderr, "scanning... timeout set for %f seconds\n", op->timeout);

	CFRunLoopRunInMode(kCFRunLoopDefaultMode, op->timeout, false);

	CFRelease(discovered);
	SFBrowserInvalidate(browser);

	[NCOutput printArray:devices withJSON:op->json];

	return 0;
}
