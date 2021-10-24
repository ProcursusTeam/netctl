#include <CTPrivate.h>
#include <CoreTelephony/CTCarrier.h>
#include <CoreTelephony/CTTelephonyNetworkInfo.h>
#include <Foundation/Foundation.h>
#include <err.h>

static int number(void) {
	printf("%s\n", [CTSettingCopyMyPhoneNumber() UTF8String]);
	return 0;
}

static int info(void) {
	CTTelephonyNetworkInfo* info = [[CTTelephonyNetworkInfo alloc] init];
	NSDictionary<NSString*, CTCarrier*>* serviceTech = info.serviceSubscriberCellularProviders;
	NSDictionary<NSString*, NSString*>* accessTechnology = info.serviceCurrentRadioAccessTechnology;

	long int raw = 0, graded = 0, bars = 0;

	CTIndicatorsGetSignalStrength(&raw, &graded, &bars);

	printf("Connection strength: %ld%%\n\n", bars * 25);

	int i = 0;
	for (NSString* key in serviceTech) {
		printf("SIM %d:\n", i);
		printf("\tCarrier Name: %s\n", serviceTech[key].carrierName.UTF8String);
		printf("\tAllows VOIP (Voice over IP): %s\n", serviceTech[key].allowsVOIP ? "Yes" : "No");
		printf("\tISO Country Code: %s\n", serviceTech[key].isoCountryCode.UTF8String);
		printf("\tMobile Country Code (MCC): %s\n", serviceTech[key].mobileCountryCode.UTF8String);
		printf("\tMobile Network Code (MCC): %s\n", serviceTech[key].mobileNetworkCode.UTF8String);
		printf("\n");
		i++;
	}

	return 0;
}

static int call(NSString* number) {
	CTCallRef call = CTCallDial(number);
	printf("Calling %s...\n", CTCallCopyAddress(nil, call).UTF8String);
	return 0;
}

int cellular(int argc, char** argv) {
	const char* cmd = argv[2];
	int ret = 0;

	if (argc < 3) {
		errx(1, "no cellular subcommand specified");
		return 1;
	}

	if (!strcmp(cmd, "number")) {
		return number();
	}

	if (!strcmp(cmd, "info")) {
		return info();
	}

	if (!strcmp(cmd, "call")) {
		if (argc < 4) {
			errx(1, "no phone number specified");
			return 1;
		}

		return call([NSString stringWithUTF8String:argv[3]]);
	}

	errx(1, "invalid cellular subcommand");

	return 1;
}
