class CourseWeekText {
  CourseWeekText._();

  static List<int> parse(String text) {
    var compact = text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('－', '-')
        .replaceAll('—', '-')
        .replaceAll('至', '-')
        .replaceAll('到', '-')
        .replaceAll('第', '');
    compact = compact.replaceFirst(
      RegExp(r'^(?:上课)?周(?:次|数)?[:：]?', caseSensitive: false),
      '',
    );
    if (compact.isEmpty) {
      return <int>[];
    }

    final weeks = <int>{};
    for (final rawToken in compact.split(RegExp(r'[，,、;；]+'))) {
      final oddOnly = rawToken.contains('单');
      final evenOnly = rawToken.contains('双');
      final token = rawToken
          .replaceAll('周', '')
          .replaceAll('单', '')
          .replaceAll('双', '')
          .replaceAll('(', '')
          .replaceAll(')', '');
      if (token.isEmpty) {
        continue;
      }
      final tokenWeeks = <int>{};
      if (token.contains('-')) {
        final bounds = token.split('-');
        if (bounds.length != 2) {
          continue;
        }
        final start = int.tryParse(bounds.first);
        final end = int.tryParse(bounds.last);
        if (start == null || end == null) {
          continue;
        }
        final lower = start <= end ? start : end;
        final upper = start <= end ? end : start;
        for (var week = lower; week <= upper; week++) {
          tokenWeeks.add(week);
        }
      } else {
        final parsed = int.tryParse(token);
        if (parsed != null) {
          tokenWeeks.add(parsed);
        }
      }

      if (oddOnly) {
        tokenWeeks.removeWhere((week) => week.isEven);
      }
      if (evenOnly) {
        tokenWeeks.removeWhere((week) => week.isOdd);
      }
      weeks.addAll(tokenWeeks);
    }

    final sorted = weeks.toList()..sort();
    return sorted;
  }

  static String format(List<int> weeks) {
    final sorted = weeks.toSet().toList()..sort();
    if (sorted.isEmpty) {
      return '';
    }

    final ranges = <String>[];
    var start = sorted.first;
    var previous = sorted.first;

    for (final week in sorted.skip(1)) {
      if (week == previous + 1) {
        previous = week;
        continue;
      }
      ranges.add(_formatRange(start, previous));
      start = week;
      previous = week;
    }

    ranges.add(_formatRange(start, previous));
    return '${ranges.join(',')}周';
  }

  static String _formatRange(int start, int end) {
    if (start == end) {
      return '$start';
    }
    return '$start-$end';
  }
}
