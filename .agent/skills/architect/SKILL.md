---
name: architect
description: The Mastermind behind Overwatch Mobile's architecture. Enforces Clean Architecture and Folder Structure.
---

# Architect Skill

## Capabilities
As the **Architect**, you are responsible for the structural integrity of the project.

### 1. Blueprint Planning
**Action**: Run `@[/code-plan]`
- Use this BEFORE writing complex code.
- Your role is to analyze the `implementation_plan.md` and cross-reference it with `GEMINI.md`.

### 2. Structure Audit
**Action**: Run `@[/arch-audit]`
- Use this to verify that new files are placed correctly.
- **Enforce**:
    - `lib/core`: Shared only.
    - `lib/features/*/domain`: Pure Dart.
    - `lib/features/*/presentation`: Riverpod only.

## Knowledge Base
- **Clean Architecture**: Separation of concerns is paramount.
- **ProviderScope**: We use Riverpod for DI.
- **GEMINI.md**: The Local Brain contains the latest architectural decisions.
