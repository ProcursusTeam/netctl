#import <MobileWiFi/MobileWiFi.h>

int list();
int info(WiFiDeviceClientRef, bool, int, char **);
int power(char *);
int scan(WiFiDeviceClientRef);
int connect(WiFiDeviceClientRef, int, char **);
WiFiNetworkRef getNetworkWithSSID(char *);
WiFiNetworkRef getNetworkWithBSSID(char *);

const char *networkBSSID(WiFiNetworkRef network);
CFStringRef networkBSSIDRef(WiFiNetworkRef);

extern CFArrayRef connectNetworks;
extern WiFiManagerRef manager;
