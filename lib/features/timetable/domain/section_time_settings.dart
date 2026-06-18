class SectionTime {
  const SectionTime({
    required this.section,
    required this.startMinutes,
    required this.endMinutes,
  });

  final int section;
  final int startMinutes;
  final int endMinutes;

  String get startText => SectionTimeSettings.formatMinutes(startMinutes);
  String get endText => SectionTimeSettings.formatMinutes(endMinutes);
  String get timeRangeText => '$startText-$endText';

  bool get isValid => section > 0 && endMinutes > startMinutes;

  Map<String, int> toJson() {
    return <String, int>{
      'section': section,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
    };
  }

  static SectionTime? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final section = _intValue(value['section']);
    final startMinutes = _intValue(value['startMinutes']);
    final endMinutes = _intValue(value['endMinutes']);
    if (section == null || startMinutes == null || endMinutes == null) {
      return null;
    }
    final sectionTime = SectionTime(
      section: section,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
    return sectionTime.isValid ? sectionTime : null;
  }

  static int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}

class DayPartTimeRule {
  const DayPartTimeRule({
    required this.name,
    required this.startSection,
    required this.sectionCount,
    required this.startMinutes,
    required this.sectionDurationMinutes,
    required this.breakMinutes,
    required this.longBreakEnabled,
    required this.longBreakAfterSection,
    required this.longBreakMinutes,
  });

  final String name;
  final int startSection;
  final int sectionCount;
  final int startMinutes;
  final int sectionDurationMinutes;
  final int breakMinutes;
  final bool longBreakEnabled;
  final int longBreakAfterSection;
  final int longBreakMinutes;

  Map<String, Object> toJson() {
    return <String, Object>{
      'name': name,
      'startSection': startSection,
      'sectionCount': sectionCount,
      'startMinutes': startMinutes,
      'sectionDurationMinutes': sectionDurationMinutes,
      'breakMinutes': breakMinutes,
      'longBreakEnabled': longBreakEnabled,
      'longBreakAfterSection': longBreakAfterSection,
      'longBreakMinutes': longBreakMinutes,
    };
  }
}

class SectionTimeSettings {
  const SectionTimeSettings._(this.sections);

  static const int defaultSectionDurationMinutes = 45;
  static const int defaultBreakMinutes = 10;

  final List<SectionTime> sections;

  factory SectionTimeSettings(List<SectionTime> sections) {
    final bySection = <int, SectionTime>{};
    for (final sectionTime in sections) {
      if (sectionTime.isValid) {
        bySection[sectionTime.section] = sectionTime;
      }
    }
    final normalized = bySection.values.toList(growable: false)
      ..sort((SectionTime a, SectionTime b) => a.section.compareTo(b.section));
    return SectionTimeSettings._(normalized);
  }

  factory SectionTimeSettings.defaultForSectionCount(int sectionCount) {
    final morningCount = sectionCount.clamp(0, 4);
    final afternoonCount = (sectionCount - 4).clamp(0, 4);
    final eveningCount = (sectionCount - 8).clamp(0, 8);
    return SectionTimeSettings.generate(
      sectionCount: sectionCount,
      rules: <DayPartTimeRule>[
        if (morningCount > 0)
          DayPartTimeRule(
            name: '上午',
            startSection: 1,
            sectionCount: morningCount,
            startMinutes: parseClockText('08:10')!,
            sectionDurationMinutes: defaultSectionDurationMinutes,
            breakMinutes: defaultBreakMinutes,
            longBreakEnabled: morningCount > 2,
            longBreakAfterSection: 2,
            longBreakMinutes: 20,
          ),
        if (afternoonCount > 0)
          DayPartTimeRule(
            name: '下午',
            startSection: 5,
            sectionCount: afternoonCount,
            startMinutes: parseClockText('14:10')!,
            sectionDurationMinutes: defaultSectionDurationMinutes,
            breakMinutes: defaultBreakMinutes,
            longBreakEnabled: afternoonCount > 2,
            longBreakAfterSection: 6,
            longBreakMinutes: 20,
          ),
        if (eveningCount > 0)
          DayPartTimeRule(
            name: '晚上',
            startSection: 9,
            sectionCount: eveningCount,
            startMinutes: parseClockText('19:00')!,
            sectionDurationMinutes: defaultSectionDurationMinutes,
            breakMinutes: defaultBreakMinutes,
            longBreakEnabled: false,
            longBreakAfterSection: 0,
            longBreakMinutes: 0,
          ),
      ],
    );
  }

  factory SectionTimeSettings.generate({
    required int sectionCount,
    required List<DayPartTimeRule> rules,
  }) {
    final generated = <SectionTime>[];
    for (final rule in rules) {
      if (rule.sectionCount <= 0 ||
          rule.startSection <= 0 ||
          rule.sectionDurationMinutes <= 0) {
        continue;
      }
      var cursor = rule.startMinutes;
      for (var offset = 0; offset < rule.sectionCount; offset++) {
        final section = rule.startSection + offset;
        if (section < 1 || section > sectionCount) {
          cursor += rule.sectionDurationMinutes + rule.breakMinutes;
          continue;
        }
        final end = cursor + rule.sectionDurationMinutes;
        generated.add(
          SectionTime(section: section, startMinutes: cursor, endMinutes: end),
        );
        if (offset < rule.sectionCount - 1) {
          final afterSection = section;
          final breakMinutes =
              rule.longBreakEnabled &&
                  rule.longBreakAfterSection == afterSection
              ? rule.longBreakMinutes
              : rule.breakMinutes;
          cursor = end + breakMinutes;
        }
      }
    }
    return SectionTimeSettings(
      generated,
    )._fillMissingSections(sectionCount: sectionCount);
  }

  factory SectionTimeSettings.fromJson(
    Map<String, dynamic> json, {
    required int sectionCount,
  }) {
    final rawSections = json['sections'];
    if (rawSections is! List) {
      return SectionTimeSettings.defaultForSectionCount(sectionCount);
    }
    return SectionTimeSettings(
      rawSections
          .map(SectionTime.fromJson)
          .whereType<SectionTime>()
          .toList(growable: false),
    )._fillMissingSections(sectionCount: sectionCount);
  }

  SectionTime section(int section) {
    for (final sectionTime in sections) {
      if (sectionTime.section == section) {
        return sectionTime;
      }
    }
    return SectionTimeSettings.defaultForSectionCount(section).sections.last;
  }

  SectionTimeSettings ensureSectionCount(int sectionCount) {
    final retained = sections
        .where((SectionTime item) => item.section <= sectionCount)
        .toList(growable: false);
    return SectionTimeSettings(
      retained,
    )._fillMissingSections(sectionCount: sectionCount);
  }

  SectionTimeSettings replaceSection(SectionTime sectionTime) {
    return SectionTimeSettings(<SectionTime>[
      for (final item in sections)
        if (item.section != sectionTime.section) item,
      sectionTime,
    ]);
  }

  String rangeText(int startSection, int endSection) {
    final start = section(startSection);
    final end = section(endSection < startSection ? startSection : endSection);
    return '${start.startText}-${end.endText}';
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'sections': sections.map((SectionTime item) => item.toJson()).toList(),
    };
  }

  SectionTimeSettings _fillMissingSections({required int sectionCount}) {
    if (sectionCount <= 0) {
      return const SectionTimeSettings._(<SectionTime>[]);
    }
    final bySection = <int, SectionTime>{
      for (final item in sections)
        if (item.section >= 1 && item.section <= sectionCount)
          item.section: item,
    };
    for (var section = 1; section <= sectionCount; section++) {
      if (bySection.containsKey(section)) {
        continue;
      }
      final previous = bySection[section - 1];
      if (previous == null) {
        final defaultSection = SectionTimeSettings.defaultForSectionCount(
          section,
        ).section(section);
        bySection[section] = defaultSection;
      } else {
        final start = previous.endMinutes + defaultBreakMinutes;
        bySection[section] = SectionTime(
          section: section,
          startMinutes: start,
          endMinutes: start + defaultSectionDurationMinutes,
        );
      }
    }
    final normalized = bySection.values.toList(growable: false)
      ..sort((SectionTime a, SectionTime b) => a.section.compareTo(b.section));
    return SectionTimeSettings._(normalized);
  }

  static int? parseClockText(String text) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
    if (match == null) {
      return null;
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  static String formatMinutes(int minutes) {
    final normalized = minutes % (24 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
