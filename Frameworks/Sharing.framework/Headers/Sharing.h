#import <CoreFoundation/CoreFoundation.h>

typedef struct __SFBrowser *SFBrowserRef;
typedef struct __SFNode *SFNodeRef;
typedef struct __SFOperation *SFOperationRef;
SFBrowserRef SFBrowserCreate(CFAllocatorRef, CFStringRef);
extern CFStringRef kSFBrowserKindAirDrop;
extern CFStringRef kSFOperationKindSender;
extern CFStringRef kSFOperationFileIconKey;
extern CFStringRef kSFOperationItemsKey;
extern CFStringRef kSFOperationNodeKey;
extern CFStringRef kSFOperationErrorKey;
extern CFStringRef kSFOperationKindKey;
void SFBrowserSetDispatchQueue(SFBrowserRef, dispatch_queue_t);
CFStringRef SFNodeCopyComputerName(SFNodeRef);
CFStringRef SFNodeCopyFirstName(SFNodeRef);
CFStringRef SFNodeCopyLastName(SFNodeRef);
CFStringRef SFNodeCopyRealName(SFNodeRef);
CFStringRef SFNodeCopyIDSDeviceIdentifier(SFNodeRef);
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

enum SFOperationEvent {
	UNKNOWN = 0,
	NEW_OPERATION,
	ASK_USER,
	WAIT_FOR_ANSWER,
	CANCELED,
	STARTED,
	PREPROCESS,
	PROGRESS,
	POSTPROCESS,
	FINISHED,
	ERROR,
	CONNECTING,
	INFORMATION,
	CONFLICT,
	BLOCKED,
	CONVERTING
};

SFOperationRef SFOperationCreate(CFAllocatorRef, CFStringRef);
typedef void (*SFOperationCallback)(SFOperationRef, CFIndex, CFDictionaryRef);
void SFOperationSetClient(SFOperationRef, SFOperationCallback, struct clientContext);
void SFOperationSetProperty(SFOperationRef, CFStringRef, CFTypeRef);
void SFOperationSetDispatchQueue(SFOperationRef, dispatch_queue_t);
void SFOperationResume(SFOperationRef);
CFTypeRef SFOperationCopyProperty(SFOperationRef, CFStringRef);
