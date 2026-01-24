# 🏗️ Architecture Audit Protocol (The Structure Enforcer)

## Objective
Verify codebase integrity against the Clean Architecture folder structure and dependency rules.

## Audit Checklist

1.  **Strict Folder Structure**
    -   [ ] `lib/core`: Only shared implementation. No Feature logic.
    -   [ ] `lib/features/*/domain`: PURE DART. No `flutter` imports (except `foundation` for `@immutable`).
    -   [ ] `lib/features/*/data`: Dependent on Domain. Implements Repositories.
    -   [ ] `lib/features/*/presentation`: Dependent on Domain. Uses `flutter_riverpod`.

2.  **Dependency Rules**
    -   [ ] **Presentation Layer**: Should NOT import `data` layer files directly (e.g. `TraceRepositoryImpl`). Must use Interface/Provider.
    -   [ ] **Feature Isolation**: `dashboard` should not import `log_detail` internals directly. Use a shared route or event.

3.  **Security Checks**
    -   [ ] No Hardcoded API Keys/Secrets in `.dart` files.
    -   [ ] All Secrets accessed via `NativeSecrets` (FFI).

4.  **State Management**
    -   [ ] No `setState` for complex business logic (Use `Riverpod` Notifiers).
    -   [ ] `ConsumerWidget` or `ConsumerStatefulWidget` used correctly.
