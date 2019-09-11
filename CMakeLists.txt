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

set(rootfs_file "${CAMKES_VM_IMAGES_DIR}/exynos5422/rootfs.cpio.gz")
AddToFileServer("linux-initrd" ${rootfs_file})
# Updated dtb based on initrd
UpdateDtbFromInitrd(
    "${CAMKES_VM_IMAGES_DIR}/exynos5422/linux-dtb"
    ${rootfs_file}
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
