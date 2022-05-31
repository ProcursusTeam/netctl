#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>

#include "wifi.h"
#include "output.h"
#include "netctl.h"

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

	if (!current && argv[0] == NULL) {
		fprintf(stderr, "Usage: netctl wifi info [-bs] [-k key] SSID\n");
		return 1;
	}

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

	NSMutableDictionary *out = [NSMutableDictionary new];

	[out setObject:(__bridge_transfer NSString *)WiFiNetworkGetSSID(network) forKey:@"SSID"];
	[out setObject:(__bridge_transfer NSString *)networkBSSIDRef(network) forKey:@"BSSID"];
	[out setObject:WiFiNetworkIsWEP(network) ? @"yes" : @"no" forKey:@"WEP"];
	[out setObject:WiFiNetworkIsWPA(network) ? @"yes" : @"no" forKey:@"WPA"];
	[out setObject:WiFiNetworkIsEAP(network) ? @"yes" : @"no" forKey:@"EAP"];
	[out setObject:WiFiNetworkIsApplePersonalHotspot(network) ? @"yes" : @"no" forKey:@"Hostspot"];
	[out setObject:WiFiNetworkIsAdHoc(network) ? @"yes" : @"no" forKey:@"AdHoc"];
	[out setObject:WiFiNetworkIsHidden(network) ? @"yes" : @"no" forKey:@"Hidden"];
	[out setObject:WiFiNetworkRequiresPassword(network) ? @"yes" : @"no" forKey:@"RequiresPassword"];
	[out setObject:WiFiNetworkRequiresUsername(network) ? @"yes" : @"no" forKey:@"RequiresUsername"];

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

	[out setObject:[NSString stringWithFormat:@"%f dBm", strength] forKey:@"Strength"];
	[out setObject:[NSString stringWithFormat:@"%d", bars] forKey:@"Bars"];
	[out setObject:(__bridge_transfer NSNumber *)WiFiNetworkGetProperty(network, CFSTR("CHANNEL")) forKey:@"Channel"];
	[out setObject:(__bridge_transfer NSNumber *)WiFiNetworkGetProperty(network, CFSTR("AP_MODE")) forKey:@"APMode"];
	[out setObject:(__bridge_transfer NSString *)WiFiDeviceClientGetInterfaceName(client) forKey:@"APMode"];
	[out setObject:(__bridge_transfer NSDate*)WiFiNetworkGetLastAssociationDate(network) forKey:@"LastAssociationDate"];
	[out setObject:(__bridge_transfer NSString *)WiFiNetworkCopyPassword(network) forKey:@"Password"];

	[NCOutput printArray:@[out] withJSON:json];

	return 0;
}
