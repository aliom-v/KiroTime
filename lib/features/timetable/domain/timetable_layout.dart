import '../../courses/data/course_meta.dart';
import '../../courses/data/course_schedule.dart';

class TimetableCoursePlacement {
  final CourseSchedule schedule;
  final CourseMeta courseMeta;
  final int dayColumn;
  final int startSlot;
  final int slotSpan;
  final int laneIndex;
  final int laneCount;

  const TimetableCoursePlacement({
    required this.schedule,
    required this.courseMeta,
    required this.dayColumn,
    required this.startSlot,
    required this.slotSpan,
    required this.laneIndex,
    required this.laneCount,
  });
}

class TimetableVisibleItem {
  final List<TimetableCoursePlacement> placements;
  final int dayColumn;
  final int startSlot;
  final int slotSpan;

  const TimetableVisibleItem({
    required this.placements,
    required this.dayColumn,
    required this.startSlot,
    required this.slotSpan,
  });

  bool get isConflict => placements.length > 1;
}

class TimetableLayout {
  static const int daysPerWeek = 7;
  static const int sectionsPerDay = 12;

  static List<CourseSchedule> filterSchedulesForWeek(
    Iterable<CourseSchedule> schedules,
    int currentWeek,
  ) {
    return schedules
        .where(
          (CourseSchedule schedule) => schedule.weeks.contains(currentWeek),
        )
        .toList(growable: false);
  }

  static List<TimetableCoursePlacement> buildPlacements({
    required List<CourseSchedule> schedules,
    required List<CourseMeta> courseMetas,
  }) {
    final byCourseId = <String, CourseMeta>{
      for (final courseMeta in courseMetas) courseMeta.id: courseMeta,
    };

    final placements = <TimetableCoursePlacement>[];

    for (var day = 1; day <= daysPerWeek; day++) {
      final daySchedules =
          schedules
              .where((CourseSchedule schedule) => schedule.dayOfWeek == day)
              .toList(growable: false)
            ..sort((CourseSchedule a, CourseSchedule b) {
              final startCompare = a.startSection.compareTo(b.startSection);
              if (startCompare != 0) {
                return startCompare;
              }

              final endCompare = a.endSection.compareTo(b.endSection);
              if (endCompare != 0) {
                return endCompare;
              }

              return a.id.compareTo(b.id);
            });

      var index = 0;
      while (index < daySchedules.length) {
        final group = <CourseSchedule>[daySchedules[index]];
        var groupEnd = daySchedules[index].endSection;
        var nextIndex = index + 1;

        while (nextIndex < daySchedules.length &&
            daySchedules[nextIndex].startSection <= groupEnd) {
          final nextSchedule = daySchedules[nextIndex];
          group.add(nextSchedule);
          if (nextSchedule.endSection > groupEnd) {
            groupEnd = nextSchedule.endSection;
          }
          nextIndex++;
        }

        final lanes = <_LaneState>[];
        final laneByScheduleId = <String, int>{};

        for (final schedule in group) {
          var laneIndex = -1;

          for (var i = 0; i < lanes.length; i++) {
            if (schedule.startSection > lanes[i].lastEndSection) {
              laneIndex = i;
              break;
            }
          }

          if (laneIndex == -1) {
            lanes.add(_LaneState(lastEndSection: schedule.endSection));
            laneIndex = lanes.length - 1;
          } else {
            lanes[laneIndex].lastEndSection = schedule.endSection;
          }

          laneByScheduleId[schedule.id] = laneIndex;
        }

        final laneCount = lanes.isEmpty ? 1 : lanes.length;

        for (final schedule in group) {
          final courseMeta = byCourseId[schedule.courseMetaId];
          if (courseMeta == null) {
            throw StateError('Missing CourseMeta for ${schedule.courseMetaId}');
          }

          placements.add(
            TimetableCoursePlacement(
              schedule: schedule,
              courseMeta: courseMeta,
              dayColumn: day - 1,
              startSlot: schedule.startSection - 1,
              slotSpan: schedule.endSection - schedule.startSection + 1,
              laneIndex: laneByScheduleId[schedule.id]!,
              laneCount: laneCount,
            ),
          );
        }

        index = nextIndex;
      }
    }

    return placements;
  }

  static List<TimetableVisibleItem> buildVisibleItems({
    required List<CourseSchedule> schedules,
    required List<CourseMeta> courseMetas,
  }) {
    final placements = buildPlacements(
      schedules: schedules,
      courseMetas: courseMetas,
    );
    return buildVisibleItemsFromPlacements(placements);
  }

  static List<TimetableVisibleItem> buildVisibleItemsFromPlacements(
    List<TimetableCoursePlacement> placements,
  ) {
    final items = <TimetableVisibleItem>[];

    for (var day = 0; day < daysPerWeek; day++) {
      final dayPlacements =
          placements
              .where(
                (TimetableCoursePlacement placement) =>
                    placement.dayColumn == day,
              )
              .toList(growable: false)
            ..sort((TimetableCoursePlacement a, TimetableCoursePlacement b) {
              final startCompare = a.startSlot.compareTo(b.startSlot);
              if (startCompare != 0) {
                return startCompare;
              }

              final endCompare = (a.startSlot + a.slotSpan).compareTo(
                b.startSlot + b.slotSpan,
              );
              if (endCompare != 0) {
                return endCompare;
              }

              return a.schedule.id.compareTo(b.schedule.id);
            });

      var index = 0;
      while (index < dayPlacements.length) {
        final group = <TimetableCoursePlacement>[dayPlacements[index]];
        var groupEndExclusive =
            dayPlacements[index].startSlot + dayPlacements[index].slotSpan;
        var nextIndex = index + 1;

        while (nextIndex < dayPlacements.length &&
            dayPlacements[nextIndex].startSlot < groupEndExclusive) {
          final nextPlacement = dayPlacements[nextIndex];
          group.add(nextPlacement);
          final nextEndExclusive =
              nextPlacement.startSlot + nextPlacement.slotSpan;
          if (nextEndExclusive > groupEndExclusive) {
            groupEndExclusive = nextEndExclusive;
          }
          nextIndex++;
        }

        final startSlot = group
            .map((TimetableCoursePlacement placement) => placement.startSlot)
            .reduce((int a, int b) => a < b ? a : b);
        final endExclusive = group
            .map(
              (TimetableCoursePlacement placement) =>
                  placement.startSlot + placement.slotSpan,
            )
            .reduce((int a, int b) => a > b ? a : b);

        items.add(
          TimetableVisibleItem(
            placements: List<TimetableCoursePlacement>.unmodifiable(group),
            dayColumn: day,
            startSlot: startSlot,
            slotSpan: endExclusive - startSlot,
          ),
        );

        index = nextIndex;
      }
    }

    return items;
  }
}

class _LaneState {
  _LaneState({required this.lastEndSection});

  int lastEndSection;
}
