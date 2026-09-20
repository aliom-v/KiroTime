import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/isar_database.dart';
import '../../courses/data/course_meta.dart';
import '../../import/presentation/course_import_page.dart';
import '../../import_export/application/import_export_providers.dart';
import '../../import_export/domain/timetable_file_naming.dart';
import '../../import_export/domain/timetable_json_codec.dart';
import '../../timetable/application/timetable_providers.dart';
import '../../timetable/domain/semester_settings.dart';
import '../../timetable/domain/section_time_settings.dart';
import '../../timetable/domain/section_time_presets.dart';
import '../../timetable/presentation/timetable_page.dart';
import '../application/settings_providers.dart';
import '../domain/import_preferences.dart';
import '../domain/timetable_appearance_settings.dart';
import '../../../ui/glass.dart';

class SettingsCenterDialog extends ConsumerStatefulWidget {
  const SettingsCenterDialog({super.key});

  @override
  ConsumerState<SettingsCenterDialog> createState() =>
      _SettingsCenterDialogState();
}

class _SettingsCenterDialogState extends ConsumerState<SettingsCenterDialog> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _urlController;
  late final TextEditingController _semesterApiPathController;
  late final TextEditingController _customUaController;
  late SemesterSettings _editingSemester;
  late TimetableAppearanceSettings _appearance;
  late ImportPreferences _importPreferences;
  bool _creatingSemester = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _editingSemester = ref.read(semesterSettingsProvider);
    _appearance = ref.read(timetableAppearanceSettingsProvider);
    _importPreferences = ref.read(importPreferencesProvider);
    _displayNameController = TextEditingController(
      text: _editingSemester.displayName,
    );
    _urlController = TextEditingController(
      text: _importPreferences.academicSystemUrl,
    );
    _semesterApiPathController = TextEditingController(
      text: _importPreferences.semesterApiPath,
    );
    _customUaController = TextEditingController(
      text: _importPreferences.customUserAgent,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _urlController.dispose();
    _semesterApiPathController.dispose();
    _customUaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semesters = sortSemestersByAcademicTime(
      ref.watch(semesterListProvider),
    );
    final selectedId = ref.watch(selectedSemesterIdProvider);
    final mediaQuery = MediaQuery.of(context);
    final safeHeight =
        mediaQuery.size.height -
        mediaQuery.viewPadding.top -
        mediaQuery.viewPadding.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: safeHeight * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '设置',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SettingsSection(
                    title: '课表设置',
                    icon: Icons.calendar_month_outlined,
                    children: <Widget>[
                      Text(
                        '学期管理',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SemesterSwitcherGrid(
                        semesters: semesters,
                        selectedId: selectedId,
                        creatingSemester: _creatingSemester,
                        onSelect: _selectSemester,
                        onCreate: _startCreateSemester,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: '学期显示名称',
                          hintText: '可选，例如 大三上',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PickerTile(
                        label: '学年',
                        value:
                            '${_editingSemester.schoolYearStart}-${_editingSemester.schoolYearStart + 1}',
                        onTap: _pickSchoolYear,
                      ),
                      _PickerTile(
                        label: '学期',
                        value: _editingSemester.semester == 1 ? '第一学期' : '第二学期',
                        onTap: _pickSemester,
                      ),
                      _PickerTile(
                        label: '开学日期',
                        value: _formatDate(_editingSemester.semesterStart),
                        onTap: _pickStartDate,
                      ),
                      _PickerTile(
                        label: '总周数',
                        value: '${_editingSemester.totalWeeks}周',
                        onTap: _pickTotalWeeks,
                      ),
                      _PickerTile(
                        label: '每日节数',
                        value: '${_editingSemester.sectionCount}节',
                        onTap: _pickSectionCount,
                      ),
                      _ActionTile(
                        icon: Icons.schedule_outlined,
                        title: '上课时间',
                        onTap: _showSectionTimeSettings,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '时间模板（一键套用常见作息）',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KiroPalette.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SectionTimePresetRow(onApply: _applySectionTimePreset),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        onPressed: semesters.length <= 1 || _creatingSemester
                            ? null
                            : _deleteSemester,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('删除学期'),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: '外观',
                    icon: Icons.palette_outlined,
                    children: <Widget>[
                      _SegmentedRow<CourseColorScheme>(
                        label: '课程卡片颜色方案',
                        value: _appearance.colorScheme,
                        values: const <CourseColorScheme>[
                          CourseColorScheme.fixedByCourse,
                          CourseColorScheme.pastel,
                          CourseColorScheme.highContrast,
                        ],
                        labelBuilder: (value) => switch (value) {
                          CourseColorScheme.fixedByCourse => '随课程固定',
                          CourseColorScheme.pastel => '浅色',
                          CourseColorScheme.highContrast => '高对比',
                        },
                        onChanged: (value) => _updateAppearance(
                          _appearance.copyWith(colorScheme: value),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('是否显示周末'),
                        value: _appearance.showWeekend,
                        onChanged: (value) => _updateAppearance(
                          _appearance.copyWith(showWeekend: value),
                        ),
                      ),
                      _SegmentedRow<CourseCardDensity>(
                        label: '卡片密度',
                        value: _appearance.density,
                        values: const <CourseCardDensity>[
                          CourseCardDensity.compact,
                          CourseCardDensity.standard,
                        ],
                        labelBuilder: (value) => switch (value) {
                          CourseCardDensity.compact => '紧凑',
                          CourseCardDensity.standard => '标准',
                        },
                        onChanged: (value) => _updateAppearance(
                          _appearance.copyWith(density: value),
                        ),
                      ),
                      _SegmentedRow<CourseFontSize>(
                        label: '字体大小',
                        value: _appearance.fontSize,
                        values: const <CourseFontSize>[
                          CourseFontSize.small,
                          CourseFontSize.medium,
                          CourseFontSize.large,
                        ],
                        labelBuilder: (value) => switch (value) {
                          CourseFontSize.small => '小',
                          CourseFontSize.medium => '中',
                          CourseFontSize.large => '大',
                        },
                        onChanged: (value) => _updateAppearance(
                          _appearance.copyWith(fontSize: value),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('课程名'),
                        value: _appearance.showCourseName,
                        onChanged: (value) => _updateAppearance(
                          _appearance.copyWith(showCourseName: value ?? true),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('地点'),
                        value: _appearance.showClassroom,
                        onChanged: (value) => _updateAppearance(
                          _appearance.copyWith(showClassroom: value ?? true),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('老师'),
                        value: _appearance.showTeacher,
                        onChanged: (value) => _updateAppearance(
                          _appearance.copyWith(showTeacher: value ?? true),
                        ),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: '导入导出',
                    icon: Icons.import_export_outlined,
                    children: <Widget>[
                      _ActionTile(
                        icon: Icons.web_asset_outlined,
                        title: '从教务系统导入',
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CourseImportPage(),
                            ),
                          );
                        },
                      ),
                      if (_importPreferences
                          .savedAcademicUrls
                          .isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        _SavedUrlManager(
                          urls: _importPreferences.savedAcademicUrls,
                          onRemove: _removeSavedUrl,
                        ),
                      ],
                      _ActionTile(
                        icon: Icons.folder_open_outlined,
                        title: '从本地 JSON 导入',
                        onTap: _busy ? null : _importLocalJson,
                      ),
                      _ActionTile(
                        icon: Icons.content_paste_go_outlined,
                        title: '从剪贴板 JSON 导入',
                        onTap: _busy ? null : _importClipboardJson,
                      ),
                      _ActionTile(
                        icon: Icons.ios_share_outlined,
                        title: '导出当前学期 JSON',
                        onTap: _busy
                            ? null
                            : () => _exportJson(
                                TimetableExportScope.currentSemester,
                              ),
                      ),
                      _ActionTile(
                        icon: Icons.archive_outlined,
                        title: '导出全部学期 JSON',
                        onTap: _busy
                            ? null
                            : () => _exportJson(
                                TimetableExportScope.allSemesters,
                              ),
                      ),
                      _ActionTile(
                        icon: Icons.cleaning_services_outlined,
                        title: '清空当前学期课程',
                        destructive: true,
                        onTap: _busy ? null : _clearCurrentSemester,
                      ),
                      _ActionTile(
                        icon: Icons.delete_forever_outlined,
                        title: '清空全部数据',
                        destructive: true,
                        onTap: _busy ? null : _clearAllData,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: '高级设置',
                    icon: Icons.tune_outlined,
                    children: <Widget>[
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: '教务系统网址',
                          hintText: 'https://example.edu.cn',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _semesterApiPathController,
                        decoration: const InputDecoration(
                          labelText: '学期 JSON 接口路径（可选）',
                          hintText: '/path/to/semester_timetable',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SegmentedRow<UserAgentMode>(
                        label: 'User-Agent',
                        value: _importPreferences.userAgentMode,
                        values: const <UserAgentMode>[
                          UserAgentMode.mobile,
                          UserAgentMode.desktop,
                          UserAgentMode.custom,
                        ],
                        labelBuilder: (value) => switch (value) {
                          UserAgentMode.mobile => '手机',
                          UserAgentMode.desktop => '电脑',
                          UserAgentMode.custom => '自定义',
                        },
                        onChanged: (value) => setState(() {
                          _importPreferences = _importPreferences.copyWith(
                            userAgentMode: value,
                          );
                        }),
                      ),
                      if (_importPreferences.userAgentMode ==
                          UserAgentMode.custom) ...<Widget>[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customUaController,
                          decoration: const InputDecoration(
                            labelText: '自定义 User-Agent',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('保留 WebView 登录状态'),
                        value: _importPreferences.keepWebViewLoginState,
                        onChanged: (value) => setState(() {
                          _importPreferences = _importPreferences.copyWith(
                            keepWebViewLoginState: value,
                          );
                        }),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('解析失败时保留 HTML 诊断文件'),
                        value: _importPreferences.keepHtmlDiagnostics,
                        onChanged: (value) => setState(() {
                          _importPreferences = _importPreferences.copyWith(
                            keepHtmlDiagnostics: value,
                          );
                        }),
                      ),
                      _ActionTile(
                        icon: Icons.content_copy_outlined,
                        title: '复制导入诊断摘要',
                        onTap: () {
                          Clipboard.setData(
                            const ClipboardData(
                              text: '请在导入页面右上角复制当前 WebView 诊断摘要',
                            ),
                          );
                          _showMessage('已复制提示');
                        },
                      ),
                      _DatabaseDebugInfo(),
                      _ActionTile(
                        icon: Icons.info_outline_rounded,
                        title: '关于 KiroTime',
                        onTap: _showAboutDialog,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _busy ? null : _saveAdvancedSettings,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('保存高级设置'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE6EAEE))),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _saveSemester,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('保存设置'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectSemester(SemesterSettings settings) {
    setState(() {
      _creatingSemester = false;
      _editingSemester = settings;
      _displayNameController.text = settings.displayName;
    });
    unawaited(ref.read(selectSemesterProvider)(settings));
  }

  void _startCreateSemester() {
    final current = ref.read(semesterSettingsProvider);
    setState(() {
      _creatingSemester = true;
      _editingSemester = SemesterSettings(
        schoolYearStart: current.schoolYearStart,
        semester: 1,
        semesterStart: current.semesterStart,
        totalWeeks: current.totalWeeks,
        sectionCount: current.sectionCount,
      );
      _displayNameController.clear();
    });
  }

  Future<void> _saveSemester() async {
    final settings = _editingSemester.copyWith(
      displayName: _displayNameController.text.trim(),
    );
    setState(() {
      _busy = true;
    });
    try {
      if (_creatingSemester) {
        final created = await ref.read(addSemesterProvider)(settings);
        setState(() {
          _creatingSemester = false;
          _editingSemester = created;
        });
      } else {
        await ref.read(updateSelectedSemesterProvider)(settings);
      }
      if (mounted) {
        _showMessage('已保存学期设置');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        _showMessage('保存失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _deleteSemester() async {
    final semesters = ref.read(semesterListProvider);
    if (semesters.length <= 1) {
      _showMessage('至少保留一个学期');
      return;
    }
    final confirmed = await showKiroDialog<bool>(
      context: context,
      child: _ConfirmDialog(
        title: '删除学期',
        message: '确定删除「${_editingSemester.label}」吗？该学期下的课程也会删除，其他学期不受影响。',
        confirmLabel: '删除',
        destructive: true,
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      await ref.read(deleteSemesterProvider)(_editingSemester.id);
      final next = ref.read(semesterSettingsProvider);
      setState(() {
        _editingSemester = next;
        _displayNameController.text = next.displayName;
      });
      _showMessage('已删除学期');
    } catch (error) {
      _showMessage('删除失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _pickSchoolYear() async {
    final year = await _pickNumber(
      title: '学年',
      initialValue: _editingSemester.schoolYearStart,
      values: List<int>.generate(13, (index) => 2020 + index),
      labelBuilder: (value) => '$value-${value + 1}',
    );
    if (year != null) {
      setState(() {
        _editingSemester = _editingSemester.copyWith(schoolYearStart: year);
      });
    }
  }

  Future<void> _pickSemester() async {
    final semester = await _pickNumber(
      title: '学期',
      initialValue: _editingSemester.semester,
      values: const <int>[1, 2],
      labelBuilder: (value) => value == 1 ? '第一学期' : '第二学期',
    );
    if (semester != null) {
      setState(() {
        _editingSemester = _editingSemester.copyWith(semester: semester);
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showKiroDialog<DateTime>(
      context: context,
      child: _DateWheelDialog(initialDate: _editingSemester.semesterStart),
    );
    if (picked != null) {
      setState(() {
        _editingSemester = _editingSemester.copyWith(semesterStart: picked);
      });
    }
  }

  Future<void> _pickTotalWeeks() async {
    final weeks = await _pickNumber(
      title: '总周数',
      initialValue: _editingSemester.totalWeeks.clamp(16, 24),
      values: List<int>.generate(9, (index) => 16 + index),
      labelBuilder: (value) => '$value周',
    );
    if (weeks != null) {
      setState(() {
        _editingSemester = _editingSemester.copyWith(totalWeeks: weeks);
      });
    }
  }

  Future<void> _pickSectionCount() async {
    final sections = await _pickNumber(
      title: '每日节数',
      initialValue: _editingSemester.sectionCount.clamp(8, 16),
      values: List<int>.generate(9, (index) => 8 + index),
      labelBuilder: (value) => '$value节',
    );
    if (sections != null) {
      setState(() {
        _editingSemester = _editingSemester.copyWith(sectionCount: sections);
      });
    }
  }

  Future<void> _showSectionTimeSettings() async {
    final updated = await showKiroDialog<SectionTimeSettings>(
      context: context,
      child: _SectionTimeSettingsDialog(
        sectionCount: _editingSemester.sectionCount,
        initialSettings: _editingSemester.sectionTimeSettings,
      ),
    );
    if (updated != null) {
      setState(() {
        _editingSemester = _editingSemester.copyWith(
          sectionTimeSettings: updated,
        );
      });
    }
  }

  Future<int?> _pickNumber({
    required String title,
    required int initialValue,
    required List<int> values,
    required String Function(int value) labelBuilder,
  }) {
    return showKiroDialog<int>(
      context: context,
      child: _NumberWheelDialog(
        title: title,
        initialValue: initialValue,
        values: values,
        labelBuilder: labelBuilder,
      ),
    );
  }

  void _updateAppearance(TimetableAppearanceSettings settings) {
    setState(() {
      _appearance = settings;
    });
    unawaited(ref.read(saveAppearanceSettingsProvider)(settings));
  }

  void _applySectionTimePreset(SectionTimePreset preset) {
    final settings = preset.build(_editingSemester.sectionCount);
    setState(() {
      _editingSemester = _editingSemester.copyWith(
        sectionTimeSettings: settings,
      );
    });
    _showMessage('已套用「${preset.name}」，记得点击保存设置');
  }

  void _removeSavedUrl(String url) {
    final next = <String>[
      for (final item in _importPreferences.savedAcademicUrls)
        if (item != url) item,
    ];
    final updated = _importPreferences.copyWith(savedAcademicUrls: next);
    setState(() => _importPreferences = updated);
    unawaited(ref.read(saveImportPreferencesProvider)(updated));
  }

  Future<void> _exportJson(TimetableExportScope scope) async {
    final defaultName = TimetableFileNaming.defaultExportFileName(
      scope: scope,
      semesterLabel: ref.read(semesterSettingsProvider).label,
      now: DateTime.now(),
    );
    final pickedName = await showKiroDialog<String>(
      context: context,
      child: _ExportFileNameDialog(initialFileName: defaultName),
    );
    if (pickedName == null) {
      return;
    }
    final fileName = TimetableFileNaming.sanitizeJsonFileName(pickedName);
    if (!mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final gateway = ref.read(timetableFileGatewayProvider);
      var exportName = fileName;
      var overwrite = false;
      final exists = await gateway.fileExistsInDownloads(exportName);
      if (exists) {
        if (!mounted) {
          return;
        }
        final choice = await showKiroDialog<_ExportCollisionChoice>(
          context: context,
          child: _ExportCollisionDialog(fileName: exportName),
        );
        if (choice == null || choice == _ExportCollisionChoice.cancel) {
          return;
        }
        if (choice == _ExportCollisionChoice.overwrite) {
          overwrite = true;
        } else {
          final existingNames = <String>{exportName};
          do {
            exportName = TimetableFileNaming.copyNameFor(
              exportName,
              existingNames,
            );
            existingNames.add(exportName);
          } while (await gateway.fileExistsInDownloads(exportName));
        }
      }
      final json = await ref.read(exportTimetableJsonProvider)(scope: scope);
      final exported = await gateway.exportTimetableJson(
        fileName: exportName,
        json: json,
        overwrite: overwrite,
      );
      _showMessage('已导出到 ${exported.displayPath}');
    } catch (error) {
      _showMessage('导出失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _importLocalJson() async {
    setState(() => _busy = true);
    try {
      final pickedFile = await ref
          .read(timetableFileGatewayProvider)
          .pickTimetableJson();
      if (pickedFile == null) {
        return;
      }
      final picked = ref.read(parseTimetableJsonFromTextProvider)(
        pickedFile.json,
        fileName: pickedFile.fileName,
      );
      await _confirmAndApplyImport(picked);
    } catch (error) {
      _showMessage('导入失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _importClipboardJson() async {
    setState(() => _busy = true);
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboard?.text?.trim();
      if (text == null || text.isEmpty) {
        if (!mounted) {
          return;
        }
        _showMessage('剪贴板没有 JSON 内容');
        return;
      }
      final picked = ref.read(parseTimetableJsonFromTextProvider)(text);
      await _confirmAndApplyImport(picked);
    } catch (error) {
      _showMessage('导入失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _confirmAndApplyImport(PickedTimetableImport picked) async {
    if (!mounted) {
      return;
    }
    final mode = await showKiroDialog<TimetableImportMode>(
      context: context,
      child: _ImportPreviewDialog(import: picked),
    );
    if (mode == null) {
      return;
    }
    await ref.read(applyTimetableImportProvider)(picked.snapshot, mode: mode);
    if (!mounted) {
      return;
    }
    final message = switch (mode) {
      TimetableImportMode.overwriteCurrentSemester =>
        '已导入 ${picked.preview.scheduleCount} 条上课安排',
      TimetableImportMode.createNewSemester =>
        '已新建学期并导入 ${picked.preview.scheduleCount} 条上课安排',
      TimetableImportMode.overwriteAllData => '已恢复全部课表数据',
    };
    _showMessage(message);
  }

  Future<void> _clearCurrentSemester() async {
    final confirmed = await showKiroDialog<bool>(
      context: context,
      child: const _ConfirmDialog(
        title: '清空当前学期课程',
        message: '确定清空当前学期全部课程吗？学期设置会保留。',
        confirmLabel: '清空',
        destructive: true,
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      await ref.read(clearCurrentSemesterCoursesProvider)();
      _showMessage('已清空当前学期课程');
    } catch (error) {
      _showMessage('清空失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showKiroDialog<bool>(
      context: context,
      child: const _ConfirmDialog(
        title: '清空全部数据',
        message: '确定清空全部学期、课程和本地设置吗？该操作会恢复为空白课表，建议先导出全部学期 JSON。',
        confirmLabel: '清空全部',
        destructive: true,
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      await ref.read(clearAllLocalDataProvider)();
      final next = ref.read(semesterSettingsProvider);
      setState(() {
        _editingSemester = next;
        _displayNameController.text = next.displayName;
      });
      _showMessage('已恢复为空白课表');
    } catch (error) {
      _showMessage('清空失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _saveAdvancedSettings() async {
    final preferences = _importPreferences.copyWith(
      academicSystemUrl: _urlController.text.trim(),
      semesterApiPath: _semesterApiPathController.text.trim(),
      customUserAgent: _customUaController.text.trim(),
    );
    setState(() {
      _busy = true;
      _importPreferences = preferences;
    });
    try {
      await ref.read(saveImportPreferencesProvider)(preferences);
      _showMessage('已保存高级设置');
    } catch (error) {
      _showMessage('保存失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _showAboutDialog() {
    return showKiroDialog<void>(
      context: context,
      child: const _AboutKiroTimeDialog(),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SemesterSwitcherGrid extends StatelessWidget {
  const _SemesterSwitcherGrid({
    required this.semesters,
    required this.selectedId,
    required this.creatingSemester,
    required this.onSelect,
    required this.onCreate,
  });

  final List<SemesterSettings> semesters;
  final String selectedId;
  final bool creatingSemester;
  final ValueChanged<SemesterSettings> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: const ValueKey<String>('semester-switcher-grid'),
      crossAxisCount: 2,
      childAspectRatio: 2.35,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        for (final semester in semesters)
          _SemesterSwitchCard(
            key: ValueKey<String>('semester-card-${semester.id}'),
            title: semester.label,
            subtitle:
                '${_formatDate(semester.semesterStart)} · ${semester.totalWeeks}周',
            selected: !creatingSemester && semester.id == selectedId,
            onTap: () => onSelect(semester),
          ),
        _SemesterSwitchCard(
          key: const ValueKey<String>('semester-card-add'),
          title: '新增学期',
          subtitle: '添加前后学期',
          selected: creatingSemester,
          leadingIcon: Icons.add_rounded,
          onTap: onCreate,
        ),
      ],
    );
  }
}

class _SemesterSwitchCard extends StatelessWidget {
  const _SemesterSwitchCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = selected ? const Color(0xFF157A6E) : const Color(0xFFB9D8D2);
    final background = selected ? const Color(0xFFE8FFF8) : Colors.white;
    final border = selected ? const Color(0xFF59B9A6) : const Color(0xFFE3ECE9);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
                  child: Row(
                    children: <Widget>[
                      if (leadingIcon != null) ...<Widget>[
                        Icon(leadingIcon, size: 19, color: accent),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF163A35),
                                fontWeight: selected
                                    ? FontWeight.w900
                                    : FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF6D7B78),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedUrlManager extends StatelessWidget {
  const _SavedUrlManager({required this.urls, required this.onRemove});

  final List<String> urls;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '常用教务网址',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: KiroPalette.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        for (final url in urls)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.push_pin_outlined,
                  size: 16,
                  color: KiroPalette.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: '移除',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onRemove(url),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionTimePresetRow extends StatelessWidget {
  const _SectionTimePresetRow({required this.onApply});

  final ValueChanged<SectionTimePreset> onApply;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SectionTimePresets.catalog.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final preset = SectionTimePresets.catalog[index];
          return GlassChipButton(
            label: preset.name,
            icon: Icons.schedule_rounded,
            onPressed: () => onApply(preset),
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white.withValues(alpha: 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: KiroPalette.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 20, color: KiroPalette.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red.shade700 : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SegmentedRow<T extends Object> extends StatelessWidget {
  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SegmentedButton<T>(
            segments: <ButtonSegment<T>>[
              for (final item in values)
                ButtonSegment<T>(value: item, label: Text(labelBuilder(item))),
            ],
            selected: <T>{value},
            onSelectionChanged: (selection) => onChanged(selection.single),
          ),
        ],
      ),
    );
  }
}

class _SectionTimeSettingsDialog extends StatefulWidget {
  const _SectionTimeSettingsDialog({
    required this.sectionCount,
    required this.initialSettings,
  });

  final int sectionCount;
  final SectionTimeSettings initialSettings;

  @override
  State<_SectionTimeSettingsDialog> createState() =>
      _SectionTimeSettingsDialogState();
}

class _SectionTimeSettingsDialogState
    extends State<_SectionTimeSettingsDialog> {
  late SectionTimeSettings _settings = widget.initialSettings
      .ensureSectionCount(widget.sectionCount);

  @override
  Widget build(BuildContext context) {
    return _SimpleDialogFrame(
      title: '上课时间',
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_settings),
          child: const Text('保存'),
        ),
      ],
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '当前 ${widget.sectionCount} 节',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              onPressed: _restoreDefault,
              icon: const Icon(Icons.restore_outlined),
              label: const Text('恢复默认'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _generateWithRules,
          icon: const Icon(Icons.auto_fix_high_outlined),
          label: const Text('三段式快速生成'),
        ),
        const SizedBox(height: 12),
        for (final sectionTime in _settings.sections)
          _SectionTimeListTile(
            sectionTime: sectionTime,
            onTap: () => _editSection(sectionTime),
          ),
      ],
    );
  }

  Future<void> _editSection(SectionTime sectionTime) async {
    final updated = await showKiroDialog<SectionTime>(
      context: context,
      child: _SectionTimeEditDialog(sectionTime: sectionTime),
    );
    if (updated != null) {
      setState(() {
        _settings = _settings
            .replaceSection(updated)
            .ensureSectionCount(widget.sectionCount);
      });
    }
  }

  Future<void> _generateWithRules() async {
    final generated = await showKiroDialog<SectionTimeSettings>(
      context: context,
      child: _SectionTimeGenerateDialog(sectionCount: widget.sectionCount),
    );
    if (generated != null) {
      setState(() {
        _settings = generated.ensureSectionCount(widget.sectionCount);
      });
    }
  }

  void _restoreDefault() {
    setState(() {
      _settings = SectionTimeSettings.defaultForSectionCount(
        widget.sectionCount,
      );
    });
  }
}

class _SectionTimeListTile extends StatelessWidget {
  const _SectionTimeListTile({required this.sectionTime, required this.onTap});

  final SectionTime sectionTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFA),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 62,
                child: Text(
                  '第 ${sectionTime.section} 节',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Text(
                  sectionTime.timeRangeText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.edit_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTimeEditDialog extends StatefulWidget {
  const _SectionTimeEditDialog({required this.sectionTime});

  final SectionTime sectionTime;

  @override
  State<_SectionTimeEditDialog> createState() => _SectionTimeEditDialogState();
}

class _SectionTimeEditDialogState extends State<_SectionTimeEditDialog> {
  late final TextEditingController _startController = TextEditingController(
    text: widget.sectionTime.startText,
  );
  late final TextEditingController _endController = TextEditingController(
    text: widget.sectionTime.endText,
  );
  String? _errorText;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleDialogFrame(
      title: '第 ${widget.sectionTime.section} 节',
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
      children: <Widget>[
        TextField(
          controller: _startController,
          decoration: const InputDecoration(
            labelText: '开始时间',
            hintText: '08:10',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _endController,
          decoration: const InputDecoration(
            labelText: '结束时间',
            hintText: '08:55',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.datetime,
        ),
        if (_errorText != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_errorText!, style: TextStyle(color: Colors.red.shade700)),
        ],
      ],
    );
  }

  void _save() {
    final start = SectionTimeSettings.parseClockText(_startController.text);
    final end = SectionTimeSettings.parseClockText(_endController.text);
    if (start == null || end == null) {
      setState(() {
        _errorText = '请输入 HH:mm 格式的时间';
      });
      return;
    }
    if (end <= start) {
      setState(() {
        _errorText = '结束时间必须晚于开始时间';
      });
      return;
    }
    Navigator.of(context).pop(
      SectionTime(
        section: widget.sectionTime.section,
        startMinutes: start,
        endMinutes: end,
      ),
    );
  }
}

class _SectionTimeGenerateDialog extends StatefulWidget {
  const _SectionTimeGenerateDialog({required this.sectionCount});

  final int sectionCount;

  @override
  State<_SectionTimeGenerateDialog> createState() =>
      _SectionTimeGenerateDialogState();
}

class _SectionTimeGenerateDialogState
    extends State<_SectionTimeGenerateDialog> {
  late final List<_EditableDayPartRule> _rules = _defaultRules(
    widget.sectionCount,
  );
  String? _errorText;

  @override
  void dispose() {
    for (final rule in _rules) {
      rule.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleDialogFrame(
      title: '三段式快速生成',
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _generate, child: const Text('生成')),
      ],
      children: <Widget>[
        for (final rule in _rules) _EditableDayPartRuleCard(rule: rule),
        if (_errorText != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_errorText!, style: TextStyle(color: Colors.red.shade700)),
        ],
      ],
    );
  }

  void _generate() {
    final rules = <DayPartTimeRule>[];
    for (final editable in _rules) {
      final parsed = editable.toRule();
      if (parsed == null) {
        setState(() {
          _errorText = '请检查三段配置，时间用 HH:mm，数字字段必须大于 0';
        });
        return;
      }
      if (parsed.sectionCount > 0) {
        rules.add(parsed);
      }
    }
    Navigator.of(context).pop(
      SectionTimeSettings.generate(
        sectionCount: widget.sectionCount,
        rules: rules,
      ),
    );
  }

  static List<_EditableDayPartRule> _defaultRules(int sectionCount) {
    final morningCount = sectionCount.clamp(0, 4);
    final afternoonCount = (sectionCount - 4).clamp(0, 4);
    final eveningCount = (sectionCount - 8).clamp(0, 8);
    return <_EditableDayPartRule>[
      _EditableDayPartRule(
        name: '上午',
        startSection: 1,
        sectionCount: morningCount,
        startTime: '08:10',
        longBreakAfterSection: 2,
        longBreakEnabled: morningCount > 2,
      ),
      _EditableDayPartRule(
        name: '下午',
        startSection: 5,
        sectionCount: afternoonCount,
        startTime: '14:10',
        longBreakAfterSection: 6,
        longBreakEnabled: afternoonCount > 2,
      ),
      _EditableDayPartRule(
        name: '晚上',
        startSection: 9,
        sectionCount: eveningCount,
        startTime: '19:00',
        longBreakAfterSection: 0,
        longBreakEnabled: false,
      ),
    ];
  }
}

class _EditableDayPartRuleCard extends StatefulWidget {
  const _EditableDayPartRuleCard({required this.rule});

  final _EditableDayPartRule rule;

  @override
  State<_EditableDayPartRuleCard> createState() =>
      _EditableDayPartRuleCardState();
}

class _EditableDayPartRuleCardState extends State<_EditableDayPartRuleCard> {
  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4EAEC)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                rule.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SmallTextField(
                      controller: rule.startSectionController,
                      label: '起始节次',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallTextField(
                      controller: rule.sectionCountController,
                      label: '节数',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SmallTextField(
                      controller: rule.startTimeController,
                      label: '开始时间',
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallTextField(
                      controller: rule.durationController,
                      label: '每节时长',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SmallTextField(
                      controller: rule.breakController,
                      label: '小课间',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallTextField(
                      controller: rule.longBreakController,
                      label: '大课间时长',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用大课间'),
                value: rule.longBreakEnabled,
                onChanged: (value) =>
                    setState(() => rule.longBreakEnabled = value),
              ),
              if (rule.longBreakEnabled)
                _SmallTextField(
                  controller: rule.longBreakAfterController,
                  label: '大课间在第几节后',
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallTextField extends StatelessWidget {
  const _SmallTextField({
    required this.controller,
    required this.label,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _EditableDayPartRule {
  _EditableDayPartRule({
    required this.name,
    required int startSection,
    required int sectionCount,
    required String startTime,
    required int longBreakAfterSection,
    required this.longBreakEnabled,
  }) : startSectionController = TextEditingController(text: '$startSection'),
       sectionCountController = TextEditingController(text: '$sectionCount'),
       startTimeController = TextEditingController(text: startTime),
       durationController = TextEditingController(
         text: '${SectionTimeSettings.defaultSectionDurationMinutes}',
       ),
       breakController = TextEditingController(
         text: '${SectionTimeSettings.defaultBreakMinutes}',
       ),
       longBreakAfterController = TextEditingController(
         text: '$longBreakAfterSection',
       ),
       longBreakController = TextEditingController(text: '20');

  final String name;
  final TextEditingController startSectionController;
  final TextEditingController sectionCountController;
  final TextEditingController startTimeController;
  final TextEditingController durationController;
  final TextEditingController breakController;
  final TextEditingController longBreakAfterController;
  final TextEditingController longBreakController;
  bool longBreakEnabled;

  DayPartTimeRule? toRule() {
    final startSection = int.tryParse(startSectionController.text.trim());
    final sectionCount = int.tryParse(sectionCountController.text.trim());
    final startMinutes = SectionTimeSettings.parseClockText(
      startTimeController.text,
    );
    final duration = int.tryParse(durationController.text.trim());
    final breakMinutes = int.tryParse(breakController.text.trim());
    final longBreakAfter = int.tryParse(longBreakAfterController.text.trim());
    final longBreakMinutes = int.tryParse(longBreakController.text.trim());
    if (startSection == null ||
        sectionCount == null ||
        startMinutes == null ||
        duration == null ||
        breakMinutes == null ||
        longBreakAfter == null ||
        longBreakMinutes == null ||
        startSection <= 0 ||
        sectionCount < 0 ||
        duration <= 0 ||
        breakMinutes < 0 ||
        longBreakMinutes < 0) {
      return null;
    }
    return DayPartTimeRule(
      name: name,
      startSection: startSection,
      sectionCount: sectionCount,
      startMinutes: startMinutes,
      sectionDurationMinutes: duration,
      breakMinutes: breakMinutes,
      longBreakEnabled: longBreakEnabled,
      longBreakAfterSection: longBreakAfter,
      longBreakMinutes: longBreakMinutes,
    );
  }

  void dispose() {
    startSectionController.dispose();
    sectionCountController.dispose();
    startTimeController.dispose();
    durationController.dispose();
    breakController.dispose();
    longBreakAfterController.dispose();
    longBreakController.dispose();
  }
}

class _NumberWheelDialog extends StatefulWidget {
  const _NumberWheelDialog({
    required this.title,
    required this.initialValue,
    required this.values,
    required this.labelBuilder,
  });

  final String title;
  final int initialValue;
  final List<int> values;
  final String Function(int value) labelBuilder;

  @override
  State<_NumberWheelDialog> createState() => _NumberWheelDialogState();
}

class _NumberWheelDialogState extends State<_NumberWheelDialog> {
  late int _selectedValue = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final initialIndex = widget.values.indexOf(widget.initialValue);
    return _WheelDialogScaffold(
      title: widget.title,
      child: ListWheelScrollView.useDelegate(
        controller: FixedExtentScrollController(
          initialItem: initialIndex < 0 ? 0 : initialIndex,
        ),
        itemExtent: 44,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedValue = widget.values[index];
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.values.length,
          builder: (context, index) {
            final value = widget.values[index];
            final selected = value == _selectedValue;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _selectedValue = value;
                });
              },
              child: Center(
                child: _WheelValueText(
                  key: selected
                      ? ValueKey<String>('wheel-selected-number-$value')
                      : ValueKey<String>('wheel-number-$value'),
                  label: widget.labelBuilder(value),
                  selected: selected,
                ),
              ),
            );
          },
        ),
      ),
      onConfirm: () => Navigator.of(context).pop(_selectedValue),
    );
  }
}

class _DateWheelDialog extends StatefulWidget {
  const _DateWheelDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_DateWheelDialog> createState() => _DateWheelDialogState();
}

class _DateWheelDialogState extends State<_DateWheelDialog> {
  late int _year = widget.initialDate.year;
  late int _month = widget.initialDate.month;
  late int _day = widget.initialDate.day;

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(13, (index) => 2020 + index);
    final months = List<int>.generate(12, (index) => index + 1);
    final maxDay = DateTime(_year, _month + 1, 0).day;
    final days = List<int>.generate(maxDay, (index) => index + 1);
    if (_day > maxDay) {
      _day = maxDay;
    }

    return _WheelDialogScaffold(
      title: '开学日期',
      child: Row(
        children: <Widget>[
          Expanded(
            child: _IntWheel(
              values: years,
              initialValue: _year,
              keyPrefix: 'year',
              labelBuilder: (value) => '$value年',
              onChanged: (value) => setState(() => _year = value),
            ),
          ),
          Expanded(
            child: _IntWheel(
              values: months,
              initialValue: _month,
              keyPrefix: 'month',
              labelBuilder: (value) => '$value月',
              onChanged: (value) => setState(() => _month = value),
            ),
          ),
          Expanded(
            child: _IntWheel(
              values: days,
              initialValue: _day,
              keyPrefix: 'day',
              labelBuilder: (value) => '$value日',
              onChanged: (value) => setState(() => _day = value),
            ),
          ),
        ],
      ),
      onConfirm: () => Navigator.of(context).pop(DateTime(_year, _month, _day)),
    );
  }
}

class _IntWheel extends StatelessWidget {
  const _IntWheel({
    required this.values,
    required this.initialValue,
    required this.labelBuilder,
    required this.onChanged,
    required this.keyPrefix,
  });

  final List<int> values;
  final int initialValue;
  final String Function(int value) labelBuilder;
  final ValueChanged<int> onChanged;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final initialIndex = values.indexOf(initialValue);
    return ListWheelScrollView.useDelegate(
      controller: FixedExtentScrollController(
        initialItem: initialIndex < 0 ? 0 : initialIndex,
      ),
      itemExtent: 44,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => onChanged(values[index]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final value = values[index];
          final selected = value == initialValue;
          final prefix = keyPrefix ?? 'int';
          return Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(value),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: _WheelValueText(
                    key: selected
                        ? ValueKey<String>('wheel-selected-$prefix-$value')
                        : ValueKey<String>('wheel-$prefix-$value'),
                    label: labelBuilder(value),
                    selected: selected,
                    compact: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WheelValueText extends StatelessWidget {
  const _WheelValueText({
    super.key,
    required this.label,
    required this.selected,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final baseStyle = compact
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.titleMedium;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE6FFF6) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 18,
          vertical: compact ? 5 : 6,
        ),
        child: Text(
          label,
          style: baseStyle?.copyWith(
            fontSize: selected ? (compact ? 16 : 18) : (compact ? 14 : 15),
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected ? const Color(0xFF14332F) : const Color(0xFF87908D),
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _WheelDialogScaffold extends StatelessWidget {
  const _WheelDialogScaffold({
    required this.title,
    required this.child,
    required this.onConfirm,
  });

  final String title;
  final Widget child;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: onConfirm, child: const Text('确定')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ExportCollisionChoice { overwrite, createCopy, cancel }

class _ExportFileNameDialog extends StatefulWidget {
  const _ExportFileNameDialog({required this.initialFileName});

  final String initialFileName;

  @override
  State<_ExportFileNameDialog> createState() => _ExportFileNameDialogState();
}

class _ExportFileNameDialogState extends State<_ExportFileNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialFileName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleDialogFrame(
      title: '导出 JSON',
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
      children: <Widget>[
        const Text('导出的文件包含完整课表信息，包括课程、老师、地点、教学班级和周次，请妥善保存。'),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '文件名',
            helperText: '将保存到 下载/KiroTime',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
      ],
    );
  }
}

class _ExportCollisionDialog extends StatelessWidget {
  const _ExportCollisionDialog({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return _SimpleDialogFrame(
      title: '文件已存在',
      actions: <Widget>[
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_ExportCollisionChoice.cancel),
          child: const Text('取消'),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(_ExportCollisionChoice.createCopy),
          child: const Text('新建副本'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_ExportCollisionChoice.overwrite),
          child: const Text('覆盖'),
        ),
      ],
      children: <Widget>[
        Text('下载/KiroTime/$fileName 已存在。'),
        const SizedBox(height: 8),
        const Text('可以覆盖原文件，也可以新建一个带编号的副本。'),
      ],
    );
  }
}

class _ImportPreviewDialog extends StatefulWidget {
  const _ImportPreviewDialog({required this.import});

  final PickedTimetableImport import;

  @override
  State<_ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<_ImportPreviewDialog> {
  late TimetableImportMode _mode =
      widget.import.preview.scope == TimetableExportScope.allSemesters
      ? TimetableImportMode.overwriteAllData
      : TimetableImportMode.overwriteCurrentSemester;

  @override
  Widget build(BuildContext context) {
    final preview = widget.import.preview;
    return _SimpleDialogFrame(
      title: '导入前预览',
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_mode),
          child: const Text('确认导入'),
        ),
      ],
      children: <Widget>[
        _PreviewLine(label: '文件', value: widget.import.fileName),
        _PreviewLine(label: '课程数量', value: '${preview.courseCount}门'),
        _PreviewLine(label: '上课安排', value: '${preview.scheduleCount}条'),
        _PreviewLine(label: '冲突数量', value: '${preview.conflictCount}处'),
        _PreviewLine(
          label: '学期起始日期',
          value: preview.semesterStart == null
              ? '未包含'
              : _formatDate(preview.semesterStart!),
        ),
        _PreviewLine(
          label: '导入范围',
          value: preview.scope == TimetableExportScope.currentSemester
              ? '当前学期'
              : '全部学期',
        ),
        const SizedBox(height: 12),
        Text(
          '导入方式',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        _ImportModeTile(
          title: '覆盖当前学期',
          subtitle: '只替换当前学期课程，保留其他学期',
          selected: _mode == TimetableImportMode.overwriteCurrentSemester,
          onTap: () => setState(
            () => _mode = TimetableImportMode.overwriteCurrentSemester,
          ),
        ),
        _ImportModeTile(
          title: '新建为一个学期',
          subtitle: '保留现有课表，导入内容作为新学期',
          selected: _mode == TimetableImportMode.createNewSemester,
          onTap: () =>
              setState(() => _mode = TimetableImportMode.createNewSemester),
        ),
        _ImportModeTile(
          title: '覆盖全部数据',
          subtitle: '用备份替换本地全部学期、课程和设置',
          selected: _mode == TimetableImportMode.overwriteAllData,
          onTap: () =>
              setState(() => _mode = TimetableImportMode.overwriteAllData),
        ),
      ],
    );
  }
}

class _ImportModeTile extends StatelessWidget {
  const _ImportModeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF157A6E) : const Color(0xFF7A8582);
    return Material(
      color: selected ? const Color(0xFFE8FFF8) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: color,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6D7B78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutKiroTimeDialog extends StatelessWidget {
  const _AboutKiroTimeDialog();

  @override
  Widget build(BuildContext context) {
    return _SimpleDialogFrame(
      title: '关于 KiroTime',
      actions: <Widget>[
        TextButton(
          onPressed: () {
            showKiroDialog<void>(
              context: context,
              child: const _PrivacyNoticeDialog(),
            );
          },
          child: const Text('隐私说明'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
      children: const <Widget>[
        _PreviewLine(label: '应用名称', value: 'KiroTime'),
        _PreviewLine(label: '版本', value: '0.1.3'),
        _PreviewLine(label: '构建号', value: '4'),
        _PreviewLine(label: '包名', value: 'com.kirotime.app'),
        SizedBox(height: 8),
        Text('KiroTime 是本地优先的轻量课程表。课程、学期和备份数据默认保存在本机。'),
      ],
    );
  }
}

class _PrivacyNoticeDialog extends StatelessWidget {
  const _PrivacyNoticeDialog();

  @override
  Widget build(BuildContext context) {
    return _SimpleDialogFrame(
      title: '隐私说明',
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
      children: const <Widget>[
        Text('课程、老师、教室、教学班级、周次和学期设置只保存在本机。'),
        SizedBox(height: 8),
        Text('KiroTime 不会上传到 KiroTime 开发者服务器，也没有广告、社交或统计 SDK。'),
        SizedBox(height: 8),
        Text('从教务系统导入时，页面内容只在本机 WebView 中读取，并在本机解析为课表数据。'),
        SizedBox(height: 8),
        Text('导出的 JSON 会保存到 Download/KiroTime，文件包含完整课表信息，请自行妥善保存和分享。'),
        SizedBox(height: 8),
        Text('Android INTERNET 权限仅用于用户主动打开教务系统网页，不用于连接 KiroTime 后端。'),
        SizedBox(height: 8),
        Text('导入诊断默认只保留摘要；完整 HTML 诊断文件默认关闭，只有你在高级设置中开启后才会保留。'),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return _SimpleDialogFrame(
      title: title,
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
      children: <Widget>[Text(message)],
    );
  }
}

class _SimpleDialogFrame extends StatelessWidget {
  const _SimpleDialogFrame({
    required this.title,
    required this.children,
    required this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Wrap(
            spacing: 8,
            alignment: WrapAlignment.end,
            children: actions,
          ),
        ),
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6F7881),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatabaseDebugInfo extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_DatabaseDebugSnapshot>(
      future: _load(ref),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            data == null
                ? '数据库调试信息：读取中'
                : '数据库调试信息：学期${data.semesterCount}个，课程${data.courseCount}门，版本1',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6F7881),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  Future<_DatabaseDebugSnapshot> _load(WidgetRef ref) async {
    final isar = await ref.read(isarProvider.future);
    final semesters = await KiroTimeDatabase.listSemesters(isar);
    final metas = await isar.courseMetas.count();
    return _DatabaseDebugSnapshot(
      semesterCount: semesters.length,
      courseCount: metas,
    );
  }
}

class _DatabaseDebugSnapshot {
  const _DatabaseDebugSnapshot({
    required this.semesterCount,
    required this.courseCount,
  });

  final int semesterCount;
  final int courseCount;
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
