# TabTab Builder — tests.
#
# Skeleton. Real tests arrive with BLD-001 et al. The smoke test below
# proves the Google Test wiring is correct.

add_executable(tabtab_tests
    test_smoke.cpp
)

target_include_directories(tabtab_tests
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(tabtab_tests
    PRIVATE
        GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(tabtab_tests)
