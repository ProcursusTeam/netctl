#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>
#include <stdbool.h>
#include <stdio.h>

#include "wifi.h"
#include "output.h"
#include "netctl.h"

CFArrayRef scanNetworks;
WiFiManagerRef manager;
WiFiDeviceClientRef client;

int wifi(int argc, char *argv[]) {
	if (!argv[2]) {
		fprintf(stderr, "Usage: netctl wifi [current | power | info | list | scan | connect | disconnect | forget] [arguments]\n");
		return 1;
	}

	int ret = 1;
	manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
	// WiFiManagerClientGetDevice(WiFiManagerRef) segfaults
	// We should investigate, but this works for now.
	CFArrayRef devices = WiFiManagerClientCopyDevices(manager);
	if (!devices) {
		errx(1, "Failed to get devices");
	}
	client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);

	// TODO: Make this not an ugly blob
	if (!strcmp(argv[2], "current")) {
		ret = wifiinfo(true, argc - 2, argv + 2);
	} else if (!strcmp(argv[2], "info")) {
		ret = wifiinfo(false, argc - 2, argv + 2);
	} else if (!strcmp(argv[2], "list")) {
		ret = wifilist();
	} else if (!strcmp(argv[2], "power")) {
		if (argc != 4)
			ret = wifipower(NULL);
		else if (!strcmp(argv[3], "on") || !strcmp(argv[3], "off") ||
				 !strcmp(argv[3], "toggle") || !strcmp(argv[3], "status"))
			ret = wifipower(argv[3]);
		else
			errx(1, "invalid action");
	} else if (!strcmp(argv[2], "scan"))
		ret = wifiscan(argc - 2, argv + 2);
	else if (!strcmp(argv[2], "connect"))
		ret = wificonnect(argc - 2, argv + 2);
	else if (!strcmp(argv[2], "disconnect"))
		ret = WiFiDeviceClientDisassociate(client);
	else if (!strcmp(argv[2], "forget")) {
		ret = wififorget(argc - 2, argv + 2);
	} else {
		fprintf(stderr, "Usage: netctl wifi [current | power | info | list | scan | connect | disconnect | forget] [arguments]\n");
		return 1;
	}
	CFRelease(manager);
	return ret;
}

int wifilist(void) {
	CFArrayRef networks = WiFiManagerClientCopyNetworks(manager);

	NSMutableArray *list = [NSMutableArray array];

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		[list addObjectsFromArray:@[
			@{ @"SSID" : (__bridge_transfer NSString*)WiFiNetworkGetSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)) },
			@{ @"BSSID" : (__bridge_transfer NSString*)networkBSSIDRef((WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)) },
		]];
	}

	[NCOutput printArray:list withJSON:json];

	return 0;
}

const char *networkBSSID(WiFiNetworkRef network) {
	return [(__bridge_transfer NSString *)networkBSSIDRef(network) UTF8String];
}

CFStringRef networkBSSIDRef(WiFiNetworkRef network) {
	return WiFiNetworkGetProperty(network, CFSTR("BSSID"));
}

void getNetworkScanCallback(WiFiDeviceClientRef client, CFArrayRef results,
							int error, void *token) {
	if (error != 0) errx(1, "Failed to scan");

	scanNetworks = CFArrayCreateCopy(kCFAllocatorDefault, results);

	WiFiManagerClientUnscheduleFromRunLoop(manager);
	CFRunLoopStop(CFRunLoopGetCurrent());
}

WiFiNetworkRef getNetworkWithSSID(char *ssid) {
	CFArrayRef networks = WiFiManagerClientCopyNetworks(manager);

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		if (CFEqual(CFStringCreateWithCString(kCFAllocatorDefault, ssid,
											  kCFStringEncodingUTF8),
					WiFiNetworkGetSSID(
						(WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)))) {
			return (WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i);
		}
	}

	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(),
										 kCFRunLoopDefaultMode);
	WiFiDeviceClientScanAsync(
		client, (__bridge CFDictionaryRef)[NSDictionary dictionary],
		(WiFiDeviceScanCallback)getNetworkScanCallback, 0);
	CFRunLoopRun();

	for (int i = 0; i < CFArrayGetCount(scanNetworks); i++) {
		if (CFEqual(CFStringCreateWithCString(kCFAllocatorDefault, ssid,
											  kCFStringEncodingUTF8),
					WiFiNetworkGetSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(
						scanNetworks, i)))) {
			return (WiFiNetworkRef)CFArrayGetValueAtIndex(scanNetworks, i);
		}
	}

	errx(1, "Could not find network with specified SSID: %s", ssid);

	/* NOT REACHED */
	return NULL;
}

WiFiNetworkRef getNetworkWithBSSID(char *bssid) {
	CFArrayRef networks;

	networks = WiFiManagerClientCopyNetworks(manager);

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		if (CFEqual(CFStringCreateWithCString(kCFAllocatorDefault, bssid,
											  kCFStringEncodingUTF8),
					networkBSSIDRef(
						(WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)))) {
			return (WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i);
		}
	}

	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(),
										 kCFRunLoopDefaultMode);
	WiFiDeviceClientScanAsync(
		client, (__bridge CFDictionaryRef)[NSDictionary dictionary],
		(WiFiDeviceScanCallback)getNetworkScanCallback, 0);
	CFRunLoopRun();

	for (int i = 0; i < CFArrayGetCount(scanNetworks); i++) {
		if (CFEqual(CFStringCreateWithCString(kCFAllocatorDefault, bssid,
											  kCFStringEncodingUTF8),
					networkBSSIDRef((WiFiNetworkRef)CFArrayGetValueAtIndex(
						scanNetworks, i)))) {
			return (WiFiNetworkRef)CFArrayGetValueAtIndex(scanNetworks, i);
		}
	}

	errx(1, "Could not find network with specified BSSID: %s", bssid);

	/* NOT REACHED */
	return NULL;
}
