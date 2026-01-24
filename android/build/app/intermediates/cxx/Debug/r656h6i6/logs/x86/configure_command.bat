@echo off
"C:\\Users\\MyBook Hype AMD\\AppData\\Local\\Android\\sdk\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HR:\\Project\\Overwatch Mobile\\overwatch_mobile\\android\\app\\src\\main\\cpp" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=21" ^
  "-DANDROID_PLATFORM=android-21" ^
  "-DANDROID_ABI=x86" ^
  "-DCMAKE_ANDROID_ARCH_ABI=x86" ^
  "-DANDROID_NDK=C:\\Users\\MyBook Hype AMD\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_ANDROID_NDK=C:\\Users\\MyBook Hype AMD\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_TOOLCHAIN_FILE=C:\\Users\\MyBook Hype AMD\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=C:\\Users\\MyBook Hype AMD\\AppData\\Local\\Android\\sdk\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=R:\\Project\\Overwatch Mobile\\overwatch_mobile\\android\\build\\app\\intermediates\\cxx\\Debug\\r656h6i6\\obj\\x86" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=R:\\Project\\Overwatch Mobile\\overwatch_mobile\\android\\build\\app\\intermediates\\cxx\\Debug\\r656h6i6\\obj\\x86" ^
  "-DCMAKE_BUILD_TYPE=Debug" ^
  "-BR:\\Project\\Overwatch Mobile\\overwatch_mobile\\android\\app\\.cxx\\Debug\\r656h6i6\\x86" ^
  -GNinja ^
  -Wno-dev ^
  --no-warn-unused-cli
