import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import/domain/academic_timetable_api_probe.dart';
import 'package:kiro_time/features/import/presentation/import_preview_dialog.dart';

void main() {
  testWidgets('allows suspicious preview override and returns true', (
    tester,
  ) async {
    bool? dialogResult;
    const summary = ImportPreviewSummary(
      courseCount: 5,
      scheduleCount: 5,
      crowdedSlots: <TimetableSlotCount>[
        TimetableSlotCount(
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          week: 3,
          count: 5,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              dialogResult = await showDialog<bool>(
                context: context,
                builder: (context) => const ImportPreviewDialog(
                  source: '接口探测',
                  path: '/kbcx/xskbcx_cxXsKb.html',
                  summary: summary,
                ),
              );
            },
            child: const Text('打开预览'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开预览'));
    await tester.pumpAndSettle();

    expect(find.text('发现疑似堆叠：'), findsOneWidget);
    expect(find.text('第3周 周一 第1-2节：5 条'), findsOneWidget);

    final overrideButton = find.widgetWithText(FilledButton, '仍然导入');
    expect(overrideButton, findsOneWidget);
    expect(tester.widget<FilledButton>(overrideButton).onPressed, isNotNull);

    await tester.tap(overrideButton);
    await tester.pumpAndSettle();

    expect(dialogResult, isTrue);
  });

  testWidgets('keeps normal preview confirmation enabled', (tester) async {
    const summary = ImportPreviewSummary(
      courseCount: 3,
      scheduleCount: 4,
      crowdedSlots: <TimetableSlotCount>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showDialog<bool>(
                context: context,
                builder: (context) => const ImportPreviewDialog(
                  source: '当前页面 HTML',
                  summary: summary,
                ),
              );
            },
            child: const Text('打开预览'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开预览'));
    await tester.pumpAndSettle();

    final confirmButton = find.widgetWithText(FilledButton, '确认导入');
    expect(confirmButton, findsOneWidget);
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNotNull);
    expect(find.text('仍然导入'), findsNothing);
  });
}
