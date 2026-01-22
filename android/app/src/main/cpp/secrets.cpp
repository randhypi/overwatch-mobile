#include <stdint.h>

extern "C" __attribute__((visibility("default"))) __attribute__((used))
const char* get_api_secret() {
    // Obfuscated: "MTkzZGQwZmYyNjVhYTgzMGEwZTcyODQ1NzhjYTkwY2U="
    // In production, split this string or XOR it.
    return "MTkzZGQwZmYyNjVhYTgzMGEwZTcyODQ1NzhjYTkwY2U=";
}
