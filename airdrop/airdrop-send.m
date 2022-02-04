#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Sharing/Sharing.h>
#include <err.h>
#include <getopt.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

NSString *name;
NSMutableArray *files;
bool foundNode = false;

void airdropSendOperationCallback(SFOperationRef operation, SFOperationEvent event, CFDictionaryRef results, void *info) {
	NSError *error;
	NSNumber *copied, *total;

	switch (event) {
		case CANCELED:
			exit(1);
			CFRunLoopStop(CFRunLoopGetCurrent());
			break;
		case FINISHED:
			CFRunLoopStop(CFRunLoopGetCurrent());
			break;
		case ERROR:
			error = (__bridge_transfer NSError*)CFDictionaryGetValue(results, kSFOperationErrorKey);
			errx(1, "%s", error.localizedDescription.UTF8String);
			break;
		case PROGRESS:
			copied = (__bridge_transfer NSNumber*)CFDictionaryGetValue(results, kSFOperationBytesCopiedKey);
			total = (__bridge_transfer NSNumber*)CFDictionaryGetValue(results, kSFOperationTotalBytesKey);
			printf("%lld B/%lld B\n", copied.longLongValue, total.longLongValue);
			break;
		default:
			break;
	}
}

void airdropSendBrowserCallback(SFBrowserRef browser, SFNodeRef node, CFStringRef protocol, SFBrowserFlags flags, SFBrowserError error, void *info) {
	CFArrayRef children = SFBrowserCopyChildren(browser, node);

	for (int i = 0; i < CFArrayGetCount(children); i++) {
		SFNodeRef node = (SFNodeRef)CFArrayGetValueAtIndex(children, i);
		if (foundNode == false &&
				([(__bridge_transfer NSString *)SFNodeCopyComputerName(node) isEqualToString:name] ||
				 [(__bridge_transfer NSString *)SFNodeCopyRealName(node) isEqualToString:name])) {
			foundNode = true;
			SFOperationRef operation = SFOperationCreate(kCFAllocatorDefault, kSFOperationKindSender);
			SFOperationSetProperty(operation, kSFOperationItemsKey, (__bridge CFArrayRef)files);
			SFOperationSetProperty(operation, kSFOperationNodeKey, node);
			SFOperationContext context = {};
			SFOperationSetDispatchQueue(operation, dispatch_get_main_queue());
			SFOperationSetClient(operation, airdropSendOperationCallback, &context);
			SFOperationResume(operation);
			break;
		}
	}
	CFRelease(children);
}

int airdropsend(int argc, char **argv) {
	if (argc < 3) {
		fprintf(stderr, "Usage: netctl airdrop send reciever files...\n");
		return 1;
	}

	name = [NSString stringWithUTF8String:argv[1]];

	files = [[NSMutableArray alloc] init];

	for (int i = 2; i < argc; i++) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:argv[i]]])
			[files addObject:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[i]]]];
		else
			[files addObject:[NSURL URLWithString:[NSString stringWithUTF8String:argv[i]]]];
	}

	SFBrowserRef browser = SFBrowserCreate(kCFAllocatorDefault, kSFBrowserKindAirDrop);
	SFBrowserSetDispatchQueue(browser, dispatch_get_main_queue());
	SFBrowserContext context = {};
	SFBrowserSetClient(browser, airdropSendBrowserCallback, &context);
	SFBrowserOpenNode(browser, 0, 0, 0);

	CFRunLoopRun();

	return 0;
}
