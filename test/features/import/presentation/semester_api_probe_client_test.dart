import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import/presentation/semester_api_probe_client.dart';

void main() {
  test(
    'starts an asynchronous XHR and completes from matching channel message',
    () async {
      final scripts = <String>[];
      final client = SemesterApiProbeClient(
        runJavaScript: (script) async => scripts.add(script),
        requestTimeout: const Duration(seconds: 1),
      );

      final responseFuture = client.request(
        semesterApiPath: '/api',
        schoolYear: '2026',
        semesterCode: '3',
      );

      await Future<void>.microtask(() {});

      expect(scripts, hasLength(1));
      final script = scripts.first;
      expect(script, contains('xhr.open'));
      expect(script, contains('/api'));
      expect(
        script,
        matches(RegExp(r"xhr\.open\('POST',\s*requestUrl,\s*true\)")),
      );
      expect(script, contains('xhr.timeout'));
      expect(script, contains('xnm'));
      expect(script, contains('2026'));
      expect(script, contains('xqm'));
      expect(script, contains('3'));
      expect(script, contains('doType'));
      expect(script, contains('kblx'));
      expect(script, contains(SemesterApiProbeClient.channelName));

      final requestId = _extractRequestId(script);
      client.handleJavaScriptMessage(
        jsonEncode(<String, Object?>{
          'requestId': requestId,
          'result': <String, Object?>{
            'ok': true,
            'status': 200,
            'payload': <String, Object?>{
              'kbList': <Object?>[],
              'sjkList': <Object?>[],
            },
          },
        }),
      );

      final response = await responseFuture;

      expect(response.error, isNull);
      expect(response.value, isA<Map<String, dynamic>>());
      expect((response.value as Map<String, dynamic>)['status'], 200);
    },
  );

  test('ignores unknown request IDs', () async {
    final scripts = <String>[];
    final client = SemesterApiProbeClient(
      runJavaScript: (script) async => scripts.add(script),
      requestTimeout: const Duration(seconds: 1),
    );

    final responseFuture = client.request(
      semesterApiPath: '/api',
      schoolYear: '2026',
      semesterCode: '3',
    );
    var completed = false;
    responseFuture.then((_) => completed = true);

    await Future<void>.microtask(() {});

    expect(scripts, hasLength(1));
    final requestId = _extractRequestId(scripts.first);

    client.handleJavaScriptMessage(
      jsonEncode(<String, Object?>{
        'requestId': 'unknown-request-id',
        'result': <String, Object?>{'ok': true, 'status': 200},
      }),
    );
    await Future<void>.microtask(() {});

    expect(completed, isFalse);

    client.handleJavaScriptMessage(
      jsonEncode(<String, Object?>{
        'requestId': requestId,
        'result': <String, Object?>{'ok': true, 'status': 200},
      }),
    );

    final response = await responseFuture;

    expect(response.error, isNull);
    expect(completed, isTrue);
  });

  test('returns a timeout error and aborts the browser request', () async {
    final scripts = <String>[];
    final client = SemesterApiProbeClient(
      runJavaScript: (script) async => scripts.add(script),
      requestTimeout: const Duration(milliseconds: 30),
    );

    final responseFuture = client.request(
      semesterApiPath: '/api',
      schoolYear: '2026',
      semesterCode: '3',
    );

    await Future<void>.microtask(() {});
    final requestId = _extractRequestId(scripts.first);

    final response = await responseFuture;

    expect(response.value, isNull);
    expect(response.error, isNotNull);
    expect(response.error, isNotEmpty);
    expect(
      response.error!.toLowerCase(),
      anyOf(contains('timeout'), contains('超时')),
    );
    expect(scripts, hasLength(2));
    expect(scripts[1], contains('abort'));
    expect(scripts[1], contains(requestId));
    expect(scripts[1], contains('delete'));
  });

  test('surfaces request-scoped JavaScript errors', () async {
    final scripts = <String>[];
    final client = SemesterApiProbeClient(
      runJavaScript: (script) async => scripts.add(script),
      requestTimeout: const Duration(seconds: 1),
    );

    final responseFuture = client.request(
      semesterApiPath: '/api',
      schoolYear: '2026',
      semesterCode: '3',
    );

    await Future<void>.microtask(() {});
    final requestId = _extractRequestId(scripts.first);

    client.handleJavaScriptMessage(
      jsonEncode(<String, Object?>{
        'requestId': requestId,
        'result': <String, Object?>{'ok': false, 'error': 'network error'},
      }),
    );

    final response = await responseFuture;

    expect(response.error, 'network error');
  });

  test(
    'retains response payload when JavaScript reports an HTTP error',
    () async {
      final scripts = <String>[];
      final client = SemesterApiProbeClient(
        runJavaScript: (script) async => scripts.add(script),
        requestTimeout: const Duration(seconds: 1),
      );

      final responseFuture = client.request(
        semesterApiPath: '/api',
        schoolYear: '2026',
        semesterCode: '3',
      );
      await Future<void>.microtask(() {});
      final requestId = _extractRequestId(scripts.first);

      client.handleJavaScriptMessage(
        jsonEncode(<String, Object?>{
          'requestId': requestId,
          'result': <String, Object?>{
            'ok': false,
            'status': 500,
            'error': 'HTTP 500',
            'payload': <String, Object?>{'kbList': <Object?>[]},
          },
        }),
      );

      final response = await responseFuture;

      expect(response.error, 'HTTP 500');
      expect(response.value, isNotNull);
      expect(response.value!['status'], 500);
    },
  );

  test('cancels pending requests without disposing the client', () async {
    final scripts = <String>[];
    final client = SemesterApiProbeClient(
      runJavaScript: (script) async => scripts.add(script),
      requestTimeout: const Duration(seconds: 1),
    );

    final canceledFuture = client.request(
      semesterApiPath: '/first',
      schoolYear: '2026',
      semesterCode: '3',
    );
    await Future<void>.microtask(() {});

    client.cancelPending(error: 'page changed');

    final canceled = await canceledFuture;
    expect(canceled.error, 'page changed');
    expect(scripts, hasLength(2));
    expect(scripts.last, contains('abort'));

    final nextFuture = client.request(
      semesterApiPath: '/second',
      schoolYear: '2026',
      semesterCode: '3',
    );
    await Future<void>.microtask(() {});
    final requestId = _extractRequestId(scripts.last);
    client.handleJavaScriptMessage(
      jsonEncode(<String, Object?>{
        'requestId': requestId,
        'result': <String, Object?>{'ok': true, 'status': 200},
      }),
    );

    expect((await nextFuture).error, isNull);
  });

  test('matches concurrent responses by request ID', () async {
    final scripts = <String>[];
    final client = SemesterApiProbeClient(
      runJavaScript: (script) async => scripts.add(script),
      requestTimeout: const Duration(seconds: 1),
    );

    final firstFuture = client.request(
      semesterApiPath: '/first',
      schoolYear: '2026',
      semesterCode: '3',
    );
    final secondFuture = client.request(
      semesterApiPath: '/second',
      schoolYear: '2026',
      semesterCode: '3',
    );
    await Future<void>.microtask(() {});

    final firstId = _extractRequestId(scripts[0]);
    final secondId = _extractRequestId(scripts[1]);
    client.handleJavaScriptMessage(
      jsonEncode(<String, Object?>{
        'requestId': secondId,
        'result': <String, Object?>{'ok': true, 'status': 202},
      }),
    );
    client.handleJavaScriptMessage(
      jsonEncode(<String, Object?>{
        'requestId': firstId,
        'result': <String, Object?>{'ok': true, 'status': 200},
      }),
    );

    expect((await firstFuture).value!['status'], 200);
    expect((await secondFuture).value!['status'], 202);
  });

  test('dispose aborts pending requests and rejects new ones', () async {
    final scripts = <String>[];
    final client = SemesterApiProbeClient(
      runJavaScript: (script) async => scripts.add(script),
      requestTimeout: const Duration(seconds: 1),
    );

    final pendingFuture = client.request(
      semesterApiPath: '/api',
      schoolYear: '2026',
      semesterCode: '3',
    );
    await Future<void>.microtask(() {});

    client.dispose();

    expect((await pendingFuture).error, 'canceled');
    expect(scripts, hasLength(2));
    expect(scripts.last, contains('abort'));

    final rejected = await client.request(
      semesterApiPath: '/after-dispose',
      schoolYear: '2026',
      semesterCode: '3',
    );
    expect(rejected.error, 'canceled');
    expect(scripts, hasLength(2));
  });
}

String _extractRequestId(String script) {
  final match = RegExp(
    r'var\s+requestId\s*=\s*("(?:\\.|[^"\\])*")\s*;',
  ).firstMatch(script);

  expect(match, isNotNull, reason: 'Expected a JSON requestId assignment');
  return jsonDecode(match!.group(1)!) as String;
}
