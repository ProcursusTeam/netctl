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

typedef CF_OPTIONS(CFOptionFlags, SFBrowserFlags) {
	kSFBrowserFlagsNone = 0,
	kSFBrowserFlagsGuest = 1,
	kSFBrowserFlagsAnonymous = 2,
	kSFBrowserFlagsForceUI = 4,
	kSFBrowserFlagsAllowUI = 8,
	kSFBrowserFlagsAsk = 16
};

enum SFBrowserError {
	kSFBrowserErrorNone = 0,
	kSFBrowserErrorFailed = -1,
	kSFBrowserErrorNotAuthorized = -2,
	kSFBrowserErrorBadArgument = -3
};
typedef enum SFBrowserError SFBrowserError;

struct SFContext {
	CFIndex version;
	void *info;
	CFAllocatorRetainCallBack retain;
	CFAllocatorReleaseCallBack release;
	CFAllocatorCopyDescriptionCallBack copyDescription;
};
typedef struct SFContext SFBrowserContext;
typedef struct SFContext SFOperationContext;

typedef void (*SFBrowserCallBack)(SFBrowserRef browser, SFNodeRef node, CFStringRef protocol, SFBrowserFlags flags, SFBrowserError error, void *info);
void SFBrowserSetClient(SFBrowserRef, SFBrowserCallBack, SFBrowserContext*);

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
typedef enum SFOperationEvent SFOperationEvent;

SFOperationRef SFOperationCreate(CFAllocatorRef, CFStringRef);
typedef void (*SFOperationCallBack)(SFOperationRef operation, SFOperationEvent event, CFDictionaryRef results, void *info);
void SFOperationSetClient(SFOperationRef, SFOperationCallBack, SFOperationContext*);
void SFOperationSetProperty(SFOperationRef, CFStringRef, CFTypeRef);
void SFOperationSetDispatchQueue(SFOperationRef, dispatch_queue_t);
void SFOperationResume(SFOperationRef);
CFTypeRef SFOperationCopyProperty(SFOperationRef, CFStringRef);
