#include <err.h>
#include <string.h>

int airdropscan(int, char **);

int airdrop(int argc, char **argv) {
	if (!argv[2]) {
		errx(1, "no airdrop subcommand specified");
		return 1;
	}

	int ret = 1;

	if (!strcmp(argv[2], "scan") || !strcmp(argv[2], "browser")) {
		ret = airdropscan(argc - 2, argv + 2);
	}

	return ret;
}
