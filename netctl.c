#include <err.h>
#include <string.h>

int wifi(int, char **);
int cellular(int, char **);

int main(int argc, char *argv[]) {
	if (argc < 2)
		errx(1, "Need a subcommand");

	if (!strcmp(argv[1], "wifi"))
		return wifi(argc, argv);
	else if (!strcmp(argv[1], "cellular"))
		return cellular(argc, argv);

	errx(1, "invalid subcommand");
}
