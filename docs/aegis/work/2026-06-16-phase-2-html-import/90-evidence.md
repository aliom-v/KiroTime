# Phase 2 HTML Import Evidence

## Environment

- `adb devices` with required permissions listed `<device-id>	device`.
- `flutter doctor -v` reported `Unable to locate Android SDK`.
- Android command-line tools downloaded from Android Developers distribution: `commandlinetools-linux-14742923_latest.zip`.
- Android SDK installed at `<android-sdk>`.
- JDK 21 installed at `<jdk-21>`.
- Flutter configured with Android SDK and JDK 21.
- `isar_flutter_libs 3.1.0+1` is overridden to `third_party/isar_flutter_libs` so Android builds have `namespace` and `compileSdkVersion 36`.

## Verification Log

- RED: `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart` failed because `academic_timetable_html_parser.dart` did not exist.
- GREEN: `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart` passed with 6 tests.
- `flutter analyze`: no issues found.
- `flutter test`: 11 tests passed.
- `flutter build apk --debug`: built `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter install -d <device-id> --debug`: installed `app-debug.apk` to `<device-model>`.
- `adb -s <device-id> shell pm list packages <old-placeholder-package>`: returned `package:<old-placeholder-package>`.
