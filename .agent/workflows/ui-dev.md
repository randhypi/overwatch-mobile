# 🎨 UI Development Protocol (The Pixel-Perfect Console Theme)

## Objective
Standardized UI implementation protocol to maintain the "Hacker/Console" aesthetic.

## Design Rules

1.  **Strict Color Palette**
    -   Background: `#282c34` (Dark / Atom One Dark).
    -   Cards: `#323842`.
    -   Success: `#98c379` (Green).
    -   Error: `#e06c75` (Red).
    -   Text: `#abb2bf` (Primary), `#5c6370` (Comments/Secondary).

2.  **Typography**
    -   **Data/Logs**: `JetBrains Mono` or `Monospace`.
    -   **Headers/Labels**: `Inter` or `Roboto`.
    -   **Sizing**: Keep it dense. 10-12sp for log content is acceptable.

3.  **Widgets**
    -   Reuse `TransactionGroupCard` patterns.
    -   Use `SliverList` for scrollable areas (Performance).
    -   Micro-animations should be subtle (opacity fades), no heavy bounces.

4.  **Responsiveness**
    -   Test on small screens (POS Devices ~5 inches).
    -   Ensure text doesn't overflow in "Console" view (use `TextOverflow.ellipsis` or `Wrap`).

5.  **Implementation Checklist**
    -   [ ] Checked `AppColors` usage (No hardcoded hex).
    -   [ ] Verified Text Styles.
    -   [ ] Tested Scroll Performance.
