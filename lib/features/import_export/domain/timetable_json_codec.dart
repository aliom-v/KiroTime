import 'dart:convert';

import '../../courses/data/course_meta.dart';
import '../../courses/data/course_schedule.dart';
import '../../timetable/domain/semester_settings.dart';
import '../../timetable/domain/section_time_settings.dart';

enum TimetableExportScope { currentSemester, allSemesters }

class TimetableExportSnapshot {
  const TimetableExportSnapshot({
    required this.scope,
    required this.exportedAt,
    required this.selectedSemesterId,
    required this.semesters,
    required this.metas,
    required this.schedules,
    this.appSettings = const <String, String>{},
  });

  final TimetableExportScope scope;
  final DateTime exportedAt;
  final String selectedSemesterId;
  final List<SemesterSettings> semesters;
  final List<CourseMeta> metas;
  final List<CourseSchedule> schedules;
  final Map<String, String> appSettings;
}

class TimetableImportPreview {
  const TimetableImportPreview({
    required this.scope,
    required this.courseCount,
    required this.scheduleCount,
    required this.conflictCount,
    required this.semesterStart,
  });

  final TimetableExportScope scope;
  final int courseCount;
  final int scheduleCount;
  final int conflictCount;
  final DateTime? semesterStart;
}

class TimetableJsonCodec {
  TimetableJsonCodec._();

  static const int version = 1;

  static String encode(TimetableExportSnapshot snapshot) {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'format': 'kiro_time_timetable',
      'version': version,
      'scope': snapshot.scope.name,
      'exportedAt': snapshot.exportedAt.toIso8601String(),
      'selectedSemesterId': snapshot.selectedSemesterId,
      'semesters': snapshot.semesters.map(_semesterToJson).toList(),
      'metas': snapshot.metas.map(_metaToJson).toList(),
      'schedules': snapshot.schedules.map(_scheduleToJson).toList(),
      'appSettings': snapshot.appSettings,
    });
  }

  static TimetableExportSnapshot decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('KiroTime JSON 根节点必须是对象');
    }
    if (decoded['format'] != 'kiro_time_timetable') {
      throw const FormatException('不是 KiroTime 课表 JSON');
    }

    final scope = _enumFromName(
      TimetableExportScope.values,
      decoded['scope'],
      TimetableExportScope.currentSemester,
    );
    final exportedAt =
        DateTime.tryParse(decoded['exportedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final semesters = _listOfMaps(
      decoded['semesters'],
    ).map(_semesterFromJson).toList(growable: false);
    final metas = _listOfMaps(
      decoded['metas'],
    ).map(_metaFromJson).toList(growable: false);
    final schedules = _listOfMaps(
      decoded['schedules'],
    ).map(_scheduleFromJson).toList(growable: false);
    final appSettings = <String, String>{};
    final rawAppSettings = decoded['appSettings'];
    if (rawAppSettings is Map) {
      rawAppSettings.forEach((key, value) {
        appSettings[key.toString()] = value.toString();
      });
    }

    return TimetableExportSnapshot(
      scope: scope,
      exportedAt: exportedAt,
      selectedSemesterId: decoded['selectedSemesterId']?.toString() ?? '',
      semesters: semesters,
      metas: metas,
      schedules: schedules,
      appSettings: appSettings,
    );
  }

  static TimetableImportPreview preview(TimetableExportSnapshot snapshot) {
    return TimetableImportPreview(
      scope: snapshot.scope,
      courseCount: snapshot.metas.length,
      scheduleCount: snapshot.schedules.length,
      conflictCount: _countConflicts(snapshot.schedules),
      semesterStart: snapshot.semesters.isEmpty
          ? null
          : snapshot.semesters.first.semesterStart,
    );
  }

  static Map<String, dynamic> _semesterToJson(SemesterSettings settings) {
    return <String, dynamic>{
      'id': settings.id,
      'schoolYearStart': settings.schoolYearStart,
      'semester': settings.semester,
      'semesterStart': settings.semesterStart.toIso8601String(),
      'totalWeeks': settings.totalWeeks,
      'sectionCount': settings.sectionCount,
      'displayName': settings.displayName,
      'sectionTimes': settings.sectionTimeSettings.toJson(),
    };
  }

  static SemesterSettings _semesterFromJson(Map<String, dynamic> json) {
    final schoolYearStart = _intValue(json['schoolYearStart'], 2026);
    final semester = _intValue(json['semester'], 1).clamp(1, 2);
    final start =
        DateTime.tryParse(json['semesterStart']?.toString() ?? '') ??
        DateTime(schoolYearStart, semester == 1 ? 9 : 3, 1);
    return SemesterSettings(
      id: json['id']?.toString(),
      schoolYearStart: schoolYearStart,
      semester: semester,
      semesterStart: DateTime(start.year, start.month, start.day),
      totalWeeks: _intValue(json['totalWeeks'], 20).clamp(1, 30),
      sectionCount: _intValue(
        json['sectionCount'],
        SemesterSettings.defaultSectionCount,
      ),
      displayName: json['displayName']?.toString() ?? '',
      sectionTimeSettings: _sectionTimesFromJson(
        json['sectionTimes'],
        sectionCount: _intValue(
          json['sectionCount'],
          SemesterSettings.defaultSectionCount,
        ),
      ),
    );
  }

  static SectionTimeSettings _sectionTimesFromJson(
    Object? value, {
    required int sectionCount,
  }) {
    if (value is Map<String, dynamic>) {
      return SectionTimeSettings.fromJson(value, sectionCount: sectionCount);
    }
    if (value is Map) {
      return SectionTimeSettings.fromJson(
        Map<String, dynamic>.from(value),
        sectionCount: sectionCount,
      );
    }
    return SectionTimeSettings.defaultForSectionCount(sectionCount);
  }

  static Map<String, dynamic> _metaToJson(CourseMeta meta) {
    return <String, dynamic>{
      'id': meta.id,
      'name': meta.name,
      'teacher': meta.teacher,
      'teachingClass': meta.teachingClass,
    };
  }

  static CourseMeta _metaFromJson(Map<String, dynamic> json) {
    return CourseMeta.create(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      teacher: json['teacher']?.toString() ?? '',
      teachingClass: json['teachingClass']?.toString() ?? '',
    );
  }

  static Map<String, dynamic> _scheduleToJson(CourseSchedule schedule) {
    return <String, dynamic>{
      'id': schedule.id,
      'courseMetaId': schedule.courseMetaId,
      'semesterId': schedule.semesterId,
      'classroom': schedule.classroom,
      'dayOfWeek': schedule.dayOfWeek,
      'startSection': schedule.startSection,
      'endSection': schedule.endSection,
      'weeks': schedule.weeks,
    };
  }

  static CourseSchedule _scheduleFromJson(Map<String, dynamic> json) {
    return CourseSchedule.create(
      id: json['id']?.toString() ?? '',
      courseMetaId: json['courseMetaId']?.toString() ?? '',
      classroom: json['classroom']?.toString() ?? '',
      dayOfWeek: _intValue(json['dayOfWeek'], 1).clamp(1, 7),
      startSection: _intValue(json['startSection'], 1).clamp(1, 32),
      endSection: _intValue(json['endSection'], 1).clamp(1, 32),
      weeks: _intList(json['weeks']),
      semesterId: json['semesterId']?.toString() ?? '',
    );
  }

  static int _countConflicts(List<CourseSchedule> schedules) {
    var conflicts = 0;
    for (var i = 0; i < schedules.length; i++) {
      for (var j = i + 1; j < schedules.length; j++) {
        final a = schedules[i];
        final b = schedules[j];
        if (a.dayOfWeek != b.dayOfWeek) {
          continue;
        }
        if (a.semesterId.isNotEmpty &&
            b.semesterId.isNotEmpty &&
            a.semesterId != b.semesterId) {
          continue;
        }
        final sectionOverlaps =
            a.startSection <= b.endSection && b.startSection <= a.endSection;
        if (!sectionOverlaps) {
          continue;
        }
        final weekOverlaps = a.weeks.toSet().intersection(b.weeks.toSet());
        if (weekOverlaps.isNotEmpty) {
          conflicts++;
        }
      }
    }
    return conflicts;
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static int _intValue(Object? value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<int> _intList(Object? value) {
    if (value is! List) {
      return const <int>[];
    }
    return value
        .map((item) => _intValue(item, -1))
        .where((item) => item > 0)
        .toSet()
        .toList()
      ..sort();
  }

  static T _enumFromName<T extends Enum>(
    List<T> values,
    Object? rawValue,
    T fallback,
  ) {
    if (rawValue is! String) {
      return fallback;
    }
    for (final value in values) {
      if (value.name == rawValue) {
        return value;
      }
    }
    return fallback;
  }
}
