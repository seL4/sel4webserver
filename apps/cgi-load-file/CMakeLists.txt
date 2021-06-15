#
# Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#

cmake_minimum_required(VERSION 3.8.2)

project(cgi-load-file C)
set(CMAKE_C_STANDARD 11)

add_executable(cgi-load-file cgi-load-file.c)
target_link_libraries(cgi-load-file -static-libgcc -static)
