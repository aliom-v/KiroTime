import 'package:isar/isar.dart';

import '../../../core/database/string_id_hash.dart';

part 'course_schedule.g.dart';

@collection
class CourseSchedule {
  @Index(unique: true, replace: true)
  late String id;

  Id get isarId => stableStringIdHash(id);

  @Index()
  late String courseMetaId;

  @Index()
  String semesterId = '';

  late String classroom;
  late int dayOfWeek;
  late int startSection;
  late int endSection;

  late List<int> weeks;

  CourseSchedule();

  factory CourseSchedule.create({
    required String id,
    required String courseMetaId,
    required String classroom,
    required int dayOfWeek,
    required int startSection,
    required int endSection,
    required List<int> weeks,
    String semesterId = '',
  }) {
    return CourseSchedule()
      ..id = id
      ..courseMetaId = courseMetaId
      ..semesterId = semesterId
      ..classroom = classroom
      ..dayOfWeek = dayOfWeek
      ..startSection = startSection
      ..endSection = endSection
      ..weeks = weeks;
  }
}
