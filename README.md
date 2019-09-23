<!--
 Copyright 2017, Data61
 Commonwealth Scientific and Industrial Research Organisation (CSIRO)
 ABN 41 687 119 230.

 This software may be distributed and modified according to the terms of
 the BSD 2-Clause license. Note that NO WARRANTY is provided.
 See "LICENSE_BSD2.txt" for details.

 @TAG(DATA61_BSD)
-->

# seL4webserver reference application

This project contains an seL4 webserver application.  Its purpose is to be a reference for
implementing applications on seL4. Currently there is only a single configuration that runs
a webserver inside a Linux VM component to serve a static website.

## Current status

Currently there is a single configuration for serving a static website from a webserver running
inside a Linux guest on an [odroid-xu4][odroid-xu4] on a local network. It would be possible to
modify which static website is being served by modifying the static html files located in `/run/site/`
in the Linux guest's file system.

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
repo init -u https://github.com/SEL4PROJ/sel4webserver-manifest.git
repo sync

# Initalise project build directory
mkdir build
cd build
../init-build.sh
# -- Configuring done
# -- Generating done
# -- Build files have been written to: /tmp/tmp.xmwD2Fc3FW/buildweb

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

[host-dependencies]:https://docs.sel4.systems/HostDependencies
[docsite-deps]:https://github.com/SEL4PROJ/docs/blob/master/tools/Dockerfile

## Contributing

Contributions are welcome in the form of feature requests, documentation requests, or documentation/code contributions.
See https://docs.sel4.systems/Contributing for our general contribution guidelinies.

Current code contributions we would be interested to receive:
- Additional platforms
- Additional VM modules
- Performance analysis
