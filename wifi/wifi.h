#import <MobileWiFi/MobileWiFi.h>

#include "netctl.h"

int wifilist(netctl_options *);
int wifiinfo(bool, netctl_options *op, int, char **);
int wifipower(char *);
int wifiscan(netctl_options *, int, char **);
int wificonnect(int, char **);
int wififorget(int, char **);
WiFiNetworkRef getNetworkWithSSID(char *ssid);
WiFiNetworkRef getNetworkWithBSSID(char *bssid);

const char *networkBSSID(WiFiNetworkRef network);
CFStringRef networkBSSIDRef(WiFiNetworkRef);

extern CFArrayRef connectNetworks;
extern WiFiManagerRef manager;
extern WiFiDeviceClientRef client;
