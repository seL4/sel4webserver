#
# Copyright 2019, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

set(DOCSITE_DIR
    "${CMAKE_CURRENT_LIST_DIR}"
    CACHE STRING ""
)
set(DOCSITE_RUN_SCRIPT
    "${DOCSITE_DIR}/unpack_site.sh"
    CACHE STRING ""
)
mark_as_advanced(DOCSITE_DIR DOCSITE_RUN_SCRIPT)

macro(docsite_build_site_tar outfile)
    include(ExternalProject)
    ExternalProject_Add(
        docsite
        GIT_REPOSITORY https://github.com/seL4/docs.git
        GIT_TAG gh-pages
        GIT_SHALLOW TRUE
        GIT_PROGRESS TRUE
        CONFIGURE_COMMAND "" # Don't run configure command
        BUILD_ALWAYS ON
        BUILD_IN_SOURCE TRUE
        USES_TERMINAL_BUILD TRUE
        BUILD_COMMAND "" # Nothing to build, gh-pages contains pre-built site
        INSTALL_COMMAND "rm;-rf;Hardware/CEI_TK1_SOM/"
        COMMAND "tar;-cvzf;../site.tar.gz;-C;..;docsite"
        COMMAND "mv;../site.tar.gz;${CMAKE_CURRENT_BINARY_DIR}"
        EXCLUDE_FROM_ALL
    )
    include(external-project-helpers)
    DeclareExternalProjObjectFiles(docsite ${CMAKE_CURRENT_BINARY_DIR} FILES site.tar.gz)
    set(${outfile} ${CMAKE_CURRENT_BINARY_DIR}/site.tar.gz)
endmacro()

macro(docsite_install_to_overlay overlay)

    AddFileToOverlayDir("S90unpack_site" ${DOCSITE_RUN_SCRIPT} "etc/init.d" ${overlay})
    docsite_build_site_tar(site_tar)
    AddFileToOverlayDir("site.tar.gz" ${site_tar} "var" ${overlay})

endmacro()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(docsite DEFAULT_MSG DOCSITE_DIR DOCSITE_RUN_SCRIPT)
