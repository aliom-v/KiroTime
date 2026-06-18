import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/database/isar_database.dart';
import '../../settings/application/settings_providers.dart';
import '../../timetable/application/timetable_providers.dart';
import '../domain/academic_timetable_html_parser.dart';
import '../domain/academic_timetable_json_parser.dart';
import '../domain/webview_html_codec.dart';

class CourseImportPage extends ConsumerStatefulWidget {
  const CourseImportPage({super.key});

  @override
  ConsumerState<CourseImportPage> createState() => _CourseImportPageState();
}

class _CourseImportPageState extends ConsumerState<CourseImportPage> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _currentUrl = '';
  String? _lastImportHtml;
  String _lastImportSource = '未导入';
  String? _lastSemesterApiError;
  int? _lastImportedScheduleCount;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
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
    unawaited(_applyImportPreferences());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    final input = _urlController.text.trim();
    final uri = Uri.tryParse(input);
    if (uri == null || !uri.hasScheme) {
      _showMessage('请输入有效网址');
      return;
    }

    await _controller.loadRequest(uri);
  }

  Future<void> _applyImportPreferences() async {
    await ref.read(settingsBootstrapProvider.future);
    final preferences = ref.read(importPreferencesProvider);
    _urlController.text = preferences.academicSystemUrl;
    await _controller.setUserAgent(preferences.effectiveUserAgent);
    if (!preferences.keepWebViewLoginState) {
      await _controller.clearCache();
      await _controller.clearLocalStorage();
    }
  }

  Future<void> _importCurrentPage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final selectedSemester = ref.read(semesterSettingsProvider);
      ImportedTimetable? imported;
      var importSource = '';
      _lastSemesterApiError = null;

      final selectedTermPayload = await _readSemesterTimetableJson(
        schoolYearStart: selectedSemester.schoolYearStart,
        semester: selectedSemester.semester,
      );
      if (selectedTermPayload != null) {
        try {
          final candidate = AcademicTimetableJsonParser.parse(
            selectedTermPayload,
          );
          if (candidate.schedules.isNotEmpty) {
            imported = candidate;
            importSource = '${selectedSemester.label}接口';
          }
        } catch (error) {
          _lastSemesterApiError = '当前学期接口解析失败：$error';
        }
      }

      if (imported == null) {
        final pageTermPayload = await _readSemesterTimetableJson();
        if (pageTermPayload != null) {
          try {
            final candidate = AcademicTimetableJsonParser.parse(
              pageTermPayload,
            );
            if (candidate.schedules.isNotEmpty) {
              imported = candidate;
              importSource = '页面当前学期接口';
            }
          } catch (error) {
            _lastSemesterApiError = '页面当前学期接口解析失败：$error';
          }
        }
      }

      if (imported == null) {
        final html = await _readCurrentPageHtml();
        if (html == null || html.isEmpty) {
          _showMessage('导入失败：页面 HTML 为空');
          return;
        }
        _lastImportHtml = html;
        imported = AcademicTimetableHtmlParser.parse(html);
        importSource = '当前页面 HTML';
      }

      if (imported.schedules.isEmpty) {
        final html = _lastImportHtml ?? await _readCurrentPageHtml() ?? '';
        _showMessage('导入失败：${_buildNoCourseMessage(html)}');
        return;
      }
      final importedTimetable = imported;
      _lastImportSource = importSource;

      await ref.read(applyImportedSemesterMetadataProvider)(
        semesterStart: importedTimetable.semesterStart,
      );

      final isar = await ref.read(isarProvider.future);
      final semesterId = ref.read(selectedSemesterIdProvider);
      await KiroTimeDatabase.replaceWithImportedData(
        isar,
        semesterId: semesterId,
        metas: importedTimetable.metas,
        schedules: importedTimetable.schedules,
      );

      ref.invalidate(courseMetasProvider);
      ref.invalidate(allCourseSchedulesProvider);
      ref.invalidate(currentWeekSchedulesProvider);
      ref.invalidate(timetablePlacementsProvider);
      ref.invalidate(timetableVisibleItemsProvider);

      if (!mounted) {
        return;
      }
      setState(() {
        _lastImportedScheduleCount = importedTimetable.schedules.length;
      });
      _showMessage(
        '已从$importSource导入 ${importedTimetable.schedules.length} 条上课安排',
      );
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

  Future<String?> _readSemesterTimetableJson({
    int? schoolYearStart,
    int? semester,
  }) async {
    final semesterApiPath = ref
        .read(importPreferencesProvider)
        .semesterApiPath
        .trim();
    if (semesterApiPath.isEmpty) {
      return null;
    }
    final xnmExpression = schoolYearStart == null
        ? r"readValue('#xnm_hide')"
        : jsonEncode(schoolYearStart.toString());
    final xqmExpression = semester == null
        ? r"readValue('#xqm_hide')"
        : jsonEncode(semester == 2 ? '12' : '3');
    final script =
        '''
(function() {
  function readValue(selector) {
    var element = document.querySelector(selector);
    return element && element.value ? element.value : '';
  }
  var xnm = $xnmExpression;
  var xqm = $xqmExpression;
  var semesterApiPath = ${jsonEncode(semesterApiPath)};
  if (!xnm || !xqm) {
    return JSON.stringify({ok: false, error: 'missing xnm/xqm'});
  }
  var path = window._path || '';
  var body = new URLSearchParams();
  body.set('xnm', xnm);
  body.set('xqm', xqm);
  body.set('doType', 'app');
  body.set('kblx', '2');
  try {
    var xhr = new XMLHttpRequest();
    xhr.open('POST', semesterApiPath.indexOf('http') === 0 ? semesterApiPath : path + semesterApiPath, false);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    xhr.send(body.toString());
    var text = xhr.responseText || '';
    var payload = text;
    try {
      payload = JSON.parse(text);
    } catch (error) {}
    return JSON.stringify({
      ok: xhr.status >= 200 && xhr.status < 300,
      status: xhr.status,
      xnm: xnm,
      xqm: xqm,
      payload: payload,
      text: text
    });
  } catch (error) {
    return JSON.stringify({ok: false, xnm: xnm, xqm: xqm, error: String(error)});
  }
})()
''';

    final rawResult = await _controller.runJavaScriptReturningResult(script);
    final decoded = WebViewHtmlCodec.decodeJson(rawResult);
    final payload = _extractSemesterJsonPayload(decoded);
    if (payload == null) {
      if (decoded is Map && decoded['error'] != null) {
        _lastSemesterApiError = decoded['error'].toString();
      }
      return null;
    }
    return payload;
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

Week-related text:
$weekLines

Candidate tags:
$styleSamples
''';
  }

  String _firstMatch(String input, RegExp pattern) {
    final match = pattern.firstMatch(input);
    if (match == null || match.groupCount < 1) {
      return '';
    }
    return match.group(1)?.trim() ?? '';
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  decoration: const InputDecoration(
                    labelText: '教务系统网址',
                    hintText: 'https://example.edu.cn',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _loadUrl(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _loadUrl,
                      icon: const Icon(Icons.open_in_browser_outlined),
                      label: const Text('打开页面'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _importCurrentPage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download_outlined),
                      label: const Text('导入当前页'),
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
                    borderRadius: BorderRadius.circular(8),
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
          const Divider(height: 1),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }
}
