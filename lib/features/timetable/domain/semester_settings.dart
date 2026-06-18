import 'academic_calendar.dart';
import 'section_time_settings.dart';

class SemesterSettings {
  SemesterSettings({
    String? id,
    required this.schoolYearStart,
    required this.semester,
    required this.semesterStart,
    required this.totalWeeks,
    int sectionCount = defaultSectionCount,
    String displayName = '',
    SectionTimeSettings? sectionTimeSettings,
  }) : id = id ?? _defaultId(schoolYearStart, semester),
       sectionCount = sectionCount.clamp(minSectionCount, maxSectionCount),
       displayName = displayName.trim(),
       sectionTimeSettings =
           (sectionTimeSettings ??
                   SectionTimeSettings.defaultForSectionCount(sectionCount))
               .ensureSectionCount(
                 sectionCount.clamp(minSectionCount, maxSectionCount),
               );

  static const int defaultSectionCount = 10;
  static const int minSectionCount = 8;
  static const int maxSectionCount = 16;

  final String id;
  final int schoolYearStart;
  final int semester;
  final DateTime semesterStart;
  final int totalWeeks;
  final int sectionCount;
  final String displayName;
  final SectionTimeSettings sectionTimeSettings;

  factory SemesterSettings.fromDate(DateTime date) {
    final termInfo = AcademicCalendar.resolve(date);
    return SemesterSettings(
      schoolYearStart: termInfo.schoolYearStart,
      semester: termInfo.semester,
      semesterStart: termInfo.semesterStart,
      totalWeeks: AcademicCalendar.maxWeek,
      sectionCount: defaultSectionCount,
    );
  }

  String get label {
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final semesterName = semester == 1 ? '第一学期' : '第二学期';
    return '$schoolYearStart-${schoolYearStart + 1}$semesterName';
  }

  int weekOf(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final rawWeek = normalized.difference(semesterStart).inDays ~/ 7 + 1;
    return rawWeek.clamp(1, totalWeeks);
  }

  DateTime weekStart(int week) {
    return semesterStart.add(Duration(days: (week - 1) * 7));
  }

  SemesterSettings copyWith({
    String? id,
    int? schoolYearStart,
    int? semester,
    DateTime? semesterStart,
    int? totalWeeks,
    int? sectionCount,
    String? displayName,
    SectionTimeSettings? sectionTimeSettings,
  }) {
    return SemesterSettings(
      id: id ?? this.id,
      schoolYearStart: schoolYearStart ?? this.schoolYearStart,
      semester: semester ?? this.semester,
      semesterStart: semesterStart ?? this.semesterStart,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      sectionCount: sectionCount ?? this.sectionCount,
      displayName: displayName ?? this.displayName,
      sectionTimeSettings: sectionTimeSettings ?? this.sectionTimeSettings,
    );
  }

  static String _defaultId(int schoolYearStart, int semester) {
    return '$schoolYearStart-$semester';
  }
}
