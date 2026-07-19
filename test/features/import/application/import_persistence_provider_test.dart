import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import/application/import_persistence_provider.dart';
import 'package:kiro_time/features/import/domain/academic_timetable_html_parser.dart';
import 'package:kiro_time/features/settings/application/settings_providers.dart';
import 'package:kiro_time/features/settings/domain/import_preferences.dart';
import 'package:kiro_time/features/timetable/application/timetable_providers.dart';
import 'package:kiro_time/features/timetable/domain/semester_settings.dart';

void main() {
  test(
    'persists core, optional state, then refreshes timetable data',
    () async {
      final events = <String>[];
      final container = _buildContainer(
        events: events,
        replace: ({required timetable, required semesterId}) async {
          events.add('replace:$semesterId');
        },
      );
      addTearDown(container.dispose);

      final result = await container.read(persistImportedTimetableProvider)(
        timetable: _timetable(),
        detectedApiPath: '/detected',
      );

      expect(events, <String>[
        'replace:2026-1',
        'metadata:2026-1:2026-08-31',
        'path:/detected',
        'refresh',
      ]);
      expect(result.warnings, isEmpty);
    },
  );

  test('core failure prevents optional state and refresh', () async {
    final events = <String>[];
    final failure = StateError('replace failed');
    final container = _buildContainer(
      events: events,
      replace: ({required timetable, required semesterId}) async {
        events.add('replace');
        throw failure;
      },
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(persistImportedTimetableProvider)(
        timetable: _timetable(),
        detectedApiPath: '/detected',
      ),
      throwsA(same(failure)),
    );

    expect(events, <String>['replace']);
  });

  test('optional failures become warnings and refresh still runs', () async {
    final events = <String>[];
    final container = _buildContainer(
      events: events,
      replace: ({required timetable, required semesterId}) async {
        events.add('replace');
      },
      failMetadata: true,
      failPath: true,
    );
    addTearDown(container.dispose);

    final result = await container.read(persistImportedTimetableProvider)(
      timetable: _timetable(),
      detectedApiPath: '/detected',
    );

    expect(events, <String>['replace', 'metadata', 'path', 'refresh']);
    expect(result.warnings, hasLength(2));
  });

  test(
    'binds imported metadata to the semester captured before replace',
    () async {
      final events = <String>[];
      late ProviderContainer container;
      container = _buildContainer(
        events: events,
        includeSecondSemester: true,
        replace: ({required timetable, required semesterId}) async {
          events.add('replace:$semesterId');
          container.read(selectedSemesterIdProvider.notifier).state = '2026-2';
        },
      );
      addTearDown(container.dispose);

      await container.read(persistImportedTimetableProvider)(
        timetable: _timetable(),
        detectedApiPath: null,
      );

      expect(events, <String>[
        'replace:2026-1',
        'metadata:2026-1:2026-08-31',
        'refresh',
      ]);
      expect(container.read(selectedSemesterIdProvider), '2026-2');
    },
  );

  test(
    'explicit metadata update keeps a different semester selected',
    () async {
      final first = SemesterSettings(
        id: '2026-1',
        schoolYearStart: 2026,
        semester: 1,
        semesterStart: DateTime(2026, 8, 17),
        totalWeeks: 24,
      );
      final second = SemesterSettings(
        id: '2026-2',
        schoolYearStart: 2026,
        semester: 2,
        semesterStart: DateTime(2027, 2, 22),
        totalWeeks: 24,
      );
      String? updatedSemesterId;
      DateTime? updatedSemesterStart;
      final container = ProviderContainer(
        overrides: <Override>[
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[first, second],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => second.id),
          updateImportedSemesterStartProvider.overrideWithValue(({
            required String semesterId,
            required DateTime semesterStart,
          }) async {
            updatedSemesterId = semesterId;
            updatedSemesterStart = semesterStart;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(applyImportedSemesterMetadataToSemesterProvider)(
        semesterId: first.id,
        semesterStart: DateTime(2026, 8, 31),
      );

      expect(updatedSemesterId, first.id);
      expect(updatedSemesterStart, DateTime(2026, 8, 31));
      expect(container.read(selectedSemesterIdProvider), second.id);
    },
  );
}

ProviderContainer _buildContainer({
  required List<String> events,
  required ReplaceImportedTimetable replace,
  bool failMetadata = false,
  bool failPath = false,
  bool includeSecondSemester = false,
}) {
  final semester = SemesterSettings(
    id: '2026-1',
    schoolYearStart: 2026,
    semester: 1,
    semesterStart: DateTime(2026, 8, 17),
    totalWeeks: 24,
  );
  final secondSemester = SemesterSettings(
    id: '2026-2',
    schoolYearStart: 2026,
    semester: 2,
    semesterStart: DateTime(2027, 2, 22),
    totalWeeks: 24,
  );
  return ProviderContainer(
    overrides: <Override>[
      semesterListProvider.overrideWith(
        (ref) => <SemesterSettings>[
          semester,
          if (includeSecondSemester) secondSemester,
        ],
      ),
      selectedSemesterIdProvider.overrideWith((ref) => semester.id),
      importPreferencesProvider.overrideWith(
        (ref) => ImportPreferences.defaults(),
      ),
      replaceImportedTimetableProvider.overrideWithValue(replace),
      applyImportedSemesterMetadataToSemesterProvider.overrideWithValue(({
        required String semesterId,
        DateTime? semesterStart,
      }) async {
        events.add(
          failMetadata
              ? 'metadata'
              : 'metadata:$semesterId:${_dateText(semesterStart!)}',
        );
        if (failMetadata) {
          throw StateError('metadata failed');
        }
      }),
      saveImportPreferencesProvider.overrideWithValue((preferences) async {
        events.add(failPath ? 'path' : 'path:${preferences.semesterApiPath}');
        if (failPath) {
          throw StateError('path failed');
        }
      }),
      refreshImportedTimetableProvider.overrideWithValue(
        () => events.add('refresh'),
      ),
    ],
  );
}

ImportedTimetable _timetable() {
  return ImportedTimetable(
    metas: const [],
    schedules: const [],
    semesterStart: DateTime(2026, 8, 31),
  );
}

String _dateText(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
