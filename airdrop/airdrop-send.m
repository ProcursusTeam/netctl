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
		case UNKNOWN:
			NSLog(@"UNKNOWN");
			break;
		case NEW_OPERATION:
			NSLog(@"NEW_OPERATION");
			break;
		case ASK_USER:
			NSLog(@"ASK_USER");
			break;
		case WAIT_FOR_ANSWER:
			NSLog(@"WAIT_FOR_ANSWER");
			break;
		case CANCELED:
			NSLog(@"CANCELED");
			CFRunLoopStop(CFRunLoopGetCurrent());
			break;
		case STARTED:
			NSLog(@"STARTED");
			break;
		case PREPROCESS:
			NSLog(@"PREPROCESS");
			break;
		case PROGRESS:
			NSLog(@"PROGRESS");
			break;
		case POSTPROCESS:
			NSLog(@"POSTPROCESS");
			break;
		case FINISHED:
			NSLog(@"FINISHED");
			CFRunLoopStop(CFRunLoopGetCurrent());
			break;
		case ERROR:
			NSLog(@"ERROR");
			error = (__bridge_transfer NSError*)SFOperationCopyProperty(operation, kSFOperationErrorKey);
			errx(1, "%s", error.localizedDescription.UTF8String);
			break;
		case CONNECTING:
			NSLog(@"CONNECTING");
			break;
		case INFORMATION:
			NSLog(@"INFORMATION");
			break;
		case CONFLICT:
			NSLog(@"CONFLICT");
			break;
		case BLOCKED:
			NSLog(@"BLOCKED");
			break;
		case CONVERTING:
			NSLog(@"CONVERTING");
			break;
		default:
			NSLog(@"%lu", (long)ret);
			break;
	}
}

void airdropSendBrowserCallback(SFBrowserRef browser, SFNodeRef node) {
	CFArrayRef children = SFBrowserCopyChildren(browser, node);

	for (int i = 0; i < CFArrayGetCount(children); i++) {
		SFNodeRef node = (SFNodeRef)CFArrayGetValueAtIndex(children, i);
		NSLog(@"%@", node);
		if ([(__bridge_transfer NSString *)SFNodeCopyComputerName(node)
				isEqualToString:name] || [(__bridge_transfer NSString *)SFNodeCopyRealName(node)
					   isEqualToString:name]) {
			SFOperationRef operation = SFOperationCreate(kCFAllocatorDefault, kSFOperationKindSender);
			NSLog(@"%@", files);
			SFOperationSetProperty(operation, kSFOperationItemsKey, (__bridge CFArrayRef)files);
			SFOperationSetProperty(operation, kSFOperationNodeKey, node);
			struct clientContext context;
			SFOperationSetClient(operation, airdropSendOperationCallback, context);
			SFOperationSetDispatchQueue(operation, dispatch_get_main_queue());
			SFOperationResume(operation);
			goto exit;
		}
	}
exit:
	CFRelease(children);
}



int airdropsend(int argc, char **argv) {
	if (argc < 3) errx(1, "Not enough args");

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
