#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#include <err.h>
#include <getopt.h>
#include <string.h>
#include <stdio.h>

typedef struct __SFBrowser *SFBrowserRef;
typedef struct __SFNode *SFNodeRef;
SFBrowserRef SFBrowserCreate(CFAllocatorRef, CFStringRef);
extern CFStringRef kSFBrowserKindAirDrop;
void SFBrowserSetDispatchQueue(SFBrowserRef, dispatch_queue_t);
CFStringRef SFNodeCopyComputerName(SFNodeRef);
void SFBrowserOpenNode(SFBrowserRef, SFNodeRef, CFTypeRef, CFOptionFlags);
CFArrayRef SFBrowserCopyChildren(SFBrowserRef, SFNodeRef);

struct clientContext {
	CFIndex version;
	CFTypeRef info;
	CFAllocatorRetainCallBack retain;
	CFAllocatorReleaseCallBack release;
	CFAllocatorCopyDescriptionCallBack copyDescription;
};

typedef void (*SFBrowserCallback)(SFBrowserRef, SFNodeRef);
void SFBrowserSetClient(SFBrowserRef, SFBrowserCallback, struct clientContext);

void airdropBrowserCallback(SFBrowserRef browser, SFNodeRef node) {
	CFArrayRef children = SFBrowserCopyChildren(browser, node);
	for (int i = 0; i < CFArrayGetCount(children); i++) {
		SFNodeRef node = (SFNodeRef)CFArrayGetValueAtIndex(children, i);
		printf("%s\n", [(__bridge_transfer NSString*)SFNodeCopyComputerName(node) UTF8String]);
	}
}

int airdrop(int argc, char **argv) {
	if (!argv[2]) {
		errx(1, "no airdrop subcommand specified");
		return 1;
	}

	int ret = 1;

	if (!strcmp(argv[2], "scan") || !strcmp(argv[2], "browser")) {
		SFBrowserRef browser = SFBrowserCreate(kCFAllocatorDefault, kSFBrowserKindAirDrop);
		SFBrowserSetDispatchQueue(browser, dispatch_get_main_queue());
		struct clientContext context;
		SFBrowserSetClient(browser, airdropBrowserCallback, context);
		SFBrowserOpenNode(browser, 0, 0, 0);
		CFRunLoopRun();
	}

	return ret;
}
