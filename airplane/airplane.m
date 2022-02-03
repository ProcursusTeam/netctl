#import <Foundation/Foundation.h>

@interface RadiosPreferences : NSObject
@property (nonatomic) bool airplaneMode;
- (void)refresh;
@end

int airplane(char *set) {
	RadiosPreferences *radiosPreferences = [RadiosPreferences new];

	[radiosPreferences refresh];

	if (set == NULL || !strcmp(set, "status")) {
		printf("%s\n", [radiosPreferences airplaneMode] ? "on" : "off");
		return 0;
	} else if (!strcmp(set, "on")) {
		[radiosPreferences setAirplaneMode:1];
		return 0;
	} else if (!strcmp(set, "off")) {
		[radiosPreferences setAirplaneMode:0];
		return 0;
	} else if (!strcmp(set, "toggle")) {
		[radiosPreferences setAirplaneMode:![radiosPreferences airplaneMode]];
		return 0;
	} else {
		fprintf(stderr, "Usage: netctl airplane [status | toggle | on | off]\n");
		return 1;
	}

	return 1;
}
