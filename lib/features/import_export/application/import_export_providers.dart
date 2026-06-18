import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/isar_database.dart';
import '../../courses/data/course_meta.dart';
import '../../courses/data/course_schedule.dart';
import '../../timetable/domain/semester_settings.dart';
import '../../timetable/application/timetable_providers.dart';
import '../data/android_timetable_file_gateway.dart';
import '../domain/timetable_json_codec.dart';

class PickedTimetableImport {
  const PickedTimetableImport({
    required this.snapshot,
    required this.preview,
    required this.fileName,
  });

  final TimetableExportSnapshot snapshot;
  final TimetableImportPreview preview;
  final String fileName;
}

final timetableFileGatewayProvider = Provider<AndroidTimetableFileGateway>(
  (ref) => const AndroidTimetableFileGateway(),
);

typedef ExportTimetableJson =
    Future<String> Function({required TimetableExportScope scope});

final exportTimetableJsonProvider = Provider<ExportTimetableJson>((ref) {
  return ({required TimetableExportScope scope}) async {
    final isar = await ref.read(isarProvider.future);
    final semesters = await KiroTimeDatabase.listSemesters(isar);
    final selectedSemesterId = ref.read(selectedSemesterIdProvider);
    final appSettings = scope == TimetableExportScope.allSemesters
        ? await KiroTimeDatabase.listAppSettings(isar)
        : const <String, String>{};

    final schedules = scope == TimetableExportScope.currentSemester
        ? await KiroTimeDatabase.findSchedulesForSemester(
            isar,
            selectedSemesterId,
          )
        : await isar.courseSchedules.where().findAll();
    final metaIds = schedules
        .map((CourseSchedule schedule) => schedule.courseMetaId)
        .toSet();
    final metas = <CourseMeta>[];
    for (final metaId in metaIds) {
      final meta = await isar.courseMetas.where().idEqualTo(metaId).findFirst();
      if (meta != null) {
        metas.add(meta);
      }
    }

    final exportedSemesters = scope == TimetableExportScope.currentSemester
        ? semesters
              .where((semester) => semester.id == selectedSemesterId)
              .toList(growable: false)
        : semesters;
    final snapshot = TimetableExportSnapshot(
      scope: scope,
      exportedAt: DateTime.now(),
      selectedSemesterId: selectedSemesterId,
      semesters: exportedSemesters,
      metas: metas,
      schedules: schedules,
      appSettings: appSettings,
    );
    return TimetableJsonCodec.encode(snapshot);
  };
});

typedef SaveTimetableJsonFile =
    Future<String> Function({required TimetableExportScope scope});

final saveTimetableJsonFileProvider = Provider<SaveTimetableJsonFile>((ref) {
  return ({required TimetableExportScope scope}) async {
    final json = await ref.read(exportTimetableJsonProvider)(scope: scope);
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/kiro_time_exports');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final fileName = scope == TimetableExportScope.currentSemester
        ? 'kiro_time_current_semester_$timestamp.json'
        : 'kiro_time_all_semesters_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(json);
    return file.path;
  };
});

typedef ParseTimetableJson =
    PickedTimetableImport Function(String source, {String? fileName});

final parseTimetableJsonFromTextProvider = Provider<ParseTimetableJson>((ref) {
  return (String source, {String? fileName}) {
    final snapshot = TimetableJsonCodec.decode(source);
    return PickedTimetableImport(
      snapshot: snapshot,
      preview: TimetableJsonCodec.preview(snapshot),
      fileName: fileName ?? '剪贴板 JSON',
    );
  };
});

typedef ApplyTimetableImport =
    Future<void> Function(
      TimetableExportSnapshot snapshot, {
      required TimetableImportMode mode,
    });

enum TimetableImportMode {
  overwriteCurrentSemester,
  createNewSemester,
  overwriteAllData,
}

final applyTimetableImportProvider = Provider<ApplyTimetableImport>((ref) {
  return (TimetableExportSnapshot snapshot, {required mode}) async {
    final isar = await ref.read(isarProvider.future);
    final currentSemesterId = ref.read(selectedSemesterIdProvider);
    if (mode == TimetableImportMode.overwriteCurrentSemester) {
      await KiroTimeDatabase.replaceWithImportedData(
        isar,
        semesterId: currentSemesterId,
        metas: snapshot.metas,
        schedules: snapshot.schedules,
      );
    } else if (mode == TimetableImportMode.createNewSemester) {
      final baseSemester = _baseSemesterForNewImport(snapshot, ref);
      final schedules = _schedulesForNewSemesterImport(snapshot);
      final metaIds = schedules
          .map((CourseSchedule schedule) => schedule.courseMetaId)
          .toSet();
      final created = await KiroTimeDatabase.importSemesterAsNew(
        isar,
        baseSemester: baseSemester,
        metas: snapshot.metas
            .where((CourseMeta meta) => metaIds.contains(meta.id))
            .toList(growable: false),
        schedules: schedules,
      );
      final semesters = sortSemestersByAcademicTime(<SemesterSettings>[
        ...ref.read(semesterListProvider),
        created,
      ]);
      ref.read(semesterListProvider.notifier).state = semesters;
      ref.read(selectedSemesterIdProvider.notifier).state = created.id;
      ref.read(currentWeekProvider.notifier).state = created.weekOf(
        DateTime.now(),
      );
    } else {
      if (snapshot.semesters.isEmpty) {
        throw const FormatException('全量备份缺少学期信息');
      }
      final selected =
          snapshot.semesters.any(
            (semester) => semester.id == snapshot.selectedSemesterId,
          )
          ? snapshot.selectedSemesterId
          : snapshot.semesters.first.id;
      await KiroTimeDatabase.replaceAllTimetableData(
        isar,
        semesters: snapshot.semesters,
        selectedSemesterId: selected,
        metas: snapshot.metas,
        schedules: snapshot.schedules,
        appSettings: snapshot.appSettings,
      );
      ref.read(semesterListProvider.notifier).state = snapshot.semesters;
      ref.read(selectedSemesterIdProvider.notifier).state = selected;
    }
    invalidateTimetableData(ref);
  };
});

SemesterSettings _baseSemesterForNewImport(
  TimetableExportSnapshot snapshot,
  Ref ref,
) {
  if (snapshot.semesters.isEmpty) {
    return ref.read(semesterSettingsProvider).copyWith(displayName: '导入备份');
  }
  final selected = snapshot.semesters.firstWhere(
    (semester) => semester.id == snapshot.selectedSemesterId,
    orElse: () => snapshot.semesters.first,
  );
  final label = selected.displayName.isEmpty
      ? '${selected.label} 导入'
      : selected.displayName;
  return selected.copyWith(displayName: label);
}

List<CourseSchedule> _schedulesForNewSemesterImport(
  TimetableExportSnapshot snapshot,
) {
  if (snapshot.scope == TimetableExportScope.currentSemester) {
    return snapshot.schedules;
  }
  final selectedSemesterId = snapshot.selectedSemesterId;
  return snapshot.schedules
      .where((schedule) => schedule.semesterId == selectedSemesterId)
      .toList(growable: false);
}

typedef ClearCurrentSemesterCourses = Future<void> Function();

final clearCurrentSemesterCoursesProvider =
    Provider<ClearCurrentSemesterCourses>((ref) {
      return () async {
        final isar = await ref.read(isarProvider.future);
        await KiroTimeDatabase.clearSemesterCourses(
          isar,
          semesterId: ref.read(selectedSemesterIdProvider),
        );
        invalidateTimetableData(ref);
      };
    });

typedef ClearAllLocalData = Future<void> Function();

final clearAllLocalDataProvider = Provider<ClearAllLocalData>((ref) {
  return () async {
    final isar = await ref.read(isarProvider.future);
    final fallback = SemesterSettings.fromDate(DateTime.now());
    final cleared = await KiroTimeDatabase.clearAllData(
      isar,
      fallback: fallback,
    );
    ref.read(semesterListProvider.notifier).state = <SemesterSettings>[cleared];
    ref.read(selectedSemesterIdProvider.notifier).state = cleared.id;
    ref.read(currentWeekProvider.notifier).state = cleared.weekOf(
      DateTime.now(),
    );
    invalidateTimetableData(ref);
  };
});
