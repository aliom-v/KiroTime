import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../courses/data/course_schedule_edit.dart';
import '../../courses/domain/course_week_text.dart';
import '../../import/presentation/course_import_page.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/timetable_appearance_settings.dart';
import '../../../ui/glass.dart';
import '../../settings/presentation/settings_center_dialog.dart';
import '../application/timetable_providers.dart';
import '../domain/semester_settings.dart';
import '../domain/section_time_settings.dart';
import '../domain/timetable_layout.dart';

final _weekTransitionDirectionProvider = StateProvider<int>((ref) => 1);

class TimetablePage extends ConsumerWidget {
  const TimetablePage({super.key});

  static const double _timeColumnWidth = 44;
  static const double _minSectionHeight = 58;
  static const double _cardGap = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeek = ref.watch(currentWeekProvider);
    final weekTransitionDirection = ref.watch(_weekTransitionDirectionProvider);
    final visibleItemsAsync = ref.watch(timetableVisibleItemsProvider);
    final semesterSettings = ref.watch(semesterSettingsProvider);
    final appearance = ref.watch(timetableAppearanceSettingsProvider);
    ref.watch(settingsBootstrapProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: KiroCanvas()),
            Column(
              children: <Widget>[
                Expanded(
                  child: visibleItemsAsync.when(
                    data: (visibleItems) => _WeekTransition(
                      direction: weekTransitionDirection,
                      child: _WeekContent(
                        key: ValueKey<String>('week-content-$currentWeek'),
                        currentWeek: currentWeek,
                        semesterSettings: semesterSettings,
                        appearance: appearance,
                        visibleItems: visibleItems,
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => _LoadError(error: error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekTransition extends StatelessWidget {
  const _WeekTransition({required this.direction, required this.child});

  final int direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: Offset(direction * 0.045, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: child,
    );
  }
}

class _WeekContent extends ConsumerWidget {
  const _WeekContent({
    super.key,
    required this.currentWeek,
    required this.semesterSettings,
    required this.appearance,
    required this.visibleItems,
  });

  final int currentWeek;
  final SemesterSettings semesterSettings;
  final TimetableAppearanceSettings appearance;
  final List<TimetableVisibleItem> visibleItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = semesterSettings.weekStart(currentWeek);
    final today = DateTime.now();
    return Column(
      children: <Widget>[
        _TermHeader(
          currentWeek: currentWeek,
          semesterSettings: semesterSettings,
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              _handleWeekSwipe(
                ref: ref,
                velocity: details.primaryVelocity ?? 0,
                currentWeek: currentWeek,
                totalWeeks: semesterSettings.totalWeeks,
              );
            },
            child: _TimetableBoard(
              visibleItems: visibleItems,
              configuredSectionCount: semesterSettings.sectionCount,
              sectionTimeSettings: semesterSettings.sectionTimeSettings,
              appearance: appearance,
              weekStart: weekStart,
              today: today,
            ),
          ),
        ),
      ],
    );
  }
}

void _handleWeekSwipe({
  required WidgetRef ref,
  required double velocity,
  required int currentWeek,
  required int totalWeeks,
}) {
  const threshold = 240.0;
  if (velocity <= -threshold && currentWeek < totalWeeks) {
    ref.read(_weekTransitionDirectionProvider.notifier).state = 1;
    ref.read(currentWeekProvider.notifier).state = currentWeek + 1;
  }
  if (velocity >= threshold && currentWeek > 1) {
    ref.read(_weekTransitionDirectionProvider.notifier).state = -1;
    ref.read(currentWeekProvider.notifier).state = currentWeek - 1;
  }
}

void _setCurrentWeek({
  required WidgetRef ref,
  required int week,
  required int direction,
}) {
  ref.read(_weekTransitionDirectionProvider.notifier).state = direction;
  ref.read(currentWeekProvider.notifier).state = week;
}

class _TermHeader extends ConsumerWidget {
  const _TermHeader({
    required this.currentWeek,
    required this.semesterSettings,
  });

  final int currentWeek;
  final SemesterSettings semesterSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GlassPanel(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showSemesterSettings(context),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: KiroPalette.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          semesterSettings.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: KiroPalette.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.unfold_more_rounded,
                        size: 16,
                        color: KiroPalette.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.add_rounded,
                tooltip: '新增课程',
                size: 36,
                filled: true,
                onPressed: () => _showCourseEditor(context, placement: null),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.file_upload_outlined,
                tooltip: '导入课表',
                size: 36,
                onPressed: () => _openImportPage(context),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.settings_outlined,
                tooltip: '课表设置',
                size: 36,
                onPressed: () => _showSemesterSettings(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: _WeekStepper(
              currentWeek: currentWeek,
              totalWeeks: semesterSettings.totalWeeks,
              onPrevious: currentWeek <= 1
                  ? null
                  : () => _setCurrentWeek(
                      ref: ref,
                      week: currentWeek - 1,
                      direction: -1,
                    ),
              onNext: currentWeek >= semesterSettings.totalWeeks
                  ? null
                  : () => _setCurrentWeek(
                      ref: ref,
                      week: currentWeek + 1,
                      direction: 1,
                    ),
              onWeekTap: () => _showWeekPicker(
                context,
                ref: ref,
                currentWeek: currentWeek,
                totalWeeks: semesterSettings.totalWeeks,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStepper extends StatelessWidget {
  const _WeekStepper({
    required this.currentWeek,
    required this.totalWeeks,
    required this.onPrevious,
    required this.onNext,
    required this.onWeekTap,
  });

  final int currentWeek;
  final int totalWeeks;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onWeekTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KiroPalette.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _CompactIconButton(
            tooltip: '上一周',
            icon: Icons.chevron_left_rounded,
            onPressed: onPrevious,
          ),
          Tooltip(
            message: '选择周数',
            child: Semantics(
              button: true,
              label: '选择周数',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onWeekTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 88,
                    minHeight: 36,
                  ),
                  child: Center(
                    child: Text(
                      '第$currentWeek周',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF14332F),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _CompactIconButton(
            tooltip: '下一周',
            icon: Icons.chevron_right_rounded,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow({
    required this.dayCount,
    required this.weekStart,
    required this.today,
  });

  static const List<String> _labels = <String>[
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '日',
  ];

  final int dayCount;
  final DateTime weekStart;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      // Header labels are fixed-size chrome: they must survive large text
      // scaling without overflowing the 46pt board header band.
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          border: const Border(
            bottom: BorderSide(color: KiroPalette.separator),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: TimetablePage._timeColumnWidth,
              child: Center(
                child: Text(
                  '${weekStart.month}月',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: KiroPalette.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            for (var index = 0; index < dayCount; index++)
              Expanded(
                child: _DateHeaderCell(
                  dayOfWeek: index + 1,
                  weekday: _labels[index],
                  date: weekStart.add(Duration(days: index)),
                  today: today,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateHeaderCell extends StatelessWidget {
  const _DateHeaderCell({
    required this.dayOfWeek,
    required this.weekday,
    required this.date,
    required this.today,
  });

  final int dayOfWeek;
  final String weekday;
  final DateTime date;
  final DateTime today;

  bool get _isToday =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;

  @override
  Widget build(BuildContext context) {
    final dayColor = _isToday
        ? KiroPalette.textPrimary
        : KiroPalette.textTertiary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          weekday,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isToday ? KiroPalette.todayAccent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${date.day}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: dayColor,
              fontWeight: _isToday ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

void _showSemesterSettings(BuildContext context) {
  showKiroDialog<void>(context: context, child: const SettingsCenterDialog());
}

Future<void> _showWeekPicker(
  BuildContext context, {
  required WidgetRef ref,
  required int currentWeek,
  required int totalWeeks,
}) async {
  final selectedWeek = await showKiroDialog<int>(
    context: context,
    child: _WeekPickerDialog(currentWeek: currentWeek, totalWeeks: totalWeeks),
  );
  if (selectedWeek == null || selectedWeek == currentWeek) {
    return;
  }
  _setCurrentWeek(
    ref: ref,
    week: selectedWeek,
    direction: selectedWeek > currentWeek ? 1 : -1,
  );
}

class _WeekPickerDialog extends StatefulWidget {
  const _WeekPickerDialog({
    required this.currentWeek,
    required this.totalWeeks,
  });

  final int currentWeek;
  final int totalWeeks;

  @override
  State<_WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<_WeekPickerDialog> {
  late int _selectedWeek = widget.currentWeek;

  @override
  Widget build(BuildContext context) {
    return _KiroDialogScaffold(
      title: '选择周数',
      subtitle: '只切换当前显示周，不进入完整设置',
      body: SizedBox(
        height: 240,
        child: ListWheelScrollView.useDelegate(
          controller: FixedExtentScrollController(
            initialItem: (widget.currentWeek - 1).clamp(
              0,
              widget.totalWeeks - 1,
            ),
          ),
          itemExtent: 44,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() => _selectedWeek = index + 1);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.totalWeeks,
            builder: (context, index) {
              final week = index + 1;
              final selected = week == _selectedWeek;
              return Center(
                child: DecoratedBox(
                  key: selected
                      ? ValueKey<String>('wheel-selected-week-$week')
                      : ValueKey<String>('wheel-week-$week'),
                  decoration: BoxDecoration(
                    color: selected
                        ? KiroPalette.todayAccent.withValues(alpha: 0.55)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 6,
                    ),
                    child: Text(
                      '第$week周',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: selected ? 18 : 15,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: selected
                            ? KiroPalette.textPrimary
                            : KiroPalette.textTertiary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedWeek),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: KiroPalette.textPrimary,
        disabledForegroundColor: KiroPalette.textTertiary,
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _TimetableBoard extends StatelessWidget {
  const _TimetableBoard({
    required this.visibleItems,
    required this.configuredSectionCount,
    required this.sectionTimeSettings,
    required this.appearance,
    required this.weekStart,
    required this.today,
  });

  static const double _bottomGap = 12;
  static const double _headerHeight = 46;

  final List<TimetableVisibleItem> visibleItems;
  final int configuredSectionCount;
  final SectionTimeSettings sectionTimeSettings;
  final TimetableAppearanceSettings appearance;
  final DateTime weekStart;
  final DateTime today;

  int get _renderSectionCount {
    final maxScheduleSection = visibleItems.fold<int>(
      configuredSectionCount,
      (maxSection, item) => item.startSlot + item.slotSpan > maxSection
          ? item.startSlot + item.slotSpan
          : maxSection,
    );
    return maxScheduleSection.clamp(
      SemesterSettings.minSectionCount,
      SemesterSettings.maxSectionCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayCount = appearance.showWeekend ? 7 : 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: _headerHeight,
          child: _WeekdayHeaderRow(
            dayCount: dayCount,
            weekStart: weekStart,
            today: today,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final renderSectionCount = _renderSectionCount;
              final sectionHeight = _resolveSectionHeight(
                availableHeight: constraints.maxHeight,
                renderSectionCount: renderSectionCount,
              );
              final gridHeight = sectionHeight * renderSectionCount;
              final boardWidth = constraints.maxWidth;
              final filteredItems = visibleItems
                  .where((item) => item.dayColumn < dayCount)
                  .toList(growable: false);
              final dayColumnWidth =
                  (boardWidth - TimetablePage._timeColumnWidth) / dayCount;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, _bottomGap),
                child: Container(
                  width: boardWidth,
                  height: gridHeight,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: <Widget>[
                      _GridBackground(
                        dayColumnWidth: dayColumnWidth,
                        dayCount: dayCount,
                        sectionCount: renderSectionCount,
                        sectionHeight: sectionHeight,
                        sectionTimeSettings: sectionTimeSettings
                            .ensureSectionCount(renderSectionCount),
                      ),
                      for (final item in filteredItems)
                        _PositionedVisibleItem(
                          item: item,
                          dayColumnWidth: dayColumnWidth,
                          sectionHeight: sectionHeight,
                          appearance: appearance,
                        ),
                      if (filteredItems.isEmpty) const _EmptyWeekHint(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double _resolveSectionHeight({
    required double availableHeight,
    required int renderSectionCount,
  }) {
    final visibleSections =
        renderSectionCount < SemesterSettings.defaultSectionCount
        ? renderSectionCount
        : SemesterSettings.defaultSectionCount;
    final targetGridHeight = availableHeight - _bottomGap;
    if (targetGridHeight <= 0) {
      return TimetablePage._minSectionHeight;
    }
    final fittedHeight = targetGridHeight / visibleSections;
    return fittedHeight < TimetablePage._minSectionHeight
        ? TimetablePage._minSectionHeight
        : fittedHeight;
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground({
    required this.dayColumnWidth,
    required this.dayCount,
    required this.sectionCount,
    required this.sectionHeight,
    required this.sectionTimeSettings,
  });

  final double dayColumnWidth;
  final int dayCount;
  final int sectionCount;
  final double sectionHeight;
  final SectionTimeSettings sectionTimeSettings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        for (var section = 1; section <= sectionCount; section++)
          Positioned(
            left: 0,
            width: TimetablePage._timeColumnWidth,
            top: (section - 1) * sectionHeight,
            height: sectionHeight,
            child: _SectionTimeCell(
              sectionTime: sectionTimeSettings.section(section),
            ),
          ),
        for (var day = 0; day <= dayCount; day++)
          Positioned(
            left: TimetablePage._timeColumnWidth + day * dayColumnWidth,
            top: 0,
            bottom: 0,
            child: const _VerticalSeparator(),
          ),
        for (var section = 1; section < sectionCount; section++)
          Positioned(
            left: TimetablePage._timeColumnWidth,
            right: 0,
            top: section * sectionHeight,
            child: const _DashedSeparator(),
          ),
      ],
    );
  }
}

class _SectionTimeCell extends StatelessWidget {
  const _SectionTimeCell({required this.sectionTime});

  final SectionTime sectionTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Align(
        alignment: Alignment.topCenter,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: TimetablePage._timeColumnWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${sectionTime.section}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sectionTime.startText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F7881),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sectionTime.endText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F7881),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedSeparator extends StatelessWidget {
  const _DashedSeparator();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _DashedSeparatorPainter(color: Color(0xFFD9DEE4)),
      child: SizedBox(height: 1),
    );
  }
}

class _VerticalSeparator extends StatelessWidget {
  const _VerticalSeparator();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0x0F2C3B45)),
      child: SizedBox(width: 1),
    );
  }
}

class _DashedSeparatorPainter extends CustomPainter {
  const _DashedSeparatorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashGap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedSeparatorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _PositionedVisibleItem extends StatelessWidget {
  const _PositionedVisibleItem({
    required this.item,
    required this.dayColumnWidth,
    required this.sectionHeight,
    required this.appearance,
  });

  final TimetableVisibleItem item;
  final double dayColumnWidth;
  final double sectionHeight;
  final TimetableAppearanceSettings appearance;

  @override
  Widget build(BuildContext context) {
    final left =
        TimetablePage._timeColumnWidth +
        item.dayColumn * dayColumnWidth +
        TimetablePage._cardGap;
    final top = item.startSlot * sectionHeight + TimetablePage._cardGap;
    final height = sectionHeight * item.slotSpan - TimetablePage._cardGap * 2;
    final width = dayColumnWidth - TimetablePage._cardGap * 2;

    return Positioned(
      left: left,
      top: top,
      width: width < 20 ? 20 : width,
      height: height,
      child: item.isConflict
          ? _ConflictCard(item: item, appearance: appearance)
          : _CourseCard(
              placement: item.placements.single,
              appearance: appearance,
            ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.placement, required this.appearance});

  final TimetableCoursePlacement placement;
  final TimetableAppearanceSettings appearance;

  @override
  Widget build(BuildContext context) {
    final palette = _CoursePalette.forKey(placement.courseMeta.id);
    return _CourseCardSurface(
      palette: palette,
      title: placement.courseMeta.name,
      classroom: placement.schedule.classroom,
      teacher: placement.courseMeta.teacher,
      appearance: appearance,
      onTap: () => _showCourseDetails(context, placement),
    );
  }

  Future<void> _showCourseDetails(
    BuildContext context,
    TimetableCoursePlacement placement,
  ) {
    return showKiroDialog<void>(
      context: context,
      child: _CourseDetailDialog(hostContext: context, placement: placement),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.item, required this.appearance});

  final TimetableVisibleItem item;
  final TimetableAppearanceSettings appearance;

  @override
  Widget build(BuildContext context) {
    final count = item.placements.length;
    final firstPlacement = item.placements.first;
    return _CourseCardSurface(
      palette: _CoursePalette.forKey(firstPlacement.courseMeta.id),
      title: item.placements
          .map(
            (TimetableCoursePlacement placement) => placement.courseMeta.name,
          )
          .join(' / '),
      classroom: _summarizeClassrooms(item.placements),
      teacher: _summarizeTeachers(item.placements),
      appearance: appearance,
      conflictCount: count,
      onTap: () => _showConflictDetails(context, item),
    );
  }

  Future<void> _showConflictDetails(
    BuildContext context,
    TimetableVisibleItem item,
  ) {
    return showKiroDialog<void>(
      context: context,
      child: _ConflictDetailDialog(hostContext: context, item: item),
    );
  }
}

class _CoursePalette {
  const _CoursePalette({
    required this.background,
    required this.accent,
    required this.text,
  });

  final Color background;
  final Color accent;
  final Color text;

  static const List<_CoursePalette> values = <_CoursePalette>[
    _CoursePalette(
      background: Color(0xFFEAF4FF),
      accent: Color(0xFF4B8FD9),
      text: Color(0xFF19527E),
    ),
    _CoursePalette(
      background: Color(0xFFEAF8EF),
      accent: Color(0xFF49A36D),
      text: Color(0xFF236542),
    ),
    _CoursePalette(
      background: Color(0xFFFFF1E4),
      accent: Color(0xFFD9893F),
      text: Color(0xFF845020),
    ),
    _CoursePalette(
      background: Color(0xFFFFEDF3),
      accent: Color(0xFFD96A92),
      text: Color(0xFF883D59),
    ),
    _CoursePalette(
      background: Color(0xFFF1EEFF),
      accent: Color(0xFF8371D9),
      text: Color(0xFF51458C),
    ),
    _CoursePalette(
      background: Color(0xFFE8F8F8),
      accent: Color(0xFF3AA8A8),
      text: Color(0xFF1E6868),
    ),
    _CoursePalette(
      background: Color(0xFFFFF7DE),
      accent: Color(0xFFD0A430),
      text: Color(0xFF745D1A),
    ),
  ];

  static _CoursePalette forKey(String key) {
    final index = key.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return values[index % values.length];
  }
}

class _CourseCardSurface extends StatelessWidget {
  const _CourseCardSurface({
    required this.palette,
    required this.title,
    required this.classroom,
    required this.teacher,
    required this.appearance,
    required this.onTap,
    this.conflictCount,
  });

  final _CoursePalette palette;
  final String title;
  final String classroom;
  final String teacher;
  final TimetableAppearanceSettings appearance;
  final VoidCallback onTap;
  final int? conflictCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: palette.accent.withValues(alpha: 0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(width: 3, color: palette.accent),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        appearance.density == CourseCardDensity.compact ? 4 : 5,
                        appearance.density == CourseCardDensity.compact ? 4 : 5,
                        conflictCount == null ? 4 : 18,
                        appearance.density == CourseCardDensity.compact ? 3 : 4,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (appearance.showCourseName)
                                    Text(
                                      title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: palette.text,
                                        fontSize: _courseTitleFontSize(
                                          appearance,
                                        ),
                                        fontWeight: FontWeight.w900,
                                        height: 1.08,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  if (appearance.showClassroom) ...<Widget>[
                                    const SizedBox(height: 2),
                                    Text(
                                      classroom.trim().isEmpty
                                          ? '地点未填写'
                                          : classroom,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: palette.text.withAlpha(220),
                                        fontSize: _courseMetaFontSize(
                                          appearance,
                                        ),
                                        fontWeight: FontWeight.w800,
                                        height: 1.0,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                  if (appearance.showTeacher) ...<Widget>[
                                    const SizedBox(height: 2),
                                    Text(
                                      teacher.trim().isEmpty
                                          ? '老师未填写'
                                          : teacher,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: palette.text.withAlpha(205),
                                        fontSize: _courseMetaFontSize(
                                          appearance,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        height: 1.12,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (conflictCount != null)
                Positioned(
                  top: 3,
                  right: 3,
                  child: _ConflictBadge(count: conflictCount!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConflictBadge extends StatelessWidget {
  const _ConflictBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('conflict-count-badge'),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE86D4A),
        borderRadius: BorderRadius.circular(9),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(28),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

double _courseTitleFontSize(TimetableAppearanceSettings appearance) {
  final base = switch (appearance.fontSize) {
    CourseFontSize.small => 10.0,
    CourseFontSize.medium => 10.8,
    CourseFontSize.large => 11.8,
  };
  return appearance.density == CourseCardDensity.compact ? base - 0.4 : base;
}

double _courseMetaFontSize(TimetableAppearanceSettings appearance) {
  final base = switch (appearance.fontSize) {
    CourseFontSize.small => 8.6,
    CourseFontSize.medium => 9.2,
    CourseFontSize.large => 10.0,
  };
  return appearance.density == CourseCardDensity.compact ? base - 0.3 : base;
}

Future<T?> showKiroDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withAlpha(72),
    transitionDuration: const Duration(milliseconds: 190),
    pageBuilder: (context, animation, secondaryAnimation) {
      final viewInsets = MediaQuery.viewInsetsOf(context);
      final viewPadding = MediaQuery.viewPaddingOf(context);
      final screenSize = MediaQuery.sizeOf(context);
      final horizontalInset = screenSize.width * 0.05;
      final usableHeight =
          screenSize.height - viewPadding.top - viewPadding.bottom - 48;

      return SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(
            horizontalInset.clamp(16.0, 24.0),
            24,
            horizontalInset.clamp(16.0, 24.0),
            24,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: usableHeight.clamp(0, 900),
              ),
              child: Center(
                child: Dialog(
                  insetPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

void _openImportPage(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CourseImportPage()));
}

String _sectionText(int startSection, int endSection) {
  if (startSection == endSection) {
    return '第$startSection节';
  }
  return '第$startSection-$endSection节';
}

String _scheduleTimeText({
  required SectionTimeSettings sectionTimeSettings,
  required int dayOfWeek,
  required int startSection,
  required int endSection,
}) {
  return '${_dayLabel(dayOfWeek)} ${_sectionText(startSection, endSection)} '
      '${sectionTimeSettings.rangeText(startSection, endSection)}';
}

String _dayLabel(int dayOfWeek) {
  const dayLabels = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return dayLabels[(dayOfWeek - 1).clamp(0, dayLabels.length - 1)];
}

String _summarizeClassrooms(List<TimetableCoursePlacement> placements) {
  final classrooms = <String>{};
  for (final placement in placements) {
    final classroom = placement.schedule.classroom.trim();
    if (classroom.isNotEmpty) {
      classrooms.add(classroom);
    }
  }
  if (classrooms.isEmpty) {
    return '地点未填写';
  }
  return classrooms.take(2).join(' / ');
}

String _summarizeTeachers(List<TimetableCoursePlacement> placements) {
  final teachers = <String>{};
  for (final placement in placements) {
    final teacher = placement.courseMeta.teacher.trim();
    if (teacher.isNotEmpty) {
      teachers.add(teacher);
    }
  }
  if (teachers.isEmpty) {
    return '老师未填写';
  }
  return teachers.take(2).join(' / ');
}

Future<void> _showCourseEditor(
  BuildContext context, {
  required TimetableCoursePlacement? placement,
}) {
  return showKiroDialog<void>(
    context: context,
    child: _CourseEditorDialog(hostContext: context, placement: placement),
  );
}

void _showHostMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showMessengerMessage(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

class _KiroDialogScaffold extends StatelessWidget {
  const _KiroDialogScaffold({
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeHeight =
        mediaQuery.size.height -
        mediaQuery.viewPadding.top -
        mediaQuery.viewPadding.bottom;
    final maxHeight = safeHeight * 0.82;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF6F7881)),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: body,
            ),
          ),
          if (actions.isNotEmpty)
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE6EAEE))),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseDetailDialog extends ConsumerWidget {
  const _CourseDetailDialog({
    required this.hostContext,
    required this.placement,
  });

  final BuildContext hostContext;
  final TimetableCoursePlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = placement.schedule;
    final meta = placement.courseMeta;
    final sectionTimeSettings = ref
        .watch(semesterSettingsProvider)
        .sectionTimeSettings;
    final teachingClass = meta.teachingClass.trim();

    return _KiroDialogScaffold(
      title: meta.name,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DetailRow(
            icon: Icons.place_outlined,
            label: '地点',
            value: schedule.classroom,
          ),
          _DetailRow(
            icon: Icons.person_outline,
            label: '老师',
            value: meta.teacher,
          ),
          if (teachingClass.isNotEmpty)
            _DetailRow(
              icon: Icons.groups_outlined,
              label: '教学班级',
              value: teachingClass,
            ),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: '时间',
            value: _scheduleTimeText(
              sectionTimeSettings: sectionTimeSettings,
              dayOfWeek: schedule.dayOfWeek,
              startSection: schedule.startSection,
              endSection: schedule.endSection,
            ),
          ),
          _DetailRow(
            icon: Icons.event_note_outlined,
            label: '周次',
            value: CourseWeekText.format(schedule.weeks),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(_showCourseEditor(hostContext, placement: placement));
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('编辑'),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(_deletePlacement(hostContext, placement));
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('删除'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(_copyPlacementToSemester(hostContext, placement));
          },
          icon: const Icon(Icons.content_copy_outlined),
          label: const Text('复制到其他学期'),
        ),
      ],
    );
  }
}

class _ConflictDetailDialog extends ConsumerWidget {
  const _ConflictDetailDialog({required this.hostContext, required this.item});

  final BuildContext hostContext;
  final TimetableVisibleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionTimeSettings = ref
        .watch(semesterSettingsProvider)
        .sectionTimeSettings;
    return _KiroDialogScaffold(
      title: '课程冲突',
      subtitle: _scheduleTimeText(
        sectionTimeSettings: sectionTimeSettings,
        dayOfWeek: item.dayColumn + 1,
        startSection: item.startSlot + 1,
        endSection: item.startSlot + item.slotSpan,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final placement in item.placements)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ConflictDetailCourse(
                hostContext: hostContext,
                dialogContext: context,
                placement: placement,
                sectionTimeSettings: sectionTimeSettings,
              ),
            ),
        ],
      ),
    );
  }
}

class _ConflictDetailCourse extends StatelessWidget {
  const _ConflictDetailCourse({
    required this.hostContext,
    required this.dialogContext,
    required this.placement,
    required this.sectionTimeSettings,
  });

  final BuildContext hostContext;
  final BuildContext dialogContext;
  final TimetableCoursePlacement placement;
  final SectionTimeSettings sectionTimeSettings;

  @override
  Widget build(BuildContext context) {
    final schedule = placement.schedule;
    final meta = placement.courseMeta;
    final palette = _CoursePalette.forKey(meta.id);
    final teachingClass = meta.teachingClass.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.accent.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    meta.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    unawaited(
                      _showCourseEditor(hostContext, placement: placement),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.place_outlined,
              label: '地点',
              value: schedule.classroom,
            ),
            _DetailRow(
              icon: Icons.person_outline,
              label: '老师',
              value: meta.teacher,
            ),
            if (teachingClass.isNotEmpty)
              _DetailRow(
                icon: Icons.groups_outlined,
                label: '教学班级',
                value: teachingClass,
              ),
            _DetailRow(
              icon: Icons.schedule_outlined,
              label: '时间',
              value: _scheduleTimeText(
                sectionTimeSettings: sectionTimeSettings,
                dayOfWeek: schedule.dayOfWeek,
                startSection: schedule.startSection,
                endSection: schedule.endSection,
              ),
            ),
            _DetailRow(
              icon: Icons.event_note_outlined,
              label: '周次',
              value: CourseWeekText.format(schedule.weeks),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '未填写' : value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _deletePlacement(
  BuildContext context,
  TimetableCoursePlacement placement,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final action = container.read(deleteCourseScheduleProvider);
  final confirmed = await showKiroDialog<bool>(
    context: context,
    child: _ConfirmActionDialog(
      title: '删除课程',
      message: '确定删除「${placement.courseMeta.name}」这条上课安排吗？其他学期不受影响。',
      confirmLabel: '删除',
      destructive: true,
    ),
  );
  if (confirmed != true) {
    return;
  }

  try {
    await action(placement.schedule.id);
    _showMessengerMessage(messenger, '已删除课程');
  } catch (error) {
    _showMessengerMessage(messenger, '删除失败：$error');
  }
}

Future<void> _copyPlacementToSemester(
  BuildContext context,
  TimetableCoursePlacement placement,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final semesters = container.read(semesterListProvider);
  final action = container.read(copyCourseScheduleProvider);
  final sourceSemesterId = placement.schedule.semesterId;
  final targets = semesters
      .where((SemesterSettings semester) => semester.id != sourceSemesterId)
      .toList(growable: false);
  if (targets.isEmpty) {
    _showMessengerMessage(messenger, '没有可复制到的其他学期');
    return;
  }

  final targetSemesterId = await showKiroDialog<String>(
    context: context,
    child: _SemesterPickerDialog(semesters: targets),
  );
  if (targetSemesterId == null) {
    return;
  }

  try {
    await action(
      scheduleId: placement.schedule.id,
      targetSemesterId: targetSemesterId,
    );
    _showMessengerMessage(messenger, '已复制到其他学期');
  } catch (error) {
    _showMessengerMessage(messenger, '复制失败：$error');
  }
}

class _ConfirmActionDialog extends StatelessWidget {
  const _ConfirmActionDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return _KiroDialogScaffold(
      title: title,
      body: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class _SemesterPickerDialog extends StatelessWidget {
  const _SemesterPickerDialog({required this.semesters});

  final List<SemesterSettings> semesters;

  @override
  Widget build(BuildContext context) {
    return _KiroDialogScaffold(
      title: '复制到其他学期',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final semester in semesters)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(semester.label),
              subtitle: Text(
                '${_formatDate(semester.semesterStart)} 开始，${semester.totalWeeks}周',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).pop(semester.id),
            ),
        ],
      ),
    );
  }
}

class _CourseEditorDialog extends ConsumerStatefulWidget {
  const _CourseEditorDialog({
    required this.hostContext,
    required this.placement,
  });

  final BuildContext hostContext;
  final TimetableCoursePlacement? placement;

  @override
  ConsumerState<_CourseEditorDialog> createState() =>
      _CourseEditorDialogState();
}

class _CourseEditorDialogState extends ConsumerState<_CourseEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late final TextEditingController _teachingClassController;
  late final TextEditingController _classroomController;
  late final TextEditingController _weeksController;
  late int _dayOfWeek;
  late int _startSection;
  late int _endSection;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final placement = widget.placement;
    final currentWeek = ref.read(currentWeekProvider);
    _nameController = TextEditingController(
      text: placement?.courseMeta.name ?? '',
    );
    _teacherController = TextEditingController(
      text: placement?.courseMeta.teacher ?? '',
    );
    _teachingClassController = TextEditingController(
      text: placement?.courseMeta.teachingClass ?? '',
    );
    _classroomController = TextEditingController(
      text: placement?.schedule.classroom ?? '',
    );
    _weeksController = TextEditingController(
      text: placement == null
          ? CourseWeekText.format(<int>[currentWeek])
          : CourseWeekText.format(placement.schedule.weeks),
    );
    _dayOfWeek = placement?.schedule.dayOfWeek ?? DateTime.now().weekday;
    _startSection = placement?.schedule.startSection ?? 1;
    _endSection = placement?.schedule.endSection ?? 2;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _teachingClassController.dispose();
    _classroomController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _KiroDialogScaffold(
      title: widget.placement == null ? '新增课程' : '编辑课程',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '课程名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _teacherController,
            decoration: const InputDecoration(
              labelText: '任课老师',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _teachingClassController,
            decoration: const InputDecoration(
              labelText: '教学班级',
              hintText: '解析不到可留空',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _classroomController,
            decoration: const InputDecoration(
              labelText: '上课地点',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _dayOfWeek,
            decoration: const InputDecoration(
              labelText: '星期',
              border: OutlineInputBorder(),
            ),
            items: const <DropdownMenuItem<int>>[
              DropdownMenuItem(value: 1, child: Text('周一')),
              DropdownMenuItem(value: 2, child: Text('周二')),
              DropdownMenuItem(value: 3, child: Text('周三')),
              DropdownMenuItem(value: 4, child: Text('周四')),
              DropdownMenuItem(value: 5, child: Text('周五')),
              DropdownMenuItem(value: 6, child: Text('周六')),
              DropdownMenuItem(value: 7, child: Text('周日')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _dayOfWeek = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _startSection,
                  decoration: const InputDecoration(
                    labelText: '开始节次',
                    border: OutlineInputBorder(),
                  ),
                  items: _sectionItems(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _startSection = value;
                      if (_endSection < value) {
                        _endSection = value;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _endSection,
                  decoration: const InputDecoration(
                    labelText: '结束节次',
                    border: OutlineInputBorder(),
                  ),
                  items: _sectionItems(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _endSection = value < _startSection
                          ? _startSection
                          : value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weeksController,
            decoration: const InputDecoration(
              labelText: '周次',
              hintText: '例如 1-5,7-17周 或 2-16周(双)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('保存'),
        ),
      ],
    );
  }

  List<DropdownMenuItem<int>> _sectionItems() {
    return <DropdownMenuItem<int>>[
      for (
        var section = 1;
        section <= SemesterSettings.maxSectionCount;
        section++
      )
        DropdownMenuItem<int>(value: section, child: Text('第$section节')),
    ];
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final teacher = _teacherController.text.trim();
    final teachingClass = _teachingClassController.text.trim();
    final classroom = _classroomController.text.trim();
    final weeks = CourseWeekText.parse(_weeksController.text);
    if (name.isEmpty) {
      _showMessage('课程名称不能为空');
      return;
    }
    if (weeks.isEmpty) {
      _showMessage('周次格式不正确');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final placement = widget.placement;
      final edit = CourseScheduleEdit(
        courseMetaId: placement?.courseMeta.id ?? '',
        scheduleId: placement?.schedule.id ?? '',
        name: name,
        teacher: teacher,
        teachingClass: teachingClass,
        classroom: classroom,
        dayOfWeek: _dayOfWeek,
        startSection: _startSection,
        endSection: _endSection,
        weeks: weeks,
      );
      if (placement == null) {
        await ref.read(createCourseScheduleProvider)(edit);
      } else {
        await ref.read(saveCourseScheduleEditProvider)(edit);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      _showMessage(placement == null ? '已新增课程' : '已保存课程');
    } catch (error) {
      _showMessage('保存失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    _showHostMessage(widget.hostContext, message);
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('课表加载失败\n$error', textAlign: TextAlign.center),
      ),
    );
  }
}

class _EmptyWeekHint extends StatelessWidget {
  const _EmptyWeekHint();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: TimetablePage._timeColumnWidth,
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(child: Text('本周暂无课程')),
    );
  }
}
