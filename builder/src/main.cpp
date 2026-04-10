// TabTab Builder entry point.
//
// This is a skeleton. The real implementation is tracked as BLD-001
// (core data structures) and BLD-002 (main window bootstrap).

#include <iostream>
#include <string_view>

namespace tabtab
{
constexpr std::string_view kVersion = "0.1.0";
constexpr std::string_view kBanner = R"(
  _______    _     _______    _
 |__   __|  | |   |__   __|  | |
    | | __ _| |__    | | __ _| |__
    | |/ _` | '_ \   | |/ _` | '_ \
    | | (_| | |_) |  | | (_| | |_) |
    |_|\__,_|_.__/   |_|\__,_|_.__/
)";
}  // namespace tabtab

int main(int argc, char** argv)
{
    (void)argc;
    (void)argv;

    std::cout << tabtab::kBanner << '\n';
    std::cout << "TabTab Builder v" << tabtab::kVersion << '\n';
    std::cout << "Builder not yet implemented. See docs/specs/requirements/builder.md\n";
    return 0;
}
