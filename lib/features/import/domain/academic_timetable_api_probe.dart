import '../../../features/courses/data/course_schedule.dart';
import 'academic_timetable_html_parser.dart';

class AcademicTimetableApiProbe {
  AcademicTimetableApiProbe._();

  static List<String> buildCandidatePaths({
    required String configuredPath,
    required String currentUrl,
    required String pageText,
  }) {
    final candidates = <String>[];

    void add(String value) {
      final normalized = _normalizePath(value);
      if (normalized == null || candidates.contains(normalized)) {
        return;
      }
      candidates.add(normalized);
    }

    add(configuredPath);

    for (final path in _extractTimetablePaths(pageText)) {
      add(path);
    }

    final uri = Uri.tryParse(currentUrl);
    final currentPath = uri?.path ?? '';
    if (currentPath.contains('/kbcx/')) {
      add('/kbcx/xskbcx_cxXsKb.html');
      add('/kbcx/xskbcxMobile_cxXsKb.html');
      add('/kbcx/xskbcx_cxXsKbByXnXq.html');
      add('/kbcx/xskbcxMobile_cxXsKbByXnXq.html');
    }

    if (currentPath.endsWith('_cxXskbcxIndex.html')) {
      add(currentPath.replaceFirst('_cxXskbcxIndex.html', '_cxXsKb.html'));
    }
    if (currentPath.endsWith('Mobile_cxXskbcxIndex.html')) {
      add(
        currentPath.replaceFirst(
          'Mobile_cxXskbcxIndex.html',
          'Mobile_cxXsKb.html',
        ),
      );
    }

    return List<String>.unmodifiable(candidates);
  }

  static TimetableProbeCandidate? selectBestCandidate(
    Iterable<TimetableProbeCandidate> candidates,
  ) {
    TimetableProbeCandidate? best;
    for (final candidate in candidates) {
      final currentBest = best;
      if (currentBest == null || _isBetterCandidate(candidate, currentBest)) {
        best = candidate;
      }
    }
    return best;
  }

  static bool _isBetterCandidate(
    TimetableProbeCandidate candidate,
    TimetableProbeCandidate currentBest,
  ) {
    if (candidate.summary.isSuspicious != currentBest.summary.isSuspicious) {
      return !candidate.summary.isSuspicious;
    }
    if (candidate.summary.scheduleCount != currentBest.summary.scheduleCount) {
      return candidate.summary.scheduleCount >
          currentBest.summary.scheduleCount;
    }
    if (candidate.summary.courseCount != currentBest.summary.courseCount) {
      return candidate.summary.courseCount > currentBest.summary.courseCount;
    }
    return false;
  }

  static Iterable<String> _extractTimetablePaths(String pageText) sync* {
    final pattern = RegExp(
      r'''["']([^"']*(?:xskbcx|kbcx)[^"']*(?:cxXsKb|xsKb|Kb)[^"']*\.html[^"']*)["']''',
      caseSensitive: false,
    );
    for (final match in pattern.allMatches(pageText)) {
      final path = match.group(1);
      if (path != null) {
        yield path;
      }
    }
  }

  static String? _normalizePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return uri.path.isEmpty ? null : uri.path;
    }

    final queryIndex = trimmed.indexOf('?');
    final withoutQuery = queryIndex >= 0
        ? trimmed.substring(0, queryIndex)
        : trimmed;
    if (!withoutQuery.startsWith('/')) {
      return null;
    }
    return withoutQuery;
  }
}

class TimetableProbeCandidate {
  TimetableProbeCandidate({required this.path, required this.timetable})
    : summary = ImportPreviewSummary.fromTimetable(timetable);

  final String path;
  final ImportedTimetable timetable;
  final ImportPreviewSummary summary;
}

class ImportPreviewSummary {
  const ImportPreviewSummary({
    required this.courseCount,
    required this.scheduleCount,
    required this.crowdedSlots,
  });

  factory ImportPreviewSummary.fromTimetable(ImportedTimetable timetable) {
    final slotCounts = <String, TimetableSlotCount>{};
    for (final schedule in timetable.schedules) {
      for (final week in schedule.weeks.toSet()) {
        final key =
            '${schedule.dayOfWeek}/${schedule.startSection}/${schedule.endSection}/$week';
        final existing = slotCounts[key];
        slotCounts[key] = existing == null
            ? TimetableSlotCount.fromSchedule(schedule, week: week, count: 1)
            : existing.copyWith(count: existing.count + 1);
      }
    }

    final crowdedSlots =
        slotCounts.values
            .where((slot) => slot.count >= suspiciousSameSlotThreshold)
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return ImportPreviewSummary(
      courseCount: timetable.metas.length,
      scheduleCount: timetable.schedules.length,
      crowdedSlots: List<TimetableSlotCount>.unmodifiable(crowdedSlots),
    );
  }

  static const int suspiciousSameSlotThreshold = 4;

  final int courseCount;
  final int scheduleCount;
  final List<TimetableSlotCount> crowdedSlots;

  bool get isSuspicious => crowdedSlots.isNotEmpty;
}

class TimetableSlotCount {
  const TimetableSlotCount({
    required this.dayOfWeek,
    required this.startSection,
    required this.endSection,
    required this.week,
    required this.count,
  });

  factory TimetableSlotCount.fromSchedule(
    CourseSchedule schedule, {
    required int week,
    required int count,
  }) {
    return TimetableSlotCount(
      dayOfWeek: schedule.dayOfWeek,
      startSection: schedule.startSection,
      endSection: schedule.endSection,
      week: week,
      count: count,
    );
  }

  final int dayOfWeek;
  final int startSection;
  final int endSection;
  final int week;
  final int count;

  TimetableSlotCount copyWith({int? count}) {
    return TimetableSlotCount(
      dayOfWeek: dayOfWeek,
      startSection: startSection,
      endSection: endSection,
      week: week,
      count: count ?? this.count,
    );
  }
}
