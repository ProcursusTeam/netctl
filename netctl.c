#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <err.h>

#include "netctl.h"

struct cmd cmds[] = {
	{ "airdrop", (cmd_main *)airdrop_cmd },
	{ "airplane", (cmd_main *)airplane_cmd },
	{ "cellular", (cmd_main *)cellular_cmd },
	{ "wifi", (cmd_main *)wifi_cmd }
};

int
main(int argc, char **argv, char **envp, char **apple)
{
	netctl_options op = {
		.json = false,
		.timeout = 30,
	};

	int ch;
	char *end;
	while ((ch = getopt(argc, argv, "jt:")) != -1) {
		switch (ch) {
			case 'j':
				op.json = true;
				break;
			case 't':
				op.timeout = strtod(optarg, &end);
				if (op.timeout == 0 && end == optarg)
					errx(125, "invalid duration");
				if (end == NULL || *end == '\0')
					break;
				if (end != NULL && *(end + 1) != '\0')
					errx(125, "invalid duration");
				switch (*end) {
					case 'd':
						op.timeout *= 24;
						/* FALLTHROUGH */
					case 'h':
						op.timeout *= 60;
						/* FALLTHROUGH */
					case 'm':
						op.timeout *= 60;
						/* FALLTHROUGH */
					case 's':
						break;
					default:
						errx(125, "invalid duration");
				}
				break;
		}
	}
	argc -= optind;
	argv += optind;

	int num_cmds = sizeof(cmds) / sizeof(struct cmd);
	if (argc >= 1)
		for (int i = 0; i < num_cmds; i++)
			if (strcmp(cmds[i].name, argv[0]) == 0)
				return cmds[i].exec(&op, argc, argv, envp, apple);

	printf("netctl [-j] [-t sec] [airdrop | airplane | cellular | wifi]\n");
	return 1;
}
