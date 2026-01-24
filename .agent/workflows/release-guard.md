# 🛡️ Release Guard Protocol (The Gatekeeper)

## Objective
Deployment Safety Checklist to prevent security regression or deployment failures.

## Release Checklist

1.  **Obfuscation Check (Mandatory)**
    -   Must run: `flutter build apk --obfuscate --split-debug-info=./debug-info`
    -   Verify that stack traces in `debug-info` are readable only with the map file.

2.  **Versioning Sync**
    -   [ ] `android/app/build.gradle.kts`: `versionCode` bumped?
    -   [ ] `android/app/build.gradle.kts`: `versionName` bumped?
    -   [ ] `CHANGELOG.md`: Does the Header match `versionName`?

3.  **ProGuard/R8 Verification**
    -   Ensure `rules.pro` (if exists) doesn't strip away `Keep` classes needed for JSON serialization.
    -   Check that `libsecrets.so` is not excluded from the final APK.

4.  **Smoke Test (Release Mode)**
    -   Install the RELEASE APK on a real device.
    -   **Test**: Login -> Dashboard -> Filter Data.
    -   **Verify**: Does the app crash on startup? (Common if FFI fails in release).

5.  **Artifact Handover**
    -   Rename APK: `Overwatch_v{versionName}_{Code}_Release.apk`.
    -   Store mapping file (for identifying crashes later).
