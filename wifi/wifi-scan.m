#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>

#include "wifi.h"

void scanCallback(WiFiDeviceClientRef, CFArrayRef, CFErrorRef, void *);

int scan(WiFiDeviceClientRef client) {
	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	WiFiDeviceClientScanAsync(
		client, (__bridge CFDictionaryRef)[NSDictionary dictionary],
		scanCallback, 0);
	CFRunLoopRun();

	return 0;
}

void scanCallback(WiFiDeviceClientRef client, CFArrayRef results,
				  CFErrorRef error, void *token) {
	if ((NSError *)CFBridgingRelease(error))
		errx(1, "Failed to scan: %s",
			 [[(NSError *)CFBridgingRelease(error) localizedDescription]
				 UTF8String]);

	for (int i = 0; i < CFArrayGetCount(results); i++) {
		NSString* SSID = (NSString*)CFBridgingRelease(WiFiNetworkGetSSID( (WiFiNetworkRef)CFArrayGetValueAtIndex(results, i) ));
		if ([SSID length] == 0) {
			SSID = @"<hidden>";
		}

		printf("%s : %s\n",
			[SSID UTF8String],
			networkBSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(results, i)));
	}

	WiFiManagerClientUnscheduleFromRunLoop(manager);
	CFRunLoopStop(CFRunLoopGetCurrent());
}
