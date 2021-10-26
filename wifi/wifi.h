#import <MobileWiFi/MobileWiFi.h>

int list(void);
int info(bool, int, char **);
int power(char *);
int scan(void);
int connect(int, char **);
int forget(int, char **);
WiFiNetworkRef getNetworkWithSSID(char *ssid);
WiFiNetworkRef getNetworkWithBSSID(char *bssid);

const char *networkBSSID(WiFiNetworkRef network);
CFStringRef networkBSSIDRef(WiFiNetworkRef);

extern CFArrayRef connectNetworks;
extern WiFiManagerRef manager;
extern WiFiDeviceClientRef client;
