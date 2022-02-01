#import <CoreFoundation/CoreFoundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>
#include <stdbool.h>

#include "wifi.h"

int wififorget(int argc, char **argv) {
	WiFiNetworkRef network;
	bool bssid = false;
	int ch;

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

	if (argv[0] == NULL) {
		fprintf(stderr, "Usage: netctl wifi forget [-bs] SSID\n");
		return 1;
	}

	if (bssid)
		network = getNetworkWithBSSID(argv[0]);
	else
		network = getNetworkWithSSID(argv[0]);

	WiFiManagerClientRemoveNetwork(manager, network);

	return 0;
}
