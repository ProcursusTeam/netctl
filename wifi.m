#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>
#include <stdbool.h>
#include <stdio.h>

int list();
int info(WiFiNetworkRef, WiFiDeviceClientRef, bool);
int power(char *);
int scan(WiFiDeviceClientRef);
int connect(WiFiDeviceClientRef, int, char **);
void scanCallback(WiFiDeviceClientRef, CFArrayRef, CFErrorRef, void *);
void connectScanCallback(WiFiDeviceClientRef, CFArrayRef, CFErrorRef, void *);
void connectCallback(WiFiDeviceClientRef, WiFiNetworkRef, CFDictionaryRef, int,
					 const void *);
WiFiNetworkRef getNetworkWithSSID(char *);

const char *networkBSSID(WiFiNetworkRef network);
CFStringRef networkBSSIDRef(WiFiNetworkRef);

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
		ret = info(WiFiDeviceClientCopyCurrentNetwork(client), client, true);
	} else if (!strcmp(argv[2], "list")) {
		ret = list();
	} else if (!strcmp(argv[2], "info")) {
		if (argc != 4)
			errx(1, "no SSID specified");
		ret = info(getNetworkWithSSID(argv[3]), client, false);
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

int info(WiFiNetworkRef network, WiFiDeviceClientRef client, bool current) {
	printf("SSID: %s\n", [(NSString *)CFBridgingRelease(
							 WiFiNetworkGetSSID(network)) UTF8String]);
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

	if (current) {
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
		printf("Channel: %i\n",
			   [(NSNumber *)CFBridgingRelease(WiFiNetworkGetProperty(
				   network, CFSTR("CHANNEL"))) intValue]);
		printf("AP Mode: %i\n",
			   [(NSNumber *)CFBridgingRelease(WiFiNetworkGetProperty(
				   network, CFSTR("AP_MODE"))) intValue]);
		printf("Interface: %s\n",
			   [(NSString *)CFBridgingRelease(
				   WiFiDeviceClientGetInterfaceName(client)) UTF8String]);
	}
	return 0;
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

int power(char *action) {
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

int scan(WiFiDeviceClientRef client) {
	WiFiManagerClientScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	WiFiDeviceClientScanAsync(
		client, (__bridge CFDictionaryRef)[NSDictionary dictionary],
		scanCallback, 0);
	CFRunLoopRun();

	return 0;
}

void scanCallback(WiFiDeviceClientRef client, CFArrayRef results,
				  CFErrorRef error, void *token) {
	if ((NSError *)CFBridgingRelease(error))
		errx(1, "Failed to scan: %s",
			 [[(NSError *)CFBridgingRelease(error) localizedDescription]
				 UTF8String]);

	for (int i = 0; i < CFArrayGetCount(results); i++) {
		printf("%s : %s\n",
			[(NSString *)CFBridgingRelease(WiFiNetworkGetSSID((
				WiFiNetworkRef)CFArrayGetValueAtIndex(results, i))) UTF8String],
			networkBSSID((WiFiNetworkRef)CFArrayGetValueAtIndex(results, i)));
	}

	WiFiManagerClientUnscheduleFromRunLoop(manager);
	CFRunLoopStop(CFRunLoopGetCurrent());
}

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

const char *networkBSSID(WiFiNetworkRef network) {
	return [(NSString *)CFBridgingRelease(networkBSSIDRef(network)) UTF8String];
}

CFStringRef networkBSSIDRef(WiFiNetworkRef network) {
	return WiFiNetworkGetProperty(network, CFSTR("BSSID"));
}
