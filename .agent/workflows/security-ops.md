# 🔐 Security Operations Protocol (The Vault Keeper)

## Objective
Protocols for Secret Rotation, Low-Level Security Maintenance, and FFI Integrity.

## Routine Tasks

1.  **Secret Rotation (C++ Level)**
    -   Open `android/app/src/main/cpp/secrets.cpp`.
    -   Update the static string values for `API_KEY` or `HMAC_SECRET`.
    -   **CRITICAL**: If you change the key length, verify the C++ array size matches.
    -   Run `flutter clean` then `flutter run` to rebuild the shared object (`.so`).

2.  **SSL Pinning Updates**
    -   If the API Server IP (`103.245.122.241`) rotates its certificate:
    -   Extract the new **Subject Public Key Info (SPKI)** SHA-256 hash.
    -   Update `lib/core/api/ssl_pinning.dart` (if hardcoded) or corresponding config.
    -   Verify connection using a physical device (Emulators may bypass SSL sometimes).

3.  **FFI Binding Integrity**
    -   When modifying `native_secrets.dart`:
    -   Ensure `DynamicLibrary.open('libsecrets.so')` call is robust.
    -   Guard against `dlsym` lookup failures (null pointers).

## Emergency Response (Breach)
1.  Rotate Keys immediately on Server.
2.  Update Keys in `secrets.cpp`.
3.  Increment `versionCode`.
4.  Force Update (if mechanism exists) or notify users to update APK.
