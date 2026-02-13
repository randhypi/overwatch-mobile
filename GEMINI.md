# PROJECT: Overwatch Mobile (Local Brain)

**High-Fidelity Transaction Monitor Companion** for DevOps & Level 2 Support.
*Source of Truth derived from PRD 1.0.0 & FSD.*


## 1. Context & Objectives (Status: IMPLEMENTED v1.1.0)

**Goal**: Allow support teams to monitor, filter, and analyze ISO 8583 & JSON transaction logs in realtime from mobile devices.
**Key Value**: Instant visibility of transaction streams (ISO/JSON), quick filtering (trace, ref, errors), and "Hacker/Console" aesthetic.


## 2. Technical Stack (Implemented)

*   **Framework**: Flutter 3.7.0+
*   **Language**: Dart 3.0+
*   **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
*   **Network**: Dio (with Interceptors for GZIP & Auth)
*   **Security**: Native C++ FFI for Secret Storage (`libsecrets.so`)
*   **Fonts**: Inter / Roboto / JetBrains Mono (Monospace)


## 3. System Architecture

**Pattern**: Clean Architecture + Feature-First (Strict Separation)


### Folder Structure

```
lib/
├── core/                  # Shared Kernel (No feature logic)
│   ├── api/               # Dio Client, SSL Pinning, Auth Headers
│   ├── error/             # Failure definitions
│   ├── security/          # NativeSecrets (FFI)
│   └── theme/             # AppColors, Fonts
├── features/              # Independent Modules
│   ├── dashboard/         # Logic for Realtime Monitoring
│   ├── log_detail/        # Logic for Detail View
│   └── ...
└── main.dart              # Entry Point (ProviderScope)
```


### Dependency Rules

*   `Presentation` -> `Domain`
*   `Data` -> `Domain`
*   `Domain` -> **Pure Dart** (No Flutter dependencies, except basic types)

### Architectural Wins (v1.1.0)
*   **LogParser (SRP)**: Parsing logic extracted from `TraceRemoteDataSource` to a reusable static utility in the Domain layer.
*   **SOC (Presentation)**: `DashboardScreen` refactored into modular, "dumb" widgets (`DashboardHeader`, `DashboardStatsBar`, `DashboardMasterList`).
*   **Responsive Engine**: Unified `isTablet` detection via `ResponsiveUtil` extension.

## 4. Key Business Logic


### A. API Integration

*   **Auth**: HMAC-SHA512 Signature (`x-signature`).
    *   Format: `path:client_id:timestamp:json_body`
    *   Secret Key: Stored in C++ layer, NOT in Dart strings.
*   **Compression**: GZIP Base64 encoded responses (`logCompressed`).
*   **SSL Pinning**: Strict pinning for `103.245.122.241`.


### B. Transaction Parsing

*   **Dual Stream**:
    *   **ISO Stream**: Regex-based parser for standard ISO 8583 messages (via `IsoParser`).
    *   **JSON Stream**: Standard JSON parsing (via `LogParser`).
*   **Log Parsing Flow**: `LogParser` handles GZip decompression and block separation before delegating to specific format parsers.
*   **Pairing Strategy**:
    *   **Key**: Match `Field 011` (ISO) with `traceNumber` (JSON).
    *   **Logic**: Merge Request + Response. If Response missing/timeout -> "Orphan/No Response".


### C. Status & Visuals

*   **Success (00)**: Green (`#98c379`)
*   **Error (!00)**: Red (`#e06c75`)
*   **No Response**: Dimmed/Opacity


## 5. Security Protocols

1.  **Secret Key Management**:
    *   NEVER hardcode keys in Dart.
    *   Use `native_secrets.dart` -> `secrets.cpp` via FFI.
    *   Obfuscate string in C++ (XOR or split strings).
2.  **Build Security**:
    *   Use `--obfuscate --split-debug-info` for Release builds.


## 6. Design System (Strict "Console" Theme)

*   **Background**: `#282c34` (Dark)
*   **Cards**: `#323842`
*   **Primary Text**: `#abb2bf`
*   **Accent**: `#61afef` (Blue), `#98c379` (Green), `#e06c75` (Red)
*   **UX**: "Matrix" view, collapsible Filter Drawer, masked PANs by default.

---

