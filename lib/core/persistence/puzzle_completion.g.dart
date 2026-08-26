// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puzzle_completion.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPuzzleCompletionCollection on Isar {
  IsarCollection<PuzzleCompletion> get puzzleCompletions => this.collection();
}

const PuzzleCompletionSchema = CollectionSchema(
  name: r'PuzzleCompletion',
  id: -4204954440997460862,
  properties: {
    r'completedAt': PropertySchema(
      id: 0,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'dayIndex': PropertySchema(id: 1, name: r'dayIndex', type: IsarType.long),
    r'elapsedSeconds': PropertySchema(
      id: 2,
      name: r'elapsedSeconds',
      type: IsarType.long,
    ),
    r'gameId': PropertySchema(id: 3, name: r'gameId', type: IsarType.string),
    r'guessesUsed': PropertySchema(
      id: 4,
      name: r'guessesUsed',
      type: IsarType.long,
    ),
    r'won': PropertySchema(id: 5, name: r'won', type: IsarType.bool),
  },

  estimateSize: _puzzleCompletionEstimateSize,
  serialize: _puzzleCompletionSerialize,
  deserialize: _puzzleCompletionDeserialize,
  deserializeProp: _puzzleCompletionDeserializeProp,
  idName: r'id',
  indexes: {
    r'gameId_dayIndex': IndexSchema(
      id: 5193425264881869479,
      name: r'gameId_dayIndex',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'gameId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'dayIndex',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _puzzleCompletionGetId,
  getLinks: _puzzleCompletionGetLinks,
  attach: _puzzleCompletionAttach,
  version: '3.3.2',
);

int _puzzleCompletionEstimateSize(
  PuzzleCompletion object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.gameId.length * 3;
  return bytesCount;
}

void _puzzleCompletionSerialize(
  PuzzleCompletion object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.completedAt);
  writer.writeLong(offsets[1], object.dayIndex);
  writer.writeLong(offsets[2], object.elapsedSeconds);
  writer.writeString(offsets[3], object.gameId);
  writer.writeLong(offsets[4], object.guessesUsed);
  writer.writeBool(offsets[5], object.won);
}

PuzzleCompletion _puzzleCompletionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PuzzleCompletion();
  object.completedAt = reader.readDateTime(offsets[0]);
  object.dayIndex = reader.readLong(offsets[1]);
  object.elapsedSeconds = reader.readLongOrNull(offsets[2]);
  object.gameId = reader.readString(offsets[3]);
  object.guessesUsed = reader.readLongOrNull(offsets[4]);
  object.id = id;
  object.won = reader.readBool(offsets[5]);
  return object;
}

P _puzzleCompletionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _puzzleCompletionGetId(PuzzleCompletion object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _puzzleCompletionGetLinks(PuzzleCompletion object) {
  return [];
}

void _puzzleCompletionAttach(
  IsarCollection<dynamic> col,
  Id id,
  PuzzleCompletion object,
) {
  object.id = id;
}

extension PuzzleCompletionByIndex on IsarCollection<PuzzleCompletion> {
  Future<PuzzleCompletion?> getByGameIdDayIndex(String gameId, int dayIndex) {
    return getByIndex(r'gameId_dayIndex', [gameId, dayIndex]);
  }

  PuzzleCompletion? getByGameIdDayIndexSync(String gameId, int dayIndex) {
    return getByIndexSync(r'gameId_dayIndex', [gameId, dayIndex]);
  }

  Future<bool> deleteByGameIdDayIndex(String gameId, int dayIndex) {
    return deleteByIndex(r'gameId_dayIndex', [gameId, dayIndex]);
  }

  bool deleteByGameIdDayIndexSync(String gameId, int dayIndex) {
    return deleteByIndexSync(r'gameId_dayIndex', [gameId, dayIndex]);
  }

  Future<List<PuzzleCompletion?>> getAllByGameIdDayIndex(
    List<String> gameIdValues,
    List<int> dayIndexValues,
  ) {
    final len = gameIdValues.length;
    assert(
      dayIndexValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([gameIdValues[i], dayIndexValues[i]]);
    }

    return getAllByIndex(r'gameId_dayIndex', values);
  }

  List<PuzzleCompletion?> getAllByGameIdDayIndexSync(
    List<String> gameIdValues,
    List<int> dayIndexValues,
  ) {
    final len = gameIdValues.length;
    assert(
      dayIndexValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([gameIdValues[i], dayIndexValues[i]]);
    }

    return getAllByIndexSync(r'gameId_dayIndex', values);
  }

  Future<int> deleteAllByGameIdDayIndex(
    List<String> gameIdValues,
    List<int> dayIndexValues,
  ) {
    final len = gameIdValues.length;
    assert(
      dayIndexValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([gameIdValues[i], dayIndexValues[i]]);
    }

    return deleteAllByIndex(r'gameId_dayIndex', values);
  }

  int deleteAllByGameIdDayIndexSync(
    List<String> gameIdValues,
    List<int> dayIndexValues,
  ) {
    final len = gameIdValues.length;
    assert(
      dayIndexValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([gameIdValues[i], dayIndexValues[i]]);
    }

    return deleteAllByIndexSync(r'gameId_dayIndex', values);
  }

  Future<Id> putByGameIdDayIndex(PuzzleCompletion object) {
    return putByIndex(r'gameId_dayIndex', object);
  }

  Id putByGameIdDayIndexSync(PuzzleCompletion object, {bool saveLinks = true}) {
    return putByIndexSync(r'gameId_dayIndex', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByGameIdDayIndex(List<PuzzleCompletion> objects) {
    return putAllByIndex(r'gameId_dayIndex', objects);
  }

  List<Id> putAllByGameIdDayIndexSync(
    List<PuzzleCompletion> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'gameId_dayIndex', objects, saveLinks: saveLinks);
  }
}

extension PuzzleCompletionQueryWhereSort
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QWhere> {
  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PuzzleCompletionQueryWhere
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QWhereClause> {
  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
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

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause> idBetween(
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

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  gameIdEqualToAnyDayIndex(String gameId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'gameId_dayIndex',
          value: [gameId],
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  gameIdNotEqualToAnyDayIndex(String gameId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'gameId_dayIndex',
                lower: [],
                upper: [gameId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'gameId_dayIndex',
                lower: [gameId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'gameId_dayIndex',
                lower: [gameId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'gameId_dayIndex',
                lower: [],
                upper: [gameId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  gameIdDayIndexEqualTo(String gameId, int dayIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'gameId_dayIndex',
          value: [gameId, dayIndex],
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  gameIdEqualToDayIndexNotEqualTo(String gameId, int dayIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'gameId_dayIndex',
                lower: [gameId],
                upper: [gameId, dayIndex],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'gameId_dayIndex',
                lower: [gameId, dayIndex],
                includeLower: false,
                upper: [gameId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'gameId_dayIndex',
                lower: [gameId, dayIndex],
                includeLower: false,
                upper: [gameId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'gameId_dayIndex',
                lower: [gameId],
                upper: [gameId, dayIndex],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  gameIdEqualToDayIndexGreaterThan(
    String gameId,
    int dayIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'gameId_dayIndex',
          lower: [gameId, dayIndex],
          includeLower: include,
          upper: [gameId],
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  gameIdEqualToDayIndexLessThan(
    String gameId,
    int dayIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'gameId_dayIndex',
          lower: [gameId],
          upper: [gameId, dayIndex],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterWhereClause>
  gameIdEqualToDayIndexBetween(
    String gameId,
    int lowerDayIndex,
    int upperDayIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'gameId_dayIndex',
          lower: [gameId, lowerDayIndex],
          includeLower: includeLower,
          upper: [gameId, upperDayIndex],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PuzzleCompletionQueryFilter
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QFilterCondition> {
  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  completedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completedAt', value: value),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  completedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'completedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  completedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'completedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  completedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'completedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  dayIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dayIndex', value: value),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  dayIndexGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dayIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  dayIndexLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dayIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  dayIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dayIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  elapsedSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'elapsedSeconds'),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  elapsedSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'elapsedSeconds'),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  elapsedSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'elapsedSeconds', value: value),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  elapsedSecondsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'elapsedSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  elapsedSecondsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'elapsedSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  elapsedSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'elapsedSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'gameId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gameId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gameId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gameId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'gameId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'gameId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'gameId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'gameId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'gameId', value: ''),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  gameIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'gameId', value: ''),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  guessesUsedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'guessesUsed'),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  guessesUsedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'guessesUsed'),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  guessesUsedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'guessesUsed', value: value),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  guessesUsedGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'guessesUsed',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  guessesUsedLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'guessesUsed',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  guessesUsedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'guessesUsed',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
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

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
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

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
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

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterFilterCondition>
  wonEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'won', value: value),
      );
    });
  }
}

extension PuzzleCompletionQueryObject
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QFilterCondition> {}

extension PuzzleCompletionQueryLinks
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QFilterCondition> {}

extension PuzzleCompletionQuerySortBy
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QSortBy> {
  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByDayIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByElapsedSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elapsedSeconds', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByElapsedSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elapsedSeconds', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByGameId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameId', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByGameIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameId', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByGuessesUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guessesUsed', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByGuessesUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guessesUsed', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy> sortByWon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'won', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  sortByWonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'won', Sort.desc);
    });
  }
}

extension PuzzleCompletionQuerySortThenBy
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QSortThenBy> {
  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByDayIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByElapsedSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elapsedSeconds', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByElapsedSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elapsedSeconds', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByGameId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameId', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByGameIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameId', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByGuessesUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guessesUsed', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByGuessesUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guessesUsed', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy> thenByWon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'won', Sort.asc);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QAfterSortBy>
  thenByWonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'won', Sort.desc);
    });
  }
}

extension PuzzleCompletionQueryWhereDistinct
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QDistinct> {
  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QDistinct>
  distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QDistinct>
  distinctByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayIndex');
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QDistinct>
  distinctByElapsedSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'elapsedSeconds');
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QDistinct> distinctByGameId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gameId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QDistinct>
  distinctByGuessesUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guessesUsed');
    });
  }

  QueryBuilder<PuzzleCompletion, PuzzleCompletion, QDistinct> distinctByWon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'won');
    });
  }
}

extension PuzzleCompletionQueryProperty
    on QueryBuilder<PuzzleCompletion, PuzzleCompletion, QQueryProperty> {
  QueryBuilder<PuzzleCompletion, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PuzzleCompletion, DateTime, QQueryOperations>
  completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<PuzzleCompletion, int, QQueryOperations> dayIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayIndex');
    });
  }

  QueryBuilder<PuzzleCompletion, int?, QQueryOperations>
  elapsedSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'elapsedSeconds');
    });
  }

  QueryBuilder<PuzzleCompletion, String, QQueryOperations> gameIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gameId');
    });
  }

  QueryBuilder<PuzzleCompletion, int?, QQueryOperations> guessesUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guessesUsed');
    });
  }

  QueryBuilder<PuzzleCompletion, bool, QQueryOperations> wonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'won');
    });
  }
}
