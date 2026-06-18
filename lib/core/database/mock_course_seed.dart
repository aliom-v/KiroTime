import '../../features/courses/data/course_meta.dart';
import '../../features/courses/data/course_schedule.dart';

class MockCourseSeed {
  static final List<CourseMeta> metas = <CourseMeta>[
    CourseMeta.create(id: 'course-os', name: '操作系统', teacher: '吕林涛'),
    CourseMeta.create(id: 'course-db', name: '数据库原理', teacher: '陈静'),
    CourseMeta.create(id: 'course-english', name: '大学英语', teacher: '王敏'),
    CourseMeta.create(id: 'course-physics', name: '大学物理', teacher: '赵强'),
  ];

  static final List<CourseSchedule> schedules = <CourseSchedule>[
    CourseSchedule.create(
      id: 'schedule-os-1',
      courseMetaId: 'course-os',
      classroom: '南校区 3#504',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
      weeks: <int>[1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    ),
    CourseSchedule.create(
      id: 'schedule-db-1',
      courseMetaId: 'course-db',
      classroom: '南校区 2#301',
      dayOfWeek: 3,
      startSection: 3,
      endSection: 4,
      weeks: <int>[2, 4, 6, 8, 10, 12, 14, 16],
    ),
    CourseSchedule.create(
      id: 'schedule-db-2',
      courseMetaId: 'course-db',
      classroom: '南校区 2#302',
      dayOfWeek: 5,
      startSection: 5,
      endSection: 6,
      weeks: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
    ),
    CourseSchedule.create(
      id: 'schedule-english-1',
      courseMetaId: 'course-english',
      classroom: '外语楼 104',
      dayOfWeek: 1,
      startSection: 2,
      endSection: 3,
      weeks: <int>[1, 2, 3, 4, 5, 6, 7, 8],
    ),
    CourseSchedule.create(
      id: 'schedule-physics-1',
      courseMetaId: 'course-physics',
      classroom: '理工楼 201',
      dayOfWeek: 1,
      startSection: 1,
      endSection: 2,
      weeks: <int>[1, 2, 3, 4, 5, 6, 7, 8],
    ),
  ];
}
