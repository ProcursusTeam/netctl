#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#include "netctl.h"

@protocol RadiosPreferencesDelegate <NSObject>
-(void)airplaneModeChanged;
@end

@interface RadiosPreferences : NSObject
@property (nonatomic) bool airplaneMode;
@property (nonatomic) id <RadiosPreferencesDelegate> delegate;
-(void)refresh;
-(void)syncrohnize;
@end

@interface NCRadiosPreferences : RadiosPreferences<RadiosPreferencesDelegate>
@end

@implementation NCRadiosPreferences
-(void)airplaneModeChanged {
	CFRunLoopStop(CFRunLoopGetCurrent());
}
@end

int airplane_cmd(netctl_options *op, int argc, char **argv) {
	NCRadiosPreferences *radiosPreferences = [NCRadiosPreferences new];

	radiosPreferences.delegate = radiosPreferences;

	if (argc != 2 || !strcmp(argv[1], "status")) {
		printf("%s\n", [radiosPreferences airplaneMode] ? "on" : "off");
		return 0;
	} else if (!strcmp(argv[1], "on")) {
		[radiosPreferences setAirplaneMode:1];
	} else if (!strcmp(argv[1], "off")) {
		[radiosPreferences setAirplaneMode:0];
	} else if (!strcmp(argv[1], "toggle")) {
		[radiosPreferences setAirplaneMode:![radiosPreferences airplaneMode]];
	} else {
		fprintf(stderr, "Usage: netctl airplane [status | toggle | on | off]\n");
		return 1;
	}

	CFRunLoopRun();

	return 0;
}
