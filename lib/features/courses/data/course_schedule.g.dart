// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_schedule.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCourseScheduleCollection on Isar {
  IsarCollection<CourseSchedule> get courseSchedules => this.collection();
}

const CourseScheduleSchema = CollectionSchema(
  name: r'CourseSchedule',
  id: -2017845801701500755,
  properties: {
    r'classroom': PropertySchema(
      id: 0,
      name: r'classroom',
      type: IsarType.string,
    ),
    r'courseMetaId': PropertySchema(
      id: 1,
      name: r'courseMetaId',
      type: IsarType.string,
    ),
    r'dayOfWeek': PropertySchema(
      id: 2,
      name: r'dayOfWeek',
      type: IsarType.long,
    ),
    r'endSection': PropertySchema(
      id: 3,
      name: r'endSection',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'semesterId': PropertySchema(
      id: 5,
      name: r'semesterId',
      type: IsarType.string,
    ),
    r'startSection': PropertySchema(
      id: 6,
      name: r'startSection',
      type: IsarType.long,
    ),
    r'weeks': PropertySchema(
      id: 7,
      name: r'weeks',
      type: IsarType.longList,
    )
  },
  estimateSize: _courseScheduleEstimateSize,
  serialize: _courseScheduleSerialize,
  deserialize: _courseScheduleDeserialize,
  deserializeProp: _courseScheduleDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'courseMetaId': IndexSchema(
      id: 6587835443623569641,
      name: r'courseMetaId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'courseMetaId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'semesterId': IndexSchema(
      id: -4385212551819087598,
      name: r'semesterId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'semesterId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _courseScheduleGetId,
  getLinks: _courseScheduleGetLinks,
  attach: _courseScheduleAttach,
  version: '3.1.0+1',
);

int _courseScheduleEstimateSize(
  CourseSchedule object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.classroom.length * 3;
  bytesCount += 3 + object.courseMetaId.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.semesterId.length * 3;
  bytesCount += 3 + object.weeks.length * 8;
  return bytesCount;
}

void _courseScheduleSerialize(
  CourseSchedule object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.classroom);
  writer.writeString(offsets[1], object.courseMetaId);
  writer.writeLong(offsets[2], object.dayOfWeek);
  writer.writeLong(offsets[3], object.endSection);
  writer.writeString(offsets[4], object.id);
  writer.writeString(offsets[5], object.semesterId);
  writer.writeLong(offsets[6], object.startSection);
  writer.writeLongList(offsets[7], object.weeks);
}

CourseSchedule _courseScheduleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CourseSchedule();
  object.classroom = reader.readString(offsets[0]);
  object.courseMetaId = reader.readString(offsets[1]);
  object.dayOfWeek = reader.readLong(offsets[2]);
  object.endSection = reader.readLong(offsets[3]);
  object.id = reader.readString(offsets[4]);
  object.semesterId = reader.readString(offsets[5]);
  object.startSection = reader.readLong(offsets[6]);
  object.weeks = reader.readLongList(offsets[7]) ?? [];
  return object;
}

P _courseScheduleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLongList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _courseScheduleGetId(CourseSchedule object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _courseScheduleGetLinks(CourseSchedule object) {
  return [];
}

void _courseScheduleAttach(
    IsarCollection<dynamic> col, Id id, CourseSchedule object) {}

extension CourseScheduleByIndex on IsarCollection<CourseSchedule> {
  Future<CourseSchedule?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  CourseSchedule? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<CourseSchedule?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<CourseSchedule?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(CourseSchedule object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(CourseSchedule object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<CourseSchedule> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<CourseSchedule> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension CourseScheduleQueryWhereSort
    on QueryBuilder<CourseSchedule, CourseSchedule, QWhere> {
  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CourseScheduleQueryWhere
    on QueryBuilder<CourseSchedule, CourseSchedule, QWhereClause> {
  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause>
      courseMetaIdEqualTo(String courseMetaId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'courseMetaId',
        value: [courseMetaId],
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause>
      courseMetaIdNotEqualTo(String courseMetaId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'courseMetaId',
              lower: [],
              upper: [courseMetaId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'courseMetaId',
              lower: [courseMetaId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'courseMetaId',
              lower: [courseMetaId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'courseMetaId',
              lower: [],
              upper: [courseMetaId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause>
      semesterIdEqualTo(String semesterId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'semesterId',
        value: [semesterId],
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterWhereClause>
      semesterIdNotEqualTo(String semesterId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'semesterId',
              lower: [],
              upper: [semesterId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'semesterId',
              lower: [semesterId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'semesterId',
              lower: [semesterId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'semesterId',
              lower: [],
              upper: [semesterId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CourseScheduleQueryFilter
    on QueryBuilder<CourseSchedule, CourseSchedule, QFilterCondition> {
  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'classroom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'classroom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'classroom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'classroom',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'classroom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'classroom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'classroom',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'classroom',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'classroom',
        value: '',
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      classroomIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'classroom',
        value: '',
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'courseMetaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'courseMetaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'courseMetaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'courseMetaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'courseMetaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'courseMetaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'courseMetaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'courseMetaId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'courseMetaId',
        value: '',
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      courseMetaIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'courseMetaId',
        value: '',
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      dayOfWeekEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      dayOfWeekGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      dayOfWeekLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayOfWeek',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      dayOfWeekBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayOfWeek',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      endSectionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endSection',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      endSectionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endSection',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      endSectionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endSection',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      endSectionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endSection',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'semesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'semesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'semesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'semesterId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'semesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'semesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'semesterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'semesterId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'semesterId',
        value: '',
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      semesterIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'semesterId',
        value: '',
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      startSectionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startSection',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      startSectionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startSection',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      startSectionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startSection',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      startSectionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startSection',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weeks',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weeks',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weeks',
        value: value,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weeks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterFilterCondition>
      weeksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weeks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension CourseScheduleQueryObject
    on QueryBuilder<CourseSchedule, CourseSchedule, QFilterCondition> {}

extension CourseScheduleQueryLinks
    on QueryBuilder<CourseSchedule, CourseSchedule, QFilterCondition> {}

extension CourseScheduleQuerySortBy
    on QueryBuilder<CourseSchedule, CourseSchedule, QSortBy> {
  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> sortByClassroom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroom', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortByClassroomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroom', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortByCourseMetaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'courseMetaId', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortByCourseMetaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'courseMetaId', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> sortByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortByEndSection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSection', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortByEndSectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSection', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortBySemesterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterId', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortBySemesterIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterId', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortByStartSection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSection', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      sortByStartSectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSection', Sort.desc);
    });
  }
}

extension CourseScheduleQuerySortThenBy
    on QueryBuilder<CourseSchedule, CourseSchedule, QSortThenBy> {
  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> thenByClassroom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroom', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByClassroomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroom', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByCourseMetaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'courseMetaId', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByCourseMetaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'courseMetaId', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> thenByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByDayOfWeekDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeek', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByEndSection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSection', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByEndSectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSection', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenBySemesterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterId', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenBySemesterIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterId', Sort.desc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByStartSection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSection', Sort.asc);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QAfterSortBy>
      thenByStartSectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSection', Sort.desc);
    });
  }
}

extension CourseScheduleQueryWhereDistinct
    on QueryBuilder<CourseSchedule, CourseSchedule, QDistinct> {
  QueryBuilder<CourseSchedule, CourseSchedule, QDistinct> distinctByClassroom(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'classroom', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QDistinct>
      distinctByCourseMetaId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'courseMetaId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QDistinct>
      distinctByDayOfWeek() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayOfWeek');
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QDistinct>
      distinctByEndSection() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endSection');
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QDistinct> distinctBySemesterId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'semesterId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QDistinct>
      distinctByStartSection() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startSection');
    });
  }

  QueryBuilder<CourseSchedule, CourseSchedule, QDistinct> distinctByWeeks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weeks');
    });
  }
}

extension CourseScheduleQueryProperty
    on QueryBuilder<CourseSchedule, CourseSchedule, QQueryProperty> {
  QueryBuilder<CourseSchedule, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<CourseSchedule, String, QQueryOperations> classroomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'classroom');
    });
  }

  QueryBuilder<CourseSchedule, String, QQueryOperations>
      courseMetaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'courseMetaId');
    });
  }

  QueryBuilder<CourseSchedule, int, QQueryOperations> dayOfWeekProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayOfWeek');
    });
  }

  QueryBuilder<CourseSchedule, int, QQueryOperations> endSectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endSection');
    });
  }

  QueryBuilder<CourseSchedule, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CourseSchedule, String, QQueryOperations> semesterIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'semesterId');
    });
  }

  QueryBuilder<CourseSchedule, int, QQueryOperations> startSectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startSection');
    });
  }

  QueryBuilder<CourseSchedule, List<int>, QQueryOperations> weeksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weeks');
    });
  }
}
