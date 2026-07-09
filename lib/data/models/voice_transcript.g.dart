// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_transcript.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVoiceTranscriptCollection on Isar {
  IsarCollection<VoiceTranscript> get voiceTranscripts => this.collection();
}

const VoiceTranscriptSchema = CollectionSchema(
  name: r'VoiceTranscript',
  id: -6315851634179649625,
  properties: {
    r'confidenceScore': PropertySchema(
      id: 0,
      name: r'confidenceScore',
      type: IsarType.double,
    ),
    r'convertedToTransaction': PropertySchema(
      id: 1,
      name: r'convertedToTransaction',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'parsedAmount': PropertySchema(
      id: 3,
      name: r'parsedAmount',
      type: IsarType.double,
    ),
    r'parsedCategoryUuid': PropertySchema(
      id: 4,
      name: r'parsedCategoryUuid',
      type: IsarType.string,
    ),
    r'parsedType': PropertySchema(
      id: 5,
      name: r'parsedType',
      type: IsarType.string,
    ),
    r'rawText': PropertySchema(id: 6, name: r'rawText', type: IsarType.string),
    r'transactionUuid': PropertySchema(
      id: 7,
      name: r'transactionUuid',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(id: 8, name: r'uuid', type: IsarType.string),
  },
  estimateSize: _voiceTranscriptEstimateSize,
  serialize: _voiceTranscriptSerialize,
  deserialize: _voiceTranscriptDeserialize,
  deserializeProp: _voiceTranscriptDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _voiceTranscriptGetId,
  getLinks: _voiceTranscriptGetLinks,
  attach: _voiceTranscriptAttach,
  version: '3.1.0+1',
);

int _voiceTranscriptEstimateSize(
  VoiceTranscript object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.parsedCategoryUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.parsedType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.rawText.length * 3;
  {
    final value = object.transactionUuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _voiceTranscriptSerialize(
  VoiceTranscript object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.confidenceScore);
  writer.writeBool(offsets[1], object.convertedToTransaction);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDouble(offsets[3], object.parsedAmount);
  writer.writeString(offsets[4], object.parsedCategoryUuid);
  writer.writeString(offsets[5], object.parsedType);
  writer.writeString(offsets[6], object.rawText);
  writer.writeString(offsets[7], object.transactionUuid);
  writer.writeString(offsets[8], object.uuid);
}

VoiceTranscript _voiceTranscriptDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VoiceTranscript(
    confidenceScore: reader.readDouble(offsets[0]),
    convertedToTransaction: reader.readBoolOrNull(offsets[1]) ?? false,
    createdAt: reader.readDateTime(offsets[2]),
    id: id,
    parsedAmount: reader.readDoubleOrNull(offsets[3]),
    parsedCategoryUuid: reader.readStringOrNull(offsets[4]),
    parsedType: reader.readStringOrNull(offsets[5]),
    rawText: reader.readString(offsets[6]),
    transactionUuid: reader.readStringOrNull(offsets[7]),
    uuid: reader.readString(offsets[8]),
  );
  return object;
}

P _voiceTranscriptDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _voiceTranscriptGetId(VoiceTranscript object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _voiceTranscriptGetLinks(VoiceTranscript object) {
  return [];
}

void _voiceTranscriptAttach(
  IsarCollection<dynamic> col,
  Id id,
  VoiceTranscript object,
) {
  object.id = id;
}

extension VoiceTranscriptByIndex on IsarCollection<VoiceTranscript> {
  Future<VoiceTranscript?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  VoiceTranscript? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<VoiceTranscript?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<VoiceTranscript?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(VoiceTranscript object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(VoiceTranscript object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<VoiceTranscript> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<VoiceTranscript> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension VoiceTranscriptQueryWhereSort
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QWhere> {
  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension VoiceTranscriptQueryWhere
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QWhereClause> {
  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause>
  uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause>
  createdAtEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause>
  createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause>
  createdAtGreaterThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause>
  createdAtLessThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterWhereClause>
  createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension VoiceTranscriptQueryFilter
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QFilterCondition> {
  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  confidenceScoreEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'confidenceScore',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  confidenceScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'confidenceScore',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  confidenceScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'confidenceScore',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  confidenceScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'confidenceScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  convertedToTransactionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'convertedToTransaction',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'parsedAmount'),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'parsedAmount'),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedAmountEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'parsedAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'parsedAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'parsedAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'parsedAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'parsedCategoryUuid'),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'parsedCategoryUuid'),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'parsedCategoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'parsedCategoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'parsedCategoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'parsedCategoryUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'parsedCategoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'parsedCategoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'parsedCategoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'parsedCategoryUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'parsedCategoryUuid', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedCategoryUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'parsedCategoryUuid', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'parsedType'),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'parsedType'),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'parsedType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'parsedType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'parsedType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'parsedType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'parsedType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'parsedType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'parsedType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'parsedType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'parsedType', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  parsedTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'parsedType', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawText', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  rawTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawText', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'transactionUuid'),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'transactionUuid'),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'transactionUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'transactionUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'transactionUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'transactionUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'transactionUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'transactionUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'transactionUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'transactionUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'transactionUuid', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  transactionUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'transactionUuid', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension VoiceTranscriptQueryObject
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QFilterCondition> {}

extension VoiceTranscriptQueryLinks
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QFilterCondition> {}

extension VoiceTranscriptQuerySortBy
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QSortBy> {
  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByConfidenceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidenceScore', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByConfidenceScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidenceScore', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByConvertedToTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedToTransaction', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByConvertedToTransactionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedToTransaction', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByParsedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedAmount', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByParsedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedAmount', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByParsedCategoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedCategoryUuid', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByParsedCategoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedCategoryUuid', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByParsedType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedType', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByParsedTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedType', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy> sortByRawText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByRawTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByTransactionUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionUuid', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByTransactionUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionUuid', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension VoiceTranscriptQuerySortThenBy
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QSortThenBy> {
  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByConfidenceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidenceScore', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByConfidenceScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confidenceScore', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByConvertedToTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedToTransaction', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByConvertedToTransactionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'convertedToTransaction', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByParsedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedAmount', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByParsedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedAmount', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByParsedCategoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedCategoryUuid', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByParsedCategoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedCategoryUuid', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByParsedType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedType', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByParsedTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parsedType', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy> thenByRawText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByRawTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawText', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByTransactionUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionUuid', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByTransactionUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionUuid', Sort.desc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QAfterSortBy>
  thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension VoiceTranscriptQueryWhereDistinct
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct> {
  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct>
  distinctByConfidenceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confidenceScore');
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct>
  distinctByConvertedToTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'convertedToTransaction');
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct>
  distinctByParsedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parsedAmount');
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct>
  distinctByParsedCategoryUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'parsedCategoryUuid',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct>
  distinctByParsedType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parsedType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct> distinctByRawText({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct>
  distinctByTransactionUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'transactionUuid',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<VoiceTranscript, VoiceTranscript, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension VoiceTranscriptQueryProperty
    on QueryBuilder<VoiceTranscript, VoiceTranscript, QQueryProperty> {
  QueryBuilder<VoiceTranscript, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VoiceTranscript, double, QQueryOperations>
  confidenceScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confidenceScore');
    });
  }

  QueryBuilder<VoiceTranscript, bool, QQueryOperations>
  convertedToTransactionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'convertedToTransaction');
    });
  }

  QueryBuilder<VoiceTranscript, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<VoiceTranscript, double?, QQueryOperations>
  parsedAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parsedAmount');
    });
  }

  QueryBuilder<VoiceTranscript, String?, QQueryOperations>
  parsedCategoryUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parsedCategoryUuid');
    });
  }

  QueryBuilder<VoiceTranscript, String?, QQueryOperations>
  parsedTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parsedType');
    });
  }

  QueryBuilder<VoiceTranscript, String, QQueryOperations> rawTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawText');
    });
  }

  QueryBuilder<VoiceTranscript, String?, QQueryOperations>
  transactionUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionUuid');
    });
  }

  QueryBuilder<VoiceTranscript, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
