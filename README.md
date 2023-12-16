<!--
     Copyright 2017, Data61, CSIRO (ABN 41 687 119 230)

     SPDX-License-Identifier: CC-BY-SA-4.0
-->

# DUMMY CHANGE

# seL4webserver reference application

This project contains an seL4 webserver application.  Its purpose is to be a reference for
implementing applications on seL4. Currently there is only a single configuration that runs
a webserver inside a Linux VM component to serve a static website.

## Current status

Currently there are two configurations for serving a static website from a webserver running
inside a Linux guest on an [odroid-xu4][odroid-xu4] on a local network. This includes a configuration
with a single VM instance that serves a static website. The second configuration involves
multiple VM's serving a static website. The multiple VM configuration has an additional VM that acts
as an network access point for the other VMs.
It would be possible to modify which static website is being served by modifying the static html files located in `/run/site/`
in the Linux guest's file system.
If you don't have [odroid-xu4][odroid-xu4] to test this project you still can use emulation. Please see "Configure: Single VM Webserver (qemu-arm-virt)". Notice: check "Configure networking (qemu-arm-virt)" to learn more about this topic".

[odroid-xu4]:https://wiki.odroid.com/odroid-xu4/odroid-xu4

## Plans

The purpose of this project is to build up a set of reference artifacts and system configurations
that leverage seL4's isolation guarantees and different board support packages.  Currently
everything is run inside a single camkes component and therefore doesn't isolate different components.
The next steps are to increase the amount of platforms that this app targets and to pull functionality
out into separate isolated components. We also want to have an idea of performance characteristics for
this system.  Longer term steps involve constructing more complicated systems that have a network
access point but also have functions that need to be strongly isolated in a secure way.

### Short-term

- Native application not involving Linux-VM
- Additional platforms
- Performance analysis/optimisation

### Long-term

- More complex system design

## Setup

This project is based on an Arm VMM running inside a camkes system and therefore requires all of the
Camkes dependencies described in [Host Dependencies][host-dependencies].

Additional dependencies required to run a lighttpd webserver serving docs.sel4.systems in a Linux guest:

- [docsite dependencies][docsite-deps]: Dependencies required to build docs.sel4.systems.
- libpcre3-dev:armel
- zlib compression library, armel arch: Required for building lighttpd (debian package: zlib1g-dev:armel)
- pcre regex library, armel arch: Required for building lighttpd (debian package: libpcre3-dev:armel)
- arm user binary emulation via qemu: Required for building lighttpd (debian package: qemu-user

### Build instructions

```sh
# After initialising a fresh directory

# Obtain sources via repo tool
repo init -u https://github.com/seL4/sel4webserver-manifest.git
repo sync
```

#### Configure: Single VM Webserver

```sh
# Initalise project build directory
mkdir build
cd build
../init-build.sh
# -- Configuring done
# -- Generating done
# -- Build files have been written to: /tmp/tmp.xmwD2Fc3FW/buildweb
```

#### Configure: Multi-VM Webserver

```sh
# Initalise project build directory
mkdir build
cd build
../init-build.sh -DMULTI_VM_LAN=1
# -- Configuring done
# -- Generating done
# -- Build files have been written to: /tmp/tmp.xmwD2Fc3FW/buildweb
```

#### Build Webserver

```sh
# build
ninja
# [0/1] Re-running CMake...
# -- Configuring done
# -- Generating done
# -- Build files have been written to: /tmp/tmp.xmwD2Fc3FW/buildweb
# [59/385] Performing CAmkES generation for 15 files
# ...
# [385/385] Generating images/capdl-loader-image-arm-exynos5

# Resulting artifacts:
ls images
# capdl-loader-image-arm-exynos5
```

See the [Odroid XU4 hardware page](https://docs.sel4.systems/Hardware/OdroidXU4.html) on the docsite
for additional information about running an seL4 image on an Odroid XU4.

Running the generated seL4webserver image will result in a running webserver listening on port 3000.

```
udhcpc: started, v1.27.2
[   10.485099] random: mktemp: uninitialized urandom read (6 bytes read)
udhcpc: sending [   10.504865] r8152 6-1:1.0 eth0: carrier on
discover
udhcpc: sending select for 10.13.1.7
udhcpc: lease of 10.13.1.7 obtained, lease time 3600
deleting routers
[   11.548877] random: mktemp: uninitialized urandom read (6 bytes read)
adding dns 10.13.0.8
adding dns 10.13.0.9

Welcome to Buildroot
buildroot login:

```

You could then navigate to 10.13.1.7:3000 in a web browser on the same local network.

[host-dependencies]: https://docs.sel4.systems/projects/buildsystem/host-dependencies.html
[docsite-deps]: https://github.com/seL4/docs/blob/master/tools/Dockerfile

#### Configure: Single VM Webserver (qemu-arm-virt)

```sh
#Initialise project build directory
mkdir build
cd build
../init-build.sh -DPLATFORM=qemu-arm-virt
#...
#Warning: no cpu specified for virt board, fallback on cortex-a53
#...
#-- Configuring done
#-- Generating done
#-- Build files have been written to: /home/hugo/seL4/sel4webserver/build
```

#### Build Webserver (qemu-arm-virt)

```sh
# build
ninja
# [13/443] Performing configure step for 'cgi-load-file'
# -- The C compiler identification is GNU 9.3.0
# ...
# This step will take some time, be patient...
# [358/443] Completed 'docsite'
# ...
# [443/443] Generating images/capdl-loader-image-arm-qemu-arm-virt

# Resulting artifacts:
ls images
# capdl-loader-image-arm-qemu-arm-virt
```

#### Running seL4 qemu-arm-virt image

```sh
./simulate
# ./simulate: qemu-system-aarch64 -machine virt,virtualization=on,highmem=off,secure=off -cpu cortex-a53 -nographic  -m size=2048  -kernel images/capdl-loader-image-arm-qemu-arm-virt
# ELF-loader started on CPU: ARM Ltd. Cortex-A53 r0p4
# ...
# Bootstrapping kernel
# Warning: Could not infer GIC interrupt target ID, assuming 0.
# Booting all finished, dropped to user space
# <<seL4(CPU 0) [decodeUntypedInvocation/205 T0xff80bf817400 "rootserver" @4006f8]: Untyped Retype: Insufficient memory (1 * 2097152 bytes needed, 0 bytes available).>>
# Loading Linux: 'linux' dtb: 'linux-dtb'
# ...
# [    0.000000] Booting Linux on physical CPU 0x0
# [    0.000000] Linux version 4.9.189+ (alisonf@shinyu-un) (gcc version 6.3.0 20170516 (Debian 6.3.0-18) ) #16 SMP Tue Feb 25 14:14:50 AEDT 2020
# [    0.000000] Boot CPU: AArch64 Processor [410fd034]
# ...
# Starting network: OK
# [    6.538957] connection: loading out-of-tree module taints kernel.
# [    6.579046] Event Bar (dev-0) initalised
# [    6.620310] 2 Dataports (dev-0) initalised
# ifconfig: SIOCGIFFLAGS: No such device
# udhcpc: SIOCGIFINDEX: No such device
#
# Welcome to Buildroot
# buildroot login:

```

## Configure networking (qemu-arm-virt)

Networking under qemu may be somewhat tricky and specific configuration details may vary depending on the host configuration/distro/etc. Thus here there are some few suggestions to try having your set up ready as easy as possible.
So, if you want to have networking on your virtualized guest then you can try:

1st- Configure a dhcp server on the host.
2nd- Run "simulate" like this:

```sh
sudo ./simulate --extra-qemu-args="-netdev tap,id=mynet0,ifname=tap0,script=no,downscript=no -device virtio-net,netdev=mynet0,mac=52:55:00:d1:55:01,disable-modern=on,disable-legacy=off"
```

3rd- Manually create the bridge interface to connect the guest and the host networking. Again, here specific commands' syntax depends on every environment. Just as an example here what worked on Ubuntu 20.04:

```sh
sudo brctl addif virbr0 eno1
sudo brctl addif virbr0 tap0
sudo ifconfig tap0 up
sudo ifconfig virbr0 up
sudo ifconfig eno1 up
brctl show
```

Anyway, probably you will need to check the documentation of your specific host distro and qemu version to see how a bridge can be created in your specific setup.
It is well known that on some deployments qemu scripts automatically takes cares of this so you will be able to skip this last step.

Thus if everything goes as desired you should see udhcpc getting networking config, that is, something like this:

```
Starting network: OK
[    6.431947] connection: loading out-of-tree module taints kernel.
[    6.469091] Event Bar (dev-0) initalised
[    6.492662] 2 Dataports (dev-0) initalised
udhcpc: started, v1.31.0
[   16.026150] random: mktemp: uninitialized urandom read (6 bytes read)
udhcpc: sending discover
udhcpc: sending select for 192.168.122.100
udhcpc: lease of 192.168.122.100 obtained, lease time 600
[   17.503524] random: mktemp: uninitialized urandom read (6 bytes read)
adding dns 8.8.8.8
adding dns 8.8.4.4

Welcome to Buildroot
buildroot login:
```

## Testing the web server (qemu-arm-virt)

Once the networking has been set up, you can check what IP has been assigned to your guest (also it is announced on the screen via udhcpc message...):

```
udhcpc: sending select for 192.168.122.100
udhcpc: lease of 192.168.122.100 obtained, lease time 600
[   17.503524] random: mktemp: uninitialized urandom read (6 bytes read)
adding dns 8.8.8.8
adding dns 8.8.4.4

Welcome to Buildroot
buildroot login: root
# ifconfig
eth0      Link encap:Ethernet  HWaddr 52:55:00:D1:55:01
          inet addr:192.168.122.100  Bcast:192.168.122.255  Mask:255.255.255.0
(...)
```

and now just open web browser and open URL: `http://<your_assigned_IP>:3000` and you should see an seL4 documentation web page.


## Contributing

Contributions are welcome in the form of feature requests, documentation requests, or documentation/code contributions.
See [CONTRIBUTING.md] for our general contribution guidelines.

Current code contributions we would be interested to receive:

- Additional platforms
- Additional VM modules
- Performance analysis

[CONTRIBUTING.md]: .github/CONTRIBUTING.md
