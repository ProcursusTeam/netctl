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

	WiFiNetworkRef network;

	if (bssid)
		network = getNetworkWithBSSID(argv[0], client);
	else
		network = getNetworkWithSSID(argv[0], client);

	WiFiManagerClientAddNetwork(manager, network);

	if (password != NULL)
		WiFiNetworkSetPassword(network, (__bridge CFStringRef)[NSString stringWithUTF8String:password]);

	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	WiFiDeviceClientAssociateAsync(client, network, connectCallback, NULL);
	CFRunLoopRun();

	return 0;
}

void connectCallback(WiFiDeviceClientRef device, WiFiNetworkRef network,
					 CFDictionaryRef dict, int error, const void *object) {
	WiFiManagerClientUnscheduleFromRunLoop(manager);
	CFRunLoopStop(CFRunLoopGetCurrent());
	if (error != 0)
		errx(1, "Failed to connect: %d", error);
}
