#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <MobileWiFi/MobileWiFi.h>
#include <err.h>

#include "wifi.h"

int wifipower(char *action) {
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
	} else if (!strcmp(action, "help")) {
		fprintf(stderr, "Usage: netctl wifi power [on | off | toggle | status | help]\n");
		return 1;
	}

	return 0;
}
