import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import/application/import_persistence_sequence.dart';

void main() {
  test(
    'runs replacement before metadata and detected path persistence',
    () async {
      final events = <String>[];

      final result = await ImportPersistenceSequence.run(
        replaceTimetable: () async => events.add('replace'),
        persistSemesterMetadata: () async => events.add('metadata'),
        persistDetectedApiPath: () async => events.add('path'),
      );

      expect(events, <String>['replace', 'metadata', 'path']);
      expect(result.warnings, isEmpty);
    },
  );

  test('does not run optional persistence when replacement fails', () async {
    final events = <String>[];
    final failure = StateError('replace failed');

    await expectLater(
      ImportPersistenceSequence.run(
        replaceTimetable: () async {
          events.add('replace');
          throw failure;
        },
        persistSemesterMetadata: () async => events.add('metadata'),
        persistDetectedApiPath: () async => events.add('path'),
      ),
      throwsA(same(failure)),
    );

    expect(events, <String>['replace']);
  });

  test('returns optional failures as warnings and continues', () async {
    final events = <String>[];

    final result = await ImportPersistenceSequence.run(
      replaceTimetable: () async => events.add('replace'),
      persistSemesterMetadata: () async {
        events.add('metadata');
        throw StateError('metadata failed');
      },
      persistDetectedApiPath: () async {
        events.add('path');
        throw StateError('path failed');
      },
    );

    expect(events, <String>['replace', 'metadata', 'path']);
    expect(result.warnings, hasLength(2));
    expect(result.warnings[0], contains('metadata failed'));
    expect(result.warnings[1], contains('path failed'));
  });
}
