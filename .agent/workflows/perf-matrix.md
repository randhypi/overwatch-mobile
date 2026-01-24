# 🏎️ Performance Matrix Protocol (The Speed Demon)

## Objective
Ensure high-frequency UI updates do not freeze the main thread, maintaining 60fps even under load.

## Optimization Checklist

1.  **Riverpod Rebuilds**
    -   [ ] Use `select` to listen only to specific parts of the state.
    -   Example: `ref.watch(provider.select((s) => s.specificValue))`.
    -   Avoid watching entire huge Objects in `build` methods.

2.  **List Rendering (The Matrix View)**
    -   [ ] STRICTLY use `ListView.builder` or `SliverList`. Never `ListView` (which renders all items).
    -   [ ] Use `itemExtent` or `prototypeItem` if list items are fixed height (Huge performance boost).
    -   [ ] Use `const` constructors for Widgets in the list.

3.  **Memory Management**
    -   [ ] **StreamSubscription**: Must be cancelled in `dispose` (or use `autoDispose` provider).
    -   [ ] **Image Caching**: If using images, ensure `cached_network_image` is used properly.
    -   [ ] **Profile Mode**: Run `flutter run --profile` to check memory spikes.

4.  **Throttle/Debounce**
    -   [ ] Use `Throttle` for Socket updates if > 10 msg/sec.
    -   [ ] Use `Debounce` for Search/Filter inputs (Wait 300ms before filtering).

5.  **Low-End Device Target**
    -   Validate performance on 2GB RAM devices (common POS specs).
    -   Disable heav animations (Blur/Glassmorphism) on low-end.
