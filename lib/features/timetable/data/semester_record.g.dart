// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSemesterRecordCollection on Isar {
  IsarCollection<SemesterRecord> get semesterRecords => this.collection();
}

const SemesterRecordSchema = CollectionSchema(
  name: r'SemesterRecord',
  id: -82286446524217794,
  properties: {
    r'displayName': PropertySchema(
      id: 0,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'id': PropertySchema(id: 1, name: r'id', type: IsarType.string),
    r'schoolYearStart': PropertySchema(
      id: 2,
      name: r'schoolYearStart',
      type: IsarType.long,
    ),
    r'sectionCount': PropertySchema(
      id: 3,
      name: r'sectionCount',
      type: IsarType.long,
    ),
    r'sectionTimesJson': PropertySchema(
      id: 4,
      name: r'sectionTimesJson',
      type: IsarType.string,
    ),
    r'semester': PropertySchema(id: 5, name: r'semester', type: IsarType.long),
    r'semesterStart': PropertySchema(
      id: 6,
      name: r'semesterStart',
      type: IsarType.dateTime,
    ),
    r'totalWeeks': PropertySchema(
      id: 7,
      name: r'totalWeeks',
      type: IsarType.long,
    ),
  },
  estimateSize: _semesterRecordEstimateSize,
  serialize: _semesterRecordSerialize,
  deserialize: _semesterRecordDeserialize,
  deserializeProp: _semesterRecordDeserializeProp,
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _semesterRecordGetId,
  getLinks: _semesterRecordGetLinks,
  attach: _semesterRecordAttach,
  version: '3.1.0+1',
);

int _semesterRecordEstimateSize(
  SemesterRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.sectionTimesJson.length * 3;
  return bytesCount;
}

void _semesterRecordSerialize(
  SemesterRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.displayName);
  writer.writeString(offsets[1], object.id);
  writer.writeLong(offsets[2], object.schoolYearStart);
  writer.writeLong(offsets[3], object.sectionCount);
  writer.writeString(offsets[4], object.sectionTimesJson);
  writer.writeLong(offsets[5], object.semester);
  writer.writeDateTime(offsets[6], object.semesterStart);
  writer.writeLong(offsets[7], object.totalWeeks);
}

SemesterRecord _semesterRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SemesterRecord();
  object.displayName = reader.readString(offsets[0]);
  object.id = reader.readString(offsets[1]);
  object.schoolYearStart = reader.readLong(offsets[2]);
  object.sectionCount = reader.readLong(offsets[3]);
  object.sectionTimesJson = reader.readString(offsets[4]);
  object.semester = reader.readLong(offsets[5]);
  object.semesterStart = reader.readDateTime(offsets[6]);
  object.totalWeeks = reader.readLong(offsets[7]);
  return object;
}

P _semesterRecordDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _semesterRecordGetId(SemesterRecord object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _semesterRecordGetLinks(SemesterRecord object) {
  return [];
}

void _semesterRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  SemesterRecord object,
) {}

extension SemesterRecordByIndex on IsarCollection<SemesterRecord> {
  Future<SemesterRecord?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  SemesterRecord? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<SemesterRecord?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<SemesterRecord?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(SemesterRecord object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(SemesterRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<SemesterRecord> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(
    List<SemesterRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension SemesterRecordQueryWhereSort
    on QueryBuilder<SemesterRecord, SemesterRecord, QWhere> {
  QueryBuilder<SemesterRecord, SemesterRecord, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SemesterRecordQueryWhere
    on QueryBuilder<SemesterRecord, SemesterRecord, QWhereClause> {
  QueryBuilder<SemesterRecord, SemesterRecord, QAfterWhereClause> isarIdEqualTo(
    Id isarId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterWhereClause>
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

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterWhereClause>
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterWhereClause>
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterWhereClause> idEqualTo(
    String id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'id', value: [id]),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterWhereClause> idNotEqualTo(
    String id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [],
                upper: [id],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [id],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [id],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'id',
                lower: [],
                upper: [id],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SemesterRecordQueryFilter
    on QueryBuilder<SemesterRecord, SemesterRecord, QFilterCondition> {
  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'displayName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'displayName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  idLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  idStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  idEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition> idMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'id', value: ''),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  schoolYearStartEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schoolYearStart', value: value),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  schoolYearStartGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schoolYearStart',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  schoolYearStartLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schoolYearStart',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  schoolYearStartBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schoolYearStart',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sectionCount', value: value),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sectionCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sectionCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sectionCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sectionTimesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sectionTimesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sectionTimesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sectionTimesJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sectionTimesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sectionTimesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sectionTimesJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sectionTimesJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sectionTimesJson', value: ''),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  sectionTimesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sectionTimesJson', value: ''),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  semesterEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'semester', value: value),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  semesterGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'semester',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  semesterLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'semester',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  semesterBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'semester',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  semesterStartEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'semesterStart', value: value),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  semesterStartGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'semesterStart',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  semesterStartLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'semesterStart',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  semesterStartBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'semesterStart',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  totalWeeksEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalWeeks', value: value),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  totalWeeksGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalWeeks',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  totalWeeksLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalWeeks',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterFilterCondition>
  totalWeeksBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalWeeks',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SemesterRecordQueryObject
    on QueryBuilder<SemesterRecord, SemesterRecord, QFilterCondition> {}

extension SemesterRecordQueryLinks
    on QueryBuilder<SemesterRecord, SemesterRecord, QFilterCondition> {}

extension SemesterRecordQuerySortBy
    on QueryBuilder<SemesterRecord, SemesterRecord, QSortBy> {
  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySchoolYearStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolYearStart', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySchoolYearStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolYearStart', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySectionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sectionCount', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySectionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sectionCount', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySectionTimesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sectionTimesJson', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySectionTimesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sectionTimesJson', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy> sortBySemester() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semester', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySemesterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semester', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySemesterStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterStart', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortBySemesterStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterStart', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortByTotalWeeks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWeeks', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  sortByTotalWeeksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWeeks', Sort.desc);
    });
  }
}

extension SemesterRecordQuerySortThenBy
    on QueryBuilder<SemesterRecord, SemesterRecord, QSortThenBy> {
  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySchoolYearStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolYearStart', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySchoolYearStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolYearStart', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySectionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sectionCount', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySectionCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sectionCount', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySectionTimesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sectionTimesJson', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySectionTimesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sectionTimesJson', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy> thenBySemester() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semester', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySemesterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semester', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySemesterStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterStart', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenBySemesterStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterStart', Sort.desc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenByTotalWeeks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWeeks', Sort.asc);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QAfterSortBy>
  thenByTotalWeeksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWeeks', Sort.desc);
    });
  }
}

extension SemesterRecordQueryWhereDistinct
    on QueryBuilder<SemesterRecord, SemesterRecord, QDistinct> {
  QueryBuilder<SemesterRecord, SemesterRecord, QDistinct>
  distinctByDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QDistinct> distinctById({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QDistinct>
  distinctBySchoolYearStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schoolYearStart');
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QDistinct>
  distinctBySectionCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sectionCount');
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QDistinct>
  distinctBySectionTimesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sectionTimesJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QDistinct> distinctBySemester() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'semester');
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QDistinct>
  distinctBySemesterStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'semesterStart');
    });
  }

  QueryBuilder<SemesterRecord, SemesterRecord, QDistinct>
  distinctByTotalWeeks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalWeeks');
    });
  }
}

extension SemesterRecordQueryProperty
    on QueryBuilder<SemesterRecord, SemesterRecord, QQueryProperty> {
  QueryBuilder<SemesterRecord, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<SemesterRecord, String, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<SemesterRecord, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SemesterRecord, int, QQueryOperations>
  schoolYearStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schoolYearStart');
    });
  }

  QueryBuilder<SemesterRecord, int, QQueryOperations> sectionCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sectionCount');
    });
  }

  QueryBuilder<SemesterRecord, String, QQueryOperations>
  sectionTimesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sectionTimesJson');
    });
  }

  QueryBuilder<SemesterRecord, int, QQueryOperations> semesterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'semester');
    });
  }

  QueryBuilder<SemesterRecord, DateTime, QQueryOperations>
  semesterStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'semesterStart');
    });
  }

  QueryBuilder<SemesterRecord, int, QQueryOperations> totalWeeksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalWeeks');
    });
  }
}
