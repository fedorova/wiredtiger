/*-
 * See the file LICENSE for redistribution information.
 *
 * Copyright (c) 2008 WiredTiger Software.
 *	All rights reserved.
 *
 * $Id$
 */

#include "wts.h"

GLOBAL g;

static void	usage(void);

int
main(int argc, char *argv[])
{
	int ch, log;

	if ((g.progname = strrchr(argv[0], '/')) == NULL)
		g.progname = argv[0];
	else
		++g.progname;

	/* Configure the FreeBSD malloc for debugging. */
	(void)putenv("MALLOC_OPTIONS=AJZ");

	/* Set values from the "CONFIG" file, if it exists. */
	if (access("CONFIG", R_OK) == 0) {
		printf("... reading CONFIG file\n");
		config_file("CONFIG");
	}

	/* Set values from the command line. */
	log = 0;
	while ((ch = getopt(argc, argv, "1C:cd:lsv")) != EOF)
		switch (ch) {
		case '1':
			g.c_runs = 1;
			break;
		case 'C':
			config_file(optarg);
			break;
		case 'c':
			config_names();
			return (EXIT_SUCCESS);
		case 'd':
			switch (optarg[0]) {
			case 'd':
				g.dump = DUMP_DEBUG;
				break;
			case 'p':
				g.dump = DUMP_PRINT;
				break;
			default:
				usage();
			}
		case 'l':
			log = 1;
			break;
		case 's':
			g.stats = 1;
			break;
		case 'v':
			g.verbose = 1;
			break;
		default:
			usage();
		}

	argc -= optind;
	argv += optind;
	for (; *argv != NULL; ++argv)
		config_single(*argv);

	printf("%s: process %lu\n", g.progname, (u_long)getpid());
	while (++g.run_cnt <= g.c_runs || g.c_runs == 0 ) {
		config();

		bdb_setup(0);		/* Open the databases */
		wts_setup(0, log);

		config_dump(1);

		if (wts_bulk_load())	/* Load initial records */
			goto err;

		if (wts_verify())	/* Verify the database */
			goto err;

		track("flushing & re-opening WT", 0);
		wts_teardown();		/* Re-open the WT database */
		wts_setup(1, log);
					/* Scan through some records */
		switch (g.c_database_type) {
		case ROW:
			if (wts_read_row_scan())
				goto err;
			break;
		case FIX:
		case VAR:
			if (wts_read_col_scan())
				goto err;
			break;
		}

		if (wts_ops())		/* Random operations */
			goto err;

					/* Optional statistics */
		if (g.stats && wts_stats())
			goto err;

					/* Close the databases */
		track("shutting down BDB", 0);
		bdb_teardown();	
		track("shutting down WT", 0);
		wts_teardown();

		track("done", 0);
		printf("\n");
	}

	return (EXIT_SUCCESS);

err:	config_dump(0);
	return (EXIT_FAILURE);
}

/*
 * usage --
 *	Display usage statement and exit failure.
 */
static void
usage()
{
	(void)fprintf(stderr,
	    "usage: %s [-1clsv] [-C config] [-d debug | print] "
	    "[name=value ...]\n",
	    g.progname);
	exit (EXIT_FAILURE);
}
