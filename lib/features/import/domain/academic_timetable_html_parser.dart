import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:uuid/uuid.dart';

import '../../../features/courses/data/course_meta.dart';
import '../../../features/courses/data/course_schedule.dart';
import '../../courses/domain/course_week_text.dart';
import '../../timetable/domain/academic_calendar.dart';
import '../../timetable/domain/semester_settings.dart';

class ImportedTimetable {
  const ImportedTimetable({
    required this.metas,
    required this.schedules,
    this.semesterStart,
  });

  final List<CourseMeta> metas;
  final List<CourseSchedule> schedules;
  final DateTime? semesterStart;
}

class AcademicTimetableHtmlParser {
  AcademicTimetableHtmlParser._();

  static const Uuid _uuid = Uuid();
  static const int _dayCount = 7;
  static const int _maxSectionCount = SemesterSettings.maxSectionCount;
  static const int _maxWeek = AcademicCalendar.maxWeek;
  static const int _percentPositionSectionCount = 12;
  static const int _extendedPercentPositionSectionCount = 16;

  static ImportedTimetable parse(String html) {
    final metas = <CourseMeta>[];
    final schedules = <CourseSchedule>[];
    final metaIdsByKey = <String, String>{};
    final scheduleKeys = <String>{};

    void addParsedSchedule(_ParsedSchedule parsed) {
      if (!scheduleKeys.add(parsed.scheduleKey)) {
        return;
      }

      final courseMetaId = metaIdsByKey.putIfAbsent(parsed.metaKey, () {
        final id = _uuid.v4();
        metas.add(
          CourseMeta.create(
            id: id,
            name: parsed.name,
            teacher: parsed.teacher,
            teachingClass: parsed.teachingClass,
          ),
        );
        return id;
      });

      schedules.add(
        CourseSchedule.create(
          id: _uuid.v4(),
          courseMetaId: courseMetaId,
          classroom: parsed.classroom,
          dayOfWeek: parsed.dayOfWeek,
          startSection: parsed.startSection,
          endSection: parsed.endSection,
          weeks: parsed.weeks,
        ),
      );
    }

    final document = html_parser.parse(html);
    _addAllFromDocument(document, addParsedSchedule);

    return ImportedTimetable(
      metas: metas,
      schedules: schedules,
      semesterStart: _parseSemesterStart(document),
    );
  }

  static List<int> parseWeeks(String text) {
    final weekText = _stripSectionRange(text);
    if (!_looksLikeHtmlWeekLine(weekText)) {
      return const <int>[];
    }

    final weeks = CourseWeekText.parse(weekText);
    if (weeks.isEmpty || weeks.any((week) => week < 1 || week > _maxWeek)) {
      return const <int>[];
    }
    return weeks;
  }

  static bool _looksLikeHtmlWeekLine(String text) {
    final compact = _normalizeComparableText(text);
    return compact.isNotEmpty &&
        RegExp(r'(?:周|单|双|[-－—至到,，、;；])').hasMatch(compact);
  }

  static void _addAllFromDocument(
    dom.Document document,
    void Function(_ParsedSchedule parsed) addParsedSchedule,
  ) {
    for (final element in document.querySelectorAll(
      'td[data-day][data-start-section][data-end-section]',
    )) {
      final parsedSchedules = _parseScheduleElement(element);
      for (final parsed in parsedSchedules) {
        addParsedSchedule(parsed);
      }
    }

    for (final element in document.querySelectorAll('body *')) {
      if (_hasExplicitScheduleAttributes(element) ||
          !_looksLikeTimetableCard(element)) {
        continue;
      }
      final parsedSchedules = _parseScheduleElement(element);
      for (final parsed in parsedSchedules) {
        addParsedSchedule(parsed);
      }
    }

    for (final table in document.querySelectorAll('table')) {
      for (final parsed in _parsePlainTimetableTable(table)) {
        addParsedSchedule(parsed);
      }
    }
  }

  static List<_ParsedSchedule> _parseScheduleElement(dom.Element element) {
    final lines = _extractCellLines(
      element,
    ).map(_cleanLabeledValue).where((line) => line.isNotEmpty).toList();
    if (lines.isEmpty) {
      return const <_ParsedSchedule>[];
    }

    final weeksIndex = _findWeeksIndex(lines);
    if (weeksIndex < 0) {
      return const <_ParsedSchedule>[];
    }

    final weeks = parseWeeks(lines[weeksIndex]);
    if (weeks.isEmpty) {
      return const <_ParsedSchedule>[];
    }

    final contentLines = lines.sublist(0, weeksIndex);
    if (contentLines.isEmpty) {
      return const <_ParsedSchedule>[];
    }

    final placement = _parsePlacement(element, contentLines);
    if (placement == null) {
      return const <_ParsedSchedule>[];
    }

    return _parseScheduleFromLines(lines, placement);
  }

  static List<_ParsedSchedule> _parseScheduleFromLines(
    List<String> lines,
    _Placement placement,
  ) {
    if (lines.isEmpty) {
      return const <_ParsedSchedule>[];
    }

    final weeksIndex = _findWeeksIndex(lines);
    if (weeksIndex < 0) {
      return const <_ParsedSchedule>[];
    }

    final weeks = parseWeeks(lines[weeksIndex]);
    if (weeks.isEmpty) {
      return const <_ParsedSchedule>[];
    }

    final contentLines = lines.sublist(0, weeksIndex);
    if (contentLines.isEmpty) {
      return const <_ParsedSchedule>[];
    }

    final name = _cleanCourseName(contentLines.first);
    if (name.isEmpty) {
      return const <_ParsedSchedule>[];
    }

    final teachingClass = _pickTeachingClass(contentLines.skip(1), name);
    final splitBlocks = _splitDetailBlocksByWeeks(lines.skip(1), name);
    if (splitBlocks.length > 1) {
      final teacher = _pickTeacher(
        splitBlocks.expand((block) => block.detailLines).toList(),
      );
      return <_ParsedSchedule>[
        for (final block in splitBlocks)
          if (_pickClassroom(block.detailLines).isNotEmpty)
            _ParsedSchedule(
              name: name,
              teacher: teacher,
              teachingClass: block.teachingClass.isNotEmpty
                  ? block.teachingClass
                  : teachingClass,
              classroom: _pickClassroom(block.detailLines),
              dayOfWeek: placement.dayOfWeek,
              startSection: placement.startSection,
              endSection: placement.endSection,
              weeks: block.weeks,
            ),
      ];
    }

    final singleDetailLines = _normalizeDetailLines(contentLines.skip(1), name);
    final teacher = _pickTeacher(singleDetailLines);
    final classroom = _pickClassroom(singleDetailLines);
    if (teacher.isEmpty && classroom.isEmpty) {
      return const <_ParsedSchedule>[];
    }

    return <_ParsedSchedule>[
      _ParsedSchedule(
        name: name,
        teacher: teacher,
        teachingClass: teachingClass,
        classroom: classroom,
        dayOfWeek: placement.dayOfWeek,
        startSection: placement.startSection,
        endSection: placement.endSection,
        weeks: weeks,
      ),
    ];
  }

  static Iterable<_ParsedSchedule> _parsePlainTimetableTable(
    dom.Element table,
  ) sync* {
    final rows = _directTableRows(table);
    if (rows.length < 2) {
      return;
    }

    final headerRowIndex = _findDayHeaderRowIndex(rows);
    if (headerRowIndex < 0 || headerRowIndex + 1 >= rows.length) {
      return;
    }

    final headerColumns = _buildDayColumnMapping(rows[headerRowIndex]);
    if (headerColumns.length < 3) {
      return;
    }
    final headerColumnCount = _expandedColumnCount(rows[headerRowIndex]);

    final occupiedColumns = <int, int>{};
    for (
      var rowIndex = headerRowIndex + 1;
      rowIndex < rows.length;
      rowIndex++
    ) {
      _advanceColumnOccupancy(occupiedColumns);

      final row = rows[rowIndex];
      final rowCells = _directTableCells(row);
      if (rowCells.isEmpty) {
        continue;
      }
      final rowColumnCount = _expandedColumnCount(row);

      final section = _parseSectionFromRow(row, rowIndex - headerRowIndex);
      if (section == null) {
        continue;
      }

      var columnIndex = 0;
      for (final cell in rowCells) {
        final lines = _extractCellLines(
          cell,
        ).map(_cleanLabeledValue).where((line) => line.isNotEmpty).toList();
        if (rowColumnCount > headerColumnCount &&
            columnIndex == 0 &&
            headerColumns[columnIndex] == null &&
            _looksLikePeriodAxisCell(lines)) {
          continue;
        }

        while (_isColumnOccupied(occupiedColumns, columnIndex)) {
          columnIndex++;
        }

        final rowSpan = _readSpan(cell, 'rowspan');
        final colSpan = _readSpan(cell, 'colspan');
        final cellIdPlacement = _parseTableCellIdPlacement(cell);
        final dayOfWeek = headerColumns[columnIndex];
        final startSection = cellIdPlacement?.startSection ?? section;
        var effectiveRowSpan = rowSpan;

        if (dayOfWeek != null && lines.isNotEmpty) {
          final sectionRangeFromText = _parseWidestSectionRange(lines);
          if (sectionRangeFromText != null &&
              sectionRangeFromText.startSection <= startSection &&
              sectionRangeFromText.endSection >= startSection) {
            effectiveRowSpan =
                sectionRangeFromText.endSection -
                sectionRangeFromText.startSection +
                1;
          }
          final placement = _Placement(
            dayOfWeek: dayOfWeek,
            startSection: startSection,
            endSection: startSection + effectiveRowSpan - 1,
          );
          final parsedSchedules = _parseTableCellSchedules(cell, placement);
          for (final parsed in parsedSchedules) {
            yield parsed;
          }
        }

        for (var offset = 0; offset < colSpan; offset++) {
          if (effectiveRowSpan > 1) {
            final existing = occupiedColumns[columnIndex + offset];
            final remaining = effectiveRowSpan;
            if (existing == null || existing < remaining) {
              occupiedColumns[columnIndex + offset] = remaining;
            }
          }
        }

        columnIndex += colSpan;
      }
    }
  }

  static Iterable<_ParsedSchedule> _parseTableCellSchedules(
    dom.Element cell,
    _Placement basePlacement,
  ) sync* {
    final lessonBlocks = _lessonBlocks(cell);
    if (lessonBlocks.isNotEmpty) {
      for (final block in lessonBlocks) {
        final lines = _extractCellLines(
          block,
        ).map(_cleanLabeledValue).where((line) => line.isNotEmpty).toList();
        final placement = _placementWithTextSection(basePlacement, lines);
        for (final parsed in _parseScheduleFromLines(lines, placement)) {
          yield parsed;
        }
      }
      return;
    }

    final lines = _extractCellLines(
      cell,
    ).map(_cleanLabeledValue).where((line) => line.isNotEmpty).toList();
    final placement = _placementWithTextSection(basePlacement, lines);
    for (final parsed in _parseScheduleFromLines(lines, placement)) {
      yield parsed;
    }
  }

  static List<dom.Element> _lessonBlocks(dom.Element cell) {
    return cell
        .querySelectorAll('.lesson')
        .where((element) => element != cell)
        .toList(growable: false);
  }

  static _Placement _placementWithTextSection(
    _Placement basePlacement,
    List<String> lines,
  ) {
    final sectionRange = _parseWidestSectionRange(lines);
    if (sectionRange == null) {
      return basePlacement;
    }
    return _Placement(
      dayOfWeek: basePlacement.dayOfWeek,
      startSection: sectionRange.startSection,
      endSection: sectionRange.endSection,
    );
  }

  static _Placement? _parsePlacement(
    dom.Element element,
    List<String> contentLines,
  ) {
    final explicit = _parseExplicitPlacement(element);
    if (explicit != null) {
      return explicit;
    }

    final fromText = _parseTextPlacement(contentLines.join(' '));
    if (fromText != null) {
      return fromText;
    }

    return _parseStylePlacement(element);
  }

  static _Placement? _parseExplicitPlacement(dom.Element element) {
    final dayOfWeek = _tryParseIntAttribute(element, 'data-day');
    final startSection = _tryParseIntAttribute(element, 'data-start-section');
    final endSection = _tryParseIntAttribute(element, 'data-end-section');
    if (dayOfWeek == null || startSection == null || endSection == null) {
      return null;
    }
    return _Placement(
      dayOfWeek: _clampInt(dayOfWeek, 1, _dayCount),
      startSection: _clampInt(startSection, 1, _maxSectionCount),
      endSection: _clampInt(endSection, 1, _maxSectionCount),
    );
  }

  static _Placement? _parseTextPlacement(String text) {
    final dayOfWeek = _parseDayOfWeek(text);
    final sectionRange = _parseSectionRange(text);
    if (dayOfWeek == null || sectionRange == null) {
      return null;
    }
    return _Placement(
      dayOfWeek: dayOfWeek,
      startSection: sectionRange.startSection,
      endSection: sectionRange.endSection,
    );
  }

  static _Placement? _parseStylePlacement(dom.Element element) {
    final styles = _parseInlineStyle(element.attributes['style']);
    if (styles.isEmpty) {
      return null;
    }

    final gridArea = styles['grid-area'];
    if (gridArea != null) {
      final placement = _parseGridArea(gridArea);
      if (placement != null) {
        return placement;
      }
    }

    final gridColumn = _parseGridLineRange(
      styles['grid-column'] ?? styles['grid-column-start'],
      styles['grid-column-end'],
    );
    final gridRow = _parseGridLineRange(
      styles['grid-row'] ?? styles['grid-row-start'],
      styles['grid-row-end'],
    );
    if (gridColumn != null && gridRow != null) {
      final startSection = _clampInt(gridRow.start, 1, _maxSectionCount);
      return _Placement(
        dayOfWeek: _clampInt(gridColumn.start, 1, _dayCount),
        startSection: startSection,
        endSection: _clampInt(
          gridRow.endLine - 1,
          startSection,
          _maxSectionCount,
        ),
      );
    }

    final left = _parseCssLength(styles['left']);
    final width = _parseCssLength(styles['width']);
    final top = _parseCssLength(styles['top']);
    final height = _parseCssLength(styles['height']);

    final dayOfWeek = _parseDayFromPosition(left: left, width: width);
    final sectionRange = _parseSectionRangeFromPosition(
      top: top,
      height: height,
    );
    if (dayOfWeek == null || sectionRange == null) {
      return null;
    }

    return _Placement(
      dayOfWeek: dayOfWeek,
      startSection: sectionRange.startSection,
      endSection: sectionRange.endSection,
    );
  }

  static int? _parseDayFromPosition({
    required _CssLength? left,
    required _CssLength? width,
  }) {
    if (left == null) {
      return null;
    }
    if (width != null && left.unit == width.unit && width.value > 0) {
      return _clampInt((left.value / width.value).round() + 1, 1, _dayCount);
    }
    if (left.unit == '%') {
      return _clampInt(
        (left.value / (100 / _dayCount)).round() + 1,
        1,
        _dayCount,
      );
    }
    return null;
  }

  static _SectionRange? _parseSectionRangeFromPosition({
    required _CssLength? top,
    required _CssLength? height,
  }) {
    if (top == null ||
        top.unit != '%' ||
        (height != null && height.unit != '%')) {
      return null;
    }

    final sectionCount = _inferPercentageSectionCount(top, height);
    final startSection = _clampInt(
      (top.value / (100 / sectionCount)).round() + 1,
      1,
      sectionCount,
    );
    var endSection = startSection;
    if (height != null) {
      endSection = _clampInt(
        ((top.value + height.value) / (100 / sectionCount)).round(),
        startSection,
        sectionCount,
      );
    }

    return _SectionRange(startSection: startSection, endSection: endSection);
  }

  static int _inferPercentageSectionCount(_CssLength top, _CssLength? height) {
    final defaultScore = _percentageAlignmentScore(
      top: top.value,
      height: height?.value,
      sectionCount: _percentPositionSectionCount,
    );
    final extendedScore = _percentageAlignmentScore(
      top: top.value,
      height: height?.value,
      sectionCount: _extendedPercentPositionSectionCount,
    );
    return extendedScore + 1e-9 < defaultScore
        ? _extendedPercentPositionSectionCount
        : _percentPositionSectionCount;
  }

  static double _percentageAlignmentScore({
    required double top,
    required double? height,
    required int sectionCount,
  }) {
    var score = _percentageLineAlignmentError(top, sectionCount);
    if (height != null) {
      score += _percentageLineAlignmentError(top + height, sectionCount);
    }
    return score;
  }

  static double _percentageLineAlignmentError(
    double percentage,
    int sectionCount,
  ) {
    final line = percentage * sectionCount / 100;
    return (line - line.roundToDouble()).abs();
  }

  static _Placement? _parseGridArea(String value) {
    final parts = value.split('/').map((part) => part.trim()).toList();
    if (parts.length != 4) {
      return null;
    }

    final gridRow = _parseGridLineRange(parts[0], parts[2]);
    final gridColumn = _parseGridLineRange(parts[1], parts[3]);
    if (gridRow == null || gridColumn == null) {
      return null;
    }

    final startSection = _clampInt(gridRow.start, 1, _maxSectionCount);
    return _Placement(
      dayOfWeek: _clampInt(gridColumn.start, 1, _dayCount),
      startSection: startSection,
      endSection: _clampInt(
        gridRow.endLine - 1,
        startSection,
        _maxSectionCount,
      ),
    );
  }

  static int _findDayHeaderRowIndex(List<dom.Element> rows) {
    for (var index = 0; index < rows.length; index++) {
      final dayCount = _directTableCells(
        rows[index],
      ).map((cell) => _parseDayHeader(cell.text)).whereType<int>().length;
      if (dayCount >= 3) {
        return index;
      }
    }
    return -1;
  }

  static Map<int, int> _buildDayColumnMapping(dom.Element headerRow) {
    final mapping = <int, int>{};
    var columnIndex = 0;
    for (final cell in _directTableCells(headerRow)) {
      final colSpan = _readSpan(cell, 'colspan');
      final dayOfWeek = _parseDayHeader(cell.text);
      if (dayOfWeek != null) {
        for (var offset = 0; offset < colSpan; offset++) {
          mapping[columnIndex + offset] = dayOfWeek + offset;
        }
      }
      columnIndex += colSpan;
    }
    return mapping;
  }

  static int _expandedColumnCount(dom.Element row) {
    return _directTableCells(
      row,
    ).fold<int>(0, (count, cell) => count + _readSpan(cell, 'colspan'));
  }

  static List<dom.Element> _directTableRows(dom.Element table) {
    final rows = <dom.Element>[];
    for (final child in table.children) {
      if (child.localName == 'tr') {
        rows.add(child);
        continue;
      }
      if (child.localName == 'thead' ||
          child.localName == 'tbody' ||
          child.localName == 'tfoot') {
        rows.addAll(
          child.children.where(
            (sectionChild) => sectionChild.localName == 'tr',
          ),
        );
      }
    }
    return rows;
  }

  static int? _parseDayHeader(String text) {
    final normalized = _normalizeComparableText(text);
    const mapping = <String, int>{
      '周一': 1,
      '星期一': 1,
      '周二': 2,
      '星期二': 2,
      '周三': 3,
      '星期三': 3,
      '周四': 4,
      '星期四': 4,
      '周五': 5,
      '星期五': 5,
      '周六': 6,
      '星期六': 6,
      '周日': 7,
      '星期日': 7,
      '周天': 7,
      '星期天': 7,
    };
    return mapping[normalized];
  }

  static List<dom.Element> _directTableCells(dom.Element row) {
    return row.children
        .where((child) => child.localName == 'td' || child.localName == 'th')
        .toList();
  }

  static int? _parseSectionFromRow(dom.Element row, int fallbackSection) {
    final cells = _directTableCells(row);
    for (final cell in cells) {
      final lines = _extractCellLines(
        cell,
      ).map(_cleanLabeledValue).where((line) => line.isNotEmpty).toList();
      if (lines.length > 2 && _findWeeksIndex(lines) >= 0) {
        continue;
      }
      for (final line in lines) {
        final match = RegExp(r'^\d{1,2}$').firstMatch(line);
        if (match != null) {
          final parsed = int.tryParse(match.group(0)!);
          if (parsed != null && parsed >= 1 && parsed <= _maxSectionCount) {
            return parsed;
          }
        }
      }
    }
    return fallbackSection >= 1 && fallbackSection <= _maxSectionCount
        ? fallbackSection
        : null;
  }

  static _Placement? _parseTableCellIdPlacement(dom.Element cell) {
    final match = RegExp(r'^td_(\d{1,2})-(\d{1,2})$').firstMatch(cell.id);
    if (match == null) {
      return null;
    }
    final dayOfWeek = int.tryParse(match.group(1)!);
    final startSection = int.tryParse(match.group(2)!);
    if (dayOfWeek == null || startSection == null) {
      return null;
    }
    return _Placement(
      dayOfWeek: _clampInt(dayOfWeek, 1, _dayCount),
      startSection: _clampInt(startSection, 1, _maxSectionCount),
      endSection: _clampInt(startSection, 1, _maxSectionCount),
    );
  }

  static DateTime? _parseSemesterStart(dom.Document document) {
    final text = document.body?.text ?? document.text ?? '';
    final firstWeekMatch = RegExp(
      r'第一周\s*(\d{4})[-/年.](\d{1,2})[-/月.](\d{1,2})',
    ).firstMatch(text);
    if (firstWeekMatch == null) {
      return null;
    }
    final year = int.tryParse(firstWeekMatch.group(1)!);
    final month = int.tryParse(firstWeekMatch.group(2)!);
    final day = int.tryParse(firstWeekMatch.group(3)!);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  static int _readSpan(dom.Element cell, String attributeName) {
    final rawValue = cell.attributes[attributeName];
    final parsed = rawValue == null ? null : int.tryParse(rawValue);
    if (parsed == null || parsed < 1) {
      return 1;
    }
    return parsed;
  }

  static void _advanceColumnOccupancy(Map<int, int> occupiedColumns) {
    final expired = <int>[];
    for (final entry in occupiedColumns.entries.toList()) {
      final remaining = entry.value - 1;
      if (remaining <= 0) {
        expired.add(entry.key);
      } else {
        occupiedColumns[entry.key] = remaining;
      }
    }
    for (final key in expired) {
      occupiedColumns.remove(key);
    }
  }

  static bool _isColumnOccupied(
    Map<int, int> occupiedColumns,
    int columnIndex,
  ) {
    final remaining = occupiedColumns[columnIndex];
    return remaining != null && remaining > 0;
  }

  static _GridLineRange? _parseGridLineRange(
    String? rangeValue,
    String? endValue,
  ) {
    if (rangeValue == null) {
      return null;
    }

    final parts = rangeValue.split('/').map((part) => part.trim()).toList();
    final startLine = _parseGridLine(parts.first);
    if (startLine == null) {
      return null;
    }

    if (parts.length > 1) {
      final second = parts[1];
      if (second.startsWith('span')) {
        final span = _parseSpan(second);
        if (span != null) {
          return _GridLineRange(start: startLine, endLine: startLine + span);
        }
      }
      final endLine = _parseGridLine(second);
      if (endLine != null) {
        return _GridLineRange(start: startLine, endLine: endLine);
      }
    }

    final explicitSpan = endValue == null ? null : _parseSpan(endValue);
    if (explicitSpan != null) {
      return _GridLineRange(
        start: startLine,
        endLine: startLine + explicitSpan,
      );
    }

    final explicitEnd = _parseGridLine(endValue);
    if (explicitEnd != null) {
      return _GridLineRange(start: startLine, endLine: explicitEnd);
    }

    final span = _parseSpan(rangeValue);
    if (span != null) {
      return _GridLineRange(start: startLine, endLine: startLine + span);
    }

    return _GridLineRange(start: startLine, endLine: startLine + 1);
  }

  static int? _parseGridLine(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(r'(\d+)').firstMatch(value);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }

  static int? _parseSpan(String value) {
    final match = RegExp(r'span\s+(\d+)').firstMatch(value);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }

  static int? _parseDayOfWeek(String text) {
    final match = RegExp(r'(?:星期|周)([一二三四五六日天1234567])').firstMatch(text);
    if (match == null) {
      return null;
    }
    const mapping = <String, int>{
      '一': 1,
      '1': 1,
      '二': 2,
      '2': 2,
      '三': 3,
      '3': 3,
      '四': 4,
      '4': 4,
      '五': 5,
      '5': 5,
      '六': 6,
      '6': 6,
      '日': 7,
      '天': 7,
      '7': 7,
    };
    return mapping[match.group(1)!];
  }

  static _SectionRange? _parseSectionRange(String text) {
    final match = RegExp(
      r'(?:第\s*)?(\d+)\s*[-~－—至到]\s*(\d+)\s*节',
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    final start = int.tryParse(match.group(1)!);
    final end = int.tryParse(match.group(2)!);
    if (start == null || end == null) {
      return null;
    }
    final startSection = start <= end ? start : end;
    final endSection = start <= end ? end : start;
    if (startSection < 1 || endSection > _maxSectionCount) {
      return null;
    }
    return _SectionRange(startSection: startSection, endSection: endSection);
  }

  static String _stripSectionRange(String text) {
    return text.replaceFirst(
      RegExp(r'^\s*[（(]?\s*(?:第\s*)?\d+\s*[-~－—至到]\s*\d+\s*节\s*[）)]?'),
      '',
    );
  }

  static Map<String, String> _parseInlineStyle(String? style) {
    if (style == null || style.trim().isEmpty) {
      return <String, String>{};
    }

    final entries = <String, String>{};
    for (final part in style.split(';')) {
      final index = part.indexOf(':');
      if (index < 0) {
        continue;
      }
      final key = part.substring(0, index).trim().toLowerCase();
      final value = part.substring(index + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        entries[key] = value;
      }
    }
    return entries;
  }

  static _CssLength? _parseCssLength(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(
      r'^(-?\d+(?:\.\d+)?)(px|%)?$',
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    final parsed = double.tryParse(match.group(1)!);
    if (parsed == null) {
      return null;
    }
    return _CssLength(value: parsed, unit: match.group(2) ?? 'px');
  }

  static _SectionRange? _parseWidestSectionRange(Iterable<String> lines) {
    _SectionRange? widest;
    for (final line in lines) {
      final sectionRange = _parseSectionRange(line);
      if (sectionRange == null) {
        continue;
      }
      if (widest == null ||
          sectionRange.endSection - sectionRange.startSection >
              widest.endSection - widest.startSection) {
        widest = sectionRange;
      }
    }
    return widest;
  }

  static int _findWeeksIndex(List<String> lines) {
    for (var index = lines.length - 1; index >= 0; index--) {
      if (parseWeeks(lines[index]).isNotEmpty) {
        return index;
      }
    }
    return -1;
  }

  static List<String> _extractCellLines(dom.Element cell) {
    final lines = <String>[];
    void walk(dom.Node node) {
      if (node is dom.Text) {
        for (final rawLine in node.text.split(RegExp(r'[\r\n]+'))) {
          final text = _normalizeText(rawLine);
          if (text.isNotEmpty) {
            lines.add(text);
          }
        }
        return;
      }
      if (node is dom.Element) {
        if (node.localName == 'br') {
          return;
        }
        for (final child in node.nodes) {
          walk(child);
        }
      }
    }

    for (final node in cell.nodes) {
      walk(node);
    }

    return lines;
  }

  static List<String> _normalizeDetailLines(
    Iterable<String> lines,
    String courseName,
  ) {
    final details = <String>[];
    final comparableName = _normalizeComparableText(courseName);
    for (final line in lines) {
      final comparableLine = _normalizeComparableText(line);
      if (comparableLine.isEmpty ||
          comparableLine == comparableName ||
          _looksLikeCourseCodeLine(line, courseName) ||
          _looksLikeDayTimeLine(line)) {
        continue;
      }
      details.add(line);
    }
    return details;
  }

  static String _pickTeachingClass(Iterable<String> lines, String courseName) {
    for (final line in lines) {
      final cleaned = _cleanLabeledValue(line);
      if (_looksLikeCourseCodeLine(cleaned, courseName)) {
        return cleaned;
      }
    }
    return '';
  }

  static bool _looksLikePeriodAxisCell(List<String> lines) {
    if (lines.length != 1) {
      return false;
    }
    return const <String>{
      '上午',
      '中午',
      '下午',
      '晚上',
      '晚间',
      '夜间',
    }.contains(_normalizeComparableText(lines.single));
  }

  static String _cleanCourseName(String value) {
    final normalized = _cleanLabeledValue(value);
    final match = RegExp(r'^(.*?)-\d{2,}$').firstMatch(normalized);
    if (match != null && match.group(1)!.trim().isNotEmpty) {
      return match.group(1)!.trim();
    }
    return normalized;
  }

  static bool _looksLikeCourseCodeLine(String line, String courseName) {
    final comparableLine = _normalizeComparableText(line);
    final comparableName = _normalizeComparableText(
      _stripCourseTypeMarkers(courseName),
    );
    if (!comparableLine.startsWith(comparableName) ||
        comparableLine.length <= comparableName.length) {
      return false;
    }

    final suffix = comparableLine.substring(comparableName.length);
    return RegExp(r'^[-_#]?[A-Za-z0-9]+$').hasMatch(suffix) ||
        RegExp(r'^[-_#]?\d{2,}$').hasMatch(suffix);
  }

  static String _stripCourseTypeMarkers(String value) {
    return value.replaceAll(RegExp(r'[★☆◆■〇●※]+$'), '').trim();
  }

  static bool _looksLikeDayTimeLine(String line) {
    return _parseDayOfWeek(line) != null || _parseSectionRange(line) != null;
  }

  static String _pickTeacher(List<String> lines) {
    for (final line in lines) {
      if (!_looksLikeClassroom(line)) {
        return line;
      }
    }
    return '';
  }

  static String _pickClassroom(List<String> lines) {
    final classrooms = lines.where(_looksLikeClassroom).toList();
    if (classrooms.isNotEmpty) {
      return classrooms.join(' ');
    }
    return lines.length > 1 ? lines.last : '';
  }

  static List<_DetailWeekBlock> _splitDetailBlocksByWeeks(
    Iterable<String> lines,
    String courseName,
  ) {
    final blocks = <_DetailWeekBlock>[];
    final pending = <String>[];
    for (final line in lines) {
      final weeks = parseWeeks(line);
      if (weeks.isEmpty) {
        pending.add(line);
        continue;
      }

      final teachingClass = _pickTeachingClass(pending, courseName);
      final detailLines = _normalizeDetailLines(pending, courseName);
      final classroomIndex = detailLines.lastIndexWhere(_looksLikeClassroom);
      if (classroomIndex > 0) {
        detailLines.removeRange(0, classroomIndex);
      }
      if (detailLines.isNotEmpty) {
        blocks.add(
          _DetailWeekBlock(
            detailLines: detailLines,
            weeks: weeks,
            teachingClass: teachingClass,
          ),
        );
      }
      pending.clear();
    }
    return blocks;
  }

  static bool _looksLikeClassroom(String value) {
    final compact = _normalizeComparableText(value);
    if (compact.isEmpty) {
      return false;
    }
    return compact.contains('校区') ||
        compact.contains('教室') ||
        compact.contains('实验') ||
        compact.contains('机房') ||
        compact.contains('报告厅') ||
        compact.contains('图书馆') ||
        compact.contains('体育馆') ||
        compact.contains('未排地点') ||
        compact.contains('线上') ||
        compact.contains('网络') ||
        compact.contains('腾讯会议') ||
        compact.contains('录播') ||
        compact.contains('在线') ||
        compact.contains('楼') ||
        compact.contains('室') ||
        compact.contains('#') ||
        RegExp(r'\d').hasMatch(compact);
  }

  static bool _looksLikeTimetableCard(dom.Element element) {
    if (_hasMultipleNestedTimetableCards(element)) {
      return false;
    }

    final lines = _extractCellLines(
      element,
    ).map(_cleanLabeledValue).where((line) => line.isNotEmpty).toList();
    if (lines.length < 3 || !lines.any((line) => parseWeeks(line).isNotEmpty)) {
      return false;
    }

    if (_parseStylePlacement(element) != null ||
        _parseTextPlacement(lines.join(' ')) != null) {
      return true;
    }

    final marker = '${element.attributes['class'] ?? ''} ${element.id}'
        .toLowerCase();
    return marker.contains('course') ||
        marker.contains('lesson') ||
        marker.contains('timetable') ||
        marker.contains('schedule') ||
        marker.contains('kb') ||
        marker.contains('card') ||
        marker.contains('cell');
  }

  static bool _hasMultipleNestedTimetableCards(dom.Element element) {
    final nestedCandidates = element
        .querySelectorAll('.lesson,.course-card,.card,.kb-card,.cell')
        .where((candidate) => candidate != element)
        .where((candidate) {
          final lines = _extractCellLines(
            candidate,
          ).map(_cleanLabeledValue).where((line) => line.isNotEmpty).toList();
          return lines.length >= 3 &&
              lines.any((line) => parseWeeks(line).isNotEmpty);
        })
        .take(2)
        .length;
    return nestedCandidates > 1;
  }

  static bool _hasExplicitScheduleAttributes(dom.Element element) {
    return element.attributes.containsKey('data-day') &&
        element.attributes.containsKey('data-start-section') &&
        element.attributes.containsKey('data-end-section');
  }

  static int? _tryParseIntAttribute(dom.Element element, String name) {
    final rawValue = element.attributes[name];
    if (rawValue == null) {
      return null;
    }
    return int.tryParse(rawValue);
  }

  static int _clampInt(int value, int minValue, int maxValue) {
    if (value < minValue) {
      return minValue;
    }
    if (value > maxValue) {
      return maxValue;
    }
    return value;
  }

  static String _normalizeComparableText(String input) {
    return input
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
  }

  static String _normalizeText(String input) {
    return input.replaceAll('\u00a0', ' ').trim();
  }

  static String _cleanLabeledValue(String input) {
    final normalized = _normalizeText(input);
    return normalized
        .replaceFirst(
          RegExp(
            r'^(?:课程名称|课程名|课程|教学班|教师姓名|任课教师|任课老师|教师|老师|上课地点|授课地点|地点|教室|周次|上课周次|周数)\s*[:：]\s*',
          ),
          '',
        )
        .trim();
  }
}

class _ParsedSchedule {
  const _ParsedSchedule({
    required this.name,
    required this.teacher,
    required this.teachingClass,
    required this.classroom,
    required this.dayOfWeek,
    required this.startSection,
    required this.endSection,
    required this.weeks,
  });

  final String name;
  final String teacher;
  final String teachingClass;
  final String classroom;
  final int dayOfWeek;
  final int startSection;
  final int endSection;
  final List<int> weeks;

  String get metaKey => '$name\u0000$teacher\u0000$teachingClass';

  String get scheduleKey =>
      '$name\u0000$teacher\u0000$teachingClass\u0000$classroom\u0000$dayOfWeek\u0000'
      '$startSection\u0000$endSection\u0000${weeks.join(',')}';
}

class _Placement {
  const _Placement({
    required this.dayOfWeek,
    required this.startSection,
    required this.endSection,
  });

  final int dayOfWeek;
  final int startSection;
  final int endSection;
}

class _SectionRange {
  const _SectionRange({required this.startSection, required this.endSection});

  final int startSection;
  final int endSection;
}

class _DetailWeekBlock {
  const _DetailWeekBlock({
    required this.detailLines,
    required this.weeks,
    required this.teachingClass,
  });

  final List<String> detailLines;
  final List<int> weeks;
  final String teachingClass;
}

class _CssLength {
  const _CssLength({required this.value, required this.unit});

  final double value;
  final String unit;
}

class _GridLineRange {
  const _GridLineRange({required this.start, required this.endLine});

  final int start;
  final int endLine;
}
