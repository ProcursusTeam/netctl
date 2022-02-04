#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <getopt.h>
#include <err.h>

#include "wifi.h"

void wifiScanCallback(WiFiDeviceClientRef, CFArrayRef, int, void *);

int wifiscan(int argc, char **argv) {
	int ch, index;
	int timeout = 30;
	const char *errstr;

	struct option opts[] = {
		{ "timeout", required_argument, 0, 't' },
		{ NULL, 0, NULL, 0 }
	};

	while ((ch = getopt_long(argc, argv, "t:", opts, &index)) != -1) {
		switch (ch) {
			case 't':
				timeout = strtonum(optarg, 0, INT_MAX, &errstr);
				if (errstr != NULL)
					err(1, "%s", optarg);
				break;
		}
	}
	argc -= optind;
	argv += optind;

	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(),
										 kCFRunLoopDefaultMode);

	WiFiDeviceClientScanAsync(
		client, (__bridge CFDictionaryRef)[NSDictionary dictionary],
		(WiFiDeviceScanCallback)wifiScanCallback, 0);
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeout, false);

	return 0;
}

void wifiScanCallback(WiFiDeviceClientRef client, CFArrayRef results, int error,
					  void *token) {
	if (error != 0) errx(1, "Failed to scan");

	for (int i = 0; i < CFArrayGetCount(results); i++) {
		NSString *SSID = (__bridge_transfer NSString *)WiFiNetworkGetSSID(
			(WiFiNetworkRef)CFArrayGetValueAtIndex(results, i));
		if ([SSID length] == 0) {
			SSID = @"<hidden>";
		}

		printf(
			"%s : %s\n", [SSID UTF8String],
			networkBSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(results, i)));
	}

	WiFiManagerClientUnscheduleFromRunLoop(manager);
	CFRunLoopStop(CFRunLoopGetCurrent());
}
