import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/settings/domain/import_preferences.dart';
import 'package:kiro_time/features/settings/domain/timetable_appearance_settings.dart';

void main() {
  test('appearance settings round-trip from json with defaults', () {
    final settings = TimetableAppearanceSettings.defaults().copyWith(
      colorScheme: CourseColorScheme.highContrast,
      showWeekend: false,
      density: CourseCardDensity.compact,
      fontSize: CourseFontSize.large,
      showTeacher: false,
    );

    final decoded = TimetableAppearanceSettings.fromJson(settings.toJson());

    expect(decoded.colorScheme, CourseColorScheme.highContrast);
    expect(decoded.showWeekend, isFalse);
    expect(decoded.density, CourseCardDensity.compact);
    expect(decoded.fontSize, CourseFontSize.large);
    expect(decoded.showCourseName, isTrue);
    expect(decoded.showClassroom, isTrue);
    expect(decoded.showTeacher, isFalse);
  });

  test('import preferences expose effective user agent', () {
    final mobile = ImportPreferences.defaults();
    final desktop = mobile.copyWith(userAgentMode: UserAgentMode.desktop);
    final custom = mobile.copyWith(
      userAgentMode: UserAgentMode.custom,
      customUserAgent: 'Custom UA',
    );

    expect(mobile.effectiveUserAgent, contains('Mobile'));
    expect(desktop.effectiveUserAgent, contains('Windows NT'));
    expect(custom.effectiveUserAgent, 'Custom UA');
    expect(
      ImportPreferences.fromJson(custom.toJson()).effectiveUserAgent,
      'Custom UA',
    );
  });

  test('import preferences preserve pinned academic URLs', () {
    final preferences = ImportPreferences.defaults().copyWith(
      academicSystemUrl: 'https://jw.example.edu.cn',
      savedAcademicUrls: const <String>[
        'https://jw.example.edu.cn',
        'https://portal.example.edu.cn',
      ],
    );

    final decoded = ImportPreferences.fromJson(preferences.toJson());

    expect(decoded.academicSystemUrl, 'https://jw.example.edu.cn');
    expect(decoded.savedAcademicUrls, <String>[
      'https://jw.example.edu.cn',
      'https://portal.example.edu.cn',
    ]);
  });

  test(
    'import preferences migrate legacy urls and preserve bookmark names',
    () {
      final decoded = ImportPreferences.fromJson(<String, dynamic>{
        'savedAcademicUrls': <Object>[
          'https://jw.example.edu.cn/path#fragment',
          <String, dynamic>{
            'name': '研究生教务',
            'url': 'https://graduate.example.edu.cn/',
          },
          'ftp://invalid.example.edu.cn',
          'https://jw.example.edu.cn/path',
        ],
      });

      expect(decoded.savedAcademicUrls, <String>[
        'https://jw.example.edu.cn/path',
        'https://graduate.example.edu.cn/',
      ]);
      expect(
        decoded.savedAcademicUrlBookmarks.map((item) => item.displayName),
        <String>['jw.example.edu.cn', '研究生教务'],
      );

      final roundTrip = ImportPreferences.fromJson(decoded.toJson());
      expect(roundTrip.savedAcademicUrlBookmarks[1].name, '研究生教务');
    },
  );

  test('import preferences default to private import behavior', () {
    final defaults = ImportPreferences.defaults();

    expect(defaults.academicSystemUrl, isEmpty);
    expect(defaults.savedAcademicUrls, isEmpty);
    expect(defaults.semesterApiPath, isEmpty);
    expect(defaults.keepWebViewLoginState, isFalse);
    expect(defaults.keepHtmlDiagnostics, isFalse);
  });
}
