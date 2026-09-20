import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../settings/application/settings_providers.dart';
import '../../settings/domain/import_preferences.dart';
import '../../../ui/glass.dart';
import '../../timetable/application/timetable_providers.dart';
import '../application/import_persistence_provider.dart';
import '../domain/academic_timetable_api_probe.dart';
import '../domain/academic_timetable_html_parser.dart';
import '../domain/academic_timetable_json_parser.dart';
import '../domain/webview_html_codec.dart';
import 'import_preview_dialog.dart';
import 'semester_api_probe_client.dart';

class CourseImportPage extends ConsumerStatefulWidget {
  const CourseImportPage({super.key});

  @override
  ConsumerState<CourseImportPage> createState() => _CourseImportPageState();
}

class _CourseImportPageState extends ConsumerState<CourseImportPage> {
  late final WebViewController _controller;
  late final SemesterApiProbeClient _semesterApiProbeClient;
  late final Future<void> _semesterApiChannelReady;
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _currentUrl = '';
  String? _lastImportHtml;
  String _lastImportSource = '未导入';
  String? _lastSemesterApiError;
  String? _semesterApiChannelError;
  int _pageGeneration = 0;
  int? _lastImportedScheduleCount;
  List<String> _lastProbeCandidates = const <String>[];
  Map<String, String> _lastProbeErrors = const <String, String>{};
  ImportPreviewSummary? _lastPreviewSummary;
  List<String> _lastJsonCourseSamples = const <String>[];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _semesterApiProbeClient = SemesterApiProbeClient(
      runJavaScript: _controller.runJavaScript,
    );
    _semesterApiChannelReady = _configureSemesterApiChannel();
    unawaited(_applyImportPreferences());
  }

  @override
  void dispose() {
    _semesterApiProbeClient.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _configureSemesterApiChannel() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _pageGeneration++;
            _semesterApiProbeClient.cancelPending(error: '页面已变化');
            if (!mounted) {
              return;
            }
            setState(() {
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            if (!mounted) {
              return;
            }
            setState(() {
              _currentUrl = url;
            });
          },
        ),
      );
      await _controller.addJavaScriptChannel(
        SemesterApiProbeClient.channelName,
        onMessageReceived: (message) {
          _semesterApiProbeClient.handleJavaScriptMessage(message.message);
        },
      );
    } catch (error) {
      _semesterApiChannelError = 'WebView 探测通道初始化失败：$error';
    }
  }

  Future<void> _loadUrl() async {
    final input = _urlController.text.trim();
    final normalizedUrl = normalizeAcademicHttpsUrl(input);
    if (normalizedUrl == null) {
      _showMessage('请输入有效的 HTTPS 网址');
      return;
    }
    _urlController.text = normalizedUrl;
    final uri = Uri.parse(normalizedUrl);

    await _semesterApiChannelReady;
    final channelError = _semesterApiChannelError;
    if (channelError != null) {
      _showMessage(channelError);
      return;
    }
    await _controller.loadRequest(uri);
  }

  Widget _buildUrlPresetChips() {
    final prefs = ref.watch(importPreferencesProvider);
    final entries = <String, String>{};
    for (final bookmark in prefs.savedAcademicUrlBookmarks) {
      entries.putIfAbsent(bookmark.url, () => bookmark.displayName);
    }
    final list = entries.entries.toList(growable: false);
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = list[index];
          return GlassChipButton(
            label: entry.value,
            selected: _urlController.text.trim() == entry.key,
            onPressed: _isLoading ? null : () => _applyPresetUrl(entry.key),
          );
        },
      ),
    );
  }

  String _shortHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return url;
    }
    return uri.host;
  }

  Future<void> _applyPresetUrl(String url) async {
    _urlController.text = url;
    await _loadUrl();
  }

  Future<void> _pinCurrentUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showMessage('请先输入或打开一个网址');
      return;
    }
    final normalizedUrl = normalizeAcademicHttpsUrl(url);
    if (normalizedUrl == null) {
      _showMessage('仅支持 HTTPS 网址');
      return;
    }
    final prefs = ref.read(importPreferencesProvider);
    final normalizedBookmark = ImportPreferences.defaults()
        .copyWith(
          savedAcademicUrlBookmarks: <SavedAcademicUrl>[
            SavedAcademicUrl(
              name: _shortHost(normalizedUrl),
              url: normalizedUrl,
            ),
          ],
        )
        .savedAcademicUrlBookmarks
        .single;
    if (prefs.savedAcademicUrls.contains(normalizedBookmark.url)) {
      _showMessage('该网址已在常用列表');
      return;
    }
    await ref.read(saveImportPreferencesProvider)(
      prefs.copyWith(
        savedAcademicUrlBookmarks: <SavedAcademicUrl>[
          ...prefs.savedAcademicUrlBookmarks,
          normalizedBookmark,
        ],
        academicSystemUrl: normalizedBookmark.url,
      ),
    );
    _showMessage('已固定到常用网址');
  }

  Future<void> _applyImportPreferences() async {
    await ref.read(settingsBootstrapProvider.future);
    final preferences = ref.read(importPreferencesProvider);
    _urlController.text = preferences.academicSystemUrl;
    await _controller.setUserAgent(preferences.effectiveUserAgent);
  }

  Future<void> _importCurrentPage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prepared = await _prepareImport();
      if (prepared == null) {
        final html = _lastImportHtml ?? await _readCurrentPageHtml() ?? '';
        _showMessage('导入失败：${_buildNoCourseMessage(html)}');
        return;
      }

      final decision = await _showImportPreview(prepared);
      if (decision == null) {
        return;
      }

      await _persistPreparedImport(prepared, decision: decision);
    } catch (error) {
      _showMessage('导入失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _probeSemesterApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pageGeneration = _pageGeneration;
      final html = await _requireCurrentPageHtml();
      _ensurePageGeneration(pageGeneration);
      final selectedSemester = ref.read(semesterSettingsProvider);
      final candidates = _buildProbeCandidates(html);
      if (candidates.isEmpty) {
        _showMessage('未找到可探测的接口候选，请复制诊断摘要');
        return;
      }

      final result = await _probeCandidates(
        candidates,
        schoolYearStart: selectedSemester.schoolYearStart,
        semester: selectedSemester.semester,
        pageGeneration: pageGeneration,
      );
      if (result == null) {
        _showMessage('接口探测失败，请复制诊断摘要');
        return;
      }

      final decision = await _showImportPreview(result);
      if (decision != null) {
        await _persistPreparedImport(result, decision: decision);
      }
    } catch (error) {
      _showMessage('探测失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<_PreparedImport?> _prepareImport() async {
    final selectedSemester = ref.read(semesterSettingsProvider);
    _lastSemesterApiError = null;
    _lastProbeErrors = const <String, String>{};

    final pageGeneration = _pageGeneration;
    final html = await _readCurrentPageHtml();
    _ensurePageGeneration(pageGeneration);
    if (html != null && html.isNotEmpty) {
      _lastImportHtml = html;
    }

    final candidates = _buildProbeCandidates(html ?? '');
    final apiResult = await _probeCandidates(
      candidates,
      schoolYearStart: selectedSemester.schoolYearStart,
      semester: selectedSemester.semester,
      pageGeneration: pageGeneration,
    );
    if (apiResult != null) {
      return apiResult;
    }

    if (html == null || html.isEmpty) {
      return null;
    }

    final imported = AcademicTimetableHtmlParser.parse(html);
    if (imported.schedules.isEmpty) {
      return null;
    }
    return _PreparedImport(
      timetable: imported,
      source: '当前页面 HTML',
      path: null,
      summary: ImportPreviewSummary.fromTimetable(imported),
    );
  }

  List<String> _buildProbeCandidates(String html) {
    final candidates = AcademicTimetableApiProbe.buildCandidatePaths(
      configuredPath: ref.read(importPreferencesProvider).semesterApiPath,
      currentUrl: _currentUrl,
      pageText: html,
    );
    setState(() {
      _lastProbeCandidates = candidates;
    });
    return candidates;
  }

  Future<_PreparedImport?> _probeCandidates(
    List<String> candidates, {
    int? schoolYearStart,
    int? semester,
    required int pageGeneration,
  }) async {
    final errors = <String, String>{};
    final successfulCandidates = <TimetableProbeCandidate>[];
    final payloadsByPath = <String, String>{};
    void ensurePageUnchanged([String? path]) {
      if (pageGeneration == _pageGeneration) {
        return;
      }
      const message = '探测期间页面已变化，请在页面稳定后重试';
      errors[path ?? 'page'] = message;
      _lastProbeErrors = Map<String, String>.unmodifiable(errors);
      _lastSemesterApiError = message;
      throw const _PageChangedDuringImport(message);
    }

    ensurePageUnchanged();
    for (final path in candidates) {
      ensurePageUnchanged(path);
      try {
        final readResult = await _readSemesterTimetableJsonFromPath(
          path,
          schoolYearStart: schoolYearStart,
          semester: semester,
        );
        ensurePageUnchanged(path);
        final payload = readResult.payload;
        if (payload == null) {
          errors[path] = readResult.error ?? '未返回课表 JSON';
          continue;
        }
        final timetable = AcademicTimetableJsonParser.parse(payload);
        if (timetable.schedules.isEmpty) {
          errors[path] = '接口返回中没有可导入课程';
          continue;
        }
        successfulCandidates.add(
          TimetableProbeCandidate(path: path, timetable: timetable),
        );
        payloadsByPath[path] = payload;
      } catch (error) {
        if (error is _PageChangedDuringImport) {
          rethrow;
        }
        errors[path] = error.toString();
      }
    }

    ensurePageUnchanged();
    final selected = AcademicTimetableApiProbe.selectBestCandidate(
      successfulCandidates,
    );
    _lastProbeErrors = Map<String, String>.unmodifiable(errors);
    _lastSemesterApiError = selected == null
        ? errors.isEmpty
              ? '没有接口候选'
              : errors.entries
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join(' | ')
        : null;
    if (selected == null) {
      _lastJsonCourseSamples = const <String>[];
      return null;
    }

    _lastJsonCourseSamples = _buildJsonCourseSamples(
      payloadsByPath[selected.path] ?? '',
    );
    return _PreparedImport(
      timetable: selected.timetable,
      source: '接口探测',
      path: selected.path,
      summary: selected.summary,
    );
  }

  void _ensurePageGeneration(int expectedGeneration) {
    if (expectedGeneration != _pageGeneration) {
      throw const _PageChangedDuringImport('页面已变化，请在页面稳定后重试');
    }
  }

  Future<void> _persistPreparedImport(
    _PreparedImport prepared, {
    required ImportPreviewResult decision,
  }) async {
    final importedTimetable = prepared.timetable;
    final persistImportedTimetable = ref.read(persistImportedTimetableProvider);
    final result = await persistImportedTimetable(
      timetable: importedTimetable,
      detectedApiPath: prepared.path,
      acceptedSectionTimes: decision.applySectionTimes
          ? importedTimetable.sectionTimeEvidence?.settings
          : null,
    );

    if (!mounted) {
      return;
    }
    _lastImportSource = prepared.source;
    _lastPreviewSummary = prepared.summary;
    setState(() {
      _lastImportedScheduleCount = importedTimetable.schedules.length;
    });
    final warningText = result.warnings.isEmpty
        ? ''
        : '；${result.warnings.join('；')}';
    _showMessage(
      '已从${prepared.source}导入 ${importedTimetable.schedules.length} 条上课安排$warningText',
    );
  }

  Future<ImportPreviewResult?> _showImportPreview(_PreparedImport prepared) {
    _lastPreviewSummary = prepared.summary;
    return showDialog<ImportPreviewResult>(
      context: context,
      builder: (context) => ImportPreviewDialog(
        source: prepared.source,
        path: prepared.path,
        summary: prepared.summary,
        sectionTimeEvidence: prepared.timetable.sectionTimeEvidence,
      ),
    );
  }

  Future<_SemesterApiReadResult> _readSemesterTimetableJsonFromPath(
    String semesterApiPath, {
    int? schoolYearStart,
    int? semester,
  }) async {
    await _semesterApiChannelReady;
    final channelError = _semesterApiChannelError;
    if (channelError != null) {
      return _SemesterApiReadResult(error: channelError);
    }

    final response = await _semesterApiProbeClient.request(
      semesterApiPath: semesterApiPath,
      schoolYear: schoolYearStart?.toString(),
      semesterCode: semester == null ? null : (semester == 2 ? '12' : '3'),
    );
    final payload = _extractSemesterJsonPayload(response.value);
    if (payload != null) {
      return _SemesterApiReadResult(payload: payload);
    }
    return _SemesterApiReadResult(error: response.error ?? '未返回可识别的课表 JSON');
  }

  String? _extractSemesterJsonPayload(Object? decoded) {
    if (decoded is String) {
      return _looksLikeSchoolTimetableJson(decoded) ? decoded : null;
    }
    if (decoded is! Map) {
      return null;
    }

    final payload = decoded['payload'];
    if (payload is Map) {
      final encoded = jsonEncode(payload);
      return _looksLikeSchoolTimetableJson(encoded) ? encoded : null;
    }

    final text = decoded['text'];
    if (text is String && _looksLikeSchoolTimetableJson(text)) {
      return text;
    }

    return null;
  }

  bool _looksLikeSchoolTimetableJson(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) {
        return false;
      }
      return decoded['kbList'] is List || decoded['sjkList'] is List;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _readCurrentPageHtml() async {
    final rawResult = await _controller.runJavaScriptReturningResult(
      'document.documentElement ? document.documentElement.outerHTML : ""',
    );
    return WebViewHtmlCodec.decodeHtml(rawResult);
  }

  String _buildNoCourseMessage(String html) {
    final documentText = html
        .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final hasUndefined = documentText.contains('undefined');
    final hasEmptyHint =
        documentText.contains('无课') ||
        documentText.contains('暂无课程') ||
        documentText.contains('查询结果为无课');

    final hints = <String>['未在当前页面解析到课程'];
    if (hasUndefined) {
      hints.add('页面筛选项含 undefined，请先重新选择学年/学期并点查询');
    }
    if (hasEmptyHint) {
      hints.add('当前页面显示无课，请确认筛选条件和周次');
    }
    hints.add('如页面明明有课，请点右上角复制诊断摘要发给开发者适配');
    return hints.join('；');
  }

  Future<void> _copyDebugSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final html = _lastImportHtml ?? await _requireCurrentPageHtml();
      final summary = _buildDebugSummary(html);
      await Clipboard.setData(ClipboardData(text: summary));
      _showMessage('已复制诊断摘要');
    } catch (error) {
      _showMessage('复制失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _requireCurrentPageHtml() async {
    final html = await _readCurrentPageHtml();
    if (html == null || html.isEmpty) {
      throw StateError(_buildInvalidPageMessage());
    }
    _lastImportHtml = html;
    return html;
  }

  String _buildInvalidPageMessage() {
    return '当前 WebView 不是完整课表 HTML，可能停在空接口/JSON 返回页。请返回学生课表页面后再导入';
  }

  String _buildDebugSummary(String html) {
    final title = _firstMatch(html, RegExp(r'<title[^>]*>([\s\S]*?)</title>'));
    final trimmedHtml = html.trimLeft();
    final text = html
        .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'<[^>]+>'), '\n')
        .replaceAll(RegExp(r'\n\s+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    final weekLines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.contains('周'))
        .take(80)
        .join('\n');
    final styleSamples = RegExp(
      r'''<[^>]+(?:class|style)=["'][^"']*(?:course|lesson|kb|card|cell|grid|absolute|周)[^"']*["'][^>]*>''',
      caseSensitive: false,
    ).allMatches(html).take(40).map((match) => match.group(0)).join('\n');
    final payloadHint =
        trimmedHtml.startsWith('[') || trimmedHtml.startsWith('{')
        ? 'JSON'
        : 'HTML';
    final probeCandidates = _lastProbeCandidates.isEmpty
        ? 'none'
        : _lastProbeCandidates.join('\n');
    final probeErrors = _lastProbeErrors.isEmpty
        ? 'none'
        : _lastProbeErrors.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join('\n');
    final previewSummary = _lastPreviewSummary;
    final previewText = previewSummary == null
        ? 'none'
        : 'courses=${previewSummary.courseCount}, schedules=${previewSummary.scheduleCount}, suspicious=${previewSummary.isSuspicious}';
    final crowdedSlots =
        previewSummary == null || previewSummary.crowdedSlots.isEmpty
        ? 'none'
        : previewSummary.crowdedSlots
              .take(10)
              .map(
                (slot) =>
                    '第${slot.week}周 ${_weekdayLabel(slot.dayOfWeek)} 第${slot.startSection}-${slot.endSection}节: ${slot.count}',
              )
              .join('\n');
    final jsonSamples = _lastJsonCourseSamples.isEmpty
        ? 'none'
        : _lastJsonCourseSamples.join('\n');

    return '''
KiroTime 导入诊断摘要
URL: $_currentUrl
Title: ${title.isEmpty ? 'unknown' : title}
HTML length: ${html.length}
Payload type: $payloadHint
Last import source: $_lastImportSource
Semester API error: ${_lastSemesterApiError ?? 'none'}
Contains undefined: ${text.contains('undefined')}
Contains no-course hint: ${text.contains('无课') || text.contains('暂无课程') || text.contains('查询结果为无课')}

Probe candidates:
$probeCandidates

Probe errors:
$probeErrors

Preview:
$previewText

Crowded slots:
$crowdedSlots

JSON course samples:
$jsonSamples

Week-related text:
$weekLines

Candidate tags:
$styleSamples
''';
  }

  List<String> _buildJsonCourseSamples(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return const <String>[];
      }
      final samples = <String>[];
      for (final listKey in const <String>['kbList', 'sjkList']) {
        final rawList = decoded[listKey];
        if (rawList is! List) {
          continue;
        }
        var count = 0;
        for (final item in rawList.whereType<Map>()) {
          final sample = _compactJsonCourseSample(listKey, item);
          if (sample.isNotEmpty) {
            samples.add(sample);
            count++;
          }
          if (count >= 6 || samples.length >= 12) {
            break;
          }
        }
        if (samples.length >= 12) {
          break;
        }
      }
      return List<String>.unmodifiable(samples);
    } catch (_) {
      return const <String>[];
    }
  }

  String _compactJsonCourseSample(String listKey, Map item) {
    const preferredKeys = <String>[
      'kcmc',
      'jxbmc',
      'xm',
      'xqj',
      'jcs',
      'zcd',
      'xqmc',
      'cdmc',
      'kcxzmc',
      'kclbmc',
      'khfsmc',
      'kcbj',
      'xkbz',
      'sxbj',
      'zt',
      'sfyx',
    ];
    final parts = <String>[];
    for (final key in preferredKeys) {
      final value = item[key];
      if (value == null || value.toString().trim().isEmpty) {
        continue;
      }
      parts.add('$key=${_redactDiagnosticValue(key, value.toString())}');
    }
    if (parts.isEmpty) {
      return '';
    }
    return '$listKey: ${parts.join(', ')}';
  }

  String _redactDiagnosticValue(String key, String value) {
    final normalizedKey = key.toLowerCase();
    if (normalizedKey.contains('xh') ||
        normalizedKey.contains('xm') && key != 'xm') {
      return '<redacted>';
    }
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _firstMatch(String input, RegExp pattern) {
    final match = pattern.firstMatch(input);
    if (match == null || match.groupCount < 1) {
      return '';
    }
    return match.group(1)?.trim() ?? '';
  }

  String _weekdayLabel(int dayOfWeek) {
    const labels = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[(dayOfWeek - 1).clamp(0, labels.length - 1)];
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表'),
        actions: <Widget>[
          IconButton(
            tooltip: '复制诊断摘要',
            onPressed: _isLoading ? null : _copyDebugSummary,
            icon: const Icon(Icons.content_copy_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: GlassPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: _urlController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                      labelText: '教务系统网址',
                      hintText: 'https://example.edu.cn',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _isLoading ? null : (_) => _loadUrl(),
                  ),
                  const SizedBox(height: 10),
                  _buildUrlPresetChips(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _loadUrl,
                        icon: const Icon(Icons.open_in_browser_outlined),
                        label: const Text('打开页面'),
                      ),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _importCurrentPage,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.file_download_outlined),
                        label: const Text('导入当前页'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _probeSemesterApi,
                        icon: const Icon(Icons.travel_explore_outlined),
                        label: const Text('自动探测接口'),
                      ),
                      TextButton.icon(
                        onPressed: _isLoading ? null : _pinCurrentUrl,
                        icon: const Icon(Icons.push_pin_outlined, size: 18),
                        label: const Text('固定当前网址'),
                      ),
                    ],
                  ),
                  if (_currentUrl.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _currentUrl,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (_lastImportedScheduleCount != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Material(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '已导入 $_lastImportedScheduleCount 条上课安排',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('返回课表'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: AbsorbPointer(
                absorbing: _isLoading,
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparedImport {
  const _PreparedImport({
    required this.timetable,
    required this.source,
    required this.path,
    required this.summary,
  });

  final ImportedTimetable timetable;
  final String source;
  final String? path;
  final ImportPreviewSummary summary;
}

class _SemesterApiReadResult {
  const _SemesterApiReadResult({this.payload, this.error});

  final String? payload;
  final String? error;
}

class _PageChangedDuringImport implements Exception {
  const _PageChangedDuringImport(this.message);

  final String message;

  @override
  String toString() => message;
}
