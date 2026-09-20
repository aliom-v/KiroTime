import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/timetable/domain/section_time_presets.dart';
import 'package:kiro_time/features/timetable/domain/section_time_settings.dart';

void main() {
  group('SectionTimeSettings', () {
    test('generates the default ten-section three-part timetable', () {
      final settings = SectionTimeSettings.defaultForSectionCount(10);

      expect(settings.sections, hasLength(10));
      expect(settings.section(1).timeRangeText, '08:10-08:55');
      expect(settings.section(2).timeRangeText, '09:05-09:50');
      expect(settings.section(3).timeRangeText, '10:10-10:55');
      expect(settings.section(5).timeRangeText, '14:10-14:55');
      expect(settings.section(9).timeRangeText, '19:00-19:45');
      expect(settings.section(10).timeRangeText, '19:55-20:40');
      expect(settings.rangeText(1, 2), '08:10-09:50');
    });

    test('generates day parts with optional long breaks', () {
      final settings = SectionTimeSettings.generate(
        sectionCount: 6,
        rules: const <DayPartTimeRule>[
          DayPartTimeRule(
            name: '上午',
            startSection: 1,
            sectionCount: 4,
            startMinutes: 8 * 60,
            sectionDurationMinutes: 40,
            breakMinutes: 5,
            longBreakEnabled: true,
            longBreakAfterSection: 2,
            longBreakMinutes: 20,
          ),
          DayPartTimeRule(
            name: '下午',
            startSection: 5,
            sectionCount: 2,
            startMinutes: 14 * 60,
            sectionDurationMinutes: 45,
            breakMinutes: 10,
            longBreakEnabled: false,
            longBreakAfterSection: 0,
            longBreakMinutes: 0,
          ),
        ],
      );

      expect(settings.section(1).timeRangeText, '08:00-08:40');
      expect(settings.section(2).timeRangeText, '08:45-09:25');
      expect(settings.section(3).timeRangeText, '09:45-10:25');
      expect(settings.section(4).timeRangeText, '10:30-11:10');
      expect(settings.section(5).timeRangeText, '14:00-14:45');
      expect(settings.section(6).timeRangeText, '14:55-15:40');
    });

    test(
      'keeps existing times and appends generated sections when expanded',
      () {
        final settings = SectionTimeSettings.defaultForSectionCount(10)
            .replaceSection(
              const SectionTime(
                section: 10,
                startMinutes: 21 * 60,
                endMinutes: 1325,
              ),
            );

        final expanded = settings.ensureSectionCount(12);

        expect(expanded.sections, hasLength(12));
        expect(expanded.section(10).timeRangeText, '21:00-22:05');
        expect(expanded.section(11).timeRangeText, '22:15-23:00');
        expect(expanded.section(12).timeRangeText, '23:10-23:55');
      },
    );

    test('trims extra sections when section count is reduced', () {
      final settings = SectionTimeSettings.defaultForSectionCount(12);

      final reduced = settings.ensureSectionCount(8);

      expect(reduced.sections.map((item) => item.section), <int>[
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
      ]);
    });

    test('round-trips through json and ignores invalid records', () {
      final settings = SectionTimeSettings.defaultForSectionCount(10)
          .replaceSection(
            const SectionTime(
              section: 1,
              startMinutes: 7 * 60,
              endMinutes: 465,
            ),
          );

      final decoded = SectionTimeSettings.fromJson(<String, dynamic>{
        'sections': <Object?>[
          ...settings.toJson()['sections'] as List<Object?>,
          <String, Object?>{'section': 0, 'startMinutes': 1, 'endMinutes': 2},
          <String, Object?>{
            'section': 3,
            'startMinutes': 700,
            'endMinutes': 650,
          },
        ],
      }, sectionCount: 10);

      expect(decoded.sections, hasLength(10));
      expect(decoded.section(1).timeRangeText, '07:00-07:45');
      expect(decoded.section(2).timeRangeText, '09:05-09:50');
    });

    test('parses and formats minute-of-day text', () {
      expect(SectionTimeSettings.parseClockText('08:05'), 485);
      expect(SectionTimeSettings.formatMinutes(485), '08:05');
      expect(SectionTimeSettings.formatMinutes(24 * 60 + 15), '00:15');
      expect(SectionTimeSettings.parseClockText('25:99'), isNull);
      expect(SectionTimeSettings.parseClockText('abc'), isNull);
    });
  });

  group('SectionTimePresets', () {
    test(
      'builds a complete 8:00 schedule for the configured section count',
      () {
        final settings = SectionTimePresets.catalog.first.build(10);

        expect(settings.sections, hasLength(10));
        expect(settings.section(1).timeRangeText, '08:00-08:45');
        expect(settings.section(3).timeRangeText, '10:00-10:45');
        expect(settings.section(5).timeRangeText, '14:00-14:45');
        expect(settings.section(9).timeRangeText, '19:00-19:45');
      },
    );

    test('does not generate sections beyond the semester configuration', () {
      final settings = SectionTimePresets.catalog.last.build(8);

      expect(settings.sections, hasLength(8));
      expect(
        settings.sections.map((section) => section.section),
        orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7, 8]),
      );
    });
  });
}
