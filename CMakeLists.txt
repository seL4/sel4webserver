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

cmake_minimum_required(VERSION 3.12.0)
project(sel4webserver C ASM)

include(settings.cmake)

# Import camkes-arm-vm build environment
find_package(camkes-arm-vm REQUIRED)
set(VmInitRdFile ON CACHE BOOL "" FORCE)
camkes_arm_vm_setup_arm_vm_environment()

find_package(camkes-vm-linux REQUIRED)
include(${CAMKES_VM_LINUX_HELPERS_PATH})

# Setup and install lighttpd and the docs.sel4.systems site into the vm's rootfs
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/lighttpd ${CMAKE_CURRENT_LIST_DIR}/docsite)
find_package(lighttpd REQUIRED)
find_package(docsite REQUIRED)
lighttpd_install_to_overlay(overlay)
docsite_install_to_overlay(overlay)

# Generate overlayed rootfs
set(rootfs_file "${CAMKES_VM_IMAGES_DIR}/exynos5422/rootfs.cpio.gz")
AddOverlayDirToRootfs(
    overlay
    ${rootfs_file}
    "buildroot"
    "rootfs_install"
    output_overlayed_rootfs_location
    rootfs_target
    GZIP
)

AddToFileServer("linux-initrd" ${output_overlayed_rootfs_location} DEPENDS rootfs_target)
# Updated dtb based on initrd
UpdateDtbFromInitrd(
    "${CAMKES_VM_IMAGES_DIR}/exynos5422/linux-dtb"
    ${output_overlayed_rootfs_location}
    "0x4d700000"
    dtb_gen_target
    output_dtb_location
)
AddToFileServer("linux-dtb" "${output_dtb_location}" DEPENDS dtb_gen_target)
AddToFileServer("linux" "${CAMKES_VM_IMAGES_DIR}/exynos5422/linux")
DefineCAmkESVMFileServer()

# Declare root server
DeclareCAmkESRootserver(main.camkes CPP_INCLUDES ${CAMKES_ARM_VM_DIR}/components/VM)
# Now generate the root server and the global configuration
GenerateCAmkESRootserver()
