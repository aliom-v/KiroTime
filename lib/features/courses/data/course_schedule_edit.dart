class CourseScheduleEdit {
  const CourseScheduleEdit({
    required this.courseMetaId,
    required this.scheduleId,
    required this.name,
    required this.teacher,
    required this.teachingClass,
    required this.classroom,
    required this.dayOfWeek,
    required this.startSection,
    required this.endSection,
    required this.weeks,
  });

  final String courseMetaId;
  final String scheduleId;
  final String name;
  final String teacher;
  final String teachingClass;
  final String classroom;
  final int dayOfWeek;
  final int startSection;
  final int endSection;
  final List<int> weeks;
}
