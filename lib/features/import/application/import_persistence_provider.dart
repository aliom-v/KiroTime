import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/isar_database.dart';
import '../../settings/application/settings_providers.dart';
import '../../timetable/application/timetable_providers.dart';
import '../../timetable/domain/section_time_settings.dart';
import '../domain/academic_timetable_html_parser.dart';
import 'import_persistence_sequence.dart';

typedef ReplaceImportedTimetable =
    Future<void> Function({
      required ImportedTimetable timetable,
      required String semesterId,
    });

final replaceImportedTimetableProvider = Provider<ReplaceImportedTimetable>((
  ref,
) {
  return ({
    required ImportedTimetable timetable,
    required String semesterId,
  }) async {
    final isar = await ref.read(isarProvider.future);
    await KiroTimeDatabase.replaceWithImportedData(
      isar,
      semesterId: semesterId,
      metas: timetable.metas,
      schedules: timetable.schedules,
    );
  };
});

typedef RefreshImportedTimetable = void Function();

final refreshImportedTimetableProvider = Provider<RefreshImportedTimetable>((
  ref,
) {
  return () => invalidateTimetableData(ref);
});

typedef PersistImportedTimetable =
    Future<ImportPersistenceResult> Function({
      required ImportedTimetable timetable,
      String? detectedApiPath,
      SectionTimeSettings? acceptedSectionTimes,
    });

final persistImportedTimetableProvider = Provider<PersistImportedTimetable>((
  ref,
) {
  final replaceTimetable = ref.read(replaceImportedTimetableProvider);
  final applySemesterMetadata = ref.read(
    applyImportedSemesterMetadataToSemesterProvider,
  );
  final saveImportPreferences = ref.read(saveImportPreferencesProvider);
  final applySectionTimes = ref.read(
    applyImportedSectionTimesToSemesterProvider,
  );
  final refreshTimetable = ref.read(refreshImportedTimetableProvider);

  return ({
    required ImportedTimetable timetable,
    String? detectedApiPath,
    SectionTimeSettings? acceptedSectionTimes,
  }) async {
    final semesterId = ref.read(selectedSemesterIdProvider);
    final result = await ImportPersistenceSequence.run(
      replaceTimetable: () =>
          replaceTimetable(timetable: timetable, semesterId: semesterId),
      persistSemesterMetadata: () => applySemesterMetadata(
        semesterId: semesterId,
        semesterStart: timetable.semesterStart,
      ),
      persistSectionTimes: acceptedSectionTimes == null
          ? null
          : () => applySectionTimes(
              semesterId: semesterId,
              sectionTimeSettings: acceptedSectionTimes,
            ),
      persistDetectedApiPath: detectedApiPath == null
          ? null
          : () async {
              final current = ref.read(importPreferencesProvider);
              if (current.semesterApiPath == detectedApiPath) {
                return;
              }
              await saveImportPreferences(
                current.copyWith(semesterApiPath: detectedApiPath),
              );
            },
    );
    refreshTimetable();
    return result;
  };
});
