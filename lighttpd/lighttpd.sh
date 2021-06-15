#
# Copyright 2019, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

# Wait time for system setup so ifconfig correctly configures ethernet device
sleep 5
ifconfig eth0 up
# Get an IP address
nohup udhcpc &

# Start ligttpd with the config file in background
lighttpd -f /etc/lighttpd.conf
