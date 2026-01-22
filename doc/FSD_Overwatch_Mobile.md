# Functional Specification Document (FSD) - Overwatch Mobile

## 1. System Architecture
*   **Framework**: Flutter (Latest Stable)
*   **State Management**: Riverpod (`floater_riverpod`, `riverpod_annotation`)
*   **Network**: Dio (with Interceptors for GZIP & Auth)
*   **Architecture Pattern**: Clean Architecture (Presentation -> Domain -> Data)

## 2. API Integration Strategy

### 2.1. Authentication (HMAC-SHA512)
The app must implement the custom headers required by the API.

**Logic (Dart Implementation Plan):**
```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

Map<String, String> generateAuthHeaders(String path, String clientId, String secretKey, dynamic payload) {
  final now = DateTime.now();
  // Format: yyyy-MM-dd HH:mm:ss.fff
  final timestamp = "${now.year}-${_pad(now.month)}-${_pad(now.day)} "
      "${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}.${_pad(now.millisecond, 3)}";

  final jsonBody = payload is String ? payload : jsonEncode(payload);
  
  // Signature Format: path:client_id:timestamp:json
  final strToSign = "$path:$clientId:$timestamp:$jsonBody";
  
  final hmac = Hmac(sha512, base64Decode(secretKey)); // Note: Check if SearchKey is base64 or raw utf8 in prod
  final digest = hmac.convert(utf8.encode(strToSign));
  final signature = base64Encode(digest.bytes);

  return {
    'Content-Type': 'application/json',
    'X-client-id': clientId,
    'x-timestamp': timestamp,
    'x-signature': signature
  };
}
```

### 2.2. Endpoints
| Function | Method | Path | Payload |
| :--- | :--- | :--- | :--- |
| **Fetch List** | POST | `/api/sdk/trace/list` | `{"appName": "...", "nodeName": "..."}` |
| **Fetch Content** | POST | `/api/sdk/trace/view` | `{"appName": "...", "fileName": "...", "lastPosition": 0}` |

### 2.3. Decompression (GZIP)
The API returns `logCompressed` as Base64 encoded GZIP data.
**Dart Implementation:**
```dart
import 'dart:io';
import 'dart:convert';

String decompressLog(String base64Payload) {
  final compressedBytes = base64Decode(base64Payload);
  final decompressedBytes = GZipCodec().decode(compressedBytes);
  return utf8.decode(decompressedBytes);
}
```

## 3. Security Specification (Secret Management)

> [!IMPORTANT]
> **Requirement**: `SecretKey` effectively grants access to all transaction logs. It must be protected against static analysis.

### 3.1. Strategy: Native C++ FFI
Store the key inside a compiled Shared Object (`.so` on Android) using Dart FFI.

**File:** `android/app/src/main/cpp/secrets.cpp`
```cpp
#include <stdint.h>

extern "C" __attribute__((visibility("default"))) __attribute__((used))
const char* get_api_secret() {
    // Obfuscated string: "MTkzZGQwZmYyNjVhYTgzMGEwZTcyODQ1NzhjYTkwY2U="
    // Technique: Return parts or XOR at runtime to prevent 'strings' command from finding it easily.
    return "MTkzZGQwZmYyNjVhYTgzMGEwZTcyODQ1NzhjYTkwY2U=";
}
```

**File:** `lib/core/security/native_secrets.dart`
```dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef GetSecretFunc = Pointer<Utf8> Function();
typedef GetSecretFuncDart = Pointer<Utf8> Function();

class NativeSecrets {
  static String get apiKey {
    final dylib = Platform.isAndroid
        ? DynamicLibrary.open('libsecrets.so')
        : DynamicLibrary.process();
    
    final getApiSecret = dylib
        .lookup<NativeFunction<GetSecretFunc>>('get_api_secret')
        .asFunction<GetSecretFuncDart>();

    return getApiSecret().toDartString();
  }
}
```

### 3.2. Network Security (SSL Pinning)
To prevent Man-In-The-Middle (MITM) attacks, the app must pin the certificate of `103.245.122.241`.

**Implementation:**
Use `dio_smart_retry` or custom `HttpClientAdapter` to validate the `SHA-256` fingerprint of the leaf certificate.

```dart
// lib/core/api/ssl_pinning.dart
void setupSslPinning(Dio dio) {
  // Fingerprint for 103.245.122.241 (Must fetch latest via OpenSSL)
  const knownFingerprint = "SHA256:XX:XX:XX..."; 
  
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) {
      if (host == "103.245.122.241") {
        // Compare cert.sha256 with knownFingerprint
        return cert.sha256 == knownFingerprint; 
      }
      return false; // Reject everything else
    };
    return client;
  };
}
```

## 6. Build & Deployment (Obfuscation)

To ensure the C++ headers and Dart logic are not easily readable, use the official Flutter obfuscation flags.

**Build Command:**
```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=./debug_info \
  --target-platform android-arm64
```

*   **`--obfuscate`**: Renames classes, methods, and fields.
*   **`--split-debug-info`**: Strips debug symbols (essential for reducing size and increasing security).

## 4. Parser Logic (Regex Porting)

### 4.1. ISO Parser (Dart RegExp)
```dart
// Header Block
final headerRegex = RegExp(r'(?:\[)?(\d{1,2}\s+[A-Za-z]{3}\s+\d{4}\s+[\d:.]+|[\d-]{10}\s+[\d:.]{8,})(?:\])?(?:\s*<(\d{4})>)?');

// Field Extractor
final fieldRegex = RegExp(r'(?:Field\s+)?(\d{3})[:\s]+(?:\[)?([^\]\r\n]+)(?:\])?');
```

### 4.2. Pairing Logic
*   **Join Key**: `Field 011` (Trace Number) for ISO, `traceNumber` for JSON.
*   **Logic**:
    *   Store Requests in a `Map<String, Transaction>`.
    *   When Response arrives, look up map by Trace Number.
    *   If matched -> Merge -> Mark as Complete.
    *   If no match (or Timeout) -> Display as Orphan.

## 5. UI/UX Composition

### 5.1. Modular File Structure (Strict Feature-First)
The project MUST follow **Clean Architecture** principles with a **Feature-First** organization. Cross-feature dependencies are strictly prohibited unless mediated by `core`.

```
lib/
├── core/                  # Shared Kernel (No feature logic here)
│   ├── api/               # Dio Client, Auth Interceptors
│   ├── error/             # Failure definitions
│   ├── security/          # NativeSecrets (FFI)
│   └── theme/             # AppColors, Fonts (Dark Mode Palette)
│
├── features/              # Independent Modules
│   ├── dashboard/
│   │   ├── data/
│   │   │   ├── datasources/   # Retrofit/Dio Service
│   │   │   ├── models/        # DTOs (fromJson/toJson)
│   │   │   └── repositories/  # Repository Implementation
│   │   ├── domain/
│   │   │   ├── entities/      # Pure Dart Objects (TraceLog, etc)
│   │   │   ├── repositories/  # Abstract Interfaces
│   │   │   └── usecases/      # "GetLogStream", "FilterLogs"
│   │   └── presentation/
│   │   │   ├── providers/     # StateNotifiers / Riverpod
│   │   │   └── widgets/       # Feature-specific widgets (LogCard)
│   │
│   └── log_detail/        # Separated for modularity
│       ├── domain/
│       └── presentation/
│
└── main.dart              # Entry Point (ProviderScope)
```

**Dependency Rule:**
*   `Data` depends on `Domain`.
*   `Presentation` depends on `Domain`.
*   `Domain` is **independent** (Pure Dart).

### 5.2. Widgets
*   **LogCard**: A widget that accepts `LogPair` and renders styling based on `status`.
    *   `Card(color: AppColors.cardBg, ...)`
    *   `Border(left: BorderSide(color: status == '00' ? AppColors.ok : AppColors.fail))`
*   **FilterDrawer**: `Drawer` widget containing all `TextField` inputs mapped to the Filter Provider state.
