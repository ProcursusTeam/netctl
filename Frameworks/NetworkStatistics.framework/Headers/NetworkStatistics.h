#include <Foundation/Foundation.h>

// credit to Jonathan Levin (jlevin) :
// http://newosxbook.com/src.jl?tree=listings&file=netbottom.c
typedef void* NStatManagerRef;
typedef void* NStatSourceRef;

NStatManagerRef NStatManagerCreate(const struct __CFAllocator*,
								   dispatch_queue_t, void (^)(void*, void*));

int NStatManagerSetInterfaceTraceFD(NStatManagerRef, int fd);
int NStatManagerSetFlags(NStatManagerRef, int Flags);
int NStatManagerAddAllTCPWithFilter(NStatManagerRef, int something,
									int somethingElse);
int NStatManagerAddAllUDPWithFilter(NStatManagerRef, int something,
									int somethingElse);
void* NStatSourceQueryDescription(NStatSourceRef);

extern CFStringRef kNStatProviderInterface;
extern CFStringRef kNStatProviderRoute;
extern CFStringRef kNStatProviderSysinfo;
extern CFStringRef kNStatProviderTCP;

extern CFStringRef kNStatSrcTCPStateCloseWait;
extern CFStringRef kNStatSrcTCPStateClosed;
extern CFStringRef kNStatSrcTCPStateClosing;
extern CFStringRef kNStatSrcTCPStateEstablished;
extern CFStringRef kNStatSrcTCPStateFinWait1;
extern CFStringRef kNStatSrcTCPStateFinWait2;
extern CFStringRef kNStatSrcTCPStateLastAck;
extern CFStringRef kNStatSrcTCPStateListen;
extern CFStringRef kNStatSrcTCPStateSynReceived;
extern CFStringRef kNStatSrcTCPStateSynSent;
extern CFStringRef kNStatSrcTCPStateTimeWait;

// Keys for the source dictionary in the description callback.
// These are actually CFStringRefs, but import them as NSStrings
// so that we can use objc APIs without a bunch of __bridges
extern NSString* kNStatProviderUDP;
extern NSString* kNStatSrcKeyAvgRTT;
extern NSString* kNStatSrcKeyChannelArchitecture;
extern NSString* kNStatSrcKeyConnProbeFailed;
extern NSString* kNStatSrcKeyConnectAttempt;
extern NSString* kNStatSrcKeyConnectSuccess;
extern NSString* kNStatSrcKeyDurationAbsoluteTime;
extern NSString* kNStatSrcKeyEPID;
extern NSString* kNStatSrcKeyEUPID;
extern NSString* kNStatSrcKeyEUUID;
extern NSString* kNStatSrcKeyInterface;
extern NSString* kNStatSrcKeyInterfaceCellConfigBackoffTime;
extern NSString* kNStatSrcKeyInterfaceCellConfigInactivityTime;
extern NSString* kNStatSrcKeyInterfaceCellUlAvgQueueSize;
extern NSString* kNStatSrcKeyInterfaceCellUlMaxQueueSize;
extern NSString* kNStatSrcKeyInterfaceCellUlMinQueueSize;
extern NSString* kNStatSrcKeyInterfaceDescription;
extern NSString* kNStatSrcKeyInterfaceDlCurrentBandwidth;
extern NSString* kNStatSrcKeyInterfaceDlMaxBandwidth;
extern NSString* kNStatSrcKeyInterfaceIsAWD;
extern NSString* kNStatSrcKeyInterfaceIsAWDL;
extern NSString* kNStatSrcKeyInterfaceIsCellFallback;
extern NSString* kNStatSrcKeyInterfaceIsExpensive;
extern NSString* kNStatSrcKeyInterfaceLinkQualityMetric;
extern NSString* kNStatSrcKeyInterfaceName;
extern NSString* kNStatSrcKeyInterfaceThreshold;
extern NSString* kNStatSrcKeyInterfaceType;
extern NSString* kNStatSrcKeyInterfaceTypeCellular;
extern NSString* kNStatSrcKeyInterfaceTypeLoopback;
extern NSString* kNStatSrcKeyInterfaceTypeUnknown;
extern NSString* kNStatSrcKeyInterfaceTypeWiFi;
extern NSString* kNStatSrcKeyInterfaceTypeWired;
extern NSString* kNStatSrcKeyInterfaceUlBytesLost;
extern NSString* kNStatSrcKeyInterfaceUlCurrentBandwidth;
extern NSString* kNStatSrcKeyInterfaceUlEffectiveLatency;
extern NSString* kNStatSrcKeyInterfaceUlMaxBandwidth;
extern NSString* kNStatSrcKeyInterfaceUlMaxLatency;
extern NSString* kNStatSrcKeyInterfaceUlMinLatency;
extern NSString* kNStatSrcKeyInterfaceUlReTxtLevel;
extern NSString* kNStatSrcKeyInterfaceWifiConfigFrequency;
extern NSString* kNStatSrcKeyInterfaceWifiConfigMulticastRate;
extern NSString* kNStatSrcKeyInterfaceWifiDlEffectiveLatency;
extern NSString* kNStatSrcKeyInterfaceWifiDlErrorRate;
extern NSString* kNStatSrcKeyInterfaceWifiDlMaxLatency;
extern NSString* kNStatSrcKeyInterfaceWifiDlMinLatency;
extern NSString* kNStatSrcKeyInterfaceWifiScanCount;
extern NSString* kNStatSrcKeyInterfaceWifiScanDuration;
extern NSString* kNStatSrcKeyInterfaceWifiUlErrorRate;
extern NSString* kNStatSrcKeyLocal;
extern NSString* kNStatSrcKeyMinRTT;
extern NSString* kNStatSrcKeyPID;
extern NSString* kNStatSrcKeyProbeActivated;
extern NSString* kNStatSrcKeyProcessName;
extern NSString* kNStatSrcKeyProvider;
extern NSString* kNStatSrcKeyRcvBufSize;
extern NSString* kNStatSrcKeyRcvBufUsed;
extern NSString* kNStatSrcKeyReadProbeFailed;
extern NSString* kNStatSrcKeyRemote;
extern NSString* kNStatSrcKeyRouteDestination;
extern NSString* kNStatSrcKeyRouteFlags;
extern NSString* kNStatSrcKeyRouteGateway;
extern NSString* kNStatSrcKeyRouteGatewayID;
extern NSString* kNStatSrcKeyRouteID;
extern NSString* kNStatSrcKeyRouteMask;
extern NSString* kNStatSrcKeyRouteParentID;
extern NSString* kNStatSrcKeyRxBytes;
extern NSString* kNStatSrcKeyRxCellularBytes;
extern NSString* kNStatSrcKeyRxDupeBytes;
extern NSString* kNStatSrcKeyRxOOOBytes;
extern NSString* kNStatSrcKeyRxPackets;
extern NSString* kNStatSrcKeyRxWiFiBytes;
extern NSString* kNStatSrcKeyRxWiredBytes;
extern NSString* kNStatSrcKeySndBufSize;
extern NSString* kNStatSrcKeySndBufUsed;
extern NSString* kNStatSrcKeyStartAbsoluteTime;
extern NSString* kNStatSrcKeyTCPCCAlgorithm;
extern NSString* kNStatSrcKeyTCPState;
extern NSString* kNStatSrcKeyTCPTxCongWindow;
extern NSString* kNStatSrcKeyTCPTxUnacked;
extern NSString* kNStatSrcKeyTCPTxWindow;
extern NSString* kNStatSrcKeyTrafficClass;
extern NSString* kNStatSrcKeyTrafficMgtFlags;
extern NSString* kNStatSrcKeyTxBytes;
extern NSString* kNStatSrcKeyTxCellularBytes;
extern NSString* kNStatSrcKeyTxPackets;
extern NSString* kNStatSrcKeyTxReTx;
extern NSString* kNStatSrcKeyTxWiFiBytes;
extern NSString* kNStatSrcKeyTxWiredBytes;
extern NSString* kNStatSrcKeyUPID;
extern NSString* kNStatSrcKeyUUID;
extern NSString* kNStatSrcKeyVUUID;
extern NSString* kNStatSrcKeyVarRTT;
extern NSString* kNStatSrcKeyWriteProbeFailed;

CFStringRef NStatSourceCopyProperty(NStatSourceRef, CFStringRef);
void NStatSourceSetDescriptionBlock(NStatSourceRef arg,
									void (^)(CFDictionaryRef));
void NStatSourceSetRemovedBlock(NStatSourceRef arg, void (^)(void));
