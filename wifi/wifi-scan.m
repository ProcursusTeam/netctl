#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>

#include "wifi.h"

void wifiScanCallback(WiFiDeviceClientRef, CFArrayRef, int, void *);

int wifiscan(void) {
	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(),
										 kCFRunLoopDefaultMode);

	WiFiDeviceClientScanAsync(
		client, (__bridge CFDictionaryRef)[NSDictionary dictionary],
		(WiFiDeviceScanCallback)wifiScanCallback, 0);
	CFRunLoopRun();

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
