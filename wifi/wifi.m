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

int wifi_cmd(netctl_options *op, int argc, char **argv) {
	if (argc < 2) {
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
	if (!strcmp(argv[1], "current")) {
		ret = wifiinfo(true, op, argc - 1, argv + 1);
	} else if (!strcmp(argv[1], "info")) {
		ret = wifiinfo(false, op, argc - 1, argv + 1);
	} else if (!strcmp(argv[1], "list")) {
		ret = wifilist(op);
	} else if (!strcmp(argv[1], "power")) {
		if (argc != 3)
			ret = wifipower(NULL);
		else if (!strcmp(argv[2], "on") || !strcmp(argv[2], "off") ||
				 !strcmp(argv[2], "toggle") || !strcmp(argv[2], "status"))
			ret = wifipower(argv[2]);
		else
			errx(1, "invalid action");
	} else if (!strcmp(argv[1], "scan"))
		ret = wifiscan(op, argc - 1, argv + 1);
	else if (!strcmp(argv[1], "connect"))
		ret = wificonnect(argc - 1, argv + 1);
	else if (!strcmp(argv[1], "disconnect"))
		ret = WiFiDeviceClientDisassociate(client);
	else if (!strcmp(argv[1], "forget")) {
		ret = wififorget(argc - 1, argv + 1);
	} else {
		fprintf(stderr, "Usage: netctl wifi [current | power | info | list | scan | connect | disconnect | forget] [arguments]\n");
		return 1;
	}
	CFRelease(manager);
	return ret;
}

int wifilist(netctl_options *op) {
	CFArrayRef networks = WiFiManagerClientCopyNetworks(manager);

	NSMutableArray *list = [NSMutableArray array];

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		[list addObjectsFromArray:@[
			@{ @"SSID" : (__bridge_transfer NSString*)WiFiNetworkGetSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)) },
			@{ @"BSSID" : (__bridge_transfer NSString*)networkBSSIDRef((WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)) },
		]];
	}

	[NCOutput printArray:list withJSON:op->json];

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
