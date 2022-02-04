#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

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

int airplane(char *set) {
	NCRadiosPreferences *radiosPreferences = [NCRadiosPreferences new];

	radiosPreferences.delegate = radiosPreferences;

	if (set == NULL || !strcmp(set, "status")) {
		printf("%s\n", [radiosPreferences airplaneMode] ? "on" : "off");
		return 0;
	} else if (!strcmp(set, "on")) {
		[radiosPreferences setAirplaneMode:1];
	} else if (!strcmp(set, "off")) {
		[radiosPreferences setAirplaneMode:0];
	} else if (!strcmp(set, "toggle")) {
		[radiosPreferences setAirplaneMode:![radiosPreferences airplaneMode]];
	} else {
		fprintf(stderr, "Usage: netctl airplane [status | toggle | on | off]\n");
		return 1;
	}

	CFRunLoopRun();

	return 0;
}
