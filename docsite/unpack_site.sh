#
# Copyright 2019, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Unpack site to location a webserver expects it at
cd /run
gunzip /var/site.tar.gz
tar -xf /var/site.tar
mv docsite site
touch site/secure
