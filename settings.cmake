#
# Copyright 2019, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

cmake_minimum_required(VERSION 3.7.2)

set(project_dir "${CMAKE_CURRENT_LIST_DIR}/../../")
set(SEL4_CONFIG_DEFAULT_ADVANCED ON)
set(supported "exynos5422;qemu-arm-virt;odroidc2;tx2")

file(GLOB project_modules ${project_dir}/projects/*)
list(
    APPEND
        CMAKE_MODULE_PATH
        ${project_dir}/kernel
        ${project_dir}/tools/seL4/cmake-tool/helpers/
        ${project_dir}/tools/seL4/elfloader-tool/
        ${project_modules}
)

include(application_settings)

if("${PLATFORM}" STREQUAL "")
    set(PLATFORM "exynos5422")
endif()
if(NOT "${PLATFORM}" IN_LIST supported)
    message(FATAL_ERROR "PLATFORM: ${PLATFORM} not supported. Supported: ${supported}")
endif()
if("${PLATFORM}" STREQUAL "exynos5422")
    set(KernelPlatform exynos5 CACHE STRING "" FORCE)
    set(KernelARMPlatform exynos5422 CACHE STRING "" FORCE)
    # Due to historic reasons, on ARMv7/AARCH32 hypervisor support is not
    # enabled by setting KernelArmHypervisorSupport, but a special architecture
    # 'arm_hyp' must be selected.
    set(KernelSel4Arch "arm_hyp" CACHE STRING "" FORCE)
endif()
if("${PLATFORM}" STREQUAL "qemu-arm-virt")
    if(MULTI_VM_LAN)
        message(
            FATAL_ERROR "The Multi-VM configuration is not supported on the qemu-arm-virt platform"
        )
    endif()
    set(KernelPlatform qemu-arm-virt CACHE STRING "" FORCE)
    set(QEMU_MEMORY "2048")
    set(
        qemu_sim_extra_args
        "-netdev tap,id=mynet0,ifname=tap0,script=no,downscript=no -device virtio-net,netdev=mynet0,mac=52:55:00:d1:55:01"
    )
    # For QEMU, setting KernelArmCPU implicitly selects AARCH32/AARCH64 also.
    # For AARCH64, enabling KernelArmHypervisorSupport activates hypervisor
    # support. On AARCH32, due to historic reasons, hypervisor support is
    # enabled by selecting a special kernel architecture:
    #    set(KernelSel4Arch "arm_hyp" CACHE STRING "" FORCE)
    set(KernelArmCPU cortex-a53 CACHE STRING "" FORCE)
    set(KernelArmHypervisorSupport ON CACHE BOOL "" FORCE)
endif()
if("${PLATFORM}" STREQUAL "odroidc2")
    set(KernelPlatform odroidc2 CACHE STRING "" FORCE)
    set(KernelArmHypervisorSupport ON CACHE BOOL "" FORCE)
    set(VmDtbFile ON CACHE BOOL "" FORCE)
endif()
if("${PLATFORM}" STREQUAL "tx2")
    set(KernelPlatform tx2 CACHE STRING "" FORCE)
    set(KernelArmHypervisorSupport ON CACHE BOOL "" FORCE)
    set(VmVirtioNet ON CACHE BOOL "" FORCE)
    set(VmDtbFile ON CACHE BOOL "" FORCE)
endif()
set(KernelRootCNodeSizeBits 18 CACHE STRING "" FORCE)
set(KernelArmVtimerUpdateVOffset OFF CACHE BOOL "" FORCE)
set(KernelArmDisableWFIWFETraps ON CACHE BOOL "" FORCE)
set(VmPCISupport ON CACHE BOOL "" FORCE)
if(MULTI_VM_LAN)
    set(VmVirtioConsole ON CACHE BOOL "" FORCE)
    set(VmVirtioNetVirtqueue ON CACHE BOOL "" FORCE)
endif()
set(VmInitRdFile ON CACHE BOOL "" FORCE)

# CAmkES Settings
set(CAmkESCPP ON CACHE BOOL "" FORCE)

# capDL settings
set(CapDLLoaderMaxObjects 90000 CACHE STRING "" FORCE)
set(LibUSB OFF CACHE BOOL "" FORCE)

find_package(seL4 REQUIRED)
sel4_configure_platform_settings()

# Set up elfloader settings for our platform
ApplyData61ElfLoaderSettings(${KernelARMPlatform} ${KernelSel4Arch})

# Release settings
ApplyCommonReleaseVerificationSettings(FALSE FALSE)
