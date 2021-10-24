#include <Foundation/Foundation.h>

NSString* CTSettingCopyMyPhoneNumber(void);
int CTGetSignalStrength(void);
void CTIndicatorsGetSignalStrength(long int* raw, long int* graded, long int* bars);
int _CTServerConnectionGetSignalStrength(void);

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
NSString* CTCallCopyAddress(CFAllocatorRef allocator, CTCallRef call);
BOOL CTCallGetDuration(CTCallRef, double*);
