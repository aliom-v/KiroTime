import 'section_time_settings.dart';

/// 常见高校上课时间模板。
///
/// 导入的课程只保存"第几节"，真正显示的时钟时间来自学期的时间设置。
/// 不同学校上下课时间差异很大，这里提供几套常见模板可一键套用，
/// 避免 imported 课程显示的时间与现实不符。
class SectionTimePreset {
  const SectionTimePreset({
    required this.id,
    required this.name,
    required this.note,
    required this.morningStart,
    required this.afternoonStart,
    required this.eveningStart,
    required this.durationMinutes,
    required this.shortBreakMinutes,
    this.morningLongBreakAfter = 2,
    this.afternoonLongBreakAfter = 6,
    required this.longBreakMinutes,
  });

  final String id;
  final String name;
  final String note;
  final String morningStart;
  final String afternoonStart;
  final String eveningStart;
  final int durationMinutes;
  final int shortBreakMinutes;
  final int morningLongBreakAfter;
  final int afternoonLongBreakAfter;
  final int longBreakMinutes;

  /// 按给定的每日节数生成时间设置（沿用 4 上午 / 4 下午 / 其余晚上 的常见切分）。
  SectionTimeSettings build(int sectionCount) {
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
            startMinutes: SectionTimeSettings.parseClockText(morningStart)!,
            sectionDurationMinutes: durationMinutes,
            breakMinutes: shortBreakMinutes,
            longBreakEnabled: morningCount > 2,
            longBreakAfterSection: morningLongBreakAfter,
            longBreakMinutes: longBreakMinutes,
          ),
        if (afternoonCount > 0)
          DayPartTimeRule(
            name: '下午',
            startSection: 5,
            sectionCount: afternoonCount,
            startMinutes: SectionTimeSettings.parseClockText(afternoonStart)!,
            sectionDurationMinutes: durationMinutes,
            breakMinutes: shortBreakMinutes,
            longBreakEnabled: afternoonCount > 2,
            longBreakAfterSection: afternoonLongBreakAfter,
            longBreakMinutes: longBreakMinutes,
          ),
        if (eveningCount > 0)
          DayPartTimeRule(
            name: '晚上',
            startSection: 9,
            sectionCount: eveningCount,
            startMinutes: SectionTimeSettings.parseClockText(eveningStart)!,
            sectionDurationMinutes: durationMinutes,
            breakMinutes: shortBreakMinutes,
            longBreakEnabled: false,
            longBreakAfterSection: 0,
            longBreakMinutes: 0,
          ),
      ],
    );
  }
}

abstract final class SectionTimePresets {
  static const List<SectionTimePreset> catalog = <SectionTimePreset>[
    SectionTimePreset(
      id: 'std8',
      name: '标准 8:00',
      note: '上午 8:00 起 · 45 分钟',
      morningStart: '08:00',
      afternoonStart: '14:00',
      eveningStart: '19:00',
      durationMinutes: 45,
      shortBreakMinutes: 10,
      longBreakMinutes: 20,
    ),
    SectionTimePreset(
      id: 'std810',
      name: '标准 8:10',
      note: '上午 8:10 起 · 45 分钟',
      morningStart: '08:10',
      afternoonStart: '14:10',
      eveningStart: '19:00',
      durationMinutes: 45,
      shortBreakMinutes: 10,
      longBreakMinutes: 20,
    ),
    SectionTimePreset(
      id: 'small40',
      name: '小课 8:00',
      note: '上午 8:00 起 · 40 分钟',
      morningStart: '08:00',
      afternoonStart: '13:30',
      eveningStart: '18:30',
      durationMinutes: 40,
      shortBreakMinutes: 10,
      longBreakMinutes: 15,
    ),
    SectionTimePreset(
      id: 'big50',
      name: '大课 8:00',
      note: '上午 8:00 起 · 50 分钟',
      morningStart: '08:00',
      afternoonStart: '14:30',
      eveningStart: '19:30',
      durationMinutes: 50,
      shortBreakMinutes: 10,
      longBreakMinutes: 20,
    ),
  ];
}
