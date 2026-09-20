import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import/domain/academic_timetable_api_probe.dart';
import 'package:kiro_time/features/import/domain/imported_section_time_evidence.dart';
import 'package:kiro_time/features/import/presentation/import_preview_dialog.dart';
import 'package:kiro_time/features/timetable/domain/section_time_settings.dart';

void main() {
  testWidgets('allows suspicious preview override and returns true', (
    tester,
  ) async {
    ImportPreviewResult? dialogResult;
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
              dialogResult = await showDialog<ImportPreviewResult>(
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

    expect(dialogResult, isNotNull);
  });

  testWidgets('explicit detected times are enabled by default', (tester) async {
    ImportPreviewResult? result;
    final evidence = ImportedSectionTimeEvidence(
      settings: SectionTimeSettings(const <SectionTime>[
        SectionTime(section: 1, startMinutes: 490, endMinutes: 535),
        SectionTime(section: 2, startMinutes: 545, endMinutes: 590),
      ]),
      kind: ImportedSectionTimeEvidenceKind.explicitRanges,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<ImportPreviewResult>(
                context: context,
                builder: (context) => ImportPreviewDialog(
                  source: '当前页面 HTML',
                  summary: const ImportPreviewSummary(
                    courseCount: 1,
                    scheduleCount: 1,
                    crowdedSlots: <TimetableSlotCount>[],
                  ),
                  sectionTimeEvidence: evidence,
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
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.text('确认导入'));
    await tester.pumpAndSettle();
    expect(result?.applySectionTimes, isTrue);
  });

  testWidgets('fallback detected times require explicit opt in', (
    tester,
  ) async {
    final evidence = ImportedSectionTimeEvidence(
      settings: SectionTimeSettings(const <SectionTime>[
        SectionTime(section: 1, startMinutes: 490, endMinutes: 535),
      ]),
      kind: ImportedSectionTimeEvidenceKind.startTimesWithDurationFallback,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<ImportPreviewResult>(
              context: context,
              builder: (context) => ImportPreviewDialog(
                source: '当前页面 HTML',
                summary: const ImportPreviewSummary(
                  courseCount: 1,
                  scheduleCount: 1,
                  crowdedSlots: <TimetableSlotCount>[],
                ),
                sectionTimeEvidence: evidence,
              ),
            ),
            child: const Text('打开预览'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开预览'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(find.textContaining('45 分钟估算'), findsOneWidget);
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
