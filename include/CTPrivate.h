#include <Foundation/Foundation.h>

CFStringRef CTSettingCopyMyPhoneNumber(void);
int CTGetSignalStrength(void);
void CTIndicatorsGetSignalStrength(long int* raw, long int* graded, long int* bars);
int _CTServerConnectionGetSignalStrength(void);
CFStringRef CTRegistrationGetStatus(void);

typedef enum {
	kCTCallStatusUnknown = 0,
	kCTCallStatusAnswered,
	kCTCallStatusDroppedInterrupted,
	kCTCallStatusOutgoingInitiated,
	kCTCallStatusIncomingCall,
	kCTCallStatusIncomingCallEnded
} CTCallStatus;

typedef void* CTCallRef;
CTCallRef CTCallDial(NSString* number);
CTCallStatus CTCallGetStatus(CTCallRef call);
CFStringRef CTCallCopyAddress(CFAllocatorRef allocator, CTCallRef call);
BOOL CTCallGetDuration(CTCallRef, double*);
