enum CourseColorScheme { pastel, highContrast, fixedByCourse }

enum CourseCardDensity { compact, standard }

enum CourseFontSize { small, medium, large }

class TimetableAppearanceSettings {
  const TimetableAppearanceSettings({
    required this.colorScheme,
    required this.showCourseName,
    required this.showClassroom,
    required this.showTeacher,
    required this.showWeekend,
    required this.density,
    required this.fontSize,
  });

  final CourseColorScheme colorScheme;
  final bool showCourseName;
  final bool showClassroom;
  final bool showTeacher;
  final bool showWeekend;
  final CourseCardDensity density;
  final CourseFontSize fontSize;

  factory TimetableAppearanceSettings.defaults() {
    return const TimetableAppearanceSettings(
      colorScheme: CourseColorScheme.fixedByCourse,
      showCourseName: true,
      showClassroom: true,
      showTeacher: true,
      showWeekend: true,
      density: CourseCardDensity.standard,
      fontSize: CourseFontSize.medium,
    );
  }

  factory TimetableAppearanceSettings.fromJson(Map<String, dynamic> json) {
    final fallback = TimetableAppearanceSettings.defaults();
    return TimetableAppearanceSettings(
      colorScheme: _enumFromName(
        CourseColorScheme.values,
        json['colorScheme'],
        fallback.colorScheme,
      ),
      showCourseName: _boolValue(
        json['showCourseName'],
        fallback.showCourseName,
      ),
      showClassroom: _boolValue(json['showClassroom'], fallback.showClassroom),
      showTeacher: _boolValue(json['showTeacher'], fallback.showTeacher),
      showWeekend: _boolValue(json['showWeekend'], fallback.showWeekend),
      density: _enumFromName(
        CourseCardDensity.values,
        json['density'],
        fallback.density,
      ),
      fontSize: _enumFromName(
        CourseFontSize.values,
        json['fontSize'],
        fallback.fontSize,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'colorScheme': colorScheme.name,
      'showCourseName': showCourseName,
      'showClassroom': showClassroom,
      'showTeacher': showTeacher,
      'showWeekend': showWeekend,
      'density': density.name,
      'fontSize': fontSize.name,
    };
  }

  TimetableAppearanceSettings copyWith({
    CourseColorScheme? colorScheme,
    bool? showCourseName,
    bool? showClassroom,
    bool? showTeacher,
    bool? showWeekend,
    CourseCardDensity? density,
    CourseFontSize? fontSize,
  }) {
    return TimetableAppearanceSettings(
      colorScheme: colorScheme ?? this.colorScheme,
      showCourseName: showCourseName ?? this.showCourseName,
      showClassroom: showClassroom ?? this.showClassroom,
      showTeacher: showTeacher ?? this.showTeacher,
      showWeekend: showWeekend ?? this.showWeekend,
      density: density ?? this.density,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, Object? rawValue, T fallback) {
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

bool _boolValue(Object? rawValue, bool fallback) {
  return rawValue is bool ? rawValue : fallback;
}
