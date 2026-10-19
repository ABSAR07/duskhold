# Build of the Duskhold native simulation extension (PLAT-01, plan 04-14).
# Entry point: tools/native_build.sh, which passes the four values below. Not meant to be run by
# hand: the script also dumps the API files from the pinned Godot binary first.
cmake_minimum_required(VERSION 3.20)

set(GODOT_CPP_DIR "" CACHE PATH "Checkout of godot-cpp at the commit in tools/godot_cpp_pin.txt")
set(DUSKHOLD_API_DIR "" CACHE PATH "Directory holding extension_api.json and gdextension_interface.json dumped from the pinned Godot binary")
set(DUSKHOLD_PIN "" CACHE STRING "The godot-cpp commit this build was made against")
set(DUSKHOLD_API_VERSION "" CACHE STRING "The Godot API version of the dumped extension_api.json")
set(DUSKHOLD_PLATFORM "" CACHE STRING "windows or linux (names the library file)")

foreach(required GODOT_CPP_DIR DUSKHOLD_API_DIR DUSKHOLD_PIN DUSKHOLD_API_VERSION DUSKHOLD_PLATFORM)
    if("${${required}}" STREQUAL "")
        message(FATAL_ERROR "${required} must be set; run tools/native_build.sh")
    endif()
endforeach()

# The static MSVC runtime, set before godot-cpp creates its targets: the shipped library then
# needs no redistributable. GCC and Clang link their runtime statically through godot-cpp.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded" CACHE STRING "" FORCE)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "" FORCE)

project(duskhold_sim LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# godot-cpp options of the port: the release template, single precision (the official 4.7.2
# binary is single precision, so real_t is 4 bytes), the API files dumped from that binary, and
# its headers exposed as system includes so they cannot trip this target's warnings.
set(GODOTCPP_TARGET "template_release" CACHE STRING "" FORCE)
set(GODOTCPP_PRECISION "single" CACHE STRING "" FORCE)
set(GODOTCPP_CUSTOM_API_FILE "${DUSKHOLD_API_DIR}/extension_api.json" CACHE FILEPATH "" FORCE)
set(GODOTCPP_GDEXTENSION_DIR "${DUSKHOLD_API_DIR}" CACHE PATH "" FORCE)
set(GODOTCPP_SYSTEM_HEADERS ON CACHE BOOL "" FORCE)
set(GODOTCPP_USE_STATIC_CPP ON CACHE BOOL "" FORCE)

add_subdirectory("${GODOT_CPP_DIR}" "${CMAKE_BINARY_DIR}/godot-cpp")

file(GLOB DUSKHOLD_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

add_library(duskhold_sim SHARED ${DUSKHOLD_SOURCES})
target_link_libraries(duskhold_sim PRIVATE godot-cpp)

set_target_properties(duskhold_sim PROPERTIES
    CXX_STANDARD 17
    CXX_EXTENSIONS OFF
    POSITION_INDEPENDENT_CODE ON
    PREFIX ""
    OUTPUT_NAME "libduskhold_sim.${DUSKHOLD_PLATFORM}.x86_64"
    LIBRARY_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}/out>"
    RUNTIME_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}/out>"
)

# The replay digests depend on every float operation rounding once and in the written order
# (diagnosis: a native step must reproduce the engine's x86-64 results bit for bit): the precise
# floating-point model, no fused multiply-add contraction, no fast math, no AVX and no
# host-tuned code. These options are on this target only; godot-cpp keeps its own.
target_compile_options(duskhold_sim PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/fp:precise /W4 /WX /permissive- /external:W0>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-ffp-contract=off -fno-fast-math -Wall -Wextra -Werror>
)

target_compile_definitions(duskhold_sim PRIVATE
    DUSKHOLD_GODOT_CPP_PIN="${DUSKHOLD_PIN}"
    DUSKHOLD_API_VERSION="${DUSKHOLD_API_VERSION}"
)
