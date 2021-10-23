#include <CoreTelephony/CTPrivate.h>
#include <Foundation/Foundation.h>
#include <err.h>

int cellular(int argc, char** argv) {
	const char* cmd = argv[2];
	int ret = 0;

	if (!cmd) {
		errx(1, "no cellular subcommand specified");
		return 1;
	}

	if (!strcmp(cmd, "number")) {
		printf("%s\n", [CTSettingCopyMyPhoneNumber() UTF8String]);
		return 0;
	}

	errx(1, "invalid cellular subcommand");

	return 1;
}
