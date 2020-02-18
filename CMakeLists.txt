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

find_package(camkes-arm-vm REQUIRED)
camkes_arm_vm_setup_arm_vm_environment()

find_package(camkes-vm-linux REQUIRED)
include(${CAMKES_VM_LINUX_HELPERS_PATH})

# Setup and install lighttpd and the docs.sel4.systems site into the vm's rootfs
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/lighttpd ${CMAKE_CURRENT_LIST_DIR}/docsite)
find_package(lighttpd REQUIRED)
find_package(docsite REQUIRED)

set(VmInitRdFile ON CACHE BOOL "" FORCE)

if("${PLATFORM}" STREQUAL "exynos5422")
    set(cpp_flags "-DKERNELARMPLATFORM_EXYNOS5422")
    set(rootfs_file "${CAMKES_VM_IMAGES_DIR}/exynos5422/rootfs.cpio.gz")
elseif("${PLATFORM}" STREQUAL "qemu-arm-virt")
    set(cpp_flags "-DKERNELARMPLATFORM_QEMU-ARM-VIRT")
    set(rootfs_file "${CAMKES_VM_IMAGES_DIR}/qemu-arm-virt/rootfs.cpio.gz")
    include(simulation)
    set(SIMULATION ON CACHE BOOL "Generate simulation script to run qemu with the proper arguments")
    if(SIMULATION)
        GenerateSimulateScript()
    endif()
endif()

if(MULTI_VM_LAN)
    # Setup our passthrough vm overlay
    AddFileToOverlayDir("inittab" ${CMAKE_CURRENT_SOURCE_DIR}/overlay_files/inittab_hvc0 "etc" overlay_vm0)
    AddFileToOverlayDir("S90bridge_setup" ${CMAKE_CURRENT_SOURCE_DIR}/overlay_files/vm0_bridge_setup.sh "etc/init.d" overlay_vm0)
    AddOverlayDirToRootfs(overlay_vm0 ${rootfs_file} "buildroot" "rootfs_install"
                          vm0_output_overlayed_rootfs_location rootfs_target_vm0
                          GZIP)
    # Setup our client vm overlays
    AddFileToOverlayDir("inittab" ${CMAKE_CURRENT_SOURCE_DIR}/overlay_files/inittab_hvc0 "etc" overlay_client_vm)
    lighttpd_install_to_overlay(overlay_client_vm)
    docsite_install_to_overlay(overlay_client_vm)
    AddOverlayDirToRootfs(overlay_client_vm ${rootfs_file} "buildroot" "rootfs_install"
                          client_output_overlayed_rootfs_location rootfs_target_client_vm
                          GZIP)
    AddToFileServer("linux-initrd-vm0" "${vm0_output_overlayed_rootfs_location}" DEPENDS rootfs_target_vm0)
    AddToFileServer("linux-initrd-vm-client" "${client_output_overlayed_rootfs_location}" DEPENDS rootfs_target_client_vm)
else()
    lighttpd_install_to_overlay(overlay)
    docsite_install_to_overlay(overlay)
    # Generate overlayed rootfs
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
endif()

AddToFileServer("linux" "${CAMKES_VM_IMAGES_DIR}/${KernelARMPlatform}/linux")
DefineCAmkESVMFileServer()

CAmkESAddImportPath(${KernelARMPlatform})

# Declare root server
if(MULTI_VM_LAN)
    DeclareCAmkESRootserver(multi_main.camkes CPP_INCLUDES ${CAMKES_ARM_VM_DIR}/components/VM)
else()
    DeclareCAmkESRootserver(main.camkes CPP_INCLUDES ${CAMKES_ARM_VM_DIR}/components/VM)
endif()
# Now generate the root server and the global configuration
GenerateCAmkESRootserver()
