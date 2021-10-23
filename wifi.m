#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>
#include <stdbool.h>
#include <stdio.h>

int list(WiFiManagerRef);
int info(WiFiNetworkRef, WiFiDeviceClientRef, bool);
int power(WiFiManagerRef, char *);
WiFiNetworkRef getNetworkWithSSID(char *, WiFiManagerRef);

int wifi(int argc, char *argv[]) {
	if (!argv[2]) {
		errx(1, "no wifi subcommand specified");
		return 1;
	}

	int ret = 1;
	WiFiManagerRef manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
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
		ret = info(WiFiDeviceClientCopyCurrentNetwork(client), client, true);
	} else if (!strcmp(argv[2], "list")) {
		ret = list(manager);
	} else if (!strcmp(argv[2], "info")) {
		if (argc != 4)
			errx(1, "no SSID specified");
		ret = info(getNetworkWithSSID(argv[3], manager), client, false);
	} else if (!strcmp(argv[2], "power")) {
		if (argc != 4)
			ret = power(manager, NULL);
		else if (!strcmp(argv[3], "on") || !strcmp(argv[3], "off") ||
				 !strcmp(argv[3], "toggle") || !strcmp(argv[3], "status"))
			ret = power(manager, argv[3]);
		else
			errx(1, "invalid action");
	} else
		errx(1, "invalid wifi subcommand");
	CFRelease(manager);
	return ret;
}

int list(WiFiManagerRef manager) {
	CFArrayRef networks = WiFiManagerClientCopyNetworks(manager);

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		printf("%s\n", [(NSString *)CFBridgingRelease(WiFiNetworkGetSSID(
						   (WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)))
						   UTF8String]);
	}

	return 0;
}

int info(WiFiNetworkRef network, WiFiDeviceClientRef client, bool status) {
	printf("SSID: %s\n", [(NSString *)CFBridgingRelease(
							 WiFiNetworkGetSSID(network)) UTF8String]);
	printf("WEP: %s\n", WiFiNetworkIsWEP(network) ? "yes" : "no");
	printf("WPA: %s\n", WiFiNetworkIsWPA(network) ? "yes" : "no");
	printf("EAP: %s\n", WiFiNetworkIsEAP(network) ? "yes" : "no");
	printf("Apple Hotspot: %s\n",
		   WiFiNetworkIsApplePersonalHotspot(network) ? "yes" : "no");
	printf("Adhoc: %s\n", WiFiNetworkIsAdHoc(network) ? "yes" : "no");
	printf("Hidden: %s\n", WiFiNetworkIsHidden(network) ? "yes" : "no");
	printf("Password Requires: %s\n",
		   WiFiNetworkRequiresPassword(network) ? "yes" : "no");
	printf("Username Required: %s\n",
		   WiFiNetworkRequiresUsername(network) ? "yes" : "no");

	if (status) {
		CFDictionaryRef data = (CFDictionaryRef)WiFiDeviceClientCopyProperty(
			client, CFSTR("RSSI"));
		CFNumberRef scaled = (CFNumberRef)WiFiDeviceClientCopyProperty(
			client, kWiFiScaledRSSIKey);

		CFNumberRef RSSI =
			(CFNumberRef)CFDictionaryGetValue(data, CFSTR("RSSI_CTL_AGR"));
		CFRelease(data);

		int raw;
		CFNumberGetValue(RSSI, kCFNumberIntType, &raw);

		float strength;
		CFNumberGetValue(scaled, kCFNumberFloatType, &strength);
		CFRelease(scaled);

		strength *= -1;

		// Apple uses -3.0.
		int bars = (int)ceilf(strength * -3.0f);
		bars = MAX(1, MIN(bars, 3));

		printf("Strength: %f dBm\n", strength);
		printf("Bars: %d\n", bars);
	}
	return 0;
}

WiFiNetworkRef getNetworkWithSSID(char *ssid, WiFiManagerRef manager) {
	WiFiNetworkRef network;
	CFArrayRef networks = WiFiManagerClientCopyNetworks(manager);

	for (int i = 0; i < CFArrayGetCount(networks); i++) {
		if (CFEqual(CFStringCreateWithCString(kCFAllocatorDefault, ssid,
											  kCFStringEncodingUTF8),
					WiFiNetworkGetSSID(
						(WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i)))) {
			network = (WiFiNetworkRef)CFArrayGetValueAtIndex(networks, i);
			break;
		}
	}

	if (network == NULL)
		errx(1, "Could not find network with specified SSID: %s", ssid);

	return network;
}

int power(WiFiManagerRef manager, char *action) {
	bool status = CFBooleanGetValue(
		WiFiManagerClientCopyProperty(manager, CFSTR("AllowEnable")));

	if (action == NULL || !strcmp(action, "status")) {
		printf("%s\n", status ? "on" : "off");
	} else if (!strcmp(action, "toggle")) {
		WiFiManagerClientSetProperty(manager, CFSTR("AllowEnable"),
									 status ? kCFBooleanFalse : kCFBooleanTrue);
	} else if (!strcmp(action, "on")) {
		WiFiManagerClientSetProperty(manager, CFSTR("AllowEnable"),
									 kCFBooleanTrue);
	} else if (!strcmp(action, "off")) {
		WiFiManagerClientSetProperty(manager, CFSTR("AllowEnable"),
									 kCFBooleanFalse);
	}

	return 0;
}
