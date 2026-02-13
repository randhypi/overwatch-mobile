# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-02-13

### Added
- **Adaptive UI**: Implemented Master-Detail layout for Tablet support with `NavigationRail`.
- **Responsive Utility**: Added standard breakpoint detection and context extensions.
- **Unit Testing**: Suite for `PairingUseCase` (ISO & JSON matching logic).

### Changed
- **Architecture (SRP)**: Extracted log parsing and decompression logic to a dedicated `LogParser` (Domain layer).
- **Architecture (SOC)**: Refactored `DashboardScreen` into modular functional widgets.

### Fixed
- Android build directory layout issue (`newBuildDir` path resolution).

### Style
- Code formatting applied to Core API, Dashboard Repositories, and Presentation layers.

## [1.0.0] - 2026-01-22
### Added
- **Native Security**: C++ implementation via FFI for API secret obfuscation.
- **Network Layer**: Dio client with HMAC-SHA512 Auth, GZIP support, and SSL Pinning.
- **Dashboard**: "The Matrix" style real-time transaction monitor (`DashboardScreen`).
- **Parsing**: ISO 8583 Regex parser and Trace Log pairing logic.
- **Filtering**: Local search (Trace, PAN, Amount) and Error-only toggle.
- **UI**: Dark Theme customized for "Hacker/Console" aesthetic.
