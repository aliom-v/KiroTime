import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/isar_database.dart';
import '../domain/import_preferences.dart';
import '../domain/timetable_appearance_settings.dart';

const String appearanceSettingsKey = 'appearance_settings';
const String importPreferencesKey = 'import_preferences';

final timetableAppearanceSettingsProvider =
    StateProvider<TimetableAppearanceSettings>(
      (ref) => TimetableAppearanceSettings.defaults(),
    );

final importPreferencesProvider = StateProvider<ImportPreferences>(
  (ref) => ImportPreferences.defaults(),
);

final settingsBootstrapProvider = FutureProvider<void>((ref) async {
  final isar = await KiroTimeDatabase.open();
  final appearanceJson = await KiroTimeDatabase.readAppSetting(
    isar,
    key: appearanceSettingsKey,
  );
  if (appearanceJson != null) {
    final decoded = jsonDecode(appearanceJson);
    if (decoded is Map<String, dynamic>) {
      ref.read(timetableAppearanceSettingsProvider.notifier).state =
          TimetableAppearanceSettings.fromJson(decoded);
    }
  }

  final importJson = await KiroTimeDatabase.readAppSetting(
    isar,
    key: importPreferencesKey,
  );
  if (importJson != null) {
    final decoded = jsonDecode(importJson);
    if (decoded is Map<String, dynamic>) {
      ref.read(importPreferencesProvider.notifier).state =
          ImportPreferences.fromJson(decoded);
    }
  }
});

typedef SaveAppearanceSettings =
    Future<void> Function(TimetableAppearanceSettings settings);

final saveAppearanceSettingsProvider = Provider<SaveAppearanceSettings>((ref) {
  return (TimetableAppearanceSettings settings) async {
    ref.read(timetableAppearanceSettingsProvider.notifier).state = settings;
    final isar = await KiroTimeDatabase.open();
    await KiroTimeDatabase.saveAppSetting(
      isar,
      key: appearanceSettingsKey,
      value: jsonEncode(settings.toJson()),
    );
  };
});

typedef SaveImportPreferences =
    Future<void> Function(ImportPreferences preferences);

final saveImportPreferencesProvider = Provider<SaveImportPreferences>((ref) {
  return (ImportPreferences preferences) async {
    final isar = await KiroTimeDatabase.open();
    await KiroTimeDatabase.saveAppSetting(
      isar,
      key: importPreferencesKey,
      value: jsonEncode(preferences.toJson()),
    );
    ref.read(importPreferencesProvider.notifier).state = preferences;
  };
});
