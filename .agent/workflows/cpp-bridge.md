# 🧱 C++ Bridge Protocol (The Native Builder)

## Objective
Maintenance and troubleshooting of the Native C++ Layer (`libsecrets.so`).

## Development Rules

1.  **Standard C++ Only**
    -   Use `std::string`, `std::vector`.
    -   Do NOT import Boost or other heavy libraries. We want a tiny `.so` file.
    -   Avoid C++20 features if targeting Android 5.0 (API 21). Stick to C++11/14.

2.  **CMake Configuration**
    -   Location: `android/app/src/main/cpp/CMakeLists.txt`.
    -   Always ensure `add_library` and `target_link_libraries` are correct.
    -   ABI Filters: `armeabi-v7a` (Old POS), `arm64-v8a` (Modern), `x86_64` (Emulator).

3.  **JNI/FFI Debugging**
    -   **UnsatisfiedLinkError**:
        -   Check if the function is `extern "C"`. Dart FFI cannot see C++ mangled names.
        -   Check `__attribute__((visibility("default")))`.
    -   **Crash (SIGSEGV)**:
        -   Usually accessing invalid memory.
        -   Check pointer allocations (`malloc`/`free`) or string conversions (`Utf8`).

4.  **Rebuild Loop**
    -   Native code doesn't "Hot Reload".
    -   **Loop**: `flutter clean` -> `flutter pub get` -> `flutter run`.
