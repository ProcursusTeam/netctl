#include <err.h>
#include <string.h>

int airdropscan(int, char **);
int airdropsend(int, char **);

int airdrop(int argc, char **argv) {
	if (!argv[2]) {
		errx(1, "no airdrop subcommand specified");
		return 1;
	}

	int ret = 1;

	if (!strcmp(argv[2], "scan") || !strcmp(argv[2], "browse")) {
		ret = airdropscan(argc - 2, argv + 2);
	} else if (!strcmp(argv[2], "send")) {
		ret = airdropsend(argc - 2, argv + 2);
	} else
		errx(1, "invalid airdrop subcommand");

	return ret;
}
