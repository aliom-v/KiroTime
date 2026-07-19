import 'dart:async';
import 'dart:convert';

class SemesterApiProbeClient {
  SemesterApiProbeClient({
    required FutureOr<void> Function(String script) runJavaScript,
    this.requestTimeout = const Duration(seconds: 8),
  }) : _runJavaScript = runJavaScript;

  static const String channelName = 'SemesterApiProbe';
  static const String _browserRequestMap = '__kiroSemesterApiProbeRequests';

  static int _requestSequence = 0;

  final FutureOr<void> Function(String script) _runJavaScript;
  final Duration requestTimeout;
  final Map<String, _PendingRequest> _pendingRequests =
      <String, _PendingRequest>{};

  bool _disposed = false;

  Future<SemesterApiProbeResponse> request({
    required String semesterApiPath,
    String? schoolYear,
    String? semesterCode,
  }) {
    if (_disposed) {
      return Future<SemesterApiProbeResponse>.value(
        const SemesterApiProbeResponse(error: 'canceled'),
      );
    }

    final requestId = _createRequestId();
    final completer = Completer<SemesterApiProbeResponse>();
    final timeoutTimer = Timer(
      requestTimeout,
      () => _handleDartTimeout(requestId),
    );
    _pendingRequests[requestId] = _PendingRequest(
      completer: completer,
      timeoutTimer: timeoutTimer,
    );

    final script = _buildRequestScript(
      requestId: requestId,
      semesterApiPath: semesterApiPath,
      schoolYear: schoolYear,
      semesterCode: semesterCode,
    );
    unawaited(
      Future<void>.sync(() => _runJavaScript(script)).catchError((
        Object error,
      ) {
        _handleLaunchError(requestId, error);
      }),
    );

    return completer.future;
  }

  void handleJavaScriptMessage(String message) {
    Object? decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      return;
    }
    if (decoded is! Map) {
      return;
    }

    final requestId = decoded['requestId'];
    final rawResult = decoded['result'];
    if (requestId is! String || rawResult is! Map) {
      return;
    }

    Map<String, dynamic> result;
    try {
      result = Map<String, dynamic>.from(rawResult);
    } on TypeError {
      return;
    }
    final ok = result['ok'];
    if (ok is! bool) {
      return;
    }

    final pending = _pendingRequests.remove(requestId);
    if (pending == null) {
      return;
    }
    pending.timeoutTimer.cancel();

    if (ok) {
      pending.completer.complete(SemesterApiProbeResponse(value: result));
      return;
    }

    final rawError = result['error'];
    pending.completer.complete(
      SemesterApiProbeResponse(
        value: result,
        error: rawError == null || rawError.toString().isEmpty
            ? 'JavaScript request failed'
            : rawError.toString(),
      ),
    );
  }

  void cancelPending({String error = 'canceled'}) {
    final pendingEntries = _pendingRequests.entries.toList(growable: false);
    _pendingRequests.clear();
    for (final entry in pendingEntries) {
      entry.value.timeoutTimer.cancel();
      _runAbortScript(entry.key);
      if (!entry.value.completer.isCompleted) {
        entry.value.completer.complete(SemesterApiProbeResponse(error: error));
      }
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    cancelPending();
  }

  void _handleDartTimeout(String requestId) {
    final pending = _pendingRequests.remove(requestId);
    if (pending == null) {
      return;
    }

    pending.timeoutTimer.cancel();
    _runAbortScript(requestId);
    pending.completer.complete(
      SemesterApiProbeResponse(
        error: 'Request timeout after ${requestTimeout.inMilliseconds}ms',
      ),
    );
  }

  void _handleLaunchError(String requestId, Object error) {
    final pending = _pendingRequests.remove(requestId);
    if (pending == null) {
      return;
    }

    pending.timeoutTimer.cancel();
    _runAbortScript(requestId);
    pending.completer.complete(
      SemesterApiProbeResponse(error: 'Failed to launch JavaScript: $error'),
    );
  }

  void _runAbortScript(String requestId) {
    unawaited(
      Future<void>.sync(
        () => _runJavaScript(_buildAbortScript(requestId)),
      ).catchError((Object _) {}),
    );
  }

  String _createRequestId() {
    final sequence = _requestSequence++;
    return 'semester-api-${DateTime.now().microsecondsSinceEpoch}-$sequence';
  }

  String _buildRequestScript({
    required String requestId,
    required String semesterApiPath,
    required String? schoolYear,
    required String? semesterCode,
  }) {
    return '''
(function() {
  var requestId = ${jsonEncode(requestId)};
  var apiPath = ${jsonEncode(semesterApiPath)};
  var schoolYear = ${jsonEncode(_initialFieldValue(schoolYear))};
  var semesterCode = ${jsonEncode(_initialFieldValue(semesterCode))};
  var requestMap = window.$_browserRequestMap =
      window.$_browserRequestMap || {};
  var xhr = new XMLHttpRequest();
  var settled = false;

  function readHiddenValue(selector) {
    var element = document.querySelector(selector);
    if (!element || element.value == null) {
      return '';
    }
    return String(element.value);
  }

  function postResult(result) {
    if (settled) {
      return;
    }
    settled = true;
    delete requestMap[requestId];

    var channel = window[${jsonEncode(channelName)}];
    if (channel && typeof channel.postMessage === 'function') {
      channel.postMessage(JSON.stringify({
        requestId: requestId,
        result: result
      }));
    }
  }

  if (!schoolYear) {
    schoolYear = readHiddenValue('#xnm_hide');
  }
  if (!semesterCode) {
    semesterCode = readHiddenValue('#xqm_hide');
  }
  if (!schoolYear || !semesterCode) {
    postResult({ok: false, error: 'missing xnm/xqm'});
    return;
  }

  var lowerPath = apiPath.toLowerCase();
  var isAbsoluteHttp =
      lowerPath.indexOf('http://') === 0 ||
      lowerPath.indexOf('https://') === 0;
  var requestUrl = isAbsoluteHttp
      ? apiPath
      : String(window._path || '') + apiPath;
  var body =
      'xnm=' + encodeURIComponent(schoolYear) +
      '&xqm=' + encodeURIComponent(semesterCode) +
      '&doType=app&kblx=2';

  requestMap[requestId] = xhr;
  xhr.onload = function() {
    var payload = xhr.responseText;
    try {
      payload = JSON.parse(xhr.responseText);
    } catch (_) {
      // Keep response text when the endpoint does not return JSON.
    }

    var ok = xhr.status >= 200 && xhr.status < 300;
    var result = {
      ok: ok,
      status: xhr.status,
      payload: payload,
      text: xhr.responseText
    };
    if (!ok) {
      result.error = 'HTTP ' + xhr.status;
    }
    postResult(result);
  };
  xhr.onerror = function() {
    postResult({ok: false, status: xhr.status, error: 'network error'});
  };
  xhr.ontimeout = function() {
    postResult({ok: false, status: xhr.status, error: 'timeout'});
  };
  xhr.onabort = function() {
    postResult({ok: false, status: xhr.status, error: 'aborted'});
  };

  try {
    xhr.open('POST', requestUrl, true);
    xhr.timeout = ${requestTimeout.inMilliseconds};
    xhr.setRequestHeader(
      'Content-Type',
      'application/x-www-form-urlencoded; charset=UTF-8'
    );
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.send(body);
  } catch (error) {
    postResult({
      ok: false,
      error: error && error.message
          ? String(error.message)
          : String(error)
    });
  }
})();
''';
  }

  String _buildAbortScript(String requestId) {
    return '''
(function() {
  var requestId = ${jsonEncode(requestId)};
  var requestMap = window.$_browserRequestMap;
  if (!requestMap) {
    return;
  }

  var xhr = requestMap[requestId];
  if (xhr) {
    xhr.abort();
  }
  delete requestMap[requestId];
})();
''';
  }

  String _initialFieldValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }
    return value;
  }
}

class SemesterApiProbeResponse {
  const SemesterApiProbeResponse({this.value, this.error});

  final Map<String, dynamic>? value;
  final String? error;
}

class _PendingRequest {
  const _PendingRequest({required this.completer, required this.timeoutTimer});

  final Completer<SemesterApiProbeResponse> completer;
  final Timer timeoutTimer;
}
