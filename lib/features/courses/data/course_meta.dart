import 'package:isar/isar.dart';

import '../../../core/database/string_id_hash.dart';

part 'course_meta.g.dart';

@collection
class CourseMeta {
  @Index(unique: true, replace: true)
  late String id;

  Id get isarId => stableStringIdHash(id);

  late String name;
  late String teacher;
  String teachingClass = '';

  CourseMeta();

  factory CourseMeta.create({
    required String id,
    required String name,
    required String teacher,
    String teachingClass = '',
  }) {
    return CourseMeta()
      ..id = id
      ..name = name
      ..teacher = teacher
      ..teachingClass = teachingClass;
  }
}
