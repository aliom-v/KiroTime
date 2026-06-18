import 'timetable_json_codec.dart';

class TimetableFileNaming {
  TimetableFileNaming._();

  static String defaultExportFileName({
    required TimetableExportScope scope,
    required String semesterLabel,
    required DateTime now,
  }) {
    final date = _dateStamp(now);
    final time = _timeStamp(now);
    final rawName = switch (scope) {
      TimetableExportScope.currentSemester =>
        'KiroTime_当前学期_${semesterLabel}_${date}_$time.json',
      TimetableExportScope.allSemesters => 'KiroTime_全部学期_${date}_$time.json',
    };
    return sanitizeJsonFileName(rawName);
  }

  static String sanitizeJsonFileName(String input) {
    var name = input.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (name.toLowerCase().endsWith('.json')) {
      name = name.substring(0, name.length - 5);
    }
    name = name.trim();
    if (name.isEmpty || name.replaceAll('_', '').trim().isEmpty) {
      name = 'KiroTime_课表备份';
    }
    return '$name.json';
  }

  static String copyNameFor(String fileName, Set<String> existingNames) {
    final sanitized = sanitizeJsonFileName(fileName);
    if (!existingNames.contains(sanitized)) {
      return sanitized;
    }

    final baseName = sanitized.substring(0, sanitized.length - 5);
    var suffix = 2;
    while (existingNames.contains('${baseName}_$suffix.json')) {
      suffix++;
    }
    return '${baseName}_$suffix.json';
  }

  static String _dateStamp(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  static String _timeStamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
