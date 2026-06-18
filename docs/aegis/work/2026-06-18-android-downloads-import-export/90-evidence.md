# Evidence

- Baseline reads:
  - `lib/features/settings/presentation/settings_center_dialog.dart`
  - `lib/features/import_export/application/import_export_providers.dart`
  - `lib/features/import_export/domain/timetable_json_codec.dart`
  - `lib/core/database/isar_database.dart`
  - `android/app/src/main/kotlin/com/example/kiro_time/MainActivity.kt`
- Current limitation:
  - export uses App Documents path and copies the path to clipboard,
  - import reads JSON from clipboard,
  - no import-as-new-semester mode exists yet.

## Verification Log

- RED: `flutter test test/features/import_export/domain/timetable_file_naming_test.dart` failed because `timetable_file_naming.dart` did not exist.
- GREEN: `flutter test test/features/import_export/domain/timetable_file_naming_test.dart` passed.
- RED: `flutter test test/features/import_export/data/android_timetable_file_gateway_test.dart` failed because `android_timetable_file_gateway.dart` did not exist.
- GREEN: `flutter test test/features/import_export/data/android_timetable_file_gateway_test.dart` passed.
- `flutter build apk --debug` passed after adding Android `MethodChannel`.
- RED: `flutter test test/core/database/kiro_time_database_test.dart` failed because `KiroTimeDatabase.importSemesterAsNew` did not exist.
- GREEN: `flutter test test/core/database/kiro_time_database_test.dart` passed.
- `flutter analyze`: no issues found.
- `flutter test`: 90 tests passed.
- `flutter build apk --debug`: built `build/app/outputs/flutter-apk/app-debug.apk`.
- `adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk`: `Success`.
- Device Android version check: SDK `36`, release `16`, so public Downloads export uses MediaStore path.
