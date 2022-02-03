#include <err.h>
#include <stdio.h>
#include <string.h>

int airdropscan(int, char **);
int airdropsend(int, char **);
int airdroppower(char *);

int airdrop(int argc, char **argv) {
	if (!argv[2]) {
		fprintf(stderr, "Usage: netctl airdrop [scan | browse | send | power] [arguments]\n");
		return 1;
	}

	if (!strcmp(argv[2], "scan") || !strcmp(argv[2], "browse")) {
		return airdropscan(argc - 2, argv + 2);
	} else if (!strcmp(argv[2], "send")) {
		return airdropsend(argc - 2, argv + 2);
	} else if (!strcmp(argv[2], "power")) {
		if (argc < 3)
			return airdroppower(NULL);
		else
			return airdroppower(argv[3]);
	}

	fprintf(stderr, "Usage: netctl airdrop [scan | browse | send | power] [arguments]\n");
	return 1;
}
