# Phase 1 verification — 2026-10-19

## Completed

- Flutter 3.47.4 / Dart 3.13.3; Android SDK 36; JDK 17.
- `flutter analyze`: no issues found.
- Complete regression suite: **16 tests passed**.
- Model: undo/redo branching, immutable strokes, layer selection/deletion/order,
  layer cap, reversible clear, JSON round trip and malformed schema rejection.
- Storage: queued latest-save ordering, previous-save recovery, interrupted first
  save recovery, preservation/reporting of unreadable files and recovery deletion.
- Rendering: exact transparent/white pixels, layer opacity/visibility and eraser
  isolation verified from rendered PNG pixel data.
- Pointer interactions: stroke commit, two-finger gesture cancellation, pointer
  cancellation and hidden-layer input rejection.
- UI: controls/undo/redo/layers exercised at 390×844, 320×640 and 1024×768.
- Flutter-rendered Home/Gallery/Canvas previews captured and visually inspected.
  The artwork is an editable vector test fixture, not preloaded user artwork.
- Android debug APK compiled successfully, including save/share native plugins.
- Approved S icon generated into Android and iOS launcher asset sets; full logo
  integrated into the Flutter startup view.

## Device / platform limits

- Physical-device input latency, large-document frame pacing, stylus/palm handling,
  low-storage behaviour and system share receivers still need device acceptance.
- iOS project is prepared, but iOS compilation, Xcode signing, simulator/device,
  Apple Pencil, iPad popover and TestFlight validation require a Mac.
- Windows Java socket failure was resolved using a workspace-local Java socket
  directory. No global Java or firewall settings were changed.
- Test builds use debug signing; they are not store submission artifacts.

## Emulator smoke test

An isolated Android 36.1 emulator booted, installed the debug APK successfully,
and displayed Sketchora Home. The emulator also reported System UI / Process
system ANRs, including before app validation. Full drawing/save/share smoke tests
and timing measurements were therefore not counted as passed. The emulator was
stopped after capturing this limitation. No Flutter/AndroidRuntime exception was
observed in the filtered startup log capture, which is not a substitute for a
complete device run.

## Packaged APK

- Optimized build: `flutter build apk --release` succeeded.
- File: `dist/Sketchora-0.1.0-phase1.apk`.
- Size: 55,063,441 bytes (52.5 MiB).
- SHA-256: `18028985E17A004765EC621437C5D2A7759D95CA44F12B1E7420D7314D0C8793`.
- ID/version: `com.srikanth.sketchora`, `0.1.0`, version code `1`.
- Minimum API 24; target/compile API 36; arm64-v8a, armeabi-v7a, x86_64.
- `apksigner verify --verbose --print-certs` passed (APK v2 signature).
- Certificate: Android Debug, for internal testing only.
- The emulator installation/Home observation used the debug APK. The optimized
  APK is build/signature verified; full runtime acceptance on a phone is pending.
- Separate debug artifact: `dist/Sketchora-0.1.0-phase1-debug.apk`.
