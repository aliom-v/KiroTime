# Phase 1 Foundation Evidence

## Environment

- Installed Flutter 3.44.2 stable to `<flutter-sdk>`.
- Flutter bundle SHA-256 verified: `b0de1d19754688ec6769c9a067db3b0594479d3d767f971bfecfc132904c8d5e`.
- Dart SDK version: 3.12.2.
- Added command symlinks in `<local-bin>`.

## Dependency Resolution

- `flutter_riverpod` was changed from `^3.3.2` to `^2.6.1`.
- Reason: `flutter_riverpod 3.3.2` pulls `riverpod 3.3.2`, which depends on `test`; this conflicts with `isar_generator 3.1.0+1` and current `build_runner` analyzer constraints.
- This preserves the Phase 1 Riverpod architecture while keeping the Isar 3 generator working.

## Commands Run And Result

```bash
command -v flutter || true
command -v dart || true
rg -n "TODO|TBD|TimetableCourseCard|buildCards|withValues|CourseMeta\\(|CourseSchedule\\(" lib test docs DEVELOPMENT_PLAN.md README.md
find lib test docs -type f | sort
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build linux --debug
```

- Text scan found no lingering `TODO`, `TBD`, old `TimetableCourseCard`, old `buildCards`, or unsupported `withValues` references.
- Dependency versions were checked against `pub.dev` package version pages for Riverpod, Isar, path_provider, uuid, and flutter_lints.
- `flutter pub get` succeeded after the Riverpod constraint change.
- `build_runner` succeeded and generated Isar collection files.
- `flutter analyze` passed with no issues.
- `flutter test` passed: 5 tests.
- `flutter build linux --debug` passed and produced `build/linux/x64/debug/bundle/kiro_time`.
- Linux desktop runner files were generated with `flutter create --platforms=linux .`.
- Direct app launch from this non-graphical command environment failed with `Gtk-WARNING ... cannot open display: :1`; run `flutter run -d linux` from a graphical desktop session.
