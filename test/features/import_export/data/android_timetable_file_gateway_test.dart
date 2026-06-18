import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import_export/data/android_timetable_file_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(AndroidTimetableFileGateway.channelName);
  final calls = <MethodCall>[];
  late AndroidTimetableFileGateway gateway;

  setUp(() {
    calls.clear();
    gateway = const AndroidTimetableFileGateway();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'exportTimetableJson' => <String, Object?>{
              'fileName': call.arguments['fileName'] as String,
              'displayPath':
                  'Download/KiroTime/${call.arguments['fileName'] as String}',
            },
            'pickTimetableJson' => <String, Object?>{
              'fileName': 'backup.json',
              'json': '{"format":"kiro_time_timetable"}',
            },
            'fileExistsInDownloads' => true,
            _ => throw PlatformException(
              code: 'unknown',
              message: 'Unexpected method ${call.method}',
            ),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'exportTimetableJson sends filename, json, and overwrite flag',
    () async {
      final result = await gateway.exportTimetableJson(
        fileName: 'backup.json',
        json: '{"ok":true}',
        overwrite: true,
      );

      expect(result.fileName, 'backup.json');
      expect(result.displayPath, 'Download/KiroTime/backup.json');
      expect(calls.single.method, 'exportTimetableJson');
      expect(calls.single.arguments, <String, Object?>{
        'fileName': 'backup.json',
        'json': '{"ok":true}',
        'overwrite': true,
      });
    },
  );

  test('pickTimetableJson returns selected file text', () async {
    final result = await gateway.pickTimetableJson();

    expect(result, isNotNull);
    expect(result!.fileName, 'backup.json');
    expect(result.json, '{"format":"kiro_time_timetable"}');
  });

  test(
    'pickTimetableJson returns null when Android picker is cancelled',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });

      final result = await gateway.pickTimetableJson();

      expect(result, isNull);
    },
  );

  test('fileExistsInDownloads sends filename and returns existence', () async {
    final exists = await gateway.fileExistsInDownloads('backup.json');

    expect(exists, isTrue);
    expect(calls.single.method, 'fileExistsInDownloads');
    expect(calls.single.arguments, <String, Object?>{
      'fileName': 'backup.json',
    });
  });
}
