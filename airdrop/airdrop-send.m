#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Sharing/Sharing.h>
#include <err.h>
#include <getopt.h>
#include <stdio.h>
#include <string.h>

NSString *name;
NSMutableArray *files;

void airdropSendOperationCallback(SFOperationRef operation, CFIndex ret, CFDictionaryRef results) {
	NSError *error;
	switch (ret) {
		case CANCELED:
			exit(1);
			CFRunLoopStop(CFRunLoopGetCurrent());
			break;
		case FINISHED:
			CFRunLoopStop(CFRunLoopGetCurrent());
			break;
		case ERROR:
			error = (__bridge_transfer NSError*)SFOperationCopyProperty(operation, kSFOperationErrorKey);
			errx(1, "%s", error.localizedDescription.UTF8String);
			break;
		default:
			break;
	}
}

void airdropSendBrowserCallback(SFBrowserRef browser, SFNodeRef node) {
	CFArrayRef children = SFBrowserCopyChildren(browser, node);

	for (int i = 0; i < CFArrayGetCount(children); i++) {
		SFNodeRef node = (SFNodeRef)CFArrayGetValueAtIndex(children, i);
		if ([(__bridge_transfer NSString *)SFNodeCopyComputerName(node)
				isEqualToString:name] || [(__bridge_transfer NSString *)SFNodeCopyRealName(node)
					   isEqualToString:name]) {
			SFOperationRef operation = SFOperationCreate(kCFAllocatorDefault, kSFOperationKindSender);
			SFOperationSetProperty(operation, kSFOperationItemsKey, (__bridge CFArrayRef)files);
			SFOperationSetProperty(operation, kSFOperationNodeKey, node);
			struct clientContext context;
			SFOperationSetDispatchQueue(operation, dispatch_get_main_queue());
			SFOperationSetClient(operation, airdropSendOperationCallback, context);
			SFOperationResume(operation);
			goto exit;
		}
	}
exit:
	CFRelease(children);
}



int airdropsend(int argc, char **argv) {
	if (argc < 3)
		errx(1, "Not enough args");

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
	struct clientContext context;
	SFBrowserSetClient(browser, airdropSendBrowserCallback, context);
	SFBrowserOpenNode(browser, 0, 0, 0);

	CFRunLoopRun();

	return 0;
}
