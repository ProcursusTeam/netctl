#include <stdbool.h>
#include <err.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>

int info(WiFiNetworkRef network, WiFiDeviceClientRef client, bool status);

int wifi(int argc, char *argv[]) {
	int ret = 1;
	WiFiManagerRef manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
	// WiFiManagerClientGetDevice(WiFiManagerRef) segfaults
	// We should investigate, but this works for now.
	CFArrayRef devices = WiFiManagerClientCopyDevices(manager);
	if (!devices) {
		errx(1, "Failed to get devices");
	}
	WiFiDeviceClientRef client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);
	if (!strcmp(argv[2], "current")) {
		ret = info(WiFiDeviceClientCopyCurrentNetwork(client), client, true);
		CFRelease(manager);
		return(ret);
	}
	CFRelease(manager);
	return(1);
}

int info(WiFiNetworkRef network, WiFiDeviceClientRef client, bool status) {
	printf("SSID: %s\n", [(NSString*)CFBridgingRelease(WiFiNetworkGetSSID(network)) UTF8String]);
	printf("Password: %s\n", [(NSString*)CFBridgingRelease(WiFiNetworkCopyPassword(network)) UTF8String]);
	printf("WEP: %s\n", WiFiNetworkIsWEP(network) ? "yes" : "no");
	printf("WPA: %s\n", WiFiNetworkIsWPA(network) ? "yes" : "no");
	printf("EAP: %s\n", WiFiNetworkIsEAP(network) ? "yes" : "no");
	printf("Apple Hotspot: %s\n", WiFiNetworkIsApplePersonalHotspot(network) ? "yes" : "no");
	printf("Adhoc: %s\n", WiFiNetworkIsAdHoc(network) ? "yes" : "no");
	printf("Hidden: %s\n", WiFiNetworkIsHidden(network) ? "yes" : "no");
	printf("Password Requires: %s\n", WiFiNetworkRequiresPassword(network) ? "yes" : "no");
	printf("Username Required: %s\n", WiFiNetworkRequiresUsername(network) ? "yes" : "no");

	if (status) {
		CFDictionaryRef data = (CFDictionaryRef)WiFiDeviceClientCopyProperty(client, CFSTR("RSSI"));
		CFNumberRef scaled = (CFNumberRef)WiFiDeviceClientCopyProperty(client, kWiFiScaledRSSIKey);

		CFNumberRef RSSI = (CFNumberRef)CFDictionaryGetValue(data, CFSTR("RSSI_CTL_AGR"));
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
