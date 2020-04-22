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

set(LIGHTTPD_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE STRING "")
set(LIGHTTPD_CONF "${LIGHTTPD_DIR}/lighttpd.conf" CACHE STRING "")
set(LIGHTTPD_RUN_SCRIPT "${LIGHTTPD_DIR}/lighttpd.sh" CACHE STRING "")
mark_as_advanced(LIGHTTPD_DIR LIGHTTPD_CONF LIGHTTPD_RUN_SCRIPT)

macro(lighttpd_build_server outfile)
    string(REGEX MATCH "^(.+)\-$" config_host "${CROSS_COMPILER_PREFIX}" )
    set(config_host "${CMAKE_MATCH_1}")
    include(ExternalProject)
    # Static compile of pcre library
    ExternalProject_Add(
        libpcre
        URL
        https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
        BINARY_DIR
        ${CMAKE_CURRENT_BINARY_DIR}/libprce-prefix/src/libpcre
        BUILD_ALWAYS
        ON
        EXCLUDE_FROM_ALL
        SOURCE_DIR
        ${CMAKE_CURRENT_BINARY_DIR}/libprce-prefix/src/libpcre
        CONFIGURE_COMMAND
        ./configure --host=${config_host} CC=${CMAKE_C_COMPILER} AR=${CMAKE_AR} STRIP=${DCMAKE_STRIP}
        RANLIB=${CMAKE_RANLIB} --prefix=${CMAKE_CURRENT_BINARY_DIR}/libpcre/_install
        BUILD_COMMAND
        make
        INSTALL_COMMAND
        make install
    )
    # Force static linking of pthread symbols
    set(linker_flags -static\ -u\ pthread_mutex_lock\ -u\ pthread_mutex_unlock\ -lpthread)
    find_package(Git)
    ExternalProject_Add(
        lighttpd
        GIT_REPOSITORY
        https://github.com/lighttpd/lighttpd1.4.git
        GIT_SHALLOW
        TRUE
        GIT_PROGRESS
        TRUE
        GIT_TAG
        lighttpd-1.4.55
        PATCH_COMMAND
        ${GIT_EXECUTABLE} apply ${LIGHTTPD_DIR}/lighttpd_cmake.patch ${LIGHTTPD_DIR}/lemon_cmake.patch
        BINARY_DIR
        ${CMAKE_CURRENT_BINARY_DIR}/lighttpd
        BUILD_ALWAYS
        ON
        INSTALL_COMMAND
        "" # Don't run install command
        EXCLUDE_FROM_ALL
        CMAKE_ARGS
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DBUILD_STATIC=ON
        -DCMAKE_C_FLAGS=-I${LIGHTTPD_DIR}
        -DCMAKE_EXE_LINKER_FLAGS=${linker_flags}
        -DBUILD_SHARED_LIBS=OFF
        -DCMAKE_FIND_LIBRARY_SUFFIXES=".a"
        -DPCRE_CONFIG="${CMAKE_CURRENT_BINARY_DIR}/libpcre/_install/bin/pcre-config"
        -DWITH_ZLIB=0
        DEPENDS
        libpcre
    )
    include(external-project-helpers)
    DeclareExternalProjObjectFiles(
        lighttpd
        ${CMAKE_CURRENT_BINARY_DIR}/lighttpd
        FILES
        build/lighttpd
    )
    set(${outfile} ${CMAKE_CURRENT_BINARY_DIR}/lighttpd/build/lighttpd)
endmacro()

macro(lighttpd_install_to_overlay overlay)
    AddFileToOverlayDir("lighttpd.conf" ${LIGHTTPD_CONF} "etc" ${overlay})
    AddFileToOverlayDir("S91lighttpd" ${LIGHTTPD_RUN_SCRIPT} "etc/init.d" ${overlay})
    lighttpd_build_server(lighttpd_binary)
    AddFileToOverlayDir("lighttpd" ${lighttpd_binary} "bin" ${overlay})

endmacro()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(
    lighttpd
    DEFAULT_MSG
    LIGHTTPD_DIR
    LIGHTTPD_CONF
    LIGHTTPD_RUN_SCRIPT
)
