# Copyright (c) 2018 Intel Corporation

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#cmake_minimum_required (VERSION 2.8)

# project(face_detection_tutorial)

#set( CMAKE_SOURCE_DIR /home/mandip/Intel_Workspace/Kiosk/kiosk/final/interactive_face_detection_sample) 

# environment variable InferenceEngine_DIR is used to find CMake files in installation 
# point to common pieces in Inference Engine's samples directory

if("$ENV{InferenceEngine_DIR}" STREQUAL "")
    message(FATAL_ERROR "Environment variable 'InferenceEngine_DIR' is not defined.  Before running CMake, please be sure to source the setupvars.sh in the OpenVINO installation directory using the command:\n\tsource /opt/intel/computer_vision_sdk/bin/setupvars.sh\n")
endif()

message(STATUS "InferenceEngine_DIR=$ENV{InferenceEngine_DIR}")
set(InferenceEngine_Samples_DIR "$ENV{InferenceEngine_DIR}/../samples" )

list (APPEND CMAKE_MODULE_PATH ${InferenceEngine_Samples_DIR}/cmake)
message(STATUS "CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")

get_filename_component(CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/../share" ABSOLUTE)

message(STATUS "Looking for inference engine configuration file at: ${CMAKE_PREFIX_PATH}")
if (IE_NOT_FOUND_MESSAGE)
    find_package(InferenceEngine 1.5 QUIET)
    if (NOT(InferenceEngine_FOUND))
        message(FATAL_ERROR ${IE_NOT_FOUND_MESSAGE})
    endif()
else()
    find_package(InferenceEngine 1.5 REQUIRED)
endif()

if("${CMAKE_BUILD_TYPE}" STREQUAL "")
    message(STATUS "CMAKE_BUILD_TYPE not defined, 'Release' will be used")
    set(CMAKE_BUILD_TYPE "Release")
endif()

if (NOT(BIN_FOLDER))
    if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
        set (ARCH intel64)
    else()
        set (ARCH ia32)
    endif()

    set (BIN_FOLDER ${ARCH})
endif()

if (NOT (IE_MAIN_SOURCE_DIR))
    set(NEED_EXTENSIONS TRUE)
    if (WIN32)
        set (IE_MAIN_SOURCE_DIR ${CMAKE_SOURCE_DIR}/../bin/)
    else()
        set (IE_MAIN_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR})
        message("Cmake source directory" ${CMAKE_CURRENT_BINARY_DIR})
    endif()
endif()

if(NOT(UNIX))
    set (CMAKE_LIBRARY_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER})
    set (CMAKE_LIBRARY_PATH ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER})
    set (CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER})
    set (CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER})
    set (CMAKE_PDB_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER})
    set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER})
    set (LIBRARY_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER})
    set (LIBRARY_OUTPUT_PATH ${LIBRARY_OUTPUT_DIRECTORY}) # compatibility issue: linux uses LIBRARY_OUTPUT_PATH, windows uses LIBRARY_OUTPUT_DIRECTORY
else ()
    set (CMAKE_LIBRARY_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER}/${CMAKE_BUILD_TYPE}/lib)
    set (CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER}/${CMAKE_BUILD_TYPE}/lib)
    set (CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER}/${CMAKE_BUILD_TYPE})
    set (CMAKE_PDB_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER}/${CMAKE_BUILD_TYPE})
    set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER}/${CMAKE_BUILD_TYPE})
    set (LIBRARY_OUTPUT_DIRECTORY ${IE_MAIN_SOURCE_DIR}/${BIN_FOLDER}/${CMAKE_BUILD_TYPE}/lib)
    set (LIBRARY_OUTPUT_PATH ${LIBRARY_OUTPUT_DIRECTORY}/lib)
endif()


set(CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS} " )
if (WIN32)
    if(NOT "${CMAKE_GENERATOR}" MATCHES "(Win64|IA64)")
        message(FATAL_ERROR "Only 64-bit supported on Windows")
    endif()

    # set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS _CRT_SECURE_NO_WARNINGS)
    # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_SCL_SECURE_NO_WARNINGS -DNOMINMAX")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /EHsc") #no asynchronous structured exception handling
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /LARGEADDRESSAWARE")
    if (ENABLE_OMP)
        find_package(OpenMP)
        if (OPENMP_FOUND)
            set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
            set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
        endif()
    endif()
else()
    # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror -Werror=return-type ")
    if (APPLE)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=unused-command-line-argument")
    elseif(UNIX)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wuninitialized -Winit-self -Wmaybe-uninitialized -g -ggdb")
    endif()
endif()

include(feature_defs OPTIONAL)

# Find OpenCV libray if exists
find_package(OpenCV)
include_directories(${OpenCV_INCLUDE_DIRS})
if(OpenCV_FOUND)
    add_definitions(-DUSE_OPENCV)
endif()

####################################
## to use C++11
set (CMAKE_CXX_STANDARD 11)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS}")
####################################

# Make sure dependencies are present
set(IE_SAMPLES_GFLAGS_DIR "${InferenceEngine_Samples_DIR}/thirdparty/gflags")
set(IE_SAMPLES_FORMAT_READER_DIR "${InferenceEngine_Samples_DIR}/common/format_reader")

if(NOT EXISTS "${IE_SAMPLES_GFLAGS_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "The required 'gflags' library was not found in the Inference Engine's samples at: ${IE_SAMPLES_GFLAGS_DIR}")
endif()
if(NOT EXISTS "${IE_SAMPLES_FORMAT_READER_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "The required 'format_reader' library was not found in the Inference Engine's samples at: ${IE_SAMPLES_GFLAGS_DIR}")
endif()

# Properties->C/C++->General->Additional Include Directories
include_directories (
    ${InferenceEngine_Samples_DIR}/common/format_reader
    ${InferenceEngine_Samples_DIR}
    ${InferenceEngine_Samples_DIR}/../include
    ${InferenceEngine_Samples_DIR}/thirdparty/gflags/include
    ${InferenceEngine_Samples_DIR}/common
)

set(GFLAGS_IS_SUBPROJECT TRUE)
add_subdirectory(${IE_SAMPLES_GFLAGS_DIR} ${CMAKE_CURRENT_BINARY_DIR}/gflags)
add_subdirectory(${IE_SAMPLES_FORMAT_READER_DIR} ${CMAKE_CURRENT_BINARY_DIR}/format_reader)

if (UNIX)
    SET(LIB_DL dl)
endif()

