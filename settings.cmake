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

cmake_minimum_required(VERSION 3.7.2)

set(project_dir "${CMAKE_CURRENT_LIST_DIR}/../../")
set(SEL4_CONFIG_DEFAULT_ADVANCED ON)
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

set(KernelPlatform exynos5 CACHE STRING "" FORCE)
set(KernelARMPlatform exynos5422 CACHE STRING "" FORCE)
set(KernelSel4Arch "arm_hyp" CACHE STRING "" FORCE)
set(KernelRootCNodeSizeBits 18 CACHE STRING "" FORCE)
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
