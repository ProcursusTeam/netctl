#include <CoreTelephony/CTCarrier.h>
#include <CoreTelephony/CTTelephonyNetworkInfo.h>
#include <Foundation/Foundation.h>
#include <err.h>

#include "CTPrivate.h"

#include "output.h"
#include "netctl.h"

static CTServerConnectionRef serverConnection;

static int number(void) {
	printf("%s\n", [(__bridge_transfer NSString*)CTSettingCopyMyPhoneNumber() UTF8String]);
	return 0;
}

static int info(netctl_options *op) {
	CTTelephonyNetworkInfo* info = [[CTTelephonyNetworkInfo alloc] init];
	NSDictionary<NSString*, CTCarrier*>* serviceTech = info.serviceSubscriberCellularProviders;
	CFDictionaryRef mobileEquipmentInfoCF;
	_CTServerConnectionCopyMobileEquipmentInfo(serverConnection, &mobileEquipmentInfoCF);
	NSDictionary* mobileEquipmentInfo = (__bridge_transfer NSDictionary*)mobileEquipmentInfoCF;

	long int raw = 0, graded = 0, bars = 0;
	bool inHomeCountry = false;
	CFStringRef registrationStatus = nil;
	NSNumber *mobileId, *subscriberId, *ICCID, *IMEI, *IMSI, *MEID, *SlotId;

	mobileId = mobileEquipmentInfo[kCTMobileEquipmentInfoCurrentMobileId];
	subscriberId = mobileEquipmentInfo[kCTMobileEquipmentInfoCurrentSubscriberId];
	ICCID = mobileEquipmentInfo[kCTMobileEquipmentInfoICCID];
	IMEI = mobileEquipmentInfo[kCTMobileEquipmentInfoIMEI];
	IMSI = mobileEquipmentInfo[kCTMobileEquipmentInfoIMSI];
	MEID = mobileEquipmentInfo[kCTMobileEquipmentInfoMEID];
	SlotId = mobileEquipmentInfo[kCTMobileEquipmentInfoSlotId];

	CTIndicatorsGetSignalStrength(&raw, &graded, &bars);
	_CTServerConnectionIsInHomeCountry(serverConnection, &inHomeCountry);
	_CTServerConnectionGetRegistrationStatus(serverConnection, &registrationStatus);

	NSMutableArray* array = [NSMutableArray array];

	[array addObjectsFromArray:@[
		@{ @"Connection Strength" : @(bars * 25)},
		@{ @"In Home Country" : inHomeCountry ? @"Yes" : @"No"},
		@{ @"Registration Status" : (__bridge NSString*)registrationStatus},
			  @{ @"Mobile ID" : mobileId},
			  @{ @"Subscriber ID" : subscriberId},
				  @{ @"ICCID" : ICCID},
				   @{ @"IMEI" : IMEI},
				   @{ @"IMSI" : IMSI},
				   @{ @"MEID" : MEID},
				@{ @"Slot ID" : SlotId}
	]];

	[array addObject:[NCNewline new]];

	int i = 0;
	for (NSString* key in serviceTech) {
		NSString* simString = [NSString stringWithFormat: @"SIM %d", i];
		[array addObject: @{ simString : @[
	     @{ @"Carrier Name" : serviceTech[key].carrierName ?: [NSNull null]},
	 @{ @"Allows VOIP (Voice over IP)" : serviceTech[key].allowsVOIP ? @"Yes" : @"No" },
		    @{ @"ISO Country Code" : serviceTech[key].isoCountryCode ?: [NSNull null]},
	   @{ @"Mobile Country Code (MCC)" : serviceTech[key].mobileCountryCode ?: [NSNull null]},
	   @{ @"Mobile Network Code (MNC)" : serviceTech[key].mobileNetworkCode ?: [NSNull null]}
		]}];
		i++;
	}

	[NCOutput printArray:array withJSON:op->json];
	CFRelease(registrationStatus);
	return 0;
}

static int call(NSString* number) {
	CTCallRef call = CTCallDial(number);
	printf("Calling %s...\n", [(__bridge_transfer NSString*)CTCallCopyAddress(nil, call) UTF8String]);
	return 0;
}

static int cells(netctl_options *op) {
	int success = 0;
	CFArrayRef cells;
	_CTServerConnectionCellMonitorCopyCellInfo(serverConnection, &success, &cells);
	if (!success) {
		errx(1, "could not get cell info");
		return 1;
	}

	for (NSDictionary* cell in (__bridge NSArray*)cells) {
		NSNumber *bandinfo = cell[kCTCellMonitorBandInfo];
		NSNumber *bandwidth = cell[kCTCellMonitorBandwidth];
		NSNumber *cellID = cell[kCTCellMonitorCellId];
		NSString *cellTechnology = [cell[kCTCellMonitorCellRadioAccessTechnology] componentsSeparatedByString:@"kCTCellMonitorRadioAccessTechnology"][1];
		NSString *cellType = cell[kCTCellMonitorCellType];
		NSNumber *mcc = cell[kCTCellMonitorMCC];
		NSNumber *mnc = cell[kCTCellMonitorMNC];
		NSNumber *pid = cell[kCTCellMonitorPID];
		NSNumber *tac = cell[kCTCellMonitorTAC];
		NSNumber *uarfcn = cell[kCTCellMonitorUARFCN];

		[NCOutput printArray:@[
		 @{ @"Current Cell" : @[
			 @{ @"Bandinfo" : bandinfo },
			@{ @"Bandwidth" : bandwidth},
			  @{ @"Cell ID" : cellID },
		  @{ @"Cell Technology" : cellTechnology },
			@{ @"Cell Type" : cellType },
			      @{ @"MCC" : mcc },
			      @{ @"MNC" : mnc },
			      @{ @"PID" : pid },
			      @{ @"TAC" : tac },
			   @{ @"UARFCN" : uarfcn },
			     ]}] withJSON:op->json];
	}

	CFRelease(cells);

	return 0;
}

static int registration(NSString* arg) {
	if ([arg isEqualToString:@"enable"]) {
		_CTServerConnectionEnableRegistration(serverConnection);
	} else if ([arg isEqualToString:@"disable"]) {
		_CTServerConnectionDisableRegistration(serverConnection);
	} else {
		fprintf(stderr, "Usage: netctl cellular registration [disable | enable]\n");
		return 1;
	}

	// we do a little race conditioning
	usleep(50000);

	return 0;
}

int cellular_cmd(netctl_options *op, int argc, char** argv) {
	if (argc < 2) {
		fprintf(stderr, "Usage: netctl cellular [number | info | call | registration | cells] [arguments]\n");
		return 1;
	}

	const char* cmd = argv[1];

	serverConnection = _CTServerConnectionCreate(NULL, NULL, NULL);

	if (!strcmp(cmd, "number")) {
		return number();
	} if (!strcmp(cmd, "info")) {
		return info(op);
	} else if (!strcmp(cmd, "call")) {
		if (argc < 4) {
			errx(1, "no phone number specified");
			return 1;
		}
		return call([NSString stringWithUTF8String:argv[3]]);
	} else if (!strcmp(cmd, "cells")) {
		return cells(op);
	} else if (!strcmp(cmd, "registration")) {
		if (argc < 4) {
			fprintf(stderr, "Usage: netctl cellular registration [disable | enable]\n");
			return 1;
		}
		return registration([NSString stringWithUTF8String:argv[3]]);
	}

	fprintf(stderr, "Usage: netctl cellular [number | info | call | registration | cells] [arguments]\n");
	return 1;
}
