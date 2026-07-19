import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/isar_database.dart';
import '../../courses/data/course_meta.dart';
import '../../courses/data/course_schedule_edit.dart';
import '../../courses/data/course_schedule.dart';
import '../domain/semester_settings.dart';
import '../domain/timetable_layout.dart';

final semesterListProvider = StateProvider<List<SemesterSettings>>(
  (ref) => <SemesterSettings>[SemesterSettings.fromDate(DateTime.now())],
);

final selectedSemesterIdProvider = StateProvider<String>(
  (ref) => ref.read(semesterListProvider).first.id,
);

final semesterSettingsProvider = Provider<SemesterSettings>((ref) {
  final semesters = ref.watch(semesterListProvider);
  final selectedId = ref.watch(selectedSemesterIdProvider);
  return semesters.firstWhere(
    (semester) => semester.id == selectedId,
    orElse: () => semesters.first,
  );
});

final currentWeekProvider = StateProvider<int>(
  (ref) => ref.read(semesterSettingsProvider).weekOf(DateTime.now()),
);

List<SemesterSettings> sortSemestersByAcademicTime(
  Iterable<SemesterSettings> semesters,
) {
  return semesters.toList(growable: false)
    ..sort((SemesterSettings a, SemesterSettings b) {
      final yearCompare = a.schoolYearStart.compareTo(b.schoolYearStart);
      if (yearCompare != 0) {
        return yearCompare;
      }
      final termCompare = a.semester.compareTo(b.semester);
      if (termCompare != 0) {
        return termCompare;
      }
      return a.id.compareTo(b.id);
    });
}

void _setSelectedSemesterInMemory(Ref ref, SemesterSettings settings) {
  ref.read(selectedSemesterIdProvider.notifier).state = settings.id;
  ref.read(currentWeekProvider.notifier).state = settings.weekOf(
    DateTime.now(),
  );
}

void invalidateTimetableData(Ref ref) {
  ref.invalidate(courseMetasProvider);
  ref.invalidate(allCourseSchedulesProvider);
  ref.invalidate(currentWeekSchedulesProvider);
  ref.invalidate(timetablePlacementsProvider);
  ref.invalidate(timetableVisibleItemsProvider);
}

typedef SelectSemester = Future<void> Function(SemesterSettings settings);

final selectSemesterProvider = Provider<SelectSemester>((ref) {
  return (SemesterSettings settings) async {
    _setSelectedSemesterInMemory(ref, settings);
    final isar = await KiroTimeDatabase.open();
    await KiroTimeDatabase.saveSelectedSemesterId(isar, settings.id);
    invalidateTimetableData(ref);
  };
});

typedef UpdateImportedSemesterStart =
    Future<void> Function({
      required String semesterId,
      required DateTime semesterStart,
    });

final updateImportedSemesterStartProvider =
    Provider<UpdateImportedSemesterStart>((ref) {
      return ({
        required String semesterId,
        required DateTime semesterStart,
      }) async {
        final isar = await KiroTimeDatabase.open();
        final persisted = await KiroTimeDatabase.updateSemesterStart(
          isar,
          semesterId: semesterId,
          semesterStart: semesterStart,
        );
        final semesters = ref.read(semesterListProvider);
        SemesterSettings? mergedTarget;
        final updatedSemesters = <SemesterSettings>[
          for (final semester in semesters)
            if (semester.id == semesterId)
              mergedTarget = semester.copyWith(
                semesterStart: persisted.semesterStart,
              )
            else
              semester,
        ];
        if (mergedTarget == null) {
          return;
        }
        ref.read(semesterListProvider.notifier).state =
            sortSemestersByAcademicTime(updatedSemesters);
        if (ref.read(selectedSemesterIdProvider) == semesterId) {
          ref.read(currentWeekProvider.notifier).state = mergedTarget.weekOf(
            DateTime.now(),
          );
        }
        invalidateTimetableData(ref);
      };
    });

final updateSelectedSemesterProvider =
    Provider<Future<void> Function(SemesterSettings)>((ref) {
      return (SemesterSettings settings) async {
        final semesters = ref.read(semesterListProvider);
        ref
            .read(semesterListProvider.notifier)
            .state = sortSemestersByAcademicTime(<SemesterSettings>[
          for (final semester in semesters)
            if (semester.id == settings.id) settings else semester,
        ]);
        _setSelectedSemesterInMemory(ref, settings);
        final isar = await KiroTimeDatabase.open();
        await KiroTimeDatabase.upsertSemester(isar, settings);
        await KiroTimeDatabase.saveSelectedSemesterId(isar, settings.id);
        invalidateTimetableData(ref);
      };
    });

typedef ApplyImportedSemesterMetadata =
    Future<void> Function({DateTime? semesterStart});

final applyImportedSemesterMetadataProvider =
    Provider<ApplyImportedSemesterMetadata>((ref) {
      return ({DateTime? semesterStart}) async {
        if (semesterStart == null) {
          return;
        }
        final current = ref.read(semesterSettingsProvider);
        final normalizedStart = DateTime(
          semesterStart.year,
          semesterStart.month,
          semesterStart.day,
        );
        if (current.semesterStart == normalizedStart) {
          return;
        }
        await ref.read(updateSelectedSemesterProvider)(
          current.copyWith(semesterStart: normalizedStart),
        );
      };
    });

typedef ApplyImportedSemesterMetadataToSemester =
    Future<void> Function({
      required String semesterId,
      DateTime? semesterStart,
    });

final applyImportedSemesterMetadataToSemesterProvider =
    Provider<ApplyImportedSemesterMetadataToSemester>((ref) {
      return ({required String semesterId, DateTime? semesterStart}) async {
        if (semesterStart == null) {
          return;
        }
        final semesters = ref.read(semesterListProvider);
        SemesterSettings? target;
        for (final semester in semesters) {
          if (semester.id == semesterId) {
            target = semester;
            break;
          }
        }
        if (target == null) {
          throw StateError('目标学期不存在：$semesterId');
        }
        final normalizedStart = DateTime(
          semesterStart.year,
          semesterStart.month,
          semesterStart.day,
        );
        if (target.semesterStart == normalizedStart) {
          return;
        }
        await ref.read(updateImportedSemesterStartProvider)(
          semesterId: semesterId,
          semesterStart: normalizedStart,
        );
      };
    });

typedef AddSemester =
    Future<SemesterSettings> Function(SemesterSettings settings);

final addSemesterProvider = Provider<AddSemester>((ref) {
  return (SemesterSettings settings) async {
    final semesters = ref.read(semesterListProvider);
    final existingIds = semesters.map((semester) => semester.id).toSet();
    final baseId = '${settings.schoolYearStart}-${settings.semester}';
    var id = baseId;
    var suffix = 2;
    while (existingIds.contains(id)) {
      id = '$baseId-$suffix';
      suffix++;
    }
    final created = settings.copyWith(
      id: id,
      semesterStart: DateTime(
        settings.semesterStart.year,
        settings.semesterStart.month,
        settings.semesterStart.day,
      ),
    );
    ref.read(semesterListProvider.notifier).state = sortSemestersByAcademicTime(
      <SemesterSettings>[...semesters, created],
    );
    _setSelectedSemesterInMemory(ref, created);
    await _persistSelectedSemester(ref, created);
    return created;
  };
});

typedef DeleteSemester = Future<void> Function(String semesterId);

final deleteSemesterProvider = Provider<DeleteSemester>((ref) {
  return (String semesterId) async {
    final semesters = ref.read(semesterListProvider);
    if (semesters.length <= 1) {
      throw StateError('Cannot delete the last semester');
    }

    final remaining = sortSemestersByAcademicTime(<SemesterSettings>[
      for (final semester in semesters)
        if (semester.id != semesterId) semester,
    ]);
    if (remaining.length == semesters.length) {
      throw StateError('Missing semester $semesterId');
    }

    final isar = await KiroTimeDatabase.open();
    final selectedSemesterId = await KiroTimeDatabase.deleteSemester(
      isar,
      semesterId: semesterId,
    );
    ref.read(semesterListProvider.notifier).state = remaining;
    final selected = remaining.firstWhere(
      (SemesterSettings semester) => semester.id == selectedSemesterId,
      orElse: () => remaining.first,
    );
    _setSelectedSemesterInMemory(ref, selected);
    invalidateTimetableData(ref);
  };
});

Future<void> _persistSelectedSemester(
  Ref ref,
  SemesterSettings settings,
) async {
  final isar = await KiroTimeDatabase.open();
  await KiroTimeDatabase.upsertSemester(isar, settings);
  await KiroTimeDatabase.saveSelectedSemesterId(isar, settings.id);
  invalidateTimetableData(ref);
}

final isarProvider = FutureProvider<Isar>((ref) async {
  final isar = await KiroTimeDatabase.open();
  final fallback = SemesterSettings.fromDate(DateTime.now());
  final semesterState = await KiroTimeDatabase.ensureSemesterState(
    isar,
    fallback: fallback,
  );
  ref.read(semesterListProvider.notifier).state = sortSemestersByAcademicTime(
    semesterState.semesters,
  );
  final selectedSemester = semesterState.semesters.firstWhere(
    (SemesterSettings semester) =>
        semester.id == semesterState.selectedSemesterId,
    orElse: () => semesterState.semesters.first,
  );
  _setSelectedSemesterInMemory(ref, selectedSemester);
  return isar;
});

final courseMetasProvider = FutureProvider<List<CourseMeta>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.courseMetas.where().findAll();
});

final allCourseSchedulesProvider = FutureProvider<List<CourseSchedule>>((
  ref,
) async {
  final selectedSemesterId = ref.watch(selectedSemesterIdProvider);
  final isar = await ref.watch(isarProvider.future);
  await KiroTimeDatabase.assignMissingSchedulesToSemester(
    isar,
    selectedSemesterId,
  );
  return KiroTimeDatabase.findSchedulesForSemester(isar, selectedSemesterId);
});

final currentWeekSchedulesProvider = FutureProvider<List<CourseSchedule>>((
  ref,
) async {
  final currentWeek = ref.watch(currentWeekProvider);
  final schedules = await ref.watch(allCourseSchedulesProvider.future);
  return TimetableLayout.filterSchedulesForWeek(schedules, currentWeek);
});

final timetablePlacementsProvider =
    FutureProvider<List<TimetableCoursePlacement>>((ref) async {
      final courseMetas = await ref.watch(courseMetasProvider.future);
      final schedules = await ref.watch(currentWeekSchedulesProvider.future);
      return TimetableLayout.buildPlacements(
        schedules: schedules,
        courseMetas: courseMetas,
      );
    });

final timetableVisibleItemsProvider =
    FutureProvider<List<TimetableVisibleItem>>((ref) async {
      final placements = await ref.watch(timetablePlacementsProvider.future);
      return TimetableLayout.buildVisibleItemsFromPlacements(placements);
    });

typedef SaveCourseScheduleEdit = Future<void> Function(CourseScheduleEdit edit);

final saveCourseScheduleEditProvider = Provider<SaveCourseScheduleEdit>((ref) {
  return (CourseScheduleEdit edit) async {
    final isar = await ref.read(isarProvider.future);
    await KiroTimeDatabase.updateScheduleAndMeta(isar, edit: edit);
    invalidateTimetableData(ref);
  };
});

typedef CreateCourseSchedule = Future<void> Function(CourseScheduleEdit edit);

final createCourseScheduleProvider = Provider<CreateCourseSchedule>((ref) {
  return (CourseScheduleEdit edit) async {
    final isar = await ref.read(isarProvider.future);
    final semesterId = ref.read(selectedSemesterIdProvider);
    await KiroTimeDatabase.createScheduleAndMeta(
      isar,
      semesterId: semesterId,
      edit: edit,
    );
    invalidateTimetableData(ref);
  };
});

typedef DeleteCourseSchedule = Future<void> Function(String scheduleId);

final deleteCourseScheduleProvider = Provider<DeleteCourseSchedule>((ref) {
  return (String scheduleId) async {
    final isar = await ref.read(isarProvider.future);
    await KiroTimeDatabase.deleteSchedule(isar, scheduleId: scheduleId);
    invalidateTimetableData(ref);
  };
});

typedef CopyCourseSchedule =
    Future<void> Function({
      required String scheduleId,
      required String targetSemesterId,
    });

final copyCourseScheduleProvider = Provider<CopyCourseSchedule>((ref) {
  return ({
    required String scheduleId,
    required String targetSemesterId,
  }) async {
    final isar = await ref.read(isarProvider.future);
    await KiroTimeDatabase.copyScheduleToSemester(
      isar,
      scheduleId: scheduleId,
      targetSemesterId: targetSemesterId,
    );
    invalidateTimetableData(ref);
  };
});
