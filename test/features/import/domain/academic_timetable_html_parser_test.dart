import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import/domain/academic_timetable_html_parser.dart';

void main() {
  group('AcademicTimetableHtmlParser.parseWeeks', () {
    test('parses continuous week ranges', () {
      expect(
        AcademicTimetableHtmlParser.parseWeeks('1-16周'),
        List<int>.generate(16, (index) => index + 1),
      );
    });

    test('parses odd week ranges', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('1-16周(单)'), <int>[
        1,
        3,
        5,
        7,
        9,
        11,
        13,
        15,
      ]);
    });

    test('parses even week ranges', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('2-16周(双)'), <int>[
        2,
        4,
        6,
        8,
        10,
        12,
        14,
        16,
      ]);
    });

    test('parses comma-separated weeks', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('1,3,5,7周'), <int>[
        1,
        3,
        5,
        7,
      ]);
    });

    test('parses mixed single ranges', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('1-5,7-9周'), <int>[
        1,
        2,
        3,
        4,
        5,
        7,
        8,
        9,
      ]);
    });

    test('parses week ranges with labels', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('周次: 1-5周,7-9周'), <int>[
        1,
        2,
        3,
        4,
        5,
        7,
        8,
        9,
      ]);
    });

    test('applies odd-even markers only to their own week token', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('10-11周,13-15周(单)'), <int>[
        10,
        11,
        13,
        15,
      ]);
    });

    test('ignores section prefix before week text', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('(9-10节)12-15周'), <int>[
        12,
        13,
        14,
        15,
      ]);
    });

    test('rejects weeks outside the import boundary', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('25周'), isEmpty);
    });

    test('rejects oversized week ranges outside the import boundary', () {
      expect(AcademicTimetableHtmlParser.parseWeeks('1-1000周'), isEmpty);
    });

    test('ignores unrelated hour counts in marked week lines', () {
      expect(
        AcademicTimetableHtmlParser.parseWeeks('1-16周,共32学时'),
        List<int>.generate(16, (index) => index + 1),
      );
    });
  });

  group('AcademicTimetableHtmlParser.parse', () {
    test('extracts first week start date from school week picker text', () {
      const html = '''
      <html>
        <body>
          <div id="zs" class="ui-alert">第一周   2026-08-31/2026-09-06</div>
          <ul class="mui-pciker-list">
            <li class="highlight">第一周   2026-08-31/2026-09-06</li>
            <li>第二周   2026-09-07/2026-09-13</li>
          </ul>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.semesterStart, DateTime(2026, 8, 31));
    });

    test('extracts course metas and schedules from explicit table cells', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <td data-day="1" data-start-section="1" data-end-section="2">
                操作系统<br>
                吕林涛<br>
                南校区 3#504<br>
                1-16周(单)
              </td>
              <td data-day="3" data-start-section="3" data-end-section="4">
                数据库原理
                <span>陈静</span>
                <span>南校区 2#301</span>
                <span>2-16周(双)</span>
              </td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.metas, hasLength(2));
      expect(timetable.schedules, hasLength(2));

      final operatingSystem = timetable.metas.singleWhere(
        (meta) => meta.name == '操作系统',
      );
      expect(operatingSystem.teacher, '吕林涛');

      final operatingSystemSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == operatingSystem.id,
      );
      expect(operatingSystemSchedule.classroom, '南校区 3#504');
      expect(operatingSystemSchedule.dayOfWeek, 1);
      expect(operatingSystemSchedule.startSection, 1);
      expect(operatingSystemSchedule.endSection, 2);
      expect(operatingSystemSchedule.weeks, <int>[1, 3, 5, 7, 9, 11, 13, 15]);

      final database = timetable.metas.singleWhere(
        (meta) => meta.name == '数据库原理',
      );
      expect(database.teacher, '陈静');

      final databaseSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == database.id,
      );
      expect(databaseSchedule.classroom, '南校区 2#301');
      expect(databaseSchedule.dayOfWeek, 3);
      expect(databaseSchedule.startSection, 3);
      expect(databaseSchedule.endSection, 4);
      expect(databaseSchedule.weeks, <int>[2, 4, 6, 8, 10, 12, 14, 16]);
    });

    test('extracts mobile absolute-positioned course cards', () {
      const html = '''
      <html>
        <body>
          <div class="mobile-timetable">
            <div class="course-card"
                 style="position:absolute;left:28.571%;top:66.666%;width:14.285%;height:16.666%;">
              <div>习近平新时代中国特色社会主义思想概论</div>
              <div>习近平新时代中国特色社会主义思想概论-0008</div>
              <div>南校区 未排地点</div>
              <div>王庆英</div>
              <div>10-17周</div>
            </div>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.metas, hasLength(1));
      expect(timetable.schedules, hasLength(1));

      final meta = timetable.metas.single;
      expect(meta.name, '习近平新时代中国特色社会主义思想概论');
      expect(meta.teacher, '王庆英');

      final schedule = timetable.schedules.single;
      expect(schedule.classroom, '南校区 未排地点');
      expect(schedule.dayOfWeek, 3);
      expect(schedule.startSection, 9);
      expect(schedule.endSection, 10);
      expect(schedule.weeks, <int>[10, 11, 12, 13, 14, 15, 16, 17]);
    });

    test('extracts mobile CSS-grid course cards', () {
      const html = '''
      <html>
        <body>
          <div class="kb-grid">
            <div class="lesson"
                 style="grid-column:5 / 6;grid-row:3 / span 2;">
              <p>数据库原理-0001</p>
              <p>南校区 2#301</p>
              <p>陈静</p>
              <p>2-16周(双)</p>
            </div>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.metas.single.name, '数据库原理');
      expect(timetable.metas.single.teacher, '陈静');
      expect(timetable.schedules.single.classroom, '南校区 2#301');
      expect(timetable.schedules.single.dayOfWeek, 5);
      expect(timetable.schedules.single.startSection, 3);
      expect(timetable.schedules.single.endSection, 4);
      expect(timetable.schedules.single.weeks, <int>[
        2,
        4,
        6,
        8,
        10,
        12,
        14,
        16,
      ]);
    });

    test('extracts plain mobile timetable tables with rowspans', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th></th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
              <th>周四</th>
              <th>周五</th>
              <th>周六</th>
              <th>周日</th>
            </tr>
            <tr>
              <td>1<br>08:10:00</td>
              <td rowspan="2">
                操作系统<br>
                操作系统-0011<br>
                南校区 3#504<br>
                吕林涛<br>
                1-5周,7-17周
              </td>
              <td rowspan="2">
                习近平新时代中国特色社会主义思想概论<br>
                习近平新时代中国特色社会主义思想概论-0008<br>
                南校区 学术苑 201<br>
                王庆英<br>
                1-5周,7-17周
              </td>
              <td rowspan="2">
                Java Web开发<br>
                Java Web开发-0003<br>
                南校区 2#301<br>
                王敏<br>
                10-17周
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>2</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, hasLength(3));

      final operatingSystem = timetable.metas.singleWhere(
        (meta) => meta.name == '操作系统',
      );
      expect(operatingSystem.teacher, '吕林涛');
      final operatingSystemSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == operatingSystem.id,
      );
      expect(operatingSystemSchedule.dayOfWeek, 1);
      expect(operatingSystemSchedule.startSection, 1);
      expect(operatingSystemSchedule.endSection, 2);
      expect(operatingSystemSchedule.classroom, '南校区 3#504');
      expect(operatingSystemSchedule.weeks, <int>[
        1,
        2,
        3,
        4,
        5,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
      ]);

      final thought = timetable.metas.singleWhere(
        (meta) => meta.name == '习近平新时代中国特色社会主义思想概论',
      );
      expect(thought.teacher, '王庆英');
      final thoughtSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == thought.id,
      );
      expect(thoughtSchedule.dayOfWeek, 2);
      expect(thoughtSchedule.startSection, 1);
      expect(thoughtSchedule.endSection, 2);
      expect(thoughtSchedule.classroom, '南校区 学术苑 201');

      final javaWeb = timetable.metas.singleWhere(
        (meta) => meta.name == 'Java Web开发',
      );
      final javaWebSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == javaWeb.id,
      );
      expect(javaWebSchedule.dayOfWeek, 3);
      expect(javaWebSchedule.startSection, 1);
      expect(javaWebSchedule.endSection, 2);
      expect(javaWebSchedule.weeks, <int>[10, 11, 12, 13, 14, 15, 16, 17]);
    });

    test('keeps Thursday and Friday columns aligned after rowspans', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th></th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
              <th>周四</th>
              <th>周五</th>
              <th>周六</th>
              <th>周日</th>
            </tr>
            <tr>
              <td>1</td>
              <td rowspan="2">
                操作系统<br>
                南校区 3#504<br>
                吕林涛<br>
                1-16周
              </td>
              <td rowspan="2">
                数据库原理<br>
                南校区 2#301<br>
                陈静<br>
                1-16周
              </td>
              <td rowspan="2">
                Java Web开发<br>
                南校区 3#318机房<br>
                杨娟<br>
                1-16周
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>2</td>
              <td>
                软件工程<br>
                南校区 3#602<br>
                赵强<br>
                1-16周
              </td>
              <td>
                编译原理<br>
                南校区 4#205<br>
                钱敏<br>
                1-16周
              </td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      final softwareEngineering = timetable.metas.singleWhere(
        (meta) => meta.name == '软件工程',
      );
      final softwareEngineeringSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == softwareEngineering.id,
      );
      expect(softwareEngineeringSchedule.dayOfWeek, 4);
      expect(softwareEngineeringSchedule.startSection, 2);

      final compiler = timetable.metas.singleWhere(
        (meta) => meta.name == '编译原理',
      );
      final compilerSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == compiler.id,
      );
      expect(compilerSchedule.dayOfWeek, 5);
      expect(compilerSchedule.startSection, 2);
    });

    test('uses section text as table occupancy when rowspan is missing', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th></th>
              <th>星期一</th>
              <th>星期二</th>
              <th>星期三</th>
              <th>星期四</th>
              <th>星期五</th>
              <th>星期六</th>
              <th>星期日</th>
            </tr>
            <tr>
              <td>1</td>
              <td rowspan="2">
                操作系统<br>
                (1-2节)<br>
                南校区 3#504<br>
                吕林涛<br>
                1-5周,7-17周
              </td>
              <td rowspan="2">
                习近平新时代中国特色社会主义思想概论<br>
                (1-2节)<br>
                南校区 学术苑201<br>
                王庆英<br>
                1-5周,7-17周
              </td>
              <td>
                Java Web开发技术<br>
                (1-4节)<br>
                南校区 3#318机房<br>
                杨娟<br>
                1-5周,7-17周
              </td>
              <td rowspan="2">
                软件分析与测试<br>
                (1-2节)<br>
                南校区 3#504<br>
                刘菁<br>
                1-4周,6-9周
              </td>
              <td rowspan="2">
                软件工程<br>
                (1-2节)<br>
                南校区 3#416<br>
                王钒霖<br>
                1-7周(单)
              </td>
              <td rowspan="10">
                Java Web开发技术课程设计<br>
                (1-10节)<br>
                南校区 3#215机房<br>
                樊同科<br>
                9-10周
              </td>
              <td rowspan="10">
                Java Web开发技术课程设计<br>
                (1-10节)<br>
                南校区 3#215机房<br>
                樊同科<br>
                9-10周
              </td>
            </tr>
            <tr>
              <td>2</td>
            </tr>
            <tr>
              <td>3</td>
              <td rowspan="2">
                软件工程<br>
                (3-4节)<br>
                南校区 3#602<br>
                王钒霖<br>
                1-5周,7-17周
              </td>
              <td></td>
              <td rowspan="2">
                计算机专业英语(双语)<br>
                (3-4节)<br>
                南校区 3#602<br>
                薛慧芳<br>
                1-4周,6-17周
              </td>
              <td rowspan="2">
                操作系统<br>
                (3-4节)<br>
                南校区 3#504<br>
                吕林涛<br>
                2-8周(双)
              </td>
            </tr>
            <tr>
              <td>4</td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      final javaWeb = timetable.metas.singleWhere(
        (meta) => meta.name == 'Java Web开发技术',
      );
      final javaWebSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == javaWeb.id,
      );
      expect(javaWebSchedule.dayOfWeek, 3);
      expect(javaWebSchedule.startSection, 1);
      expect(javaWebSchedule.endSection, 4);

      final professionalEnglish = timetable.metas.singleWhere(
        (meta) => meta.name == '计算机专业英语(双语)',
      );
      final professionalEnglishSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == professionalEnglish.id,
      );
      expect(professionalEnglishSchedule.dayOfWeek, 4);
      expect(professionalEnglishSchedule.startSection, 3);
      expect(professionalEnglishSchedule.endSection, 4);

      final operatingSystemSchedules = timetable.schedules
          .where(
            (schedule) =>
                schedule.courseMetaId ==
                timetable.metas.singleWhere((meta) => meta.name == '操作系统').id,
          )
          .toList();
      expect(
        operatingSystemSchedules.any(
          (schedule) =>
              schedule.dayOfWeek == 5 &&
              schedule.startSection == 3 &&
              schedule.endSection == 4,
        ),
        isTrue,
      );
    });

    test('ignores nested lesson table rows when applying rowspans', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <td></td>
              <td>周一</td>
              <td>周二</td>
              <td>周三</td>
              <td>周四</td>
              <td>周五</td>
              <td>周六</td>
              <td>周日</td>
            </tr>
            <tr>
              <td>1<br>08:10:00</td>
              <td id="td_1-1" rowspan="2">
                <div class="lesson"><table><tbody>
                  <tr><td><p>操作系统</p></td></tr>
                  <tr><td><p>操作系统-0011</p></td></tr>
                  <tr><td><p>南校区 3#504</p></td></tr>
                  <tr><td><p>吕林涛</p></td></tr>
                  <tr><td><p>1-5周,7-17周</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_2-1" rowspan="2">
                <div class="lesson"><table><tbody>
                  <tr><td><p>习近平新时代中国特色社会主义思想概论</p></td></tr>
                  <tr><td><p>习近平新时代中国特色社会主义思想概论-0008</p></td></tr>
                  <tr><td><p>南校区 学术苑201</p></td></tr>
                  <tr><td><p>王庆英</p></td></tr>
                  <tr><td><p>1-5周,7-17周</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_3-1" rowspan="4">
                <div class="lesson"><table><tbody>
                  <tr><td><p>Java Web开发技术</p></td></tr>
                  <tr><td><p>Java Web开发技术-0003</p></td></tr>
                  <tr><td><p>南校区 3#318机房</p></td></tr>
                  <tr><td><p>杨娟</p></td></tr>
                  <tr><td><p>1-5周,7-17周</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_4-1" rowspan="2">
                <div class="lesson"><table><tbody>
                  <tr><td><p>软件分析与测试</p></td></tr>
                  <tr><td><p>软件分析与测试-0001</p></td></tr>
                  <tr><td><p>南校区 3#504</p></td></tr>
                  <tr><td><p>刘菁</p></td></tr>
                  <tr><td><p>1-4周,6-9周</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_5-1" rowspan="2">
                <div class="lesson"><table><tbody>
                  <tr><td><p>软件工程</p></td></tr>
                  <tr><td><p>软件工程-0004</p></td></tr>
                  <tr><td><p>南校区 3#416</p></td></tr>
                  <tr><td><p>王钒霖</p></td></tr>
                  <tr><td><p>1-7周(单)</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_6-1" rowspan="10">
                <div class="lesson"><table><tbody>
                  <tr><td><p>Java Web开发技术课程设计</p></td></tr>
                  <tr><td><p>Java Web开发技术课程设计-0001</p></td></tr>
                  <tr><td><p>南校区 3#215机房</p></td></tr>
                  <tr><td><p>樊同科</p></td></tr>
                  <tr><td><p>9-10周</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_7-1" rowspan="10">
                <div class="lesson"><table><tbody>
                  <tr><td><p>Java Web开发技术课程设计</p></td></tr>
                  <tr><td><p>Java Web开发技术课程设计-0001</p></td></tr>
                  <tr><td><p>南校区 3#215机房</p></td></tr>
                  <tr><td><p>樊同科</p></td></tr>
                  <tr><td><p>9-10周</p></td></tr>
                </tbody></table></div>
              </td>
            </tr>
            <tr>
              <td>2<br>09:05:00</td>
              <td id="td_1-2"></td>
              <td id="td_2-2"></td>
              <td id="td_3-2"></td>
              <td id="td_4-2"></td>
              <td id="td_5-2"></td>
              <td id="td_6-2"></td>
              <td id="td_7-2"></td>
            </tr>
            <tr>
              <td>3<br>10:15:00</td>
              <td id="td_1-3" rowspan="2">
                <div class="lesson"><table><tbody>
                  <tr><td><p>软件工程</p></td></tr>
                  <tr><td><p>软件工程-0004</p></td></tr>
                  <tr><td><p>南校区 3#602</p></td></tr>
                  <tr><td><p>王钒霖</p></td></tr>
                  <tr><td><p>1-5周,7-17周</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_2-3"></td>
              <td id="td_3-3" rowspan="2">
                <div class="lesson"><table><tbody>
                  <tr><td><p>计算机专业英语(双语)</p></td></tr>
                  <tr><td><p>计算机专业英语(双语)-0005</p></td></tr>
                  <tr><td><p>南校区 3#602</p></td></tr>
                  <tr><td><p>薛慧芳</p></td></tr>
                  <tr><td><p>1-4周,6-17周</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_4-3" rowspan="2">
                <div class="lesson"><table><tbody>
                  <tr><td><p>操作系统</p></td></tr>
                  <tr><td><p>操作系统-0011</p></td></tr>
                  <tr><td><p>南校区 3#504</p></td></tr>
                  <tr><td><p>吕林涛</p></td></tr>
                  <tr><td><p>2-8周(双)</p></td></tr>
                </tbody></table></div>
              </td>
              <td id="td_5-3"></td>
              <td id="td_6-3"></td>
              <td id="td_7-3"></td>
            </tr>
            <tr>
              <td>4<br>11:10:00</td>
              <td id="td_1-4"></td>
              <td id="td_2-4"></td>
              <td id="td_3-4"></td>
              <td id="td_4-4"></td>
              <td id="td_5-4"></td>
              <td id="td_6-4"></td>
              <td id="td_7-4"></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      final professionalEnglish = timetable.metas.singleWhere(
        (meta) => meta.name == '计算机专业英语(双语)',
      );
      final professionalEnglishSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == professionalEnglish.id,
      );
      expect(professionalEnglishSchedule.dayOfWeek, 4);
      expect(professionalEnglishSchedule.startSection, 3);
      expect(professionalEnglishSchedule.endSection, 4);

      final operatingSystem = timetable.metas.singleWhere(
        (meta) => meta.name == '操作系统',
      );
      final operatingSystemSchedules = timetable.schedules
          .where((schedule) => schedule.courseMetaId == operatingSystem.id)
          .toList();
      expect(
        operatingSystemSchedules.any(
          (schedule) =>
              schedule.dayOfWeek == 5 &&
              schedule.startSection == 3 &&
              schedule.endSection == 4,
        ),
        isTrue,
      );
    });

    test('extracts teaching class from nested lesson code line', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <td></td>
              <td>周一</td>
              <td>周二</td>
              <td>周三</td>
              <td>周四</td>
              <td>周五</td>
              <td>周六</td>
              <td>周日</td>
            </tr>
            <tr>
              <td>1<br>08:10:00</td>
              <td rowspan="2">
                <div class="lesson"><table><tbody>
                  <tr><td><p>操作系统</p></td></tr>
                  <tr><td><p>操作系统-0011</p></td></tr>
                  <tr><td><p>南校区 3#504</p></td></tr>
                  <tr><td><p>吕林涛</p></td></tr>
                  <tr><td><p>1-5周,7-17周</p></td></tr>
                </tbody></table></div>
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>2<br>09:05:00</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.metas.single.teachingClass, '操作系统-0011');
    });

    test('splits one cell with multiple week and classroom blocks', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th></th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
              <th>周四</th>
              <th>周五</th>
              <th>周六</th>
              <th>周日</th>
            </tr>
            <tr>
              <td>1</td>
              <td></td>
              <td></td>
              <td></td>
              <td rowspan="2">
                软件分析与测试<br>
                软件分析与测试-0001<br>
                刘菁<br>
                南校区 3#504<br>
                1-4周,6-9周<br>
                软件分析与测试-0001A<br>
                南校区 3#415机房<br>
                10-17周
              </td>
              <td rowspan="2">
                软件工程<br>
                软件工程-0004<br>
                王钒霖<br>
                南校区 3#416<br>
                1-7周(单)<br>
                软件工程-0004A<br>
                南校区 3#318机房<br>
                10-11周,13-15周(单)
              </td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>2</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      final analysisLecture = timetable.metas.singleWhere(
        (meta) =>
            meta.name == '软件分析与测试' && meta.teachingClass == '软件分析与测试-0001',
      );
      final analysisPractice = timetable.metas.singleWhere(
        (meta) =>
            meta.name == '软件分析与测试' && meta.teachingClass == '软件分析与测试-0001A',
      );
      final analysisLectureSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == analysisLecture.id,
      );
      final analysisPracticeSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == analysisPractice.id,
      );
      expect(analysisLectureSchedule.dayOfWeek, 4);
      expect(analysisLectureSchedule.startSection, 1);
      expect(analysisLectureSchedule.endSection, 2);
      expect(analysisLectureSchedule.classroom, '南校区 3#504');
      expect(analysisLectureSchedule.weeks, <int>[1, 2, 3, 4, 6, 7, 8, 9]);
      expect(analysisPracticeSchedule.classroom, '南校区 3#415机房');
      expect(analysisPracticeSchedule.weeks, <int>[
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
      ]);

      final softwareEngineeringLecture = timetable.metas.singleWhere(
        (meta) => meta.name == '软件工程' && meta.teachingClass == '软件工程-0004',
      );
      final softwareEngineeringPractice = timetable.metas.singleWhere(
        (meta) => meta.name == '软件工程' && meta.teachingClass == '软件工程-0004A',
      );
      final engineeringLectureSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == softwareEngineeringLecture.id,
      );
      final engineeringPracticeSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == softwareEngineeringPractice.id,
      );
      expect(engineeringLectureSchedule.dayOfWeek, 5);
      expect(engineeringLectureSchedule.classroom, '南校区 3#416');
      expect(engineeringLectureSchedule.weeks, <int>[1, 3, 5, 7]);
      expect(engineeringPracticeSchedule.classroom, '南校区 3#318机房');
      expect(engineeringPracticeSchedule.weeks, <int>[10, 11, 13, 15]);
    });

    test(
      'does not shift weekdays when a period axis cell precedes section',
      () {
        const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th>节次</th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
              <th>周四</th>
              <th>周五</th>
              <th>周六</th>
              <th>周日</th>
            </tr>
            <tr>
              <td rowspan="4">上午</td>
              <td>1</td>
              <td rowspan="2">
                毛泽东思想和中国特色社会主义理论体系概论<br>
                毛泽东思想和中国特色社会主义理论体系概论-0010<br>
                南校区 学术苑302<br>
                高禾莹<br>
                1-16周
              </td>
              <td rowspan="2">
                计算机组成原理<br>
                计算机组成原理-0001<br>
                南校区 3#604<br>
                周小娟<br>
                1-16周
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>2</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

        final timetable = AcademicTimetableHtmlParser.parse(html);

        final thought = timetable.metas.singleWhere(
          (meta) => meta.name == '毛泽东思想和中国特色社会主义理论体系概论',
        );
        final thoughtSchedule = timetable.schedules.singleWhere(
          (schedule) => schedule.courseMetaId == thought.id,
        );
        expect(thoughtSchedule.dayOfWeek, 1);
        expect(thoughtSchedule.startSection, 1);
        expect(thoughtSchedule.endSection, 2);

        final organization = timetable.metas.singleWhere(
          (meta) => meta.name == '计算机组成原理',
        );
        final organizationSchedule = timetable.schedules.singleWhere(
          (schedule) => schedule.courseMetaId == organization.id,
        );
        expect(organizationSchedule.dayOfWeek, 2);
        expect(organizationSchedule.startSection, 1);
        expect(organizationSchedule.endSection, 2);
      },
    );

    test('keeps weekdays aligned after the period axis rowspan continues', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th>时间段</th>
              <th>节次</th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
              <th>周四</th>
              <th>周五</th>
              <th>周六</th>
              <th>周日</th>
            </tr>
            <tr>
              <td rowspan="4">上午</td>
              <td>1</td>
              <td rowspan="2">
                毛泽东思想和中国特色社会主义理论体系概论<br>
                毛泽东思想和中国特色社会主义理论体系概论-0010<br>
                南校区 学术苑302<br>
                高禾莹<br>
                1-16周
              </td>
              <td rowspan="2">
                计算机组成原理<br>
                计算机组成原理-0001<br>
                南校区 3#604<br>
                周小娟<br>
                1-16周
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>2</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>3</td>
              <td rowspan="2">
                Java高级技术<br>
                Java高级技术-0002<br>
                南校区 3#318机房<br>
                高文玲<br>
                1-16周
              </td>
              <td></td>
              <td rowspan="2">
                数据库原理<br>
                数据库原理-0002<br>
                南校区 3#315机房<br>
                刘智慧<br>
                1-16周
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>4</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      final java = timetable.metas.singleWhere(
        (meta) => meta.name == 'Java高级技术',
      );
      final javaSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == java.id,
      );
      expect(javaSchedule.dayOfWeek, 1);
      expect(javaSchedule.startSection, 3);
      expect(javaSchedule.endSection, 4);

      final database = timetable.metas.singleWhere(
        (meta) => meta.name == '数据库原理',
      );
      final databaseSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == database.id,
      );
      expect(databaseSchedule.dayOfWeek, 3);
      expect(databaseSchedule.startSection, 3);
      expect(databaseSchedule.endSection, 4);
    });

    test(
      'keeps names and teachers for different lesson blocks in one cell',
      () {
        const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th></th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
              <th>周四</th>
              <th>周五</th>
              <th>周六</th>
              <th>周日</th>
            </tr>
            <tr>
              <td>5</td>
              <td></td>
              <td rowspan="4">
                <div class="lesson">
                  <table><tbody>
                    <tr><td><p>计算机网络原理</p></td></tr>
                    <tr><td><p>计算机网络原理-0001</p></td></tr>
                    <tr><td><p>南校区 3#604</p></td></tr>
                    <tr><td><p>王奕丹</p></td></tr>
                    <tr><td><p>(5-6节)1-14周,16周</p></td></tr>
                  </tbody></table>
                </div>
                <div class="lesson">
                  <table><tbody>
                    <tr><td><p>英美小说影视欣赏</p></td></tr>
                    <tr><td><p>英美小说影视欣赏-0001</p></td></tr>
                    <tr><td><p>南校区 3#208</p></td></tr>
                    <tr><td><p>武海平</p></td></tr>
                    <tr><td><p>(5-6节)11-12周</p></td></tr>
                  </tbody></table>
                </div>
                <div class="lesson">
                  <table><tbody>
                    <tr><td><p>计算机网络原理</p></td></tr>
                    <tr><td><p>计算机网络原理-0001A</p></td></tr>
                    <tr><td><p>南校区 3#315机房</p></td></tr>
                    <tr><td><p>王奕丹</p></td></tr>
                    <tr><td><p>(5-8节)15周</p></td></tr>
                  </tbody></table>
                </div>
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>6</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>7</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>8</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

        final timetable = AcademicTimetableHtmlParser.parse(html);

        final english = timetable.metas.singleWhere(
          (meta) => meta.name == '英美小说影视欣赏',
        );
        expect(english.teacher, '武海平');
        expect(english.teachingClass, '英美小说影视欣赏-0001');
        final englishSchedule = timetable.schedules.singleWhere(
          (schedule) => schedule.courseMetaId == english.id,
        );
        expect(englishSchedule.dayOfWeek, 2);
        expect(englishSchedule.startSection, 5);
        expect(englishSchedule.endSection, 6);
        expect(englishSchedule.classroom, '南校区 3#208');
        expect(englishSchedule.weeks, <int>[11, 12]);

        final practice = timetable.metas.singleWhere(
          (meta) =>
              meta.name == '计算机网络原理' && meta.teachingClass == '计算机网络原理-0001A',
        );
        final practiceSchedule = timetable.schedules.singleWhere(
          (schedule) => schedule.courseMetaId == practice.id,
        );
        expect(practiceSchedule.startSection, 5);
        expect(practiceSchedule.endSection, 8);
        expect(practiceSchedule.weeks, <int>[15]);
      },
    );

    test('keeps non-theory marker in table course names', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th></th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
              <th>周四</th>
              <th>周五</th>
              <th>周六</th>
              <th>周日</th>
            </tr>
            <tr>
              <td>5</td>
              <td></td>
              <td rowspan="4">
                <div class="lesson">
                  <table><tbody>
                    <tr><td><p>计算机网络原理■</p></td></tr>
                    <tr><td><p>计算机网络原理-0001A</p></td></tr>
                    <tr><td><p>示例校区 3#315机房</p></td></tr>
                    <tr><td><p>教师A</p></td></tr>
                    <tr><td><p>(5-8节)15周</p></td></tr>
                  </tbody></table>
                </div>
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.metas.single.name, '计算机网络原理■');
      expect(timetable.metas.single.teachingClass, '计算机网络原理-0001A');
      expect(timetable.schedules.single.dayOfWeek, 2);
      expect(timetable.schedules.single.startSection, 5);
      expect(timetable.schedules.single.endSection, 8);
      expect(timetable.schedules.single.weeks, <int>[15]);
    });

    test('extracts labeled newline-separated table cell text', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th></th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
              <th>周四</th>
              <th>周五</th>
              <th>周六</th>
              <th>周日</th>
            </tr>
            <tr>
              <td>1</td>
              <td rowspan="2">
课程名称：操作系统
教师：吕林涛
地点：南校区 3#504
周次：1-5周,7-9周
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <td>2</td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.metas, hasLength(1));
      expect(timetable.schedules, hasLength(1));
      expect(timetable.metas.single.name, '操作系统');
      expect(timetable.metas.single.teacher, '吕林涛');
      expect(timetable.schedules.single.classroom, '南校区 3#504');
      expect(timetable.schedules.single.dayOfWeek, 1);
      expect(timetable.schedules.single.startSection, 1);
      expect(timetable.schedules.single.endSection, 2);
      expect(timetable.schedules.single.weeks, <int>[1, 2, 3, 4, 5, 7, 8, 9]);
    });
  });

  group('AcademicTimetableHtmlParser.parse', () {
    test('deduplicates repeated schedules in one HTML page', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <td data-day="1" data-start-section="1" data-end-section="2">
                操作系统<br>
                吕林涛<br>
                南校区 3#504<br>
                1-5周,7-17周
              </td>
              <td data-day="1" data-start-section="1" data-end-section="2">
                操作系统<br>
                吕林涛<br>
                南校区 3#504<br>
                1-5周,7-17周
              </td>
              <td data-day="4" data-start-section="5" data-end-section="6">
                软件工程<br>
                赵强<br>
                南校区 3#602<br>
                1-16周
              </td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.metas, hasLength(2));
      expect(timetable.schedules, hasLength(2));
      expect(
        timetable.metas.map((meta) => meta.name),
        containsAll(<String>['操作系统', '软件工程']),
      );
    });

    test('does not parse an outer timetable container as one course card', () {
      const html = '''
      <html>
        <body>
          <div class="kb timetable-card"
               style="position:absolute;left:0%;top:0%;width:100%;height:100%;">
            <div class="lesson"
                 style="position:absolute;left:0%;top:0%;width:14.285%;height:16.666%;">
              <p>操作系统</p>
              <p>操作系统-0011</p>
              <p>南校区 3#504</p>
              <p>吕林涛</p>
              <p>1-5周</p>
            </div>
            <div class="lesson"
                 style="position:absolute;left:14.285%;top:16.666%;width:14.285%;height:16.666%;">
              <p>软件工程</p>
              <p>软件工程-0004</p>
              <p>南校区 3#602</p>
              <p>王钒霖</p>
              <p>1-5周</p>
            </div>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, hasLength(2));
      final operatingSystem = timetable.metas.singleWhere(
        (meta) => meta.name == '操作系统',
      );
      final operatingSystemSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == operatingSystem.id,
      );
      expect(operatingSystemSchedule.dayOfWeek, 1);
      expect(operatingSystemSchedule.startSection, 1);

      final softwareEngineering = timetable.metas.singleWhere(
        (meta) => meta.name == '软件工程',
      );
      final softwareEngineeringSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == softwareEngineering.id,
      );
      expect(softwareEngineeringSchedule.dayOfWeek, 2);
      expect(softwareEngineeringSchedule.startSection, 3);
    });

    test('reads course rows when table head and body are separate', () {
      const html = '''
      <html>
        <body>
          <table>
            <thead>
              <tr>
                <th></th>
                <th>周一</th>
                <th>周二</th>
                <th>周三</th>
                <th>周四</th>
                <th>周五</th>
                <th>周六</th>
                <th>周日</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>1</td>
                <td rowspan="2">
                  操作系统<br>
                  南校区 3#504<br>
                  吕林涛<br>
                  1-5周
                </td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
              </tr>
              <tr>
                <td>2</td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
              </tr>
            </tbody>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, hasLength(1));
      expect(timetable.metas.single.name, '操作系统');
      expect(timetable.schedules.single.dayOfWeek, 1);
      expect(timetable.schedules.single.startSection, 1);
      expect(timetable.schedules.single.endSection, 2);
    });

    test('parses separate CSS grid start and span end properties', () {
      const html = '''
      <html>
        <body>
          <div class="kb-grid">
            <div class="lesson"
                 style="grid-column-start:2;grid-column-end:span 1;grid-row-start:3;grid-row-end:span 2;">
              <p>操作系统</p>
              <p>南校区 3#504</p>
              <p>吕林涛</p>
              <p>1-5周</p>
            </div>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, hasLength(1));
      expect(timetable.schedules.single.dayOfWeek, 2);
      expect(timetable.schedules.single.startSection, 3);
      expect(timetable.schedules.single.endSection, 4);
    });

    test('parses grid-area row span values', () {
      const html = '''
      <html>
        <body>
          <div class="kb-grid">
            <div class="lesson"
                 style="grid-area:3 / 2 / span 2 / span 1;">
              <p>操作系统</p>
              <p>南校区 3#504</p>
              <p>吕林涛</p>
              <p>1-5周</p>
            </div>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, hasLength(1));
      expect(timetable.schedules.single.dayOfWeek, 2);
      expect(timetable.schedules.single.startSection, 3);
      expect(timetable.schedules.single.endSection, 4);
    });

    test('preserves absolute grid-area end lines', () {
      const html = '''
      <html>
        <body>
          <div class="kb-grid">
            <div class="lesson" style="grid-area:3 / 2 / 5 / 3;">
              <p>操作系统</p>
              <p>南校区 3#504</p>
              <p>吕林涛</p>
              <p>1-5周</p>
            </div>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, hasLength(1));
      expect(timetable.schedules.single.dayOfWeek, 2);
      expect(timetable.schedules.single.startSection, 3);
      expect(timetable.schedules.single.endSection, 4);
    });

    test(
      'infers sixteen-row percentage placement when alignment is stronger',
      () {
        const html = '''
      <html>
        <body>
          <div class="mobile-timetable">
            <div class="course-card"
                 style="position:absolute;left:0%;top:75%;width:14.285%;height:6.25%;">
              <p>晚间课程 13</p><p>南校区 报告厅</p><p>吕林涛</p><p>1-5周</p>
            </div>
            <div class="course-card"
                 style="position:absolute;left:0%;top:81.25%;width:14.285%;height:6.25%;">
              <p>晚间课程 14</p><p>南校区 报告厅</p><p>吕林涛</p><p>1-5周</p>
            </div>
            <div class="course-card"
                 style="position:absolute;left:0%;top:87.5%;width:14.285%;height:6.25%;">
              <p>晚间课程 15</p><p>南校区 报告厅</p><p>吕林涛</p><p>1-5周</p>
            </div>
            <div class="course-card"
                 style="position:absolute;left:0%;top:93.75%;width:14.285%;height:6.25%;">
              <p>晚间课程 16</p><p>南校区 报告厅</p><p>吕林涛</p><p>1-5周</p>
            </div>
          </div>
        </body>
      </html>
      ''';

        final timetable = AcademicTimetableHtmlParser.parse(html);
        final startSections =
            timetable.schedules
                .map((schedule) => schedule.startSection)
                .toList()
              ..sort();

        expect(startSections, <int>[13, 14, 15, 16]);
        expect(
          timetable.schedules.map((schedule) => schedule.endSection).toSet(),
          <int>{13, 14, 15, 16},
        );
      },
    );

    test('keeps ambiguous percentage placement on twelve rows', () {
      const html = '''
      <html>
        <body>
          <div class="course-card"
               style="position:absolute;left:0%;top:75%;width:14.285%;height:25%;">
            <p>晚间课程</p>
            <p>南校区 报告厅</p>
            <p>吕林涛</p>
            <p>1-5周</p>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, hasLength(1));
      expect(timetable.schedules.single.startSection, 10);
      expect(timetable.schedules.single.endSection, 12);
    });

    test('does not guess sections from pixel-only positioning', () {
      const html = '''
      <html>
        <body>
          <div class="course-card"
               style="position:absolute;left:0px;top:120px;width:100px;height:40px;">
            <p>操作系统</p>
            <p>南校区 3#504</p>
            <p>吕林涛</p>
            <p>1-5周</p>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, isEmpty);
    });

    test('rejects out-of-range text sections', () {
      const html = '''
      <html>
        <body>
          <div class="lesson">
            <p>操作系统</p>
            <p>周一 第17-18节</p>
            <p>南校区 3#504</p>
            <p>吕林涛</p>
            <p>1-5周</p>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, isEmpty);
    });

    test(
      'rejects out-of-range text sections before percentage placement fallback',
      () {
        const html = '''
      <html>
        <body>
          <div class="course-card"
               style="position:absolute;left:0%;top:0%;width:14.285%;height:16.666%;">
            <p>操作系统</p>
            <p>周一 第17-18节</p>
            <p>南校区 3#504</p>
            <p>吕林涛</p>
            <p>1-5周</p>
          </div>
        </body>
      </html>
      ''';

        final timetable = AcademicTimetableHtmlParser.parse(html);

        expect(timetable.schedules, isEmpty);
      },
    );

    test('rejects out-of-range text sections in plain timetable cells', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <th>节次</th>
              <th>周一</th>
              <th>周二</th>
              <th>周三</th>
            </tr>
            <tr>
              <td>1</td>
              <td>
                操作系统<br>
                周一 第17-18节<br>
                南校区 3#504<br>
                吕林涛<br>
                1-5周
              </td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, isEmpty);
    });

    test('does not treat a bare classroom number as week text', () {
      const html = '''
      <html>
        <body>
          <div class="lesson">
            <p>离散数学</p>
            <p>周一 第1-2节</p>
            <p>吕林涛</p>
            <p>12</p>
          </div>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, isEmpty);
    });

    test('keeps explicit HTML schedules in sections thirteen to sixteen', () {
      const html = '''
      <html>
        <body>
          <table>
            <tr>
              <td data-day="7" data-start-section="13" data-end-section="16">
                晚间课程<br>
                南校区 报告厅<br>
                吕林涛<br>
                1-5周
              </td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final timetable = AcademicTimetableHtmlParser.parse(html);

      expect(timetable.schedules, hasLength(1));
      expect(timetable.schedules.single.dayOfWeek, 7);
      expect(timetable.schedules.single.startSection, 13);
      expect(timetable.schedules.single.endSection, 16);
    });
  });
}
