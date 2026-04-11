# Strip @*.modmap response-file references from compile_commands.json.
#
# Workaround for a CMake + Ninja + Clang 21 issue: even with
# CMAKE_CXX_SCAN_FOR_MODULES set to OFF, the compile commands emitted into
# compile_commands.json still contain `@<dir>/<obj>.obj.modmap` response-file
# tokens. clang-tidy reads the database, tries to expand the response file,
# and fails with `no such file or directory` because the modmap files were
# never written to disk (module scanning is off).
#
# This script post-processes the database in place, deleting just the
# `@*.modmap` tokens. The result is a compile DB clang-tidy can consume.
# On platforms where the issue doesn't occur (Linux + GCC + Ninja, for
# example), the regex matches nothing and the file is rewritten unchanged.
#
# Invoked by the `clang-tidy` custom target as a pre-step. Safe to run on
# every invocation — the cost is a single read+write of a small JSON file.
#
# Required:
#   -DDB=<absolute path to compile_commands.json>

if(NOT DEFINED DB)
    message(FATAL_ERROR "strip-modmap.cmake: DB variable not set")
endif()

if(NOT EXISTS "${DB}")
    message(FATAL_ERROR "strip-modmap.cmake: ${DB} does not exist")
endif()

file(READ "${DB}" _db_content)
string(REGEX REPLACE "@[^ ]+\\.modmap" "" _db_stripped "${_db_content}")
file(WRITE "${DB}" "${_db_stripped}")
