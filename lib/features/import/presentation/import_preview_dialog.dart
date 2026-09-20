import 'package:flutter/material.dart';

import '../domain/academic_timetable_api_probe.dart';
import '../domain/imported_section_time_evidence.dart';

class ImportPreviewResult {
  const ImportPreviewResult({required this.applySectionTimes});

  final bool applySectionTimes;
}

class ImportPreviewDialog extends StatefulWidget {
  const ImportPreviewDialog({
    super.key,
    required this.source,
    this.path,
    required this.summary,
    this.sectionTimeEvidence,
  });

  final String source;
  final String? path;
  final ImportPreviewSummary summary;
  final ImportedSectionTimeEvidence? sectionTimeEvidence;

  @override
  State<ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<ImportPreviewDialog> {
  late bool _applySectionTimes =
      widget.sectionTimeEvidence?.hasExplicitEndTimes ?? false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入预览'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PreviewLine(label: '来源', value: widget.source),
            if (widget.path != null)
              _PreviewLine(label: '接口', value: widget.path!),
            _PreviewLine(
              label: '课程数',
              value: '${widget.summary.courseCount} 门',
            ),
            _PreviewLine(
              label: '安排数',
              value: '${widget.summary.scheduleCount} 条',
            ),
            if (widget.sectionTimeEvidence case final evidence?) ...<Widget>[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('应用检测到的上课时间'),
                subtitle: Text(
                  evidence.usesDurationFallback
                      ? '页面仅提供开始时间，结束时间按 45 分钟估算，请确认后再应用。'
                      : '已检测到完整时间范围：${_timeSummary(evidence)}',
                ),
                value: _applySectionTimes,
                onChanged: (value) => setState(() {
                  _applySectionTimes = value;
                }),
              ),
            ],
            if (widget.summary.isSuspicious) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                '发现疑似堆叠：',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              for (final slot in widget.summary.crowdedSlots.take(5))
                Text(
                  '第${slot.week}周 ${_weekdayLabel(slot.dayOfWeek)} 第${slot.startSection}-${slot.endSection}节：${slot.count} 条',
                ),
              const SizedBox(height: 8),
              Text(
                '建议先取消并复制诊断摘要，避免覆盖原课表。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(ImportPreviewResult(applySectionTimes: _applySectionTimes)),
          child: Text(widget.summary.isSuspicious ? '仍然导入' : '确认导入'),
        ),
      ],
    );
  }
}

String _timeSummary(ImportedSectionTimeEvidence evidence) {
  final sections = evidence.settings.sections;
  if (sections.isEmpty) {
    return '';
  }
  return '${sections.first.timeRangeText} 至 ${sections.last.timeRangeText}';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F7881)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _weekdayLabel(int dayOfWeek) {
  const labels = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return labels[(dayOfWeek - 1).clamp(0, labels.length - 1)];
}
