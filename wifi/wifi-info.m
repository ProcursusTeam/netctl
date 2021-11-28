#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>

#include "wifi.h"

int wifiinfo(bool current, int argc, char **argv) {
	WiFiNetworkRef network;
	int ch;
	bool bssid = false;
	char *key = NULL;

	while ((ch = getopt(argc, argv, "bk:s")) != -1) {
		switch (ch) {
			case 'b':
				bssid = true;
				break;
			case 'k':
				key = optarg;
				break;
			case 's':
				bssid = false;
				break;
		}
	}
	argc -= optind;
	argv += optind;

	if (!current && argv[0] == NULL) errx(1, "no SSID or BSSID specified");

	if (current)
		network = WiFiDeviceClientCopyCurrentNetwork(client);
	else if (bssid)
		network = getNetworkWithBSSID(argv[0]);
	else
		network = getNetworkWithSSID(argv[0]);

	if (key != NULL) {
		CFPropertyListRef property = WiFiNetworkGetProperty(
			network, (__bridge CFStringRef)[NSString stringWithUTF8String:key]);
		if (!property) errx(1, "cannot get property \"%s\"", key);

		CFTypeID type = CFGetTypeID(property);

		if (type == CFStringGetTypeID()) {
			printf(
				"%s: %s\n", key,
				[(__bridge_transfer NSString *)WiFiNetworkGetProperty(
					network,
					(__bridge CFStringRef)[NSString stringWithUTF8String:key])
					UTF8String]);
		} else if (type == CFNumberGetTypeID()) {
			printf(
				"%s: %i\n", key,
				[(__bridge_transfer NSNumber *)WiFiNetworkGetProperty(
					network,
					(__bridge CFStringRef)[NSString stringWithUTF8String:key])
					intValue]);
		} else if (type == CFDateGetTypeID()) {
			printf(
				"%s: %s\n", key,
				[(__bridge_transfer NSDate *)WiFiNetworkGetProperty(
					 network,
					 (__bridge CFStringRef)[NSString stringWithUTF8String:key])
					description]
					.UTF8String);
		} else if (type == CFBooleanGetTypeID()) {
			printf(
				"%s: %s\n", key,
				CFBooleanGetValue(WiFiNetworkGetProperty(
					network,
					(__bridge CFStringRef)[NSString stringWithUTF8String:key]))
					? "true"
					: "false");
		} else
			errx(1, "unknown return type");
		return 0;
	}

	printf(
		"SSID: %s\n",
		[(__bridge_transfer NSString *)WiFiNetworkGetSSID(network) UTF8String]);
	printf("BSSID: %s\n", networkBSSID(network));
	printf("WEP: %s\n", WiFiNetworkIsWEP(network) ? "yes" : "no");
	printf("WPA: %s\n", WiFiNetworkIsWPA(network) ? "yes" : "no");
	printf("EAP: %s\n", WiFiNetworkIsEAP(network) ? "yes" : "no");
	printf("Apple Hotspot: %s\n",
		   WiFiNetworkIsApplePersonalHotspot(network) ? "yes" : "no");
	printf("Adhoc: %s\n", WiFiNetworkIsAdHoc(network) ? "yes" : "no");
	printf("Hidden: %s\n", WiFiNetworkIsHidden(network) ? "yes" : "no");
	printf("Password Required: %s\n",
		   WiFiNetworkRequiresPassword(network) ? "yes" : "no");
	printf("Username Required: %s\n",
		   WiFiNetworkRequiresUsername(network) ? "yes" : "no");

	CFDictionaryRef data =
		(CFDictionaryRef)WiFiDeviceClientCopyProperty(client, CFSTR("RSSI"));
	CFNumberRef scaled =
		(CFNumberRef)WiFiDeviceClientCopyProperty(client, kWiFiScaledRSSIKey);

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
	printf("Channel: %i\n",
		   [(__bridge_transfer NSNumber *)WiFiNetworkGetProperty(
			   network, CFSTR("CHANNEL")) intValue]);
	printf("AP Mode: %i\n",
		   [(__bridge_transfer NSNumber *)WiFiNetworkGetProperty(
			   network, CFSTR("AP_MODE")) intValue]);
	printf("Interface: %s\n",
		   [(__bridge_transfer NSString *)WiFiDeviceClientGetInterfaceName(
			   client) UTF8String]);
	printf("Last Association Date: %s\n",
		   [(__bridge_transfer NSDate *)WiFiNetworkGetLastAssociationDate(
				network) descriptionWithLocale:nil]
			   .UTF8String);
	printf("Password: %s\n",
		   [(__bridge_transfer NSString *)WiFiNetworkCopyPassword(network)
			   UTF8String]);

	return 0;
}
