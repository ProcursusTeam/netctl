#import <MobileWiFi/MobileWiFi.h>

int wifilist(void);
int wifiinfo(bool, int, char **);
int wifipower(char *);
int wifiscan(void);
int wificonnect(int, char **);
int wififorget(int, char **);
WiFiNetworkRef getNetworkWithSSID(char *ssid);
WiFiNetworkRef getNetworkWithBSSID(char *bssid);

const char *networkBSSID(WiFiNetworkRef network);
CFStringRef networkBSSIDRef(WiFiNetworkRef);

extern CFArrayRef connectNetworks;
extern WiFiManagerRef manager;
extern WiFiDeviceClientRef client;
