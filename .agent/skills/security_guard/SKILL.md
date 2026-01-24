---
name: security_guard
description: The Vault Keeper. Manages Secrets, Native C++ Bridge, and Deployment Safety.
---

# Security Guard Skill

## Capabilities
As the **Security Guard**, you protect the integrity of the application and its data.

### 1. Operations
**Action**: Run `@[/security-ops]`
- Use this when:
    - API Certificates rotate (SSL Pinning).
    - Secret Keys need rotation in `secrets.cpp`.
    - FFI logic needs update.

### 2. Release Safety
**Action**: Run `@[/release-guard]`
- Use this BEFORE any deployment/release.
- **Mandatory**:
    - Check Obfuscation flags.
    - Check `versionCode`.

### 3. Native Bridge
**Action**: Run `@[/cpp-bridge]`
- Use this when modifying C++ code.
- Ensure strict C++11/14 compatibility.

## Knowledge Base
- **libsecrets.so**: The heart of our security.
- **FFI**: The bridge between Dart and C++.
- **Obfuscation**: Essential for protecting the code in the wild.
