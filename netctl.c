#include <err.h>
#include <stdio.h>
#include <string.h>

int wifi(int, char **);
int cellular(int, char **);
int airdrop(int, char **);

void usage(void);

int main(int argc, char *argv[]) {
	if (argc < 2) {
		usage();
		return 1;
	}

	if (!strcmp(argv[1], "wifi"))
		return wifi(argc, argv);
	else if (!strcmp(argv[1], "cellular"))
		return cellular(argc, argv);
	else if (!strcmp(argv[1], "airdrop"))
		return airdrop(argc, argv);

	usage();
	return 1;
}

void usage() {
	fprintf(stderr, "Usage: netctl [airdrop | cellular | wifi] [arguments]\n");
}
