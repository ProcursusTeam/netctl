#import <Foundation/Foundation.h>
#include <cups/cups.h>
#include <err.h>

int nctl_print_browse(void) {
	cups_dest_t* dests;
	int numdests = cupsGetDests(&dests);

	for (int i = 0; i < numdests; i++) {
		printf("%s\n", dests[i].name);
	}

	return 0;
}

int nctl_print(int argc, char** argv) {
	if (argc < 1) {
		errx(1, "give command");
	}

	if (!strcmp(argv[0], "browse")) {
		nctl_print_browse();
	}

	return 1;
}