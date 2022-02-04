#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Sharing/Sharing.h>
#include <err.h>
#include <getopt.h>
#include <stdio.h>
#include <string.h>

CFMutableArrayRef discovered;

void airdropBrowserCallBack(SFBrowserRef browser, SFNodeRef node, CFStringRef protocol, SFBrowserFlags flags, SFBrowserError error, void *info) {
	CFArrayRef children = SFBrowserCopyChildren(browser, node);

	for (int i = 0; i < CFArrayGetCount(children); i++) {
		SFNodeRef node = (SFNodeRef)CFArrayGetValueAtIndex(children, i);
		if (![(__bridge NSArray *)discovered
				containsObject:(__bridge id)node]) {
			printf("name: '%s',", [(__bridge_transfer NSString *)SFNodeCopyComputerName(node) UTF8String]);
			printf(" id: '%s'`\n", [(__bridge_transfer NSString *)SFNodeCopyRealName(node) UTF8String]);
			CFArrayAppendValue(discovered, node);
		}
	}
	CFRelease(children);
}

int airdropscan(int argc, char **argv) {
	discovered = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	SFBrowserRef browser = SFBrowserCreate(kCFAllocatorDefault, kSFBrowserKindAirDrop);
	SFBrowserSetDispatchQueue(browser, dispatch_get_main_queue());
	SFBrowserContext context = {};

	SFBrowserSetClient(browser, airdropBrowserCallBack, &context);
	SFBrowserOpenNode(browser, 0, 0, 0);

	CFRunLoopRun();

	CFRelease(discovered);
	SFBrowserInvalidate(browser);

	return 0;
}
