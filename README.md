# Overwatch Mobile

**High-Fidelity Transaction Monitor Companion for DevOps & Level 2 Support.**

![Flutter](https://img.shields.io/badge/Flutter-3.7.0-blue.svg)
![Architecture](https://img.shields.io/badge/Architecture-Clean-green.svg)
![Status](https://img.shields.io/badge/Status-Stable-success.svg)

## Overview
Overwatch Mobile is a specialized monitoring tool designed for the "Jalanin Aja" support team. It provides real-time visibility into ISO 8583 and JSON transaction streams directly from a mobile device, eliminating the need for laptop-based log scraping.

## Key Features
-   **The Matrix View**: Real-time scrolling log feed with instant status visualization (Green/Red).
-   **Adaptive Tablet Support**: Expert-grade Master-Detail layout for tablets with Navigation Rail for efficient monitoring on larger screens.
-   **Dual-Stream Parsing**: Automatically pairs Request (ISO) and Response (JSON) logs.
-   **Console-Grade Filtering**:
    -   Filter by Trace Number, PAN (Masked), or Reference.
    -   Toggle "Show Errors Only (!00)" for rapid debugging.
-   **Secure by Design**:
    -   API Secrets obfuscated in Native C++ layer (`libsecrets.so`).
    -   SSL Pinning enforced for API connections.
    -   HMAC-SHA512 Request Signing.

## Getting Started

### Prerequisites
-   Flutter SDK 3.7.0+
-   Android NDK (for C++ compilation)
-   Java 11 or 17

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/randhypi/overwatch-mobile.git
    cd overwatch-mobile
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```
    *Note: The Native C++ library will be compiled automatically via Gradle.*

## Architecture
The project follows **Clean Architecture** with a **Feature-First** structure:
-   `lib/core`: Shared utilities, API Client, Security (FFI).
-   `lib/features/dashboard`: Dashboard UI (Modular SOC Widgets), Log Logic (LogParser/Pairing), and Data Layer.
-   `lib/features/log_detail`: Detail view logic.

## Security
To protect sensitive API keys, this project uses **Native C++ Obfuscation**.
-   Secrets are stored in `android/app/src/main/cpp/secrets.cpp`.
-   Accessed via Dart FFI in `lib/core/security/native_secrets.dart`.
