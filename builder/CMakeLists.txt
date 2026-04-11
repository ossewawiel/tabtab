# TabTab Builder — C++ entry-point CMakeLists.
#
# This is a SKELETON. The full build is tracked as story INF-005 (wire Skia)
# and BLD-001 (core data structures). For now we compile a minimal hello-world
# so the CI path works end-to-end.

cmake_minimum_required(VERSION 3.28)

project(tabtab
    VERSION 0.1.0
    DESCRIPTION "Visual UI builder for Compose Multiplatform"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Always emit a compile_commands.json so clang-tidy (and clangd, IDEs, ...) can
# pick up the real per-translation-unit flags. Required by INF-002. Honored by
# Ninja and Makefile generators; the Visual Studio generator silently ignores
# it (see docs/specs/features/infra-bootstrap/implementation-plan.md §Risks).
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Disable C++20 module dependency scanning. We don't use modules anywhere in
# the builder, and CMake's scanner emits `.modmap` response-file references
# into the compile database that clang-tidy can't resolve, causing every
# translation unit to fail with `no such file or directory: '@...obj.modmap'`.
# Re-enable per-target with `set_target_properties(... CXX_SCAN_FOR_MODULES ON)`
# if a future subsystem actually uses modules.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

# ----------------------------------------------------------------------
# Build options
# ----------------------------------------------------------------------

option(TABTAB_BUILD_TESTS "Build unit tests" ON)
option(TABTAB_ENABLE_COVERAGE "Enable code coverage instrumentation" OFF)
option(TABTAB_ENABLE_ASAN "Enable AddressSanitizer" OFF)

if(TABTAB_ENABLE_COVERAGE)
    add_compile_options(--coverage)
    add_link_options(--coverage)
endif()

if(TABTAB_ENABLE_ASAN)
    add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
    add_link_options(-fsanitize=address)
endif()

# ----------------------------------------------------------------------
# Warnings (stay noisy, catch bugs early)
# ----------------------------------------------------------------------

if(MSVC)
    add_compile_options(/W4 /permissive-)
else()
    add_compile_options(
        -Wall -Wextra -Wpedantic
        -Wshadow -Wnon-virtual-dtor -Wold-style-cast
        -Wcast-align -Wunused -Woverloaded-virtual
        -Wconversion -Wsign-conversion
        -Wnull-dereference -Wdouble-promotion
        -Wformat=2
    )
endif()

# ----------------------------------------------------------------------
# Third-party dependencies
# ----------------------------------------------------------------------

# Skia is fetched by scripts/fetch-skia.sh and will be wired up in INF-005.
# For now we just check that the third_party directory exists.
set(TABTAB_SKIA_DIR "${CMAKE_SOURCE_DIR}/third_party/skia")
if(EXISTS "${TABTAB_SKIA_DIR}/include/core/SkCanvas.h")
    message(STATUS "Skia: found at ${TABTAB_SKIA_DIR}")
    set(TABTAB_HAS_SKIA ON)
else()
    message(WARNING "Skia: not found at ${TABTAB_SKIA_DIR}. Run scripts/fetch-skia.sh. Builder will compile without Skia support.")
    set(TABTAB_HAS_SKIA OFF)
endif()

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------

add_executable(tabtab
    src/main.cpp
)

target_include_directories(tabtab
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# ----------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------

if(TABTAB_BUILD_TESTS)
    enable_testing()

    include(FetchContent)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG v1.15.2
    )
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)

    add_subdirectory(tests)
endif()

# ----------------------------------------------------------------------
# clang-format targets (INF-001)
#
# Authoritative config: repo-root `.clang-format`.
# Run `cmake --build build --target clang-format` to rewrite sources in place.
# Run `cmake --build build --target clang-format-check` for a dry-run that
# exits non-zero on drift — this is what CI uses.
# ----------------------------------------------------------------------

find_program(TABTAB_CLANG_FORMAT_EXECUTABLE NAMES clang-format)
if(NOT TABTAB_CLANG_FORMAT_EXECUTABLE)
    message(FATAL_ERROR
        "clang-format not found on PATH. Install LLVM (https://releases.llvm.org) "
        "— on Debian/Ubuntu: `apt-get install clang-format`; on macOS: "
        "`brew install clang-format`; on Windows: the LLVM installer. "
        "The `clang-format` and `clang-format-check` CMake targets require it."
    )
endif()
message(STATUS "clang-format: ${TABTAB_CLANG_FORMAT_EXECUTABLE}")

file(GLOB_RECURSE TABTAB_CXX_SOURCES
    CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp"
)

add_custom_target(clang-format
    COMMAND ${TABTAB_CLANG_FORMAT_EXECUTABLE} -i ${TABTAB_CXX_SOURCES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "clang-format -i on all builder C++ sources"
    VERBATIM
)

add_custom_target(clang-format-check
    COMMAND ${TABTAB_CLANG_FORMAT_EXECUTABLE} --dry-run --Werror ${TABTAB_CXX_SOURCES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "clang-format --dry-run --Werror on all builder C++ sources"
    VERBATIM
)

# ----------------------------------------------------------------------
# clang-tidy target (INF-002)
#
# Authoritative config: repo-root `.clang-tidy`.
# Runs against the compile database in `build/` (see CMAKE_EXPORT_COMPILE_COMMANDS
# above). `WarningsAsErrors: '*'` in the .clang-tidy makes any diagnostic a
# build failure — this is the same gate CI enforces.
#
# Pre-step: cmake/strip-modmap.cmake removes `@*.modmap` response-file refs
# from compile_commands.json. Required because Clang 21 + Ninja still emits
# those tokens even when CMAKE_CXX_SCAN_FOR_MODULES is OFF, and clang-tidy
# then fails to expand the (non-existent) response files. The strip is a
# no-op on platforms where the issue doesn't occur (e.g. Linux + GCC).
#
# Local Windows builds with the Visual Studio generator do not produce a
# compile_commands.json, so this target is best-effort there. CI uses Ninja.
# ----------------------------------------------------------------------

find_program(TABTAB_CLANG_TIDY_EXECUTABLE NAMES clang-tidy)
if(NOT TABTAB_CLANG_TIDY_EXECUTABLE)
    message(FATAL_ERROR
        "clang-tidy not found on PATH. Install LLVM (https://releases.llvm.org) "
        "— on Debian/Ubuntu: `apt-get install clang-tidy`; on macOS: "
        "`brew install llvm`; on Windows: the LLVM installer. "
        "The `clang-tidy` CMake target requires it."
    )
endif()
message(STATUS "clang-tidy: ${TABTAB_CLANG_TIDY_EXECUTABLE}")

add_custom_target(clang-tidy
    COMMAND ${CMAKE_COMMAND}
        -DDB=${CMAKE_BINARY_DIR}/compile_commands.json
        -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/strip-modmap.cmake
    COMMAND ${TABTAB_CLANG_TIDY_EXECUTABLE}
        -p ${CMAKE_BINARY_DIR}
        --quiet
        ${TABTAB_CXX_SOURCES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "clang-tidy on all builder C++ sources (compile DB: ${CMAKE_BINARY_DIR})"
    VERBATIM
)
