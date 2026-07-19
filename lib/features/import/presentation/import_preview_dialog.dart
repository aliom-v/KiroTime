import 'package:flutter/material.dart';

import '../domain/academic_timetable_api_probe.dart';

class ImportPreviewDialog extends StatelessWidget {
  const ImportPreviewDialog({
    super.key,
    required this.source,
    this.path,
    required this.summary,
  });

  final String source;
  final String? path;
  final ImportPreviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入预览'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PreviewLine(label: '来源', value: source),
            if (path != null) _PreviewLine(label: '接口', value: path!),
            _PreviewLine(label: '课程数', value: '${summary.courseCount} 门'),
            _PreviewLine(label: '安排数', value: '${summary.scheduleCount} 条'),
            if (summary.isSuspicious) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                '发现疑似堆叠：',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              for (final slot in summary.crowdedSlots.take(5))
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
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(summary.isSuspicious ? '仍然导入' : '确认导入'),
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
