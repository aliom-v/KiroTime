import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../core/database/string_id_hash.dart';
import '../domain/semester_settings.dart';
import '../domain/section_time_settings.dart';

part 'semester_record.g.dart';

@collection
class SemesterRecord {
  @Index(unique: true, replace: true)
  late String id;

  Id get isarId => stableStringIdHash(id);

  late int schoolYearStart;
  late int semester;
  late DateTime semesterStart;
  late int totalWeeks;
  late int sectionCount;
  String displayName = '';
  String sectionTimesJson = '';

  SemesterRecord();

  factory SemesterRecord.fromSettings(SemesterSettings settings) {
    return SemesterRecord()
      ..id = settings.id
      ..schoolYearStart = settings.schoolYearStart
      ..semester = settings.semester
      ..semesterStart = settings.semesterStart
      ..totalWeeks = settings.totalWeeks
      ..sectionCount = settings.sectionCount
      ..displayName = settings.displayName
      ..sectionTimesJson = jsonEncode(settings.sectionTimeSettings.toJson());
  }

  SemesterSettings toSettings() {
    final sectionTimeSettings = _decodeSectionTimes(
      sectionTimesJson,
      sectionCount: sectionCount,
    );
    return SemesterSettings(
      id: id,
      schoolYearStart: schoolYearStart,
      semester: semester,
      semesterStart: semesterStart,
      totalWeeks: totalWeeks,
      sectionCount: sectionCount,
      displayName: displayName,
      sectionTimeSettings: sectionTimeSettings,
    );
  }

  static SectionTimeSettings _decodeSectionTimes(
    String source, {
    required int sectionCount,
  }) {
    if (source.trim().isEmpty) {
      return SectionTimeSettings.defaultForSectionCount(sectionCount);
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return SectionTimeSettings.fromJson(
          decoded,
          sectionCount: sectionCount,
        );
      }
      if (decoded is Map) {
        return SectionTimeSettings.fromJson(
          Map<String, dynamic>.from(decoded),
          sectionCount: sectionCount,
        );
      }
    } catch (_) {
      return SectionTimeSettings.defaultForSectionCount(sectionCount);
    }
    return SectionTimeSettings.defaultForSectionCount(sectionCount);
  }
}
