import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiro_time/features/import_export/application/import_export_providers.dart';
import 'package:kiro_time/features/import_export/data/android_timetable_file_gateway.dart';
import 'package:kiro_time/features/import_export/domain/timetable_json_codec.dart';
import 'package:kiro_time/features/timetable/application/timetable_providers.dart';
import 'package:kiro_time/features/courses/data/course_meta.dart';
import 'package:kiro_time/features/courses/data/course_schedule.dart';
import 'package:kiro_time/features/courses/data/course_schedule_edit.dart';
import 'package:kiro_time/features/timetable/domain/semester_settings.dart';
import 'package:kiro_time/features/timetable/domain/section_time_settings.dart';
import 'package:kiro_time/features/timetable/domain/timetable_layout.dart';
import 'package:kiro_time/features/timetable/presentation/timetable_page.dart';

void main() {
  test(
    'imported semester metadata updates selected semester start date',
    () async {
      final initialSemester = SemesterSettings(
        id: '2026-1',
        schoolYearStart: 2026,
        semester: 1,
        semesterStart: DateTime(2026, 8, 17),
        totalWeeks: 24,
        sectionCount: 10,
        displayName: '大三上',
      );
      SemesterSettings? savedSettings;
      final container = ProviderContainer(
        overrides: <Override>[
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[initialSemester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => initialSemester.id),
          updateSelectedSemesterProvider.overrideWithValue((
            SemesterSettings settings,
          ) async {
            savedSettings = settings;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(applyImportedSemesterMetadataProvider)(
        semesterStart: DateTime(2026, 8, 31),
      );

      expect(savedSettings, isNotNull);
      expect(savedSettings!.id, initialSemester.id);
      expect(savedSettings!.semesterStart, DateTime(2026, 8, 31));
      expect(savedSettings!.totalWeeks, 24);
      expect(savedSettings!.sectionCount, 10);
      expect(savedSettings!.displayName, '大三上');
    },
  );

  test('placement math matches Stack absolute positioning inputs', () {
    final placement = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-a',
          courseMetaId: 'course-a',
          classroom: 'Room A',
          dayOfWeek: 3,
          startSection: 5,
          endSection: 6,
          weeks: <int>[1],
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(id: 'course-a', name: 'A', teacher: 'Teacher A'),
      ],
    ).single;

    expect(placement.dayColumn, 2);
    expect(placement.startSlot, 4);
    expect(placement.slotSpan, 2);
    expect(placement.laneIndex, 0);
    expect(placement.laneCount, 1);
  });

  testWidgets('course cards do not overflow with imported long text', (
    tester,
  ) async {
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-os',
          courseMetaId: 'course-os',
          classroom: '南校区 3#504',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
        ),
        CourseSchedule.create(
          id: 'schedule-thought',
          courseMetaId: 'course-thought',
          classroom: '南校区 学术苑201',
          dayOfWeek: 2,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
        ),
        CourseSchedule.create(
          id: 'schedule-java',
          courseMetaId: 'course-java',
          classroom: '南校区 3#318机房',
          dayOfWeek: 3,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(id: 'course-os', name: '操作系统', teacher: '吕林涛'),
        CourseMeta.create(
          id: 'course-thought',
          name: '习近平新时代中国特色社会主义思想概论',
          teacher: '王庆英',
        ),
        CourseMeta.create(
          id: 'course-java',
          name: 'Java Web开发技术',
          teacher: '杨娟',
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.35)),
              child: child!,
            );
          },
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders mobile timetable chrome with compact week controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('校园课程表'), findsNothing);
    expect(find.text('第16周'), findsOneWidget);
    expect(find.text('08:10'), findsOneWidget);
    expect(find.text('08:55'), findsOneWidget);
    expect(find.byTooltip('导入课表'), findsOneWidget);
    expect(find.byTooltip('课表设置'), findsOneWidget);
    expect(find.byTooltip('新增课程'), findsOneWidget);
    expect(find.text('今日'), findsNothing);
    expect(find.text('课表'), findsNothing);
    expect(find.text('导入'), findsNothing);
  });

  testWidgets('section times stay inside the left time column', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('08:10')).dx, lessThan(72));
    expect(tester.getTopLeft(find.text('08:55')).dx, lessThan(72));
  });

  testWidgets('uses semester section times on board and course details', (
    tester,
  ) async {
    final semester = SemesterSettings(
      id: '2026-1',
      schoolYearStart: 2026,
      semester: 1,
      semesterStart: DateTime(2026, 8, 31),
      totalWeeks: 19,
      sectionCount: 10,
      sectionTimeSettings: SectionTimeSettings.defaultForSectionCount(10)
          .replaceSection(
            const SectionTime(
              section: 1,
              startMinutes: 7 * 60,
              endMinutes: 465,
            ),
          ),
    );
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-os',
          courseMetaId: 'course-os',
          classroom: '南校区 3#504',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(id: 'course-os', name: '操作系统', teacher: '吕林涛'),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[semester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => semester.id),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('07:45'), findsOneWidget);

    await tester.tap(find.text('操作系统'));
    await tester.pumpAndSettle();

    expect(find.text('周一 第1-2节 07:00-09:50'), findsOneWidget);
  });

  testWidgets('default board shows ten sections on the page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pageBottom = tester.getBottomRight(find.byType(TimetablePage)).dy;
    expect(tester.getTopLeft(find.text('10')).dy, lessThan(pageBottom));
    expect(find.text('20:40'), findsOneWidget);
  });

  testWidgets('default ten sections fill the timetable viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pageBottom = tester.getBottomRight(find.byType(TimetablePage)).dy;
    final sectionTenTop = tester.getTopLeft(find.text('10')).dy;

    expect(sectionTenTop, lessThan(pageBottom));
    expect(sectionTenTop, greaterThan(pageBottom - 96));
  });

  testWidgets('board extends beyond default sections for late schedules', (
    tester,
  ) async {
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-night',
          courseMetaId: 'course-night',
          classroom: '南校区 1#101',
          dayOfWeek: 1,
          startSection: 11,
          endSection: 12,
          weeks: <int>[1],
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(id: 'course-night', name: '晚间实验', teacher: '李老师'),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('11'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('top settings button opens settings center groups', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('课表设置'), findsWidgets);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('导入导出'), findsOneWidget);
    expect(find.text('高级设置'), findsOneWidget);
    expect(find.text('上课时间'), findsOneWidget);
    expect(find.text('从本地 JSON 导入'), findsOneWidget);
    expect(find.text('从剪贴板 JSON 导入'), findsOneWidget);
    expect(find.text('导出当前学期 JSON'), findsOneWidget);
    expect(find.text('导出全部学期 JSON'), findsOneWidget);
    expect(find.text('清空全部数据'), findsOneWidget);

    await tester.ensureVisible(find.text('上课时间'));
    await tester.tap(find.text('上课时间'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsWidgets);
    expect(find.text('当前 10 节'), findsOneWidget);
    expect(find.text('第 1 节'), findsOneWidget);
    expect(find.text('08:10-08:55'), findsOneWidget);
    expect(find.text('三段式快速生成'), findsOneWidget);
  });

  testWidgets('settings about dialog shows formal app identity', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('关于 KiroTime'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('关于 KiroTime'));
    await tester.pumpAndSettle();

    expect(find.text('版本'), findsOneWidget);
    expect(find.text('0.1.3'), findsOneWidget);
    expect(find.text('构建号'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('包名'), findsOneWidget);
    expect(find.text('com.kirotime.app'), findsOneWidget);
  });

  testWidgets('about dialog opens privacy notice', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('关于 KiroTime'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('关于 KiroTime'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('隐私说明'));
    await tester.pumpAndSettle();

    expect(find.text('隐私说明'), findsWidgets);
    expect(find.textContaining('只保存在本机'), findsWidgets);
    expect(find.textContaining('不会上传到 KiroTime 开发者服务器'), findsOneWidget);
    expect(find.textContaining('WebView'), findsWidgets);
    expect(find.textContaining('Download/KiroTime'), findsOneWidget);
    expect(find.textContaining('INTERNET 权限'), findsOneWidget);
  });

  testWidgets('JSON export dialog warns about timetable data sensitivity', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('导出当前学期 JSON'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出当前学期 JSON'));
    await tester.pumpAndSettle();

    expect(find.text('导出 JSON'), findsOneWidget);
    expect(find.textContaining('导出的文件包含完整课表信息'), findsOneWidget);
    expect(find.textContaining('请妥善保存'), findsOneWidget);
  });

  testWidgets('local JSON import preview exposes import modes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final snapshot = TimetableExportSnapshot(
      scope: TimetableExportScope.currentSemester,
      exportedAt: DateTime(2026, 6, 18, 12),
      selectedSemesterId: '2026-1',
      semesters: <SemesterSettings>[
        SemesterSettings(
          id: '2026-1',
          schoolYearStart: 2026,
          semester: 1,
          semesterStart: DateTime(2026, 8, 31),
          totalWeeks: 19,
        ),
      ],
      metas: <CourseMeta>[
        CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'Teacher A'),
      ],
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-a',
          courseMetaId: 'meta-a',
          classroom: 'Room A',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
          semesterId: '2026-1',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
          timetableFileGatewayProvider.overrideWithValue(
            _FakeTimetableFileGateway(
              pickedFile: PickedTimetableJsonFile(
                fileName: 'backup.json',
                json: TimetableJsonCodec.encode(snapshot),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('从本地 JSON 导入'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从本地 JSON 导入'));
    await tester.pumpAndSettle();

    expect(find.text('导入前预览'), findsOneWidget);
    expect(find.text('backup.json'), findsOneWidget);
    expect(find.text('覆盖当前学期'), findsOneWidget);
    expect(find.text('新建为一个学期'), findsOneWidget);
    expect(find.text('覆盖全部数据'), findsOneWidget);
  });

  testWidgets('week controls are interactive and date labels are static', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('下一周'));
    await tester.pumpAndSettle();
    expect(find.text('第17周'), findsOneWidget);

    await tester.tap(find.byTooltip('上一周'));
    await tester.pumpAndSettle();
    expect(find.text('第16周'), findsOneWidget);

    expect(find.byTooltip('选择周三'), findsNothing);
    expect(find.byTooltip('已选择周三'), findsNothing);
  });

  testWidgets('horizontal swipe changes visible week', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TimetablePage), const Offset(-320, 0), 900);
    await tester.pumpAndSettle();
    expect(find.text('第17周'), findsOneWidget);

    await tester.fling(find.byType(TimetablePage), const Offset(320, 0), 900);
    await tester.pumpAndSettle();
    expect(find.text('第16周'), findsOneWidget);
  });

  testWidgets('week transition animates header and board together', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('week-content-16')),
      findsOneWidget,
    );

    await tester.fling(find.byType(TimetablePage), const Offset(-320, 0), 900);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('week-content-17')),
      findsOneWidget,
    );
    expect(find.text('第17周'), findsOneWidget);
  });

  testWidgets('week label opens lightweight week picker only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('选择周数'));
    await tester.pumpAndSettle();

    expect(find.text('选择周数'), findsWidgets);
    expect(find.text('课表设置'), findsNothing);
    expect(find.text('外观'), findsNothing);
    expect(find.text('导入导出'), findsNothing);
  });

  testWidgets('week picker marks the centered selected week', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('选择周数'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('wheel-selected-week-16')),
      findsOneWidget,
    );
  });

  testWidgets('week settings target is large enough for touch', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final settingsTargetSize = tester.getSize(find.byTooltip('选择周数'));

    expect(settingsTargetSize.width, greaterThanOrEqualTo(88));
    expect(settingsTargetSize.height, greaterThanOrEqualTo(36));
  });

  testWidgets('semester settings update visible term and current week', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final initialSemester = SemesterSettings(
      schoolYearStart: 2025,
      semester: 2,
      semesterStart: DateTime(2026, 3, 2),
      totalWeeks: 20,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[initialSemester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => initialSemester.id),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('学年').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026-2027'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('总周数').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('总周数').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('18周'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('每日节数').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('每日节数').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('12节'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('保存设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存设置'));
    await tester.pumpAndSettle();

    final expectedWeek = initialSemester
        .copyWith(schoolYearStart: 2026, totalWeeks: 18, sectionCount: 12)
        .weekOf(DateTime.now());
    expect(find.text('2026-2027第二学期'), findsWidgets);
    expect(find.text('第$expectedWeek周'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('adding a semester switches the active term', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增学期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('学年').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2024-2025'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存设置'));
    await tester.pumpAndSettle();

    expect(find.text('2024-2025第一学期'), findsWidgets);
  });

  testWidgets('semester settings displays terms sorted by academic time', (
    tester,
  ) async {
    final laterSemester = SemesterSettings(
      id: '2026-1',
      schoolYearStart: 2026,
      semester: 1,
      semesterStart: DateTime(2026, 8, 31),
      totalWeeks: 20,
    );
    final earlierSemester = SemesterSettings(
      id: '2024-1',
      schoolYearStart: 2024,
      semester: 1,
      semesterStart: DateTime(2024, 8, 26),
      totalWeeks: 20,
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[laterSemester, earlierSemester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => laterSemester.id),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();

    final earlierChip = tester.getTopLeft(
      find.byKey(const ValueKey<String>('semester-card-2024-1')),
    );
    final laterChip = tester.getTopLeft(
      find.byKey(const ValueKey<String>('semester-card-2026-1')),
    );
    expect(earlierChip.dy, lessThanOrEqualTo(laterChip.dy));
    if (earlierChip.dy == laterChip.dy) {
      expect(earlierChip.dx, lessThan(laterChip.dx));
    }
  });

  testWidgets('semester settings uses fixed two-column switcher cards', (
    tester,
  ) async {
    final firstSemester = SemesterSettings(
      id: '2024-1',
      schoolYearStart: 2024,
      semester: 1,
      semesterStart: DateTime(2024, 8, 26),
      totalWeeks: 20,
    );
    final secondSemester = SemesterSettings(
      id: '2024-2',
      schoolYearStart: 2024,
      semester: 2,
      semesterStart: DateTime(2025, 2, 24),
      totalWeeks: 20,
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[firstSemester, secondSemester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => firstSemester.id),
          currentWeekProvider.overrideWith((ref) => 16),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('semester-switcher-grid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('semester-card-2024-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('semester-card-2024-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('semester-card-add')),
      findsOneWidget,
    );

    final firstSize = tester.getSize(
      find.byKey(const ValueKey<String>('semester-card-2024-1')),
    );
    final secondSize = tester.getSize(
      find.byKey(const ValueKey<String>('semester-card-2024-2')),
    );
    expect(firstSize.width, moreOrLessEquals(secondSize.width, epsilon: 1));
    expect(firstSize.height, moreOrLessEquals(secondSize.height, epsilon: 1));
  });

  testWidgets('date wheel marks selected year month and day', (tester) async {
    final initialSemester = SemesterSettings(
      id: '2026-1',
      schoolYearStart: 2026,
      semester: 1,
      semesterStart: DateTime(2026, 8, 31),
      totalWeeks: 20,
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[initialSemester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => initialSemester.id),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开学日期').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('wheel-selected-year-2026')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('wheel-selected-month-8')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('wheel-selected-day-31')),
      findsOneWidget,
    );
  });

  testWidgets('single-section cards do not overflow with large imported text', (
    tester,
  ) async {
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-thought',
          courseMetaId: 'course-thought',
          classroom: '南校区 学术苑 201',
          dayOfWeek: 2,
          startSection: 1,
          endSection: 1,
          weeks: <int>[1],
        ),
        CourseSchedule.create(
          id: 'schedule-java',
          courseMetaId: 'course-java',
          classroom: '南校区 3#318机房',
          dayOfWeek: 3,
          startSection: 1,
          endSection: 1,
          weeks: <int>[1],
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(
          id: 'course-thought',
          name: '习近平新时代中国特色社会主义思想概论',
          teacher: '王庆英',
        ),
        CourseMeta.create(
          id: 'course-java',
          name: 'Java Web开发技术',
          teacher: '杨娟',
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.35)),
              child: child!,
            );
          },
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('course card shows core fields and details show full schedule', (
    tester,
  ) async {
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-os',
          courseMetaId: 'course-os',
          classroom: '南校区 3#504',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1, 2, 3, 4, 5, 7, 8, 9],
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(
          id: 'course-os',
          name: '操作系统',
          teacher: '吕林涛',
          teachingClass: '计科2301',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('操作系统'), findsOneWidget);
    expect(find.text('南校区 3#504'), findsOneWidget);
    expect(find.text('吕林涛'), findsOneWidget);
    expect(find.text('1-2节'), findsNothing);

    await tester.tap(find.text('操作系统'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('吕林涛'), findsWidgets);
    expect(find.text('教学班级'), findsOneWidget);
    expect(find.text('计科2301'), findsOneWidget);
    expect(find.text('南校区 3#504'), findsWidgets);
    expect(find.text('周一 第1-2节 08:10-09:50'), findsOneWidget);
    expect(find.text('1-5,7-9周'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('复制到其他学期'), findsOneWidget);
  });

  testWidgets('overlapping current-week courses render one conflict card', (
    tester,
  ) async {
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-java',
          courseMetaId: 'course-java',
          classroom: '南校区 3#318机房',
          dayOfWeek: 3,
          startSection: 1,
          endSection: 4,
          weeks: <int>[10],
        ),
        CourseSchedule.create(
          id: 'schedule-english',
          courseMetaId: 'course-english',
          classroom: '南校区 2#201',
          dayOfWeek: 3,
          startSection: 3,
          endSection: 4,
          weeks: <int>[10],
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(
          id: 'course-java',
          name: 'Java Web开发技术',
          teacher: '杨娟',
        ),
        CourseMeta.create(
          id: 'course-english',
          name: '计算机专业英语(双语)',
          teacher: '李老师',
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('conflict-count-badge')),
      findsOneWidget,
    );
    expect(find.text('2门冲突'), findsNothing);
    expect(find.textContaining('Java Web开发技术'), findsOneWidget);
    expect(find.textContaining('计算机专业英语(双语)'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('conflict-count-badge')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('课程冲突'), findsOneWidget);
    expect(find.text('Java Web开发技术'), findsOneWidget);
    expect(find.text('计算机专业英语(双语)'), findsOneWidget);
    expect(find.text('周三 第1-4节 08:10-11:50'), findsWidgets);
    expect(find.text('周三 第3-4节 10:10-11:50'), findsOneWidget);
    expect(find.text('编辑'), findsWidgets);
  });

  testWidgets(
    'top add button opens centered course editor and creates course',
    (tester) async {
      CourseScheduleEdit? createdEdit;

      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            timetablePlacementsProvider.overrideWith(
              (ref) async => <TimetableCoursePlacement>[],
            ),
            createCourseScheduleProvider.overrideWithValue((
              CourseScheduleEdit edit,
            ) async {
              createdEdit = edit;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF157A6E),
              ),
              useMaterial3: true,
            ),
            home: const TimetablePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('新增课程'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      await tester.enterText(find.bySemanticsLabel('课程名称'), '编译原理');
      await tester.enterText(find.bySemanticsLabel('任课老师'), '周老师');
      await tester.enterText(find.bySemanticsLabel('教学班级'), '计科2302');
      await tester.enterText(find.bySemanticsLabel('上课地点'), '南校区 2#204');
      await tester.enterText(find.bySemanticsLabel('周次'), '1-4周');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(createdEdit, isNotNull);
      expect(createdEdit!.name, '编译原理');
      expect(createdEdit!.teacher, '周老师');
      expect(createdEdit!.teachingClass, '计科2302');
      expect(createdEdit!.classroom, '南校区 2#204');
      expect(createdEdit!.weeks, <int>[1, 2, 3, 4]);
    },
  );

  testWidgets('editing a course saves changed schedule fields', (tester) async {
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-os',
          courseMetaId: 'course-os',
          classroom: '南校区 3#504',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1, 2],
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(id: 'course-os', name: '操作系统', teacher: '吕林涛'),
      ],
    );
    CourseScheduleEdit? savedEdit;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
          saveCourseScheduleEditProvider.overrideWithValue((
            CourseScheduleEdit edit,
          ) async {
            savedEdit = edit;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('操作系统'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('课程名称'), '高级操作系统');
    await tester.enterText(find.bySemanticsLabel('任课老师'), '张老师');
    await tester.enterText(find.bySemanticsLabel('教学班级'), '计科2303');
    await tester.enterText(find.bySemanticsLabel('上课地点'), '北校区 A101');
    await tester.enterText(find.bySemanticsLabel('周次'), '3-4周');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedEdit, isNotNull);
    expect(savedEdit!.courseMetaId, 'course-os');
    expect(savedEdit!.scheduleId, 'schedule-os');
    expect(savedEdit!.name, '高级操作系统');
    expect(savedEdit!.teacher, '张老师');
    expect(savedEdit!.teachingClass, '计科2303');
    expect(savedEdit!.classroom, '北校区 A101');
    expect(savedEdit!.weeks, <int>[3, 4]);
  });

  testWidgets('deleting a course confirms and deletes only the schedule', (
    tester,
  ) async {
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-os',
          courseMetaId: 'course-os',
          classroom: '南校区 3#504',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
          semesterId: '2025-2',
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(id: 'course-os', name: '操作系统', teacher: '吕林涛'),
      ],
    );
    String? deletedScheduleId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
          deleteCourseScheduleProvider.overrideWithValue((
            String scheduleId,
          ) async {
            deletedScheduleId = scheduleId;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('操作系统'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除课程'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(deletedScheduleId, 'schedule-os');
  });

  testWidgets('copying a course opens semester picker and calls copy action', (
    tester,
  ) async {
    final sourceSemester = SemesterSettings(
      id: '2025-2',
      schoolYearStart: 2025,
      semester: 2,
      semesterStart: DateTime(2026, 3, 2),
      totalWeeks: 20,
    );
    final targetSemester = SemesterSettings(
      id: '2026-1',
      schoolYearStart: 2026,
      semester: 1,
      semesterStart: DateTime(2026, 8, 31),
      totalWeeks: 19,
      displayName: '大三上',
    );
    final placements = TimetableLayout.buildPlacements(
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-os',
          courseMetaId: 'course-os',
          classroom: '南校区 3#504',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
          semesterId: sourceSemester.id,
        ),
      ],
      courseMetas: <CourseMeta>[
        CourseMeta.create(
          id: 'course-os',
          name: '操作系统',
          teacher: '吕林涛',
          teachingClass: '计科2301',
        ),
      ],
    );
    String? copiedScheduleId;
    String? copiedTargetSemesterId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith((ref) async => placements),
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[sourceSemester, targetSemester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => sourceSemester.id),
          copyCourseScheduleProvider.overrideWithValue(({
            required String scheduleId,
            required String targetSemesterId,
          }) async {
            copiedScheduleId = scheduleId;
            copiedTargetSemesterId = targetSemesterId;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('操作系统'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制到其他学期'));
    await tester.pumpAndSettle();

    expect(find.text('复制到其他学期'), findsOneWidget);
    expect(find.text('大三上'), findsOneWidget);

    await tester.tap(find.text('大三上'));
    await tester.pumpAndSettle();

    expect(copiedScheduleId, 'schedule-os');
    expect(copiedTargetSemesterId, '2026-1');
  });

  testWidgets('semester settings saves custom display name', (tester) async {
    final initialSemester = SemesterSettings(
      id: '2025-2',
      schoolYearStart: 2025,
      semester: 2,
      semesterStart: DateTime(2026, 3, 2),
      totalWeeks: 20,
    );
    SemesterSettings? savedSettings;

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[initialSemester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => initialSemester.id),
          updateSelectedSemesterProvider.overrideWithValue((
            SemesterSettings settings,
          ) async {
            savedSettings = settings;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('学期显示名称'), '大三上');
    await tester.tap(find.text('保存设置'));
    await tester.pumpAndSettle();

    expect(savedSettings, isNotNull);
    expect(savedSettings!.displayName, '大三上');
  });

  testWidgets('semester settings blocks deleting the final semester', (
    tester,
  ) async {
    final initialSemester = SemesterSettings(
      id: '2025-2',
      schoolYearStart: 2025,
      semester: 2,
      semesterStart: DateTime(2026, 3, 2),
      totalWeeks: 20,
    );

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          timetablePlacementsProvider.overrideWith(
            (ref) async => <TimetableCoursePlacement>[],
          ),
          semesterListProvider.overrideWith(
            (ref) => <SemesterSettings>[initialSemester],
          ),
          selectedSemesterIdProvider.overrideWith((ref) => initialSemester.id),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF157A6E),
            ),
            useMaterial3: true,
          ),
          home: const TimetablePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('课表设置'));
    await tester.pumpAndSettle();

    final deleteButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '删除学期'),
    );
    expect(deleteButton.onPressed, isNull);
  });
}

class _FakeTimetableFileGateway extends AndroidTimetableFileGateway {
  const _FakeTimetableFileGateway({required this.pickedFile});

  final PickedTimetableJsonFile? pickedFile;

  @override
  Future<ExportedTimetableFile> exportTimetableJson({
    required String fileName,
    required String json,
    required bool overwrite,
  }) async {
    return ExportedTimetableFile(
      fileName: fileName,
      displayPath: 'Download/KiroTime/$fileName',
    );
  }

  @override
  Future<PickedTimetableJsonFile?> pickTimetableJson() async {
    return pickedFile;
  }

  @override
  Future<bool> fileExistsInDownloads(String fileName) async {
    return false;
  }
}
