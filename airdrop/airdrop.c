#include <err.h>
#include <stdio.h>
#include <string.h>

#include "netctl.h"

int airdropscan(netctl_options *, int, char **);
int airdropsend(int, char **);
int airdroppower(char *);

int airdrop_cmd(netctl_options *op, int argc, char **argv) {
	if (!argv[1]) {
		fprintf(stderr, "Usage: netctl airdrop [scan | browse | send | power] [arguments]\n");
		return 1;
	}

	if (!strcmp(argv[1], "scan") || !strcmp(argv[1], "browse")) {
		return airdropscan(op, argc - 1, argv + 1);
	} else if (!strcmp(argv[1], "send")) {
		return airdropsend(argc - 1, argv + 1);
	} /* else if (!strcmp(argv[1], "power")) {
		if (argc < 2)
			return airdroppower(NULL);
		else
			return airdroppower(argv[2]);
	} */

	fprintf(stderr, "Usage: netctl airdrop [scan | send] [arguments]\n");
	return 1;
}
