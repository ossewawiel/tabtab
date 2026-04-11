// Smoke test — proves the test harness compiles and runs.
// Replaced by real tests as stories land.

#include <gtest/gtest.h>

TEST(Smoke, gtestIsWiredCorrectly_passesTrivially) {
    EXPECT_EQ(2 + 2, 4);
}
