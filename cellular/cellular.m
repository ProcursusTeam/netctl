#include <CTPrivate.h>
#include <CoreTelephony/CTCarrier.h>
#include <CoreTelephony/CTTelephonyNetworkInfo.h>
#include <Foundation/Foundation.h>
#include <err.h>

static CTServerConnectionRef serverConnection;

static int number(void) {
	printf("%s\n", [(NSString*)CFBridgingRelease(CTSettingCopyMyPhoneNumber()) UTF8String]);
	return 0;
}

static int info(void) {
	CTTelephonyNetworkInfo* info = [[CTTelephonyNetworkInfo alloc] init];
	NSDictionary<NSString*, CTCarrier*>* serviceTech = info.serviceSubscriberCellularProviders;
	NSDictionary<NSString*, NSString*>* accessTechnology = info.serviceCurrentRadioAccessTechnology;


	long int raw = 0, graded = 0, bars = 0;
	bool inHomeCountry = false;
	CFStringRef registrationStatus = nil;

	CTIndicatorsGetSignalStrength(&raw, &graded, &bars);
	_CTServerConnectionIsInHomeCountry(serverConnection, &inHomeCountry);
	_CTServerConnectionGetRegistrationStatus(serverConnection, &registrationStatus);

	printf("Connection Strength: %ld%%\n", bars * 25);
	printf("In Home Country: %s\n", inHomeCountry ? "Yes" : "No");
	printf("Registration status: %s\n", [(__bridge NSString*)registrationStatus UTF8String]);
	printf("\n");

	int i = 0;
	for (NSString* key in serviceTech) {
		printf("SIM %d:\n", i);
		printf("\tCarrier Name: %s\n", serviceTech[key].carrierName.UTF8String);
		printf("\tAllows VOIP (Voice over IP): %s\n", serviceTech[key].allowsVOIP ? "Yes" : "No");
		printf("\tISO Country Code: %s\n", serviceTech[key].isoCountryCode.UTF8String);
		printf("\tMobile Country Code (MCC): %s\n", serviceTech[key].mobileCountryCode.UTF8String);
		printf("\tMobile Network Code (MCC): %s\n", serviceTech[key].mobileNetworkCode.UTF8String);
		printf("\n");
		i++;
	}

	CFRelease(registrationStatus);
	return 0;
}

static int call(NSString* number) {
	CTCallRef call = CTCallDial(number);
	printf("Calling %s...\n", [(NSString*)CFBridgingRelease(CTCallCopyAddress(nil, call)) UTF8String]);
	return 0;
}

static int cells(void) {
	int success = 0;
	CFArrayRef cells;
	_CTServerConnectionCellMonitorCopyCellInfo(serverConnection, &success, &cells);
	if (!success) {
		errx(1, "could not get cell info");
		return 1;
	}

	int ctr = 1;
	for (NSDictionary* cell in (__bridge NSArray*)cells) {
		int bandinfo = [cell[kCTCellMonitorBandInfo] intValue];
		int bandwidth = [cell[kCTCellMonitorBandwidth] intValue];
		int cellID = [cell[kCTCellMonitorCellId] intValue];
		NSString* cellTechnology = [cell[kCTCellMonitorCellRadioAccessTechnology] componentsSeparatedByString:@"kCTCellMonitorRadioAccessTechnology"][1];
		NSString* cellType = cell[kCTCellMonitorCellType];
		int mcc = [cell[kCTCellMonitorMCC] intValue];
		int mnc = [cell[kCTCellMonitorMNC] intValue];
		int pid = [cell[kCTCellMonitorPID] intValue];
		int tac = [cell[kCTCellMonitorTAC] intValue];
		int uarfcn = [cell[kCTCellMonitorUARFCN] intValue];

		printf( "Cell %d:\n"
			"\tBandinfo: %d\n"
			"\tBandwidth: %d\n"
			  "\tCell ID: %d\n"
		  "\tCell Technology: %s\n"
			"\tCell Type: %s\n"
			      "\tMCC: %d\n"
			      "\tMNC: %d\n"
			      "\tPID: %d\n"
			      "\tTAC: %d\n"
			   "\tUARFCN: %d\n",
			   ctr, bandinfo, bandwidth, cellID, [cellTechnology UTF8String], [cellType UTF8String], mcc, mnc, pid, tac, uarfcn);
		ctr++;
	}

	CFRelease(cells);

	return 0;
}

static int registration(NSString* arg) {
	if ([arg isEqualToString:@"enable"]) {
		_CTServerConnectionEnableRegistration(serverConnection);
	}

	else if ([arg isEqualToString:@"disable"]) {
		_CTServerConnectionDisableRegistration(serverConnection);
	}

	else {
		errx(1, "must specify 'disable' or 'enable'");
	}

	// we do a little race conditioning
	usleep(50000);

	return 0;
}

int cellular(int argc, char** argv) {
	const char* cmd = argv[2];
	int ret = 0;

	if (argc < 3) {
		errx(1, "no cellular subcommand specified");
		return 1;
	}

	serverConnection = _CTServerConnectionCreate(NULL, NULL, NULL);

	if (!strcmp(cmd, "number")) {
		return number();
	}

	if (!strcmp(cmd, "info")) {
		return info();
	}

	if (!strcmp(cmd, "call")) {
		if (argc < 4) {
			errx(1, "no phone number specified");
			return 1;
		}

		return call([NSString stringWithUTF8String:argv[3]]);
	}

	if (!strcmp(cmd, "cells")) {
		return cells();
	}

	if (!strcmp(cmd, "registration")) {
		if (argc < 4) {
			errx(1, "must specify 'disable' or 'enable'");
			return 1;
		}

		return registration([NSString stringWithUTF8String:argv[3]]);
	}

	errx(1, "invalid cellular subcommand");

	return 1;
}
