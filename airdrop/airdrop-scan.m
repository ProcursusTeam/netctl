#import <Sharing/Sharing.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#include <err.h>
#include <getopt.h>
#include <string.h>
#include <stdio.h>

CFMutableArrayRef discovered;

void airdropBrowserCallback(SFBrowserRef browser, SFNodeRef node) {
	CFArrayRef children = SFBrowserCopyChildren(browser, node);

	for (int i = 0; i < CFArrayGetCount(children); i++) {
		SFNodeRef node = (SFNodeRef)CFArrayGetValueAtIndex(children, i);
		if (![(__bridge NSArray *)discovered containsObject:(__bridge id)node]) {
			printf("%s\n", [(__bridge_transfer NSString*)SFNodeCopyComputerName(node) UTF8String]);
			CFArrayAppendValue(discovered, node);
		}
	}
	CFRelease(children);
}

int airdropscan(int argc, char **argv) {
	discovered = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	SFBrowserRef browser = SFBrowserCreate(kCFAllocatorDefault, kSFBrowserKindAirDrop);
	SFBrowserSetDispatchQueue(browser, dispatch_get_main_queue());
	struct clientContext context;
	SFBrowserSetClient(browser, airdropBrowserCallback, context);
	SFBrowserOpenNode(browser, 0, 0, 0);

	CFRunLoopRun();

	CFRelease(discovered);
	SFBrowserInvalidate(browser);

	return 0;
}
