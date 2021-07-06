/*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <string.h>
#include <camkes.h>
#include <ctype.h>
#include <cpio/cpio.h>
#include <stdio.h>
#include <muslcsys/io.h>
#include <fcntl.h>

extern char _cpio_archive[];
extern char _cpio_archive_end[];
/* Camkes signal function symbol */
extern void done_emit_underlying(void);


#define MAX_FILENAME_LENGTH 200

void pre_init()
{
    /* install the _cpio_archive */
    unsigned long cpio_size = _cpio_archive_end - _cpio_archive;
    muslcsys_install_cpio_interface(_cpio_archive, cpio_size, cpio_get_file);
}


int run(void)
{
    /* Zero out the data port */
    memset(dest, '\0', 4096);
    char *dest_c = (char *)dest;
    char filename[MAX_FILENAME_LENGTH] = {0};
    while (1) {
        ready_wait();
        strncpy(filename, dest_c + strlen("/"), MAX_FILENAME_LENGTH - 1);
        int fd = open(filename, O_RDONLY);
        if (fd < 0) {
            snprintf(dest_c, 4, "404");
            printf("Received Bad request for file: %s.\n", filename);
            done_emit_underlying();
            continue;
        }
        size_t len = read(fd, dest_c, 4095);
        dest_c[len] = 0;
        printf("Received request for file: %s. Returned %d bytes.\n", filename, len);

        done_emit_underlying();
    }

    return 0;
}
