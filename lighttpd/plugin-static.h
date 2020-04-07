/*
 * Copyright 2019, Data61
 * Commonwealth Scientific and Industrial Research Organisation (CSIRO)
 * ABN 41 687 119 230.
 *
 * This software may be distributed and modified according to the terms of
 * the BSD 2-Clause license. Note that NO WARRANTY is provided.
 * See "LICENSE_BSD2.txt" for details.
 *
 * @TAG(DATA61_BSD)
 */

/* Modules that lighttpd will be statically compiled with */
PLUGIN_INIT(mod_indexfile)
PLUGIN_INIT(mod_dirlisting)
PLUGIN_INIT(mod_staticfile)
PLUGIN_INIT(mod_rewrite)
PLUGIN_INIT(mod_cgi)
