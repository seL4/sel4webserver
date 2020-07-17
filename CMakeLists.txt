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
include(settings.cmake)

project(sel4webserver C ASM)


find_package(camkes-arm-vm REQUIRED)
camkes_arm_vm_setup_arm_vm_environment()

find_package(camkes-vm-linux REQUIRED)
include(${CAMKES_VM_LINUX_HELPERS_PATH})
include(${CAMKES_VM_LINUX_MODULE_HELPERS_PATH})
include(${CAMKES_VM_LINUX_SOURCE_HELPERS_PATH})

# Setup and install lighttpd and the docs.sel4.systems site into the vm's rootfs
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/lighttpd ${CMAKE_CURRENT_LIST_DIR}/docsite)
find_package(lighttpd REQUIRED)
find_package(docsite REQUIRED)

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
elseif("${PLATFORM}" STREQUAL "odroidc2")
    set(cpp_flags "-DKERNELARMPLATFORM_ODROIDC2")
    set(CAMKES_ROOT_DTB_FILE_PATH "${CAMKES_VM_IMAGES_DIR}/odroidc2/camkes-linux-dtb" CACHE STRING "")
    AddToFileServer("linux-dtb" "${CAMKES_VM_IMAGES_DIR}/odroidc2/linux_crossvm-dtb")
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

    # Build crossvm kernel module for qemu
    if("${KernelARMPlatform}" STREQUAL "qemu-arm-virt")
        include(ExternalProject)
        include(external-project-helpers)
        set(cpp_flags "-DKERNELARMPLATFORM_QEMU-ARM-VIRT")
        set(linux_repo "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git")
        set(linux_tag "v4.9.189")
        set(linux_arch "arm64")
        set(linux_cross_compile "aarch64-linux-gnu-")
        set(rootfs_file "${CAMKES_VM_IMAGES_DIR}/${KernelARMPlatform}/rootfs.cpio.gz")
        # Checkout and configure linux to build crossvm module
        ExternalProject_Add(
            checkout_linux
            GIT_REPOSITORY
            ${linux_repo}
            GIT_TAG
            ${linux_tag}
            GIT_SHALLOW
            1
            GIT_PROGRESS
            1
            BUILD_COMMAND
            ""
            INSTALL_COMMAND
            ""
            CONFIGURE_COMMAND
            ""
            SOURCE_DIR
            ${CMAKE_CURRENT_BINARY_DIR}/linux_out
        )
        # Linux config and symvers are to be copied to unpacked archive
        set(linux_config "${CAMKES_VM_IMAGES_DIR}/${KernelARMPlatform}/linux_configs/config")
        set(linux_symvers "${CAMKES_VM_IMAGES_DIR}/${KernelARMPlatform}/linux_configs/Module.symvers")
        # Configure unpacked archive with config and symvers
        ConfigureLinux(
            ${CMAKE_CURRENT_BINARY_DIR}/linux_out
            ${linux_config}
            ${linux_symvers}
            configure_vm_linux
            ARCH
            ${linux_arch}
            CROSS_COMPILE
            ${linux_cross_compile}
            DEPENDS
            checkout_linux
        )

        # Compile CrossVM Dataport Module
        DefineLinuxModule(
            ${CAMKES_VM_LINUX_DIR}/camkes-linux-artifacts/camkes-linux-modules/camkes-connector-modules/connection
            output_module
            output_module_target
            KERNEL_DIR
            ${CMAKE_CURRENT_BINARY_DIR}/linux_out
            ARCH
            ${linux_arch}
            CROSS_COMPILE
            ${linux_cross_compile}
            DEPENDS
            checkout_linux
            configure_vm_linux
        )
        AddFileToOverlayDir(
            "connection.ko"
            ${output_module}
            "lib/modules/4.14.87/kernel/drivers/vmm"
            overlay
            DEPENDS
            output_module_target
        )
        # Add script to initialise dataport module
        AddFileToOverlayDir(
            "S90crossvm_module_init"
            ${CMAKE_CURRENT_SOURCE_DIR}/overlay_files/cross_vm_module_init
            "etc/init.d"
            overlay
        )
    else()
        # User pre-configured rootfs file with crossvm modules and apps installed
        set(rootfs_file "${CAMKES_VM_IMAGES_DIR}/${KernelARMPlatform}/rootfs_crossvm.cpio.gz")
    endif()
    lighttpd_install_to_overlay(overlay)
    docsite_install_to_overlay(overlay)
    foreach(item IN ITEMS cgi-load-file)
        ExternalProject_Add(
            ${item}
            SOURCE_DIR
            ${CMAKE_CURRENT_SOURCE_DIR}/apps/${item}
            BINARY_DIR
            ${CMAKE_CURRENT_BINARY_DIR}/${item}
            INSTALL_COMMAND
            ""
            BUILD_ALWAYS
            ON
            EXCLUDE_FROM_ALL
            CMAKE_ARGS
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_C_FLAGS=${BASE_C_FLAGS}
        )

        AddExternalProjFilesToOverlay(
            ${item}
            ${CMAKE_CURRENT_BINARY_DIR}/${item}
            overlay
            "usr/bin"
            FILES
            ${item}
        )
    endforeach()


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


# Define our demo component that shares a dataport with the VM
include(cpio)
MakeCPIO(secure_file_archive.o ${CMAKE_CURRENT_SOURCE_DIR}/secure_file.html)
DeclareCAmkESComponent(LoggingFileserver SOURCES components/logging-fileserver/fileserver.c secure_file_archive.o)

# Define our VM Component with out cross vm dataports glue code
DeclareCAmkESComponent(VM SOURCES src/cross_vm_connections.c)

# Declare root server
if(MULTI_VM_LAN)
    DeclareCAmkESRootserver(multi_main.camkes CPP_INCLUDES ${CAMKES_ARM_VM_DIR}/components/VM)
else()
    DeclareCAmkESRootserver(main.camkes CPP_INCLUDES ${CAMKES_ARM_VM_DIR}/components/VM)
endif()
# Now generate the root server and the global configuration
GenerateCAmkESRootserver()
