# ------------------------------------------------------------------------------
# Redshift POCs CMake Build Script
# ------------------------------------------------------------------------------

# -- CMake setup ---------------------------------------------------------------

project(redshift-pocs)
cmake_minimum_required(VERSION 3.2)

# -- Third-party dependencies: Find m4 -----------------------------------------

find_program(
  M4_BINARY m4
  PATHS usr/local/bin /usr/bin /bin /opt/local/bin
  DOC "Path to the GNU m4 preprocessor."
)

if(NOT M4_BINARY)
  message(FATAL_ERROR "Cannot find the m4 preprocessor.")
endif(NOT M4_BINARY)

# TODO: Require a specific version.
# execute_process(
#   COMMAND ${M4_BINARY} --version
#   OUTPUT_VARIABLE M4V
# )
# message(${M4V})


# -- Global definitions (filenames, paths, etc.) --------------------------------

# No need to install outside the project dir for now
# "/usr/local" is the CMake default
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(
    CMAKE_INSTALL_PREFIX "${PROJECT_SOURCE_DIR}/pocs" CACHE PATH
    "Install path prefix, prepended onto install directories." FORCE
  )
endif(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

# Set the directory for tools needed during build time
set(BUILD_TOOLS ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# Set build type
if(NOT CMAKE_BUILD_TYPE)
  set(
    CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING
    "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE
  )
endif(NOT CMAKE_BUILD_TYPE)

set(COMPONENT "" CACHE STRING "Components to build and instal. Options: client, worker. Do not specify to build all.")

# Save build time
execute_process(
  COMMAND date -u +"%Y-%m-%dT%H:%M:%SZ"
  OUTPUT_VARIABLE BUILD_TIME
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Save git revision
execute_process(
  COMMAND git describe
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE GIT_REVISION
  ERROR_QUIET
  RESULT_VARIABLE _RESULT
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(NOT _RESULT EQUAL 0)
  set(GIT_REVISION "unknown")
endif(NOT _RESULT EQUAL 0)

# force a `m4_' prefix to all builtins
set(M4_ARGUMENTS "--prefix-builtins" "-I${CMAKE_CURRENT_SOURCE_DIR}/m4")

# Read and parse VERSION.yml file
set(VERSION_YML ${CMAKE_CURRENT_SOURCE_DIR}/VERSION.yml)
file(READ "${VERSION_YML}" _VERSION_CONTENTS)
string(REGEX REPLACE "^.*version:[ \t]*([^\n]*)\n.*" "\\1" VERSION_STRING "${_VERSION_CONTENTS}")
string(REGEX REPLACE "([0-9]+).*" "\\1" VERSION_MAJOR "${VERSION_STRING}")
string(REGEX REPLACE "[0-9]+\\.([0-9]+).*" "\\1" VERSION_MINOR "${VERSION_STRING}")
if("${VERSION_STRING}" MATCHES "[0-9]+\\.[0-9]+\\.([0-9]+).*")
  string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+).*" "\\1" VERSION_PATCH "${VERSION_STRING}")
else()
  set(VERSION_PATCH 0)
endif()

set(VENDOR ${CMAKE_BINARY_DIR}/vendor)

# Scale factors to generate POCs for
set(SCALE_FACTORS 1 10 100 1000 10000)

# Username for SSH access to workers
# TODO: Make sure this is provided
set(SSH_USERNAME "" CACHE STRING "Username for SSH access to workers")

# -- Global includes ------------------------------------------------------------

list(APPEND CMAKE_MODULE_PATH "${BUILD_TOOLS}")
include(Utils)

# -- Add subdirectories --------------------------------------------------------

add_subdirectory(src)
