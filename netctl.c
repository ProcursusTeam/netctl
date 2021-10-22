#include <err.h>
#include <string.h>

int wifi(int, char**);

int main(int argc, char *argv[]) {
	if (argc < 2)
		errx(1, "Need a subcommand");

	if (!strcmp(argv[1], "wifi"))
		return wifi(argc, argv);

	errx(1, "invalid subcommand");
}
