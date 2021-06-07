#
# Copyright 2019, Data61
# Commonwealth Scientific and Industrial Research Organisation (CSIRO)
# ABN 41 687 119 230.
#
# This software may be distributed and modified according to the terms of
# the BSD 2-Clause license. Note that NO WARRANTY is provided.
# See "LICENSE_BSD2.txt" for details.
#
# @TAG(DATA61_BSD)
#

# Wait time for system setup so ifconfig correctly configures ethernet device
sleep 5
ifconfig eth0 up
# Get an IP address
nohup udhcpc &

# Start ligttpd with the config file in background
lighttpd -f /etc/lighttpd.conf
