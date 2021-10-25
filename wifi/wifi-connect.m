#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>

#include "wifi.h"

void connectScanCallback(WiFiDeviceClientRef, CFArrayRef, CFErrorRef, void *);
void connectCallback(WiFiDeviceClientRef, WiFiNetworkRef, CFDictionaryRef, int,
					 const void *);

int connect(WiFiDeviceClientRef client, int argc, char **argv) {
	int ch;
	char *password = NULL;
	bool bssid = false;
	while ((ch = getopt(argc, argv, "bp:s")) != -1) {
		switch (ch) {
			case 'b':
				bssid = true;
				break;
			case 'p':
				password = optarg;
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
	WiFiManagerClientAddNetwork(manager, network);

	if (password != NULL)
		WiFiNetworkSetPassword(network, (__bridge CFStringRef)[NSString stringWithUTF8String:password]);

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
	if (error != 0)
		errx(1, "Failed to connect: %d", error);
}
