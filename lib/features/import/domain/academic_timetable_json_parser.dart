import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../features/courses/data/course_meta.dart';
import '../../../features/courses/data/course_schedule.dart';
import '../../courses/domain/course_week_text.dart';
import '../../timetable/domain/academic_calendar.dart';
import '../../timetable/domain/semester_settings.dart';
import 'academic_timetable_html_parser.dart';

class AcademicTimetableJsonParser {
  AcademicTimetableJsonParser._();

  static const Uuid _uuid = Uuid();

  static ImportedTimetable parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('学校课表 JSON 根节点必须是对象');
    }

    final root = Map<String, dynamic>.from(decoded);
    final metas = <CourseMeta>[];
    final schedules = <CourseSchedule>[];
    final metaIdsByKey = <String, String>{};
    final scheduleKeys = <String>{};

    for (final item in _courseItems(root)) {
      final parsed = _parseItem(item);
      if (parsed == null || !scheduleKeys.add(parsed.scheduleKey)) {
        continue;
      }

      final courseMetaId = metaIdsByKey.putIfAbsent(parsed.metaKey, () {
        final id = _uuid.v4();
        metas.add(
          CourseMeta.create(
            id: id,
            name: parsed.name,
            teacher: parsed.teacher,
            teachingClass: parsed.teachingClass,
          ),
        );
        return id;
      });

      schedules.add(
        CourseSchedule.create(
          id: _uuid.v4(),
          courseMetaId: courseMetaId,
          classroom: parsed.classroom,
          dayOfWeek: parsed.dayOfWeek,
          startSection: parsed.startSection,
          endSection: parsed.endSection,
          weeks: parsed.weeks,
        ),
      );
    }

    return ImportedTimetable(metas: metas, schedules: schedules);
  }

  static Iterable<Map<String, dynamic>> _courseItems(
    Map<String, dynamic> root,
  ) sync* {
    for (final key in const <String>['kbList', 'sjkList']) {
      final rawList = root[key];
      if (rawList is! List) {
        continue;
      }
      for (final item in rawList.whereType<Map>()) {
        yield Map<String, dynamic>.from(item);
      }
    }
  }

  static _JsonSchedule? _parseItem(Map<String, dynamic> item) {
    final name = _cleanCourseName(_string(item['kcmc']));
    final teacher = _string(item['xm']);
    final teachingClass = _string(item['jxbmc']);
    final weeks = CourseWeekText.parse(
      _string(item['zcd']),
      minWeek: 1,
      maxWeek: AcademicCalendar.maxWeek,
    );
    final dayOfWeek = _parseInt(item['xqj']);
    final sectionRange = _parseSectionRange(_string(item['jcs']));
    if (name.isEmpty ||
        weeks.isEmpty ||
        dayOfWeek == null ||
        dayOfWeek < 1 ||
        dayOfWeek > 7 ||
        sectionRange == null) {
      return null;
    }

    return _JsonSchedule(
      name: name,
      teacher: teacher,
      teachingClass: teachingClass,
      classroom: _joinClassroom(
        campus: _string(item['xqmc']),
        classroom: _string(item['cdmc']),
      ),
      dayOfWeek: dayOfWeek,
      startSection: sectionRange.startSection,
      endSection: sectionRange.endSection,
      weeks: weeks,
    );
  }

  static _SectionRange? _parseSectionRange(String value) {
    final normalized = value
        .replaceAll('－', '-')
        .replaceAll('—', '-')
        .replaceAll('至', '-')
        .replaceAll('到', '-')
        .replaceAll(RegExp(r'\s+'), '');
    final rangeMatch = RegExp(
      r'^第?(\d{1,2})-(\d{1,2})节?$',
    ).firstMatch(normalized);
    if (rangeMatch != null) {
      final start = int.tryParse(rangeMatch.group(1)!);
      final end = int.tryParse(rangeMatch.group(2)!);
      if (start != null && end != null) {
        final startSection = start <= end ? start : end;
        final endSection = start <= end ? end : start;
        if (startSection < 1 || endSection > SemesterSettings.maxSectionCount) {
          return null;
        }
        return _SectionRange(
          startSection: startSection,
          endSection: endSection,
        );
      }
    }

    final singleMatch = RegExp(r'^\d{1,2}$').firstMatch(normalized);
    if (singleMatch == null) {
      return null;
    }
    final section = int.tryParse(singleMatch.group(0)!);
    if (section == null ||
        section < 1 ||
        section > SemesterSettings.maxSectionCount) {
      return null;
    }
    return _SectionRange(startSection: section, endSection: section);
  }

  static String _joinClassroom({
    required String campus,
    required String classroom,
  }) {
    if (campus.isEmpty) {
      return classroom;
    }
    if (classroom.isEmpty || classroom.startsWith(campus)) {
      return classroom.isEmpty ? campus : classroom;
    }
    return '$campus $classroom';
  }

  static String _cleanCourseName(String value) {
    return value.trim();
  }

  static String _string(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}

class _JsonSchedule {
  const _JsonSchedule({
    required this.name,
    required this.teacher,
    required this.teachingClass,
    required this.classroom,
    required this.dayOfWeek,
    required this.startSection,
    required this.endSection,
    required this.weeks,
  });

  final String name;
  final String teacher;
  final String teachingClass;
  final String classroom;
  final int dayOfWeek;
  final int startSection;
  final int endSection;
  final List<int> weeks;

  String get metaKey => '$name\u0000$teacher\u0000$teachingClass';

  String get scheduleKey =>
      '$name\u0000$teacher\u0000$teachingClass\u0000$classroom\u0000$dayOfWeek\u0000'
      '$startSection\u0000$endSection\u0000${weeks.join(',')}';
}

class _SectionRange {
  const _SectionRange({required this.startSection, required this.endSection});

  final int startSection;
  final int endSection;
}
