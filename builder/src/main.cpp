// TabTab Builder entry point.
//
// This is a skeleton. The real implementation is tracked as BLD-001
// (core data structures) and BLD-002 (main window bootstrap).

#include <cstdio>
#include <exception>
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

int main(int argc, char** argv) {
    (void)argc;
    (void)argv;

    // `std::cout <<` can theoretically throw `std::ios_base::failure`. The
    // `bugprone-exception-escape` check (and the coding standards: no
    // exceptions out of `main`) require the top-level entry point to swallow
    // anything before unwinding the runtime. Error reporting in the catch
    // handlers uses C `stdio` (`std::fputs`/`std::fprintf`) because those are
    // `noexcept` — `std::cerr <<` would re-trigger the same check.
    try {
        std::cout << tabtab::kBanner << '\n';
        std::cout << "TabTab Builder v" << tabtab::kVersion << '\n';
        std::cout << "Builder not yet implemented. See docs/specs/requirements/builder.md\n";
    } catch (const std::exception& ex) {
        std::fprintf(stderr, "fatal: %s\n", ex.what());
        return 1;
    } catch (...) {
        std::fputs("fatal: unknown exception\n", stderr);
        return 1;
    }
    return 0;
}
