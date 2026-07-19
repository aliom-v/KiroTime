import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/timetable/data/semester_record.dart';
import '../../features/timetable/domain/semester_settings.dart';
import '../../features/courses/data/course_meta.dart';
import '../../features/courses/data/course_schedule_edit.dart';
import '../../features/courses/data/course_schedule.dart';
import 'app_setting_record.dart';
import 'mock_course_seed.dart';

class SemesterState {
  const SemesterState({
    required this.semesters,
    required this.selectedSemesterId,
  });

  final List<SemesterSettings> semesters;
  final String selectedSemesterId;
}

class KiroTimeDatabase {
  KiroTimeDatabase._();

  static const Uuid _uuid = Uuid();
  static const String selectedSemesterSettingKey = 'selected_semester_id';

  static const List<CollectionSchema<dynamic>> schemas =
      <CollectionSchema<dynamic>>[
        CourseMetaSchema,
        CourseScheduleSchema,
        SemesterRecordSchema,
        AppSettingRecordSchema,
      ];

  static Isar? _instance;

  static Future<Isar> open() async {
    final existing = _instance;
    if (existing != null) {
      return existing;
    }

    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      schemas,
      directory: dir.path,
      name: 'kiro_time',
    );

    _instance = isar;
    return isar;
  }

  static Future<void> seedMockData(Isar isar) async {
    await isar.writeTxn(() async {
      await isar.courseMetas.putAll(MockCourseSeed.metas);
      await isar.courseSchedules.putAll(MockCourseSeed.schedules);
    });
  }

  static Future<SemesterState> ensureSemesterState(
    Isar isar, {
    required SemesterSettings fallback,
  }) async {
    var semesters = await listSemesters(isar);
    if (semesters.isEmpty) {
      await upsertSemester(isar, fallback);
      semesters = <SemesterSettings>[fallback];
    }

    var selectedSemesterId = await readSelectedSemesterId(isar);
    final selectedExists = semesters.any(
      (SemesterSettings semester) => semester.id == selectedSemesterId,
    );
    if (selectedSemesterId == null || !selectedExists) {
      selectedSemesterId = semesters.first.id;
      await saveSelectedSemesterId(isar, selectedSemesterId);
    }

    await assignMissingSchedulesToSemester(isar, selectedSemesterId);

    return SemesterState(
      semesters: semesters,
      selectedSemesterId: selectedSemesterId,
    );
  }

  static Future<List<SemesterSettings>> listSemesters(Isar isar) async {
    final records = await isar.semesterRecords.where().findAll();
    final semesters =
        records.map((SemesterRecord record) => record.toSettings()).toList()
          ..sort((SemesterSettings a, SemesterSettings b) {
            final yearCompare = a.schoolYearStart.compareTo(b.schoolYearStart);
            if (yearCompare != 0) {
              return yearCompare;
            }
            return a.semester.compareTo(b.semester);
          });
    return semesters;
  }

  static Future<void> upsertSemester(
    Isar isar,
    SemesterSettings settings,
  ) async {
    await isar.writeTxn(() async {
      await isar.semesterRecords.put(SemesterRecord.fromSettings(settings));
    });
  }

  static Future<SemesterSettings> updateSemesterStart(
    Isar isar, {
    required String semesterId,
    required DateTime semesterStart,
  }) async {
    late SemesterSettings updated;
    await isar.writeTxn(() async {
      final record = await isar.semesterRecords
          .where()
          .idEqualTo(semesterId)
          .findFirst();
      if (record == null) {
        throw StateError('Missing semester $semesterId');
      }
      record.semesterStart = semesterStart;
      await isar.semesterRecords.put(record);
      updated = record.toSettings();
    });
    return updated;
  }

  static Future<String?> readSelectedSemesterId(Isar isar) async {
    final record = await isar.appSettingRecords
        .where()
        .keyEqualTo(selectedSemesterSettingKey)
        .findFirst();
    return record?.value;
  }

  static Future<void> saveSelectedSemesterId(
    Isar isar,
    String semesterId,
  ) async {
    await isar.writeTxn(() async {
      await isar.appSettingRecords.put(
        AppSettingRecord.create(
          key: selectedSemesterSettingKey,
          value: semesterId,
        ),
      );
    });
  }

  static Future<String?> readAppSetting(
    Isar isar, {
    required String key,
  }) async {
    final record = await isar.appSettingRecords
        .where()
        .keyEqualTo(key)
        .findFirst();
    return record?.value;
  }

  static Future<Map<String, String>> listAppSettings(Isar isar) async {
    final records = await isar.appSettingRecords.where().findAll();
    return <String, String>{
      for (final record in records) record.key: record.value,
    };
  }

  static Future<void> saveAppSetting(
    Isar isar, {
    required String key,
    required String value,
  }) async {
    await isar.writeTxn(() async {
      await isar.appSettingRecords.put(
        AppSettingRecord.create(key: key, value: value),
      );
    });
  }

  static Future<void> assignMissingSchedulesToSemester(
    Isar isar,
    String semesterId,
  ) async {
    final schedules = await isar.courseSchedules
        .filter()
        .semesterIdEqualTo('')
        .findAll();
    if (schedules.isEmpty) {
      return;
    }

    await isar.writeTxn(() async {
      for (final schedule in schedules) {
        schedule.semesterId = semesterId;
      }
      await isar.courseSchedules.putAll(schedules);
    });
  }

  static Future<List<CourseSchedule>> findSchedulesForSemester(
    Isar isar,
    String semesterId,
  ) {
    return isar.courseSchedules.where().semesterIdEqualTo(semesterId).findAll();
  }

  static Future<void> clearSemesterCourses(
    Isar isar, {
    required String semesterId,
  }) async {
    await isar.writeTxn(() async {
      final schedules = await isar.courseSchedules
          .where()
          .semesterIdEqualTo(semesterId)
          .findAll();
      final metaIds = schedules
          .map((CourseSchedule schedule) => schedule.courseMetaId)
          .toSet();
      await isar.courseSchedules
          .where()
          .semesterIdEqualTo(semesterId)
          .deleteAll();
      for (final metaId in metaIds) {
        await _deleteMetaIfOrphaned(isar, metaId);
      }
    });
  }

  static Future<SemesterSettings> clearAllData(
    Isar isar, {
    required SemesterSettings fallback,
  }) async {
    await isar.writeTxn(() async {
      await isar.courseSchedules.clear();
      await isar.courseMetas.clear();
      await isar.semesterRecords.clear();
      await isar.appSettingRecords.clear();
      await isar.semesterRecords.put(SemesterRecord.fromSettings(fallback));
      await isar.appSettingRecords.put(
        AppSettingRecord.create(
          key: selectedSemesterSettingKey,
          value: fallback.id,
        ),
      );
    });
    return fallback;
  }

  static Future<void> replaceWithImportedData(
    Isar isar, {
    required String semesterId,
    required List<CourseMeta> metas,
    required List<CourseSchedule> schedules,
  }) async {
    await isar.writeTxn(() async {
      final semesterExists = await isar.semesterRecords
          .where()
          .idEqualTo(semesterId)
          .findFirst();
      if (semesterExists == null) {
        throw StateError('Missing semester $semesterId');
      }
      final oldSchedules = await isar.courseSchedules
          .where()
          .semesterIdEqualTo(semesterId)
          .findAll();
      final oldMetaIds = oldSchedules
          .map((CourseSchedule schedule) => schedule.courseMetaId)
          .toSet();
      await isar.courseSchedules
          .where()
          .semesterIdEqualTo(semesterId)
          .deleteAll();

      for (final schedule in schedules) {
        schedule.semesterId = semesterId;
      }
      await isar.courseMetas.putAll(metas);
      await isar.courseSchedules.putAll(schedules);

      final importedMetaIds = metas.map((CourseMeta meta) => meta.id).toSet();
      for (final metaId in oldMetaIds.difference(importedMetaIds)) {
        final stillUsed = await isar.courseSchedules
            .where()
            .courseMetaIdEqualTo(metaId)
            .count();
        if (stillUsed == 0) {
          await isar.courseMetas.deleteById(metaId);
        }
      }
    });
  }

  static Future<void> updateScheduleAndMeta(
    Isar isar, {
    required CourseScheduleEdit edit,
  }) async {
    await isar.writeTxn(() async {
      final meta = await isar.courseMetas
          .where()
          .idEqualTo(edit.courseMetaId)
          .findFirst();
      if (meta == null) {
        throw StateError('Missing CourseMeta for ${edit.courseMetaId}');
      }
      meta.name = edit.name;
      meta.teacher = edit.teacher;
      meta.teachingClass = edit.teachingClass;
      await isar.courseMetas.put(meta);

      final schedule = await isar.courseSchedules
          .where()
          .idEqualTo(edit.scheduleId)
          .findFirst();
      if (schedule == null) {
        throw StateError('Missing CourseSchedule for ${edit.scheduleId}');
      }
      schedule.classroom = edit.classroom;
      schedule.dayOfWeek = edit.dayOfWeek;
      schedule.startSection = edit.startSection;
      schedule.endSection = edit.endSection;
      schedule.weeks = List<int>.from(edit.weeks);
      await isar.courseSchedules.put(schedule);
    });
  }

  static Future<CourseSchedule> createScheduleAndMeta(
    Isar isar, {
    required String semesterId,
    required CourseScheduleEdit edit,
  }) async {
    final meta = CourseMeta.create(
      id: edit.courseMetaId.isEmpty ? _uuid.v4() : edit.courseMetaId,
      name: edit.name,
      teacher: edit.teacher,
      teachingClass: edit.teachingClass,
    );
    final schedule = CourseSchedule.create(
      id: edit.scheduleId.isEmpty ? _uuid.v4() : edit.scheduleId,
      courseMetaId: meta.id,
      classroom: edit.classroom,
      dayOfWeek: edit.dayOfWeek,
      startSection: edit.startSection,
      endSection: edit.endSection,
      weeks: List<int>.from(edit.weeks),
      semesterId: semesterId,
    );

    await isar.writeTxn(() async {
      await isar.courseMetas.put(meta);
      await isar.courseSchedules.put(schedule);
    });

    return schedule;
  }

  static Future<void> deleteSchedule(
    Isar isar, {
    required String scheduleId,
  }) async {
    await isar.writeTxn(() async {
      final schedule = await isar.courseSchedules
          .where()
          .idEqualTo(scheduleId)
          .findFirst();
      if (schedule == null) {
        return;
      }

      final metaId = schedule.courseMetaId;
      await isar.courseSchedules.deleteById(scheduleId);
      await _deleteMetaIfOrphaned(isar, metaId);
    });
  }

  static Future<CourseSchedule> copyScheduleToSemester(
    Isar isar, {
    required String scheduleId,
    required String targetSemesterId,
  }) async {
    final original = await isar.courseSchedules
        .where()
        .idEqualTo(scheduleId)
        .findFirst();
    if (original == null) {
      throw StateError('Missing CourseSchedule for $scheduleId');
    }
    final originalMeta = await isar.courseMetas
        .where()
        .idEqualTo(original.courseMetaId)
        .findFirst();
    if (originalMeta == null) {
      throw StateError('Missing CourseMeta for ${original.courseMetaId}');
    }

    final copiedMeta = CourseMeta.create(
      id: _uuid.v4(),
      name: originalMeta.name,
      teacher: originalMeta.teacher,
      teachingClass: originalMeta.teachingClass,
    );
    final copied = CourseSchedule.create(
      id: _uuid.v4(),
      courseMetaId: copiedMeta.id,
      classroom: original.classroom,
      dayOfWeek: original.dayOfWeek,
      startSection: original.startSection,
      endSection: original.endSection,
      weeks: List<int>.from(original.weeks),
      semesterId: targetSemesterId,
    );

    await isar.writeTxn(() async {
      await isar.courseMetas.put(copiedMeta);
      await isar.courseSchedules.put(copied);
    });

    return copied;
  }

  static Future<String> deleteSemester(
    Isar isar, {
    required String semesterId,
  }) async {
    final semesters = await listSemesters(isar);
    if (semesters.length <= 1) {
      throw StateError('Cannot delete the last semester');
    }
    if (!semesters.any(
      (SemesterSettings semester) => semester.id == semesterId,
    )) {
      throw StateError('Missing semester $semesterId');
    }

    final nextSemester = semesters.firstWhere(
      (SemesterSettings semester) => semester.id != semesterId,
    );
    final currentSelectedId = await readSelectedSemesterId(isar);

    await isar.writeTxn(() async {
      final schedules = await isar.courseSchedules
          .where()
          .semesterIdEqualTo(semesterId)
          .findAll();
      final metaIds = schedules
          .map((CourseSchedule schedule) => schedule.courseMetaId)
          .toSet();
      await isar.courseSchedules
          .where()
          .semesterIdEqualTo(semesterId)
          .deleteAll();
      await isar.semesterRecords.deleteById(semesterId);
      if (currentSelectedId == semesterId || currentSelectedId == null) {
        await isar.appSettingRecords.put(
          AppSettingRecord.create(
            key: selectedSemesterSettingKey,
            value: nextSemester.id,
          ),
        );
      }
      for (final metaId in metaIds) {
        await _deleteMetaIfOrphaned(isar, metaId);
      }
    });

    return currentSelectedId == semesterId || currentSelectedId == null
        ? nextSemester.id
        : currentSelectedId;
  }

  static Future<SemesterSettings> importSemesterAsNew(
    Isar isar, {
    required SemesterSettings baseSemester,
    required List<CourseMeta> metas,
    required List<CourseSchedule> schedules,
  }) async {
    final existingIds = (await listSemesters(
      isar,
    )).map((SemesterSettings semester) => semester.id).toSet();
    final baseId = baseSemester.id.isEmpty
        ? '${baseSemester.schoolYearStart}-${baseSemester.semester}'
        : baseSemester.id;
    var id = baseId;
    var suffix = 2;
    while (existingIds.contains(id)) {
      id = '$baseId-$suffix';
      suffix++;
    }
    final created = baseSemester.copyWith(id: id);

    final metaIdMap = <String, String>{};
    final importedMetas = <CourseMeta>[];
    for (final meta in metas) {
      final newId = _uuid.v4();
      metaIdMap[meta.id] = newId;
      importedMetas.add(
        CourseMeta.create(
          id: newId,
          name: meta.name,
          teacher: meta.teacher,
          teachingClass: meta.teachingClass,
        ),
      );
    }

    final importedSchedules = <CourseSchedule>[];
    for (final schedule in schedules) {
      final mappedMetaId = metaIdMap[schedule.courseMetaId];
      if (mappedMetaId == null) {
        continue;
      }
      importedSchedules.add(
        CourseSchedule.create(
          id: _uuid.v4(),
          courseMetaId: mappedMetaId,
          classroom: schedule.classroom,
          dayOfWeek: schedule.dayOfWeek,
          startSection: schedule.startSection,
          endSection: schedule.endSection,
          weeks: List<int>.from(schedule.weeks),
          semesterId: created.id,
        ),
      );
    }

    await isar.writeTxn(() async {
      await isar.semesterRecords.put(SemesterRecord.fromSettings(created));
      await isar.courseMetas.putAll(importedMetas);
      await isar.courseSchedules.putAll(importedSchedules);
      await isar.appSettingRecords.put(
        AppSettingRecord.create(
          key: selectedSemesterSettingKey,
          value: created.id,
        ),
      );
    });

    return created;
  }

  static Future<void> _deleteMetaIfOrphaned(Isar isar, String metaId) async {
    final stillUsed = await isar.courseSchedules
        .where()
        .courseMetaIdEqualTo(metaId)
        .count();
    if (stillUsed == 0) {
      await isar.courseMetas.deleteById(metaId);
    }
  }

  static Future<void> resetWithMockData(Isar isar) async {
    await isar.writeTxn(() async {
      await isar.courseSchedules.clear();
      await isar.courseMetas.clear();
      await isar.courseMetas.putAll(MockCourseSeed.metas);
      await isar.courseSchedules.putAll(MockCourseSeed.schedules);
    });
  }

  static Future<void> replaceAllTimetableData(
    Isar isar, {
    required List<SemesterSettings> semesters,
    required String selectedSemesterId,
    required List<CourseMeta> metas,
    required List<CourseSchedule> schedules,
    required Map<String, String> appSettings,
  }) async {
    await isar.writeTxn(() async {
      await isar.courseSchedules.clear();
      await isar.courseMetas.clear();
      await isar.semesterRecords.clear();
      await isar.courseMetas.putAll(metas);
      await isar.courseSchedules.putAll(schedules);
      await isar.semesterRecords.putAll(
        semesters.map(SemesterRecord.fromSettings).toList(growable: false),
      );
      await isar.appSettingRecords.put(
        AppSettingRecord.create(
          key: selectedSemesterSettingKey,
          value: selectedSemesterId,
        ),
      );
      for (final entry in appSettings.entries) {
        if (entry.key == selectedSemesterSettingKey) {
          continue;
        }
        await isar.appSettingRecords.put(
          AppSettingRecord.create(key: entry.key, value: entry.value),
        );
      }
    });
  }
}
