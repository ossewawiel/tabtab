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
# clang-format / clang-tidy targets (stubs; wired up in INF-002 / INF-006)
# ----------------------------------------------------------------------

add_custom_target(clang-format
    COMMAND ${CMAKE_COMMAND} -E echo "clang-format target not yet wired (see INF-002)"
)

add_custom_target(clang-tidy
    COMMAND ${CMAKE_COMMAND} -E echo "clang-tidy target not yet wired (see INF-006)"
)
