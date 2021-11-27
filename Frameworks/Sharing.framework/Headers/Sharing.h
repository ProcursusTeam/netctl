#import <CoreFoundation/CoreFoundation.h>

typedef struct __SFBrowser *SFBrowserRef;
typedef struct __SFNode *SFNodeRef;
SFBrowserRef SFBrowserCreate(CFAllocatorRef, CFStringRef);
extern CFStringRef kSFBrowserKindAirDrop;
void SFBrowserSetDispatchQueue(SFBrowserRef, dispatch_queue_t);
CFStringRef SFNodeCopyComputerName(SFNodeRef);
void SFBrowserOpenNode(SFBrowserRef, SFNodeRef, CFTypeRef, CFOptionFlags);
CFArrayRef SFBrowserCopyChildren(SFBrowserRef, SFNodeRef);
void SFBrowserInvalidate(SFBrowserRef);

struct clientContext {
	CFIndex version;
	CFTypeRef info;
	CFAllocatorRetainCallBack retain;
	CFAllocatorReleaseCallBack release;
	CFAllocatorCopyDescriptionCallBack copyDescription;
};

typedef void (*SFBrowserCallback)(SFBrowserRef, SFNodeRef);
void SFBrowserSetClient(SFBrowserRef, SFBrowserCallback, struct clientContext);
