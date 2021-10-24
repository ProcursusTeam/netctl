#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>

#include "wifi.h"

int connect(WiFiDeviceClientRef client, int argc, char **argv) {
	int ch;
	bool bssid = false;
	while ((ch = getopt(argc, argv, "bs")) != -1) {
		switch (ch) {
			case 'b':
				bssid = true;
				break;
			case 's':
				bssid = false;
				break;
		}
	}
	argc -= optind;
	argv += optind;

	if (argv[0] == NULL)
		errx(1, "specify a SSID or BSSID");

	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	WiFiDeviceClientScanAsync(
		client, (__bridge CFDictionaryRef)[NSDictionary dictionary],
		connectScanCallback, 0);
	CFRunLoopRun();

	WiFiNetworkRef network;

	for (int i = 0; i < CFArrayGetCount(connectNetworks); i++) {
		if (bssid) {
			if (CFEqual(CFStringCreateWithCString(kCFAllocatorDefault, argv[0],
												  kCFStringEncodingUTF8),
						WiFiNetworkGetProperty(
							(WiFiNetworkRef)CFArrayGetValueAtIndex(
								connectNetworks, i),
							CFSTR("BSSID")))) {
				network = (WiFiNetworkRef)CFArrayGetValueAtIndex(connectNetworks, i);
				goto cont;
			}
		} else {
			if (CFEqual(
					CFStringCreateWithCString(kCFAllocatorDefault, argv[0], kCFStringEncodingUTF8),
					WiFiNetworkGetSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(connectNetworks, i)))) {
				network = (WiFiNetworkRef)CFArrayGetValueAtIndex(connectNetworks, i);
				goto cont;
			}
		}
	}

	errx(1, "cannot find network %s", argv[0]);

cont:
	if (CFEqual(network, WiFiDeviceClientCopyCurrentNetwork(client)))
		WiFiDeviceClientDisassociate(client);

	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	WiFiDeviceClientAssociateAsync(client, network, connectCallback, NULL);
	CFRunLoopRun();

	return 0;
}

void connectScanCallback(WiFiDeviceClientRef client, CFArrayRef results,
						 CFErrorRef error, void *token) {
	if ((NSError *)CFBridgingRelease(error))
		errx(1, "Failed to scan: %s",
			 [[(NSError *)CFBridgingRelease(error) localizedDescription]
				 UTF8String]);

	connectNetworks = CFArrayCreateCopy(kCFAllocatorDefault, results);

	WiFiManagerClientUnscheduleFromRunLoop(manager);
	CFRunLoopStop(CFRunLoopGetCurrent());
}

void connectCallback(WiFiDeviceClientRef device, WiFiNetworkRef network,
					 CFDictionaryRef dict, int error, const void *object) {
	WiFiManagerClientUnscheduleFromRunLoop(manager);
	CFRunLoopStop(CFRunLoopGetCurrent());
	exit(error);
}
