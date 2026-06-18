class AcademicTermInfo {
  const AcademicTermInfo({
    required this.schoolYearStart,
    required this.semester,
    required this.semesterStart,
    required this.currentWeek,
  });

  final int schoolYearStart;
  final int semester;
  final DateTime semesterStart;
  final int currentWeek;

  String get label {
    final semesterName = semester == 1 ? '第一学期' : '第二学期';
    return '$schoolYearStart-${schoolYearStart + 1}$semesterName';
  }

  DateTime weekStart(int week) {
    return semesterStart.add(Duration(days: (week - 1) * 7));
  }
}

class AcademicCalendar {
  AcademicCalendar._();

  static const int maxWeek = 24;

  static AcademicTermInfo resolve(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final bool fallTerm = normalized.month >= 9;
    final semesterStart = _firstMonday(
      DateTime(normalized.year, fallTerm ? 9 : 3),
    );
    final rawWeek = normalized.difference(semesterStart).inDays ~/ 7 + 1;

    return AcademicTermInfo(
      schoolYearStart: fallTerm ? normalized.year : normalized.year - 1,
      semester: fallTerm ? 1 : 2,
      semesterStart: semesterStart,
      currentWeek: rawWeek.clamp(1, maxWeek),
    );
  }

  static DateTime _firstMonday(DateTime monthStart) {
    final offset = (DateTime.monday - monthStart.weekday) % 7;
    return DateTime(monthStart.year, monthStart.month, monthStart.day + offset);
  }
}
