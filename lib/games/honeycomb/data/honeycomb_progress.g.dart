// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'honeycomb_progress.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHoneycombProgressCollection on Isar {
  IsarCollection<HoneycombProgress> get honeycombProgress => this.collection();
}

const HoneycombProgressSchema = CollectionSchema(
  name: r'HoneycombProgress',
  id: -5191185629168265728,
  properties: {
    r'dayIndex': PropertySchema(id: 0, name: r'dayIndex', type: IsarType.long),
    r'foundWords': PropertySchema(
      id: 1,
      name: r'foundWords',
      type: IsarType.stringList,
    ),
    r'updatedAt': PropertySchema(
      id: 2,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _honeycombProgressEstimateSize,
  serialize: _honeycombProgressSerialize,
  deserialize: _honeycombProgressDeserialize,
  deserializeProp: _honeycombProgressDeserializeProp,
  idName: r'id',
  indexes: {
    r'dayIndex': IndexSchema(
      id: 8120396275912827524,
      name: r'dayIndex',
      unique: true,
      replace: true,
      properties: [
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

  getId: _honeycombProgressGetId,
  getLinks: _honeycombProgressGetLinks,
  attach: _honeycombProgressAttach,
  version: '3.3.2',
);

int _honeycombProgressEstimateSize(
  HoneycombProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.foundWords.length * 3;
  {
    for (var i = 0; i < object.foundWords.length; i++) {
      final value = object.foundWords[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _honeycombProgressSerialize(
  HoneycombProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.dayIndex);
  writer.writeStringList(offsets[1], object.foundWords);
  writer.writeDateTime(offsets[2], object.updatedAt);
}

HoneycombProgress _honeycombProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HoneycombProgress();
  object.dayIndex = reader.readLong(offsets[0]);
  object.foundWords = reader.readStringList(offsets[1]) ?? [];
  object.id = id;
  object.updatedAt = reader.readDateTime(offsets[2]);
  return object;
}

P _honeycombProgressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _honeycombProgressGetId(HoneycombProgress object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _honeycombProgressGetLinks(
  HoneycombProgress object,
) {
  return [];
}

void _honeycombProgressAttach(
  IsarCollection<dynamic> col,
  Id id,
  HoneycombProgress object,
) {
  object.id = id;
}

extension HoneycombProgressByIndex on IsarCollection<HoneycombProgress> {
  Future<HoneycombProgress?> getByDayIndex(int dayIndex) {
    return getByIndex(r'dayIndex', [dayIndex]);
  }

  HoneycombProgress? getByDayIndexSync(int dayIndex) {
    return getByIndexSync(r'dayIndex', [dayIndex]);
  }

  Future<bool> deleteByDayIndex(int dayIndex) {
    return deleteByIndex(r'dayIndex', [dayIndex]);
  }

  bool deleteByDayIndexSync(int dayIndex) {
    return deleteByIndexSync(r'dayIndex', [dayIndex]);
  }

  Future<List<HoneycombProgress?>> getAllByDayIndex(List<int> dayIndexValues) {
    final values = dayIndexValues.map((e) => [e]).toList();
    return getAllByIndex(r'dayIndex', values);
  }

  List<HoneycombProgress?> getAllByDayIndexSync(List<int> dayIndexValues) {
    final values = dayIndexValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dayIndex', values);
  }

  Future<int> deleteAllByDayIndex(List<int> dayIndexValues) {
    final values = dayIndexValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dayIndex', values);
  }

  int deleteAllByDayIndexSync(List<int> dayIndexValues) {
    final values = dayIndexValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dayIndex', values);
  }

  Future<Id> putByDayIndex(HoneycombProgress object) {
    return putByIndex(r'dayIndex', object);
  }

  Id putByDayIndexSync(HoneycombProgress object, {bool saveLinks = true}) {
    return putByIndexSync(r'dayIndex', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDayIndex(List<HoneycombProgress> objects) {
    return putAllByIndex(r'dayIndex', objects);
  }

  List<Id> putAllByDayIndexSync(
    List<HoneycombProgress> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'dayIndex', objects, saveLinks: saveLinks);
  }
}

extension HoneycombProgressQueryWhereSort
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QWhere> {
  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhere>
  anyDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dayIndex'),
      );
    });
  }
}

extension HoneycombProgressQueryWhere
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QWhereClause> {
  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
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

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  idBetween(
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

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  dayIndexEqualTo(int dayIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dayIndex', value: [dayIndex]),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  dayIndexNotEqualTo(int dayIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dayIndex',
                lower: [],
                upper: [dayIndex],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dayIndex',
                lower: [dayIndex],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dayIndex',
                lower: [dayIndex],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dayIndex',
                lower: [],
                upper: [dayIndex],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  dayIndexGreaterThan(int dayIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dayIndex',
          lower: [dayIndex],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  dayIndexLessThan(int dayIndex, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dayIndex',
          lower: [],
          upper: [dayIndex],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterWhereClause>
  dayIndexBetween(
    int lowerDayIndex,
    int upperDayIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dayIndex',
          lower: [lowerDayIndex],
          includeLower: includeLower,
          upper: [upperDayIndex],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension HoneycombProgressQueryFilter
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QFilterCondition> {
  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  dayIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dayIndex', value: value),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
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

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
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

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
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

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'foundWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'foundWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'foundWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'foundWords',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'foundWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'foundWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'foundWords',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'foundWords',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'foundWords', value: ''),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'foundWords', value: ''),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'foundWords', length, true, length, true);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'foundWords', 0, true, 0, true);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'foundWords', 0, false, 999999, true);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'foundWords', 0, true, length, include);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'foundWords', length, include, 999999, true);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  foundWordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'foundWords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
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

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
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

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
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

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension HoneycombProgressQueryObject
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QFilterCondition> {}

extension HoneycombProgressQueryLinks
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QFilterCondition> {}

extension HoneycombProgressQuerySortBy
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QSortBy> {
  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  sortByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.asc);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  sortByDayIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.desc);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension HoneycombProgressQuerySortThenBy
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QSortThenBy> {
  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  thenByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.asc);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  thenByDayIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayIndex', Sort.desc);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension HoneycombProgressQueryWhereDistinct
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QDistinct> {
  QueryBuilder<HoneycombProgress, HoneycombProgress, QDistinct>
  distinctByDayIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayIndex');
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QDistinct>
  distinctByFoundWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'foundWords');
    });
  }

  QueryBuilder<HoneycombProgress, HoneycombProgress, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension HoneycombProgressQueryProperty
    on QueryBuilder<HoneycombProgress, HoneycombProgress, QQueryProperty> {
  QueryBuilder<HoneycombProgress, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HoneycombProgress, int, QQueryOperations> dayIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayIndex');
    });
  }

  QueryBuilder<HoneycombProgress, List<String>, QQueryOperations>
  foundWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'foundWords');
    });
  }

  QueryBuilder<HoneycombProgress, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
