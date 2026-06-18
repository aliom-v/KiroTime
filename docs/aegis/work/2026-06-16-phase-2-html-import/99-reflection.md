# Phase 2 HTML Import Reflection

## Goal

Install KiroTime to the connected Android device and implement the initial Phase 2 safe local HTML import loop.

## DeeperCause

No unresolved implementation blocker remains for the initial loop. Android build failures were caused by environment and dependency compatibility:

- Missing Android SDK.
- System Java 26 incompatible with Gradle 9.1.
- `isar_flutter_libs 3.1.0+1` Android plugin missing AGP 9 namespace and using `compileSdkVersion 30`.

## Evidence

- Android SDK and JDK 21 are installed under user-local paths.
- `pubspec.yaml` overrides `isar_flutter_libs` to a repository-local patched copy.
- Parser RED/GREEN was observed.
- Final `flutter analyze`, `flutter test`, `flutter build apk --debug`, and `flutter install -d <device-id> --debug` succeeded.
- ADB confirmed `package:<old-placeholder-package>` on the device.

## Risk/Unknown

- The generic parser currently expects timetable cells with explicit `data-day`, `data-start-section`, and `data-end-section` attributes. Real school pages will likely need school-specific adapter normalization.
- Manual WebView import was installed but not visually exercised here on a real教务系统 page.

## Decision

Phase 2 initial import foundation is ready for real HTML sample testing and adapter expansion.
