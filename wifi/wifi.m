#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>
#include <stdbool.h>
#include <stdio.h>

#include "wifi.h"

CFArrayRef connectNetworks;
WiFiManagerRef manager;

int wifi(int argc, char *argv[]) {
	if (!argv[2]) {
		errx(1, "no wifi subcommand specified");
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
	WiFiDeviceClientRef client =
		(WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);

	// TODO: Make this not an ugly blob
	if (!strcmp(argv[2], "current")) {
		ret = info(client, true, argc - 2, argv + 2);
	} else if (!strcmp(argv[2], "info")) {
		ret = info(client, false, argc - 2, argv + 2);
	} else if (!strcmp(argv[2], "list")) {
		ret = list();
	} else if (!strcmp(argv[2], "power")) {
		if (argc != 4)
			ret = power(NULL);
		else if (!strcmp(argv[3], "on") || !strcmp(argv[3], "off") ||
				 !strcmp(argv[3], "toggle") || !strcmp(argv[3], "status"))
			ret = power(argv[3]);
		else
			errx(1, "invalid action");
	} else if (!strcmp(argv[2], "scan"))
		ret = scan(client);
	else if (!strcmp(argv[2], "connect"))
		ret = connect(client, argc - 2, argv + 2);
	else if (!strcmp(argv[2], "disconnect"))
		ret = WiFiDeviceClientDisassociate(client);
	else
		errx(1, "invalid wifi subcommand");
	CFRelease(manager);
	return ret;
}

int list() {
	CFArrayRef networks = WiFiManagerClientCopyNetworks(manager);

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		printf("%s : %s\n",
			[(NSString *)CFBridgingRelease(WiFiNetworkGetSSID(
				(WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)))
				UTF8String],
			networkBSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)));
	}

	return 0;
}

const char *networkBSSID(WiFiNetworkRef network) {
	return [(NSString *)CFBridgingRelease(networkBSSIDRef(network)) UTF8String];
}

CFStringRef networkBSSIDRef(WiFiNetworkRef network) {
	return WiFiNetworkGetProperty(network, CFSTR("BSSID"));
}

WiFiNetworkRef getNetworkWithSSID(char *ssid) {
	WiFiNetworkRef network;
	CFArrayRef networks = WiFiManagerClientCopyNetworks(manager);

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		if (CFEqual(CFStringCreateWithCString(kCFAllocatorDefault, ssid, kCFStringEncodingUTF8),
					WiFiNetworkGetSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)))) {
			network = (WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i);
			break;
		}
	}

	if (network == NULL)
		errx(1, "Could not find network with specified SSID: %s", ssid);

	return network;
}

WiFiNetworkRef getNetworkWithBSSID(char *ssid) {
	WiFiNetworkRef network;
	CFArrayRef networks = WiFiManagerClientCopyNetworks(manager);

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		if (CFEqual(CFStringCreateWithCString(kCFAllocatorDefault, ssid, kCFStringEncodingUTF8),
					networkBSSIDRef((WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)))) {
			network = (WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i);
			break;
		}
	}

	if (network == NULL)
		errx(1, "Could not find network with specified SSID: %s", ssid);

	return network;
}
