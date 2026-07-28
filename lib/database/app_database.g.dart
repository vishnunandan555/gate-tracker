// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyllabusCategoriesTable extends SyllabusCategories
    with TableInfo<$SyllabusCategoriesTable, SyllabusCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyllabusCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastInteractedAtMeta = const VerificationMeta(
    'lastInteractedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastInteractedAt =
      GeneratedColumn<DateTime>(
        'last_interacted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    position,
    color,
    lastInteractedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syllabus_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyllabusCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('last_interacted_at')) {
      context.handle(
        _lastInteractedAtMeta,
        lastInteractedAt.isAcceptableOrUnknown(
          data['last_interacted_at']!,
          _lastInteractedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyllabusCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyllabusCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      lastInteractedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_interacted_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $SyllabusCategoriesTable createAlias(String alias) {
    return $SyllabusCategoriesTable(attachedDatabase, alias);
  }
}

class SyllabusCategory extends DataClass
    implements Insertable<SyllabusCategory> {
  final int id;
  final String name;
  final int position;
  final int color;
  final DateTime? lastInteractedAt;
  final bool isDeleted;
  const SyllabusCategory({
    required this.id,
    required this.name,
    required this.position,
    required this.color,
    this.lastInteractedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || lastInteractedAt != null) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  SyllabusCategoriesCompanion toCompanion(bool nullToAbsent) {
    return SyllabusCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      color: Value(color),
      lastInteractedAt: lastInteractedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastInteractedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory SyllabusCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyllabusCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      color: serializer.fromJson<int>(json['color']),
      lastInteractedAt: serializer.fromJson<DateTime?>(
        json['lastInteractedAt'],
      ),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'color': serializer.toJson<int>(color),
      'lastInteractedAt': serializer.toJson<DateTime?>(lastInteractedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  SyllabusCategory copyWith({
    int? id,
    String? name,
    int? position,
    int? color,
    Value<DateTime?> lastInteractedAt = const Value.absent(),
    bool? isDeleted,
  }) => SyllabusCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    color: color ?? this.color,
    lastInteractedAt: lastInteractedAt.present
        ? lastInteractedAt.value
        : this.lastInteractedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  SyllabusCategory copyWithCompanion(SyllabusCategoriesCompanion data) {
    return SyllabusCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      color: data.color.present ? data.color.value : this.color,
      lastInteractedAt: data.lastInteractedAt.present
          ? data.lastInteractedAt.value
          : this.lastInteractedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('lastInteractedAt: $lastInteractedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, position, color, lastInteractedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyllabusCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.color == this.color &&
          other.lastInteractedAt == this.lastInteractedAt &&
          other.isDeleted == this.isDeleted);
}

class SyllabusCategoriesCompanion extends UpdateCompanion<SyllabusCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> position;
  final Value<int> color;
  final Value<DateTime?> lastInteractedAt;
  final Value<bool> isDeleted;
  const SyllabusCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.color = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  SyllabusCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int position,
    required int color,
    this.lastInteractedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  }) : name = Value(name),
       position = Value(position),
       color = Value(color);
  static Insertable<SyllabusCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<int>? color,
    Expression<DateTime>? lastInteractedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (color != null) 'color': color,
      if (lastInteractedAt != null) 'last_interacted_at': lastInteractedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  SyllabusCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? position,
    Value<int>? color,
    Value<DateTime?>? lastInteractedAt,
    Value<bool>? isDeleted,
  }) {
    return SyllabusCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      color: color ?? this.color,
      lastInteractedAt: lastInteractedAt ?? this.lastInteractedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (lastInteractedAt.present) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('lastInteractedAt: $lastInteractedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $SyllabusTopicsTable extends SyllabusTopics
    with TableInfo<$SyllabusTopicsTable, SyllabusTopic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyllabusTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES syllabus_categories (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCounterMeta = const VerificationMeta(
    'isCounter',
  );
  @override
  late final GeneratedColumn<bool> isCounter = GeneratedColumn<bool>(
    'is_counter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_counter" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currentCountMeta = const VerificationMeta(
    'currentCount',
  );
  @override
  late final GeneratedColumn<int> currentCount = GeneratedColumn<int>(
    'current_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxCountMeta = const VerificationMeta(
    'maxCount',
  );
  @override
  late final GeneratedColumn<int> maxCount = GeneratedColumn<int>(
    'max_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _resourceUrlMeta = const VerificationMeta(
    'resourceUrl',
  );
  @override
  late final GeneratedColumn<String> resourceUrl = GeneratedColumn<String>(
    'resource_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastInteractedAtMeta = const VerificationMeta(
    'lastInteractedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastInteractedAt =
      GeneratedColumn<DateTime>(
        'last_interacted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    name,
    position,
    isCounter,
    currentCount,
    maxCount,
    resourceUrl,
    isDeleted,
    lastInteractedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syllabus_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyllabusTopic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('is_counter')) {
      context.handle(
        _isCounterMeta,
        isCounter.isAcceptableOrUnknown(data['is_counter']!, _isCounterMeta),
      );
    }
    if (data.containsKey('current_count')) {
      context.handle(
        _currentCountMeta,
        currentCount.isAcceptableOrUnknown(
          data['current_count']!,
          _currentCountMeta,
        ),
      );
    }
    if (data.containsKey('max_count')) {
      context.handle(
        _maxCountMeta,
        maxCount.isAcceptableOrUnknown(data['max_count']!, _maxCountMeta),
      );
    }
    if (data.containsKey('resource_url')) {
      context.handle(
        _resourceUrlMeta,
        resourceUrl.isAcceptableOrUnknown(
          data['resource_url']!,
          _resourceUrlMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('last_interacted_at')) {
      context.handle(
        _lastInteractedAtMeta,
        lastInteractedAt.isAcceptableOrUnknown(
          data['last_interacted_at']!,
          _lastInteractedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyllabusTopic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyllabusTopic(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      isCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_counter'],
      )!,
      currentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_count'],
      )!,
      maxCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_count'],
      )!,
      resourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_url'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastInteractedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_interacted_at'],
      ),
    );
  }

  @override
  $SyllabusTopicsTable createAlias(String alias) {
    return $SyllabusTopicsTable(attachedDatabase, alias);
  }
}

class SyllabusTopic extends DataClass implements Insertable<SyllabusTopic> {
  final int id;
  final int categoryId;
  final String name;
  final int position;
  final bool isCounter;
  final int currentCount;
  final int maxCount;
  final String? resourceUrl;
  final bool isDeleted;
  final DateTime? lastInteractedAt;
  const SyllabusTopic({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.position,
    required this.isCounter,
    required this.currentCount,
    required this.maxCount,
    this.resourceUrl,
    required this.isDeleted,
    this.lastInteractedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['is_counter'] = Variable<bool>(isCounter);
    map['current_count'] = Variable<int>(currentCount);
    map['max_count'] = Variable<int>(maxCount);
    if (!nullToAbsent || resourceUrl != null) {
      map['resource_url'] = Variable<String>(resourceUrl);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || lastInteractedAt != null) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt);
    }
    return map;
  }

  SyllabusTopicsCompanion toCompanion(bool nullToAbsent) {
    return SyllabusTopicsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      position: Value(position),
      isCounter: Value(isCounter),
      currentCount: Value(currentCount),
      maxCount: Value(maxCount),
      resourceUrl: resourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceUrl),
      isDeleted: Value(isDeleted),
      lastInteractedAt: lastInteractedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastInteractedAt),
    );
  }

  factory SyllabusTopic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyllabusTopic(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      isCounter: serializer.fromJson<bool>(json['isCounter']),
      currentCount: serializer.fromJson<int>(json['currentCount']),
      maxCount: serializer.fromJson<int>(json['maxCount']),
      resourceUrl: serializer.fromJson<String?>(json['resourceUrl']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastInteractedAt: serializer.fromJson<DateTime?>(
        json['lastInteractedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'isCounter': serializer.toJson<bool>(isCounter),
      'currentCount': serializer.toJson<int>(currentCount),
      'maxCount': serializer.toJson<int>(maxCount),
      'resourceUrl': serializer.toJson<String?>(resourceUrl),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastInteractedAt': serializer.toJson<DateTime?>(lastInteractedAt),
    };
  }

  SyllabusTopic copyWith({
    int? id,
    int? categoryId,
    String? name,
    int? position,
    bool? isCounter,
    int? currentCount,
    int? maxCount,
    Value<String?> resourceUrl = const Value.absent(),
    bool? isDeleted,
    Value<DateTime?> lastInteractedAt = const Value.absent(),
  }) => SyllabusTopic(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    position: position ?? this.position,
    isCounter: isCounter ?? this.isCounter,
    currentCount: currentCount ?? this.currentCount,
    maxCount: maxCount ?? this.maxCount,
    resourceUrl: resourceUrl.present ? resourceUrl.value : this.resourceUrl,
    isDeleted: isDeleted ?? this.isDeleted,
    lastInteractedAt: lastInteractedAt.present
        ? lastInteractedAt.value
        : this.lastInteractedAt,
  );
  SyllabusTopic copyWithCompanion(SyllabusTopicsCompanion data) {
    return SyllabusTopic(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      isCounter: data.isCounter.present ? data.isCounter.value : this.isCounter,
      currentCount: data.currentCount.present
          ? data.currentCount.value
          : this.currentCount,
      maxCount: data.maxCount.present ? data.maxCount.value : this.maxCount,
      resourceUrl: data.resourceUrl.present
          ? data.resourceUrl.value
          : this.resourceUrl,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastInteractedAt: data.lastInteractedAt.present
          ? data.lastInteractedAt.value
          : this.lastInteractedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusTopic(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('isCounter: $isCounter, ')
          ..write('currentCount: $currentCount, ')
          ..write('maxCount: $maxCount, ')
          ..write('resourceUrl: $resourceUrl, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    name,
    position,
    isCounter,
    currentCount,
    maxCount,
    resourceUrl,
    isDeleted,
    lastInteractedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyllabusTopic &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.position == this.position &&
          other.isCounter == this.isCounter &&
          other.currentCount == this.currentCount &&
          other.maxCount == this.maxCount &&
          other.resourceUrl == this.resourceUrl &&
          other.isDeleted == this.isDeleted &&
          other.lastInteractedAt == this.lastInteractedAt);
}

class SyllabusTopicsCompanion extends UpdateCompanion<SyllabusTopic> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<String> name;
  final Value<int> position;
  final Value<bool> isCounter;
  final Value<int> currentCount;
  final Value<int> maxCount;
  final Value<String?> resourceUrl;
  final Value<bool> isDeleted;
  final Value<DateTime?> lastInteractedAt;
  const SyllabusTopicsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.isCounter = const Value.absent(),
    this.currentCount = const Value.absent(),
    this.maxCount = const Value.absent(),
    this.resourceUrl = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  });
  SyllabusTopicsCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required String name,
    required int position,
    this.isCounter = const Value.absent(),
    this.currentCount = const Value.absent(),
    this.maxCount = const Value.absent(),
    this.resourceUrl = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  }) : categoryId = Value(categoryId),
       name = Value(name),
       position = Value(position);
  static Insertable<SyllabusTopic> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<int>? position,
    Expression<bool>? isCounter,
    Expression<int>? currentCount,
    Expression<int>? maxCount,
    Expression<String>? resourceUrl,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastInteractedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (isCounter != null) 'is_counter': isCounter,
      if (currentCount != null) 'current_count': currentCount,
      if (maxCount != null) 'max_count': maxCount,
      if (resourceUrl != null) 'resource_url': resourceUrl,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastInteractedAt != null) 'last_interacted_at': lastInteractedAt,
    });
  }

  SyllabusTopicsCompanion copyWith({
    Value<int>? id,
    Value<int>? categoryId,
    Value<String>? name,
    Value<int>? position,
    Value<bool>? isCounter,
    Value<int>? currentCount,
    Value<int>? maxCount,
    Value<String?>? resourceUrl,
    Value<bool>? isDeleted,
    Value<DateTime?>? lastInteractedAt,
  }) {
    return SyllabusTopicsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      position: position ?? this.position,
      isCounter: isCounter ?? this.isCounter,
      currentCount: currentCount ?? this.currentCount,
      maxCount: maxCount ?? this.maxCount,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      isDeleted: isDeleted ?? this.isDeleted,
      lastInteractedAt: lastInteractedAt ?? this.lastInteractedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isCounter.present) {
      map['is_counter'] = Variable<bool>(isCounter.value);
    }
    if (currentCount.present) {
      map['current_count'] = Variable<int>(currentCount.value);
    }
    if (maxCount.present) {
      map['max_count'] = Variable<int>(maxCount.value);
    }
    if (resourceUrl.present) {
      map['resource_url'] = Variable<String>(resourceUrl.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastInteractedAt.present) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusTopicsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('isCounter: $isCounter, ')
          ..write('currentCount: $currentCount, ')
          ..write('maxCount: $maxCount, ')
          ..write('resourceUrl: $resourceUrl, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }
}

class $SyllabusTasksTable extends SyllabusTasks
    with TableInfo<$SyllabusTasksTable, SyllabusTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyllabusTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES syllabus_topics (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastInteractedAtMeta = const VerificationMeta(
    'lastInteractedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastInteractedAt =
      GeneratedColumn<DateTime>(
        'last_interacted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    name,
    isCompleted,
    position,
    completedAt,
    isDeleted,
    lastInteractedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syllabus_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyllabusTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('last_interacted_at')) {
      context.handle(
        _lastInteractedAtMeta,
        lastInteractedAt.isAcceptableOrUnknown(
          data['last_interacted_at']!,
          _lastInteractedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyllabusTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyllabusTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastInteractedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_interacted_at'],
      ),
    );
  }

  @override
  $SyllabusTasksTable createAlias(String alias) {
    return $SyllabusTasksTable(attachedDatabase, alias);
  }
}

class SyllabusTask extends DataClass implements Insertable<SyllabusTask> {
  final int id;
  final int topicId;
  final String name;
  final bool isCompleted;
  final int position;
  final DateTime? completedAt;
  final bool isDeleted;
  final DateTime? lastInteractedAt;
  const SyllabusTask({
    required this.id,
    required this.topicId,
    required this.name,
    required this.isCompleted,
    required this.position,
    this.completedAt,
    required this.isDeleted,
    this.lastInteractedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic_id'] = Variable<int>(topicId);
    map['name'] = Variable<String>(name);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || lastInteractedAt != null) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt);
    }
    return map;
  }

  SyllabusTasksCompanion toCompanion(bool nullToAbsent) {
    return SyllabusTasksCompanion(
      id: Value(id),
      topicId: Value(topicId),
      name: Value(name),
      isCompleted: Value(isCompleted),
      position: Value(position),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      isDeleted: Value(isDeleted),
      lastInteractedAt: lastInteractedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastInteractedAt),
    );
  }

  factory SyllabusTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyllabusTask(
      id: serializer.fromJson<int>(json['id']),
      topicId: serializer.fromJson<int>(json['topicId']),
      name: serializer.fromJson<String>(json['name']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      position: serializer.fromJson<int>(json['position']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastInteractedAt: serializer.fromJson<DateTime?>(
        json['lastInteractedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topicId': serializer.toJson<int>(topicId),
      'name': serializer.toJson<String>(name),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'position': serializer.toJson<int>(position),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastInteractedAt': serializer.toJson<DateTime?>(lastInteractedAt),
    };
  }

  SyllabusTask copyWith({
    int? id,
    int? topicId,
    String? name,
    bool? isCompleted,
    int? position,
    Value<DateTime?> completedAt = const Value.absent(),
    bool? isDeleted,
    Value<DateTime?> lastInteractedAt = const Value.absent(),
  }) => SyllabusTask(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    name: name ?? this.name,
    isCompleted: isCompleted ?? this.isCompleted,
    position: position ?? this.position,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    lastInteractedAt: lastInteractedAt.present
        ? lastInteractedAt.value
        : this.lastInteractedAt,
  );
  SyllabusTask copyWithCompanion(SyllabusTasksCompanion data) {
    return SyllabusTask(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      name: data.name.present ? data.name.value : this.name,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      position: data.position.present ? data.position.value : this.position,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastInteractedAt: data.lastInteractedAt.present
          ? data.lastInteractedAt.value
          : this.lastInteractedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusTask(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('name: $name, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('position: $position, ')
          ..write('completedAt: $completedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topicId,
    name,
    isCompleted,
    position,
    completedAt,
    isDeleted,
    lastInteractedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyllabusTask &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.name == this.name &&
          other.isCompleted == this.isCompleted &&
          other.position == this.position &&
          other.completedAt == this.completedAt &&
          other.isDeleted == this.isDeleted &&
          other.lastInteractedAt == this.lastInteractedAt);
}

class SyllabusTasksCompanion extends UpdateCompanion<SyllabusTask> {
  final Value<int> id;
  final Value<int> topicId;
  final Value<String> name;
  final Value<bool> isCompleted;
  final Value<int> position;
  final Value<DateTime?> completedAt;
  final Value<bool> isDeleted;
  final Value<DateTime?> lastInteractedAt;
  const SyllabusTasksCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.name = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.position = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  });
  SyllabusTasksCompanion.insert({
    this.id = const Value.absent(),
    required int topicId,
    required String name,
    this.isCompleted = const Value.absent(),
    required int position,
    this.completedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  }) : topicId = Value(topicId),
       name = Value(name),
       position = Value(position);
  static Insertable<SyllabusTask> custom({
    Expression<int>? id,
    Expression<int>? topicId,
    Expression<String>? name,
    Expression<bool>? isCompleted,
    Expression<int>? position,
    Expression<DateTime>? completedAt,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastInteractedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (name != null) 'name': name,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (position != null) 'position': position,
      if (completedAt != null) 'completed_at': completedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastInteractedAt != null) 'last_interacted_at': lastInteractedAt,
    });
  }

  SyllabusTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? topicId,
    Value<String>? name,
    Value<bool>? isCompleted,
    Value<int>? position,
    Value<DateTime?>? completedAt,
    Value<bool>? isDeleted,
    Value<DateTime?>? lastInteractedAt,
  }) {
    return SyllabusTasksCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      completedAt: completedAt ?? this.completedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      lastInteractedAt: lastInteractedAt ?? this.lastInteractedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastInteractedAt.present) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusTasksCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('name: $name, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('position: $position, ')
          ..write('completedAt: $completedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accomplishmentsMeta = const VerificationMeta(
    'accomplishments',
  );
  @override
  late final GeneratedColumn<String> accomplishments = GeneratedColumn<String>(
    'accomplishments',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressDeltaMeta = const VerificationMeta(
    'progressDelta',
  );
  @override
  late final GeneratedColumn<double> progressDelta = GeneratedColumn<double>(
    'progress_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES syllabus_categories (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    method,
    startTime,
    durationSeconds,
    accomplishments,
    progressDelta,
    categoryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('accomplishments')) {
      context.handle(
        _accomplishmentsMeta,
        accomplishments.isAcceptableOrUnknown(
          data['accomplishments']!,
          _accomplishmentsMeta,
        ),
      );
    }
    if (data.containsKey('progress_delta')) {
      context.handle(
        _progressDeltaMeta,
        progressDelta.isAcceptableOrUnknown(
          data['progress_delta']!,
          _progressDeltaMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      accomplishments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accomplishments'],
      ),
      progressDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_delta'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }
}

class FocusSession extends DataClass implements Insertable<FocusSession> {
  final int id;
  final String method;
  final DateTime startTime;
  final int durationSeconds;
  final String? accomplishments;
  final double progressDelta;
  final int? categoryId;
  const FocusSession({
    required this.id,
    required this.method,
    required this.startTime,
    required this.durationSeconds,
    this.accomplishments,
    required this.progressDelta,
    this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['method'] = Variable<String>(method);
    map['start_time'] = Variable<DateTime>(startTime);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || accomplishments != null) {
      map['accomplishments'] = Variable<String>(accomplishments);
    }
    map['progress_delta'] = Variable<double>(progressDelta);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      method: Value(method),
      startTime: Value(startTime),
      durationSeconds: Value(durationSeconds),
      accomplishments: accomplishments == null && nullToAbsent
          ? const Value.absent()
          : Value(accomplishments),
      progressDelta: Value(progressDelta),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
    );
  }

  factory FocusSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSession(
      id: serializer.fromJson<int>(json['id']),
      method: serializer.fromJson<String>(json['method']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      accomplishments: serializer.fromJson<String?>(json['accomplishments']),
      progressDelta: serializer.fromJson<double>(json['progressDelta']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'method': serializer.toJson<String>(method),
      'startTime': serializer.toJson<DateTime>(startTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'accomplishments': serializer.toJson<String?>(accomplishments),
      'progressDelta': serializer.toJson<double>(progressDelta),
      'categoryId': serializer.toJson<int?>(categoryId),
    };
  }

  FocusSession copyWith({
    int? id,
    String? method,
    DateTime? startTime,
    int? durationSeconds,
    Value<String?> accomplishments = const Value.absent(),
    double? progressDelta,
    Value<int?> categoryId = const Value.absent(),
  }) => FocusSession(
    id: id ?? this.id,
    method: method ?? this.method,
    startTime: startTime ?? this.startTime,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    accomplishments: accomplishments.present
        ? accomplishments.value
        : this.accomplishments,
    progressDelta: progressDelta ?? this.progressDelta,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
  );
  FocusSession copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSession(
      id: data.id.present ? data.id.value : this.id,
      method: data.method.present ? data.method.value : this.method,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      accomplishments: data.accomplishments.present
          ? data.accomplishments.value
          : this.accomplishments,
      progressDelta: data.progressDelta.present
          ? data.progressDelta.value
          : this.progressDelta,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSession(')
          ..write('id: $id, ')
          ..write('method: $method, ')
          ..write('startTime: $startTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('accomplishments: $accomplishments, ')
          ..write('progressDelta: $progressDelta, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    method,
    startTime,
    durationSeconds,
    accomplishments,
    progressDelta,
    categoryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSession &&
          other.id == this.id &&
          other.method == this.method &&
          other.startTime == this.startTime &&
          other.durationSeconds == this.durationSeconds &&
          other.accomplishments == this.accomplishments &&
          other.progressDelta == this.progressDelta &&
          other.categoryId == this.categoryId);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSession> {
  final Value<int> id;
  final Value<String> method;
  final Value<DateTime> startTime;
  final Value<int> durationSeconds;
  final Value<String?> accomplishments;
  final Value<double> progressDelta;
  final Value<int?> categoryId;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.method = const Value.absent(),
    this.startTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.accomplishments = const Value.absent(),
    this.progressDelta = const Value.absent(),
    this.categoryId = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String method,
    required DateTime startTime,
    required int durationSeconds,
    this.accomplishments = const Value.absent(),
    this.progressDelta = const Value.absent(),
    this.categoryId = const Value.absent(),
  }) : method = Value(method),
       startTime = Value(startTime),
       durationSeconds = Value(durationSeconds);
  static Insertable<FocusSession> custom({
    Expression<int>? id,
    Expression<String>? method,
    Expression<DateTime>? startTime,
    Expression<int>? durationSeconds,
    Expression<String>? accomplishments,
    Expression<double>? progressDelta,
    Expression<int>? categoryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (method != null) 'method': method,
      if (startTime != null) 'start_time': startTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (accomplishments != null) 'accomplishments': accomplishments,
      if (progressDelta != null) 'progress_delta': progressDelta,
      if (categoryId != null) 'category_id': categoryId,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? method,
    Value<DateTime>? startTime,
    Value<int>? durationSeconds,
    Value<String?>? accomplishments,
    Value<double>? progressDelta,
    Value<int?>? categoryId,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      method: method ?? this.method,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      accomplishments: accomplishments ?? this.accomplishments,
      progressDelta: progressDelta ?? this.progressDelta,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (accomplishments.present) {
      map['accomplishments'] = Variable<String>(accomplishments.value);
    }
    if (progressDelta.present) {
      map['progress_delta'] = Variable<double>(progressDelta.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('method: $method, ')
          ..write('startTime: $startTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('accomplishments: $accomplishments, ')
          ..write('progressDelta: $progressDelta, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }
}

class $DailyHistoryTable extends DailyHistory
    with TableInfo<$DailyHistoryTable, DailyHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateStrMeta = const VerificationMeta(
    'dateStr',
  );
  @override
  late final GeneratedColumn<String> dateStr = GeneratedColumn<String>(
    'date_str',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalFocusSecondsMeta = const VerificationMeta(
    'totalFocusSeconds',
  );
  @override
  late final GeneratedColumn<int> totalFocusSeconds = GeneratedColumn<int>(
    'total_focus_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetGoalSecondsMeta = const VerificationMeta(
    'targetGoalSeconds',
  );
  @override
  late final GeneratedColumn<int> targetGoalSeconds = GeneratedColumn<int>(
    'target_goal_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7200),
  );
  static const VerificationMeta _isGoalCompletedMeta = const VerificationMeta(
    'isGoalCompleted',
  );
  @override
  late final GeneratedColumn<bool> isGoalCompleted = GeneratedColumn<bool>(
    'is_goal_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_goal_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syllabusProgressPctMeta =
      const VerificationMeta('syllabusProgressPct');
  @override
  late final GeneratedColumn<double> syllabusProgressPct =
      GeneratedColumn<double>(
        'syllabus_progress_pct',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _tasksCompletedTotalMeta =
      const VerificationMeta('tasksCompletedTotal');
  @override
  late final GeneratedColumn<int> tasksCompletedTotal = GeneratedColumn<int>(
    'tasks_completed_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    dateStr,
    totalFocusSeconds,
    targetGoalSeconds,
    isGoalCompleted,
    syllabusProgressPct,
    tasksCompletedTotal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_str')) {
      context.handle(
        _dateStrMeta,
        dateStr.isAcceptableOrUnknown(data['date_str']!, _dateStrMeta),
      );
    } else if (isInserting) {
      context.missing(_dateStrMeta);
    }
    if (data.containsKey('total_focus_seconds')) {
      context.handle(
        _totalFocusSecondsMeta,
        totalFocusSeconds.isAcceptableOrUnknown(
          data['total_focus_seconds']!,
          _totalFocusSecondsMeta,
        ),
      );
    }
    if (data.containsKey('target_goal_seconds')) {
      context.handle(
        _targetGoalSecondsMeta,
        targetGoalSeconds.isAcceptableOrUnknown(
          data['target_goal_seconds']!,
          _targetGoalSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_goal_completed')) {
      context.handle(
        _isGoalCompletedMeta,
        isGoalCompleted.isAcceptableOrUnknown(
          data['is_goal_completed']!,
          _isGoalCompletedMeta,
        ),
      );
    }
    if (data.containsKey('syllabus_progress_pct')) {
      context.handle(
        _syllabusProgressPctMeta,
        syllabusProgressPct.isAcceptableOrUnknown(
          data['syllabus_progress_pct']!,
          _syllabusProgressPctMeta,
        ),
      );
    }
    if (data.containsKey('tasks_completed_total')) {
      context.handle(
        _tasksCompletedTotalMeta,
        tasksCompletedTotal.isAcceptableOrUnknown(
          data['tasks_completed_total']!,
          _tasksCompletedTotalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateStr};
  @override
  DailyHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyHistoryData(
      dateStr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_str'],
      )!,
      totalFocusSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_focus_seconds'],
      )!,
      targetGoalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_goal_seconds'],
      )!,
      isGoalCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_goal_completed'],
      )!,
      syllabusProgressPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}syllabus_progress_pct'],
      )!,
      tasksCompletedTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tasks_completed_total'],
      )!,
    );
  }

  @override
  $DailyHistoryTable createAlias(String alias) {
    return $DailyHistoryTable(attachedDatabase, alias);
  }
}

class DailyHistoryData extends DataClass
    implements Insertable<DailyHistoryData> {
  final String dateStr;
  final int totalFocusSeconds;
  final int targetGoalSeconds;
  final bool isGoalCompleted;
  final double syllabusProgressPct;
  final int tasksCompletedTotal;
  const DailyHistoryData({
    required this.dateStr,
    required this.totalFocusSeconds,
    required this.targetGoalSeconds,
    required this.isGoalCompleted,
    required this.syllabusProgressPct,
    required this.tasksCompletedTotal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_str'] = Variable<String>(dateStr);
    map['total_focus_seconds'] = Variable<int>(totalFocusSeconds);
    map['target_goal_seconds'] = Variable<int>(targetGoalSeconds);
    map['is_goal_completed'] = Variable<bool>(isGoalCompleted);
    map['syllabus_progress_pct'] = Variable<double>(syllabusProgressPct);
    map['tasks_completed_total'] = Variable<int>(tasksCompletedTotal);
    return map;
  }

  DailyHistoryCompanion toCompanion(bool nullToAbsent) {
    return DailyHistoryCompanion(
      dateStr: Value(dateStr),
      totalFocusSeconds: Value(totalFocusSeconds),
      targetGoalSeconds: Value(targetGoalSeconds),
      isGoalCompleted: Value(isGoalCompleted),
      syllabusProgressPct: Value(syllabusProgressPct),
      tasksCompletedTotal: Value(tasksCompletedTotal),
    );
  }

  factory DailyHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyHistoryData(
      dateStr: serializer.fromJson<String>(json['dateStr']),
      totalFocusSeconds: serializer.fromJson<int>(json['totalFocusSeconds']),
      targetGoalSeconds: serializer.fromJson<int>(json['targetGoalSeconds']),
      isGoalCompleted: serializer.fromJson<bool>(json['isGoalCompleted']),
      syllabusProgressPct: serializer.fromJson<double>(
        json['syllabusProgressPct'],
      ),
      tasksCompletedTotal: serializer.fromJson<int>(
        json['tasksCompletedTotal'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateStr': serializer.toJson<String>(dateStr),
      'totalFocusSeconds': serializer.toJson<int>(totalFocusSeconds),
      'targetGoalSeconds': serializer.toJson<int>(targetGoalSeconds),
      'isGoalCompleted': serializer.toJson<bool>(isGoalCompleted),
      'syllabusProgressPct': serializer.toJson<double>(syllabusProgressPct),
      'tasksCompletedTotal': serializer.toJson<int>(tasksCompletedTotal),
    };
  }

  DailyHistoryData copyWith({
    String? dateStr,
    int? totalFocusSeconds,
    int? targetGoalSeconds,
    bool? isGoalCompleted,
    double? syllabusProgressPct,
    int? tasksCompletedTotal,
  }) => DailyHistoryData(
    dateStr: dateStr ?? this.dateStr,
    totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
    targetGoalSeconds: targetGoalSeconds ?? this.targetGoalSeconds,
    isGoalCompleted: isGoalCompleted ?? this.isGoalCompleted,
    syllabusProgressPct: syllabusProgressPct ?? this.syllabusProgressPct,
    tasksCompletedTotal: tasksCompletedTotal ?? this.tasksCompletedTotal,
  );
  DailyHistoryData copyWithCompanion(DailyHistoryCompanion data) {
    return DailyHistoryData(
      dateStr: data.dateStr.present ? data.dateStr.value : this.dateStr,
      totalFocusSeconds: data.totalFocusSeconds.present
          ? data.totalFocusSeconds.value
          : this.totalFocusSeconds,
      targetGoalSeconds: data.targetGoalSeconds.present
          ? data.targetGoalSeconds.value
          : this.targetGoalSeconds,
      isGoalCompleted: data.isGoalCompleted.present
          ? data.isGoalCompleted.value
          : this.isGoalCompleted,
      syllabusProgressPct: data.syllabusProgressPct.present
          ? data.syllabusProgressPct.value
          : this.syllabusProgressPct,
      tasksCompletedTotal: data.tasksCompletedTotal.present
          ? data.tasksCompletedTotal.value
          : this.tasksCompletedTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyHistoryData(')
          ..write('dateStr: $dateStr, ')
          ..write('totalFocusSeconds: $totalFocusSeconds, ')
          ..write('targetGoalSeconds: $targetGoalSeconds, ')
          ..write('isGoalCompleted: $isGoalCompleted, ')
          ..write('syllabusProgressPct: $syllabusProgressPct, ')
          ..write('tasksCompletedTotal: $tasksCompletedTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dateStr,
    totalFocusSeconds,
    targetGoalSeconds,
    isGoalCompleted,
    syllabusProgressPct,
    tasksCompletedTotal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyHistoryData &&
          other.dateStr == this.dateStr &&
          other.totalFocusSeconds == this.totalFocusSeconds &&
          other.targetGoalSeconds == this.targetGoalSeconds &&
          other.isGoalCompleted == this.isGoalCompleted &&
          other.syllabusProgressPct == this.syllabusProgressPct &&
          other.tasksCompletedTotal == this.tasksCompletedTotal);
}

class DailyHistoryCompanion extends UpdateCompanion<DailyHistoryData> {
  final Value<String> dateStr;
  final Value<int> totalFocusSeconds;
  final Value<int> targetGoalSeconds;
  final Value<bool> isGoalCompleted;
  final Value<double> syllabusProgressPct;
  final Value<int> tasksCompletedTotal;
  final Value<int> rowid;
  const DailyHistoryCompanion({
    this.dateStr = const Value.absent(),
    this.totalFocusSeconds = const Value.absent(),
    this.targetGoalSeconds = const Value.absent(),
    this.isGoalCompleted = const Value.absent(),
    this.syllabusProgressPct = const Value.absent(),
    this.tasksCompletedTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyHistoryCompanion.insert({
    required String dateStr,
    this.totalFocusSeconds = const Value.absent(),
    this.targetGoalSeconds = const Value.absent(),
    this.isGoalCompleted = const Value.absent(),
    this.syllabusProgressPct = const Value.absent(),
    this.tasksCompletedTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dateStr = Value(dateStr);
  static Insertable<DailyHistoryData> custom({
    Expression<String>? dateStr,
    Expression<int>? totalFocusSeconds,
    Expression<int>? targetGoalSeconds,
    Expression<bool>? isGoalCompleted,
    Expression<double>? syllabusProgressPct,
    Expression<int>? tasksCompletedTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateStr != null) 'date_str': dateStr,
      if (totalFocusSeconds != null) 'total_focus_seconds': totalFocusSeconds,
      if (targetGoalSeconds != null) 'target_goal_seconds': targetGoalSeconds,
      if (isGoalCompleted != null) 'is_goal_completed': isGoalCompleted,
      if (syllabusProgressPct != null)
        'syllabus_progress_pct': syllabusProgressPct,
      if (tasksCompletedTotal != null)
        'tasks_completed_total': tasksCompletedTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyHistoryCompanion copyWith({
    Value<String>? dateStr,
    Value<int>? totalFocusSeconds,
    Value<int>? targetGoalSeconds,
    Value<bool>? isGoalCompleted,
    Value<double>? syllabusProgressPct,
    Value<int>? tasksCompletedTotal,
    Value<int>? rowid,
  }) {
    return DailyHistoryCompanion(
      dateStr: dateStr ?? this.dateStr,
      totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
      targetGoalSeconds: targetGoalSeconds ?? this.targetGoalSeconds,
      isGoalCompleted: isGoalCompleted ?? this.isGoalCompleted,
      syllabusProgressPct: syllabusProgressPct ?? this.syllabusProgressPct,
      tasksCompletedTotal: tasksCompletedTotal ?? this.tasksCompletedTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateStr.present) {
      map['date_str'] = Variable<String>(dateStr.value);
    }
    if (totalFocusSeconds.present) {
      map['total_focus_seconds'] = Variable<int>(totalFocusSeconds.value);
    }
    if (targetGoalSeconds.present) {
      map['target_goal_seconds'] = Variable<int>(targetGoalSeconds.value);
    }
    if (isGoalCompleted.present) {
      map['is_goal_completed'] = Variable<bool>(isGoalCompleted.value);
    }
    if (syllabusProgressPct.present) {
      map['syllabus_progress_pct'] = Variable<double>(
        syllabusProgressPct.value,
      );
    }
    if (tasksCompletedTotal.present) {
      map['tasks_completed_total'] = Variable<int>(tasksCompletedTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyHistoryCompanion(')
          ..write('dateStr: $dateStr, ')
          ..write('totalFocusSeconds: $totalFocusSeconds, ')
          ..write('targetGoalSeconds: $targetGoalSeconds, ')
          ..write('isGoalCompleted: $isGoalCompleted, ')
          ..write('syllabusProgressPct: $syllabusProgressPct, ')
          ..write('tasksCompletedTotal: $tasksCompletedTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomTasksTable extends CustomTasks
    with TableInfo<$CustomTasksTable, CustomTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastInteractedAtMeta = const VerificationMeta(
    'lastInteractedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastInteractedAt =
      GeneratedColumn<DateTime>(
        'last_interacted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    isCompleted,
    createdAt,
    position,
    isDeleted,
    lastInteractedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('last_interacted_at')) {
      context.handle(
        _lastInteractedAtMeta,
        lastInteractedAt.isAcceptableOrUnknown(
          data['last_interacted_at']!,
          _lastInteractedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastInteractedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_interacted_at'],
      ),
    );
  }

  @override
  $CustomTasksTable createAlias(String alias) {
    return $CustomTasksTable(attachedDatabase, alias);
  }
}

class CustomTask extends DataClass implements Insertable<CustomTask> {
  final int id;
  final String content;
  final bool isCompleted;
  final DateTime createdAt;
  final int position;
  final bool isDeleted;
  final DateTime? lastInteractedAt;
  const CustomTask({
    required this.id,
    required this.content,
    required this.isCompleted,
    required this.createdAt,
    required this.position,
    required this.isDeleted,
    this.lastInteractedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['position'] = Variable<int>(position);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || lastInteractedAt != null) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt);
    }
    return map;
  }

  CustomTasksCompanion toCompanion(bool nullToAbsent) {
    return CustomTasksCompanion(
      id: Value(id),
      content: Value(content),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      position: Value(position),
      isDeleted: Value(isDeleted),
      lastInteractedAt: lastInteractedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastInteractedAt),
    );
  }

  factory CustomTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomTask(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      position: serializer.fromJson<int>(json['position']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastInteractedAt: serializer.fromJson<DateTime?>(
        json['lastInteractedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'position': serializer.toJson<int>(position),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastInteractedAt': serializer.toJson<DateTime?>(lastInteractedAt),
    };
  }

  CustomTask copyWith({
    int? id,
    String? content,
    bool? isCompleted,
    DateTime? createdAt,
    int? position,
    bool? isDeleted,
    Value<DateTime?> lastInteractedAt = const Value.absent(),
  }) => CustomTask(
    id: id ?? this.id,
    content: content ?? this.content,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    position: position ?? this.position,
    isDeleted: isDeleted ?? this.isDeleted,
    lastInteractedAt: lastInteractedAt.present
        ? lastInteractedAt.value
        : this.lastInteractedAt,
  );
  CustomTask copyWithCompanion(CustomTasksCompanion data) {
    return CustomTask(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      position: data.position.present ? data.position.value : this.position,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastInteractedAt: data.lastInteractedAt.present
          ? data.lastInteractedAt.value
          : this.lastInteractedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomTask(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    isCompleted,
    createdAt,
    position,
    isDeleted,
    lastInteractedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomTask &&
          other.id == this.id &&
          other.content == this.content &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.position == this.position &&
          other.isDeleted == this.isDeleted &&
          other.lastInteractedAt == this.lastInteractedAt);
}

class CustomTasksCompanion extends UpdateCompanion<CustomTask> {
  final Value<int> id;
  final Value<String> content;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<int> position;
  final Value<bool> isDeleted;
  final Value<DateTime?> lastInteractedAt;
  const CustomTasksCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.position = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  });
  CustomTasksCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    this.position = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  }) : content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<CustomTask> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<int>? position,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastInteractedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (position != null) 'position': position,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastInteractedAt != null) 'last_interacted_at': lastInteractedAt,
    });
  }

  CustomTasksCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<bool>? isCompleted,
    Value<DateTime>? createdAt,
    Value<int>? position,
    Value<bool>? isDeleted,
    Value<DateTime?>? lastInteractedAt,
  }) {
    return CustomTasksCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      position: position ?? this.position,
      isDeleted: isDeleted ?? this.isDeleted,
      lastInteractedAt: lastInteractedAt ?? this.lastInteractedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastInteractedAt.present) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomTasksCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }
}

class $SyllabusProgressLogsTable extends SyllabusProgressLogs
    with TableInfo<$SyllabusProgressLogsTable, SyllabusProgressLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyllabusProgressLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES syllabus_categories (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES syllabus_topics (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES syllabus_tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
    'delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastInteractedAtMeta = const VerificationMeta(
    'lastInteractedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastInteractedAt =
      GeneratedColumn<DateTime>(
        'last_interacted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    topicId,
    taskId,
    delta,
    timestamp,
    isDeleted,
    lastInteractedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syllabus_progress_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyllabusProgressLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('delta')) {
      context.handle(
        _deltaMeta,
        delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('last_interacted_at')) {
      context.handle(
        _lastInteractedAtMeta,
        lastInteractedAt.isAcceptableOrUnknown(
          data['last_interacted_at']!,
          _lastInteractedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyllabusProgressLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyllabusProgressLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      ),
      delta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastInteractedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_interacted_at'],
      ),
    );
  }

  @override
  $SyllabusProgressLogsTable createAlias(String alias) {
    return $SyllabusProgressLogsTable(attachedDatabase, alias);
  }
}

class SyllabusProgressLog extends DataClass
    implements Insertable<SyllabusProgressLog> {
  final int id;
  final int categoryId;
  final int topicId;
  final int? taskId;
  final int delta;
  final DateTime timestamp;
  final bool isDeleted;
  final DateTime? lastInteractedAt;
  const SyllabusProgressLog({
    required this.id,
    required this.categoryId,
    required this.topicId,
    this.taskId,
    required this.delta,
    required this.timestamp,
    required this.isDeleted,
    this.lastInteractedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['topic_id'] = Variable<int>(topicId);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<int>(taskId);
    }
    map['delta'] = Variable<int>(delta);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || lastInteractedAt != null) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt);
    }
    return map;
  }

  SyllabusProgressLogsCompanion toCompanion(bool nullToAbsent) {
    return SyllabusProgressLogsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      topicId: Value(topicId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      delta: Value(delta),
      timestamp: Value(timestamp),
      isDeleted: Value(isDeleted),
      lastInteractedAt: lastInteractedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastInteractedAt),
    );
  }

  factory SyllabusProgressLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyllabusProgressLog(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      topicId: serializer.fromJson<int>(json['topicId']),
      taskId: serializer.fromJson<int?>(json['taskId']),
      delta: serializer.fromJson<int>(json['delta']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      lastInteractedAt: serializer.fromJson<DateTime?>(
        json['lastInteractedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'topicId': serializer.toJson<int>(topicId),
      'taskId': serializer.toJson<int?>(taskId),
      'delta': serializer.toJson<int>(delta),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'lastInteractedAt': serializer.toJson<DateTime?>(lastInteractedAt),
    };
  }

  SyllabusProgressLog copyWith({
    int? id,
    int? categoryId,
    int? topicId,
    Value<int?> taskId = const Value.absent(),
    int? delta,
    DateTime? timestamp,
    bool? isDeleted,
    Value<DateTime?> lastInteractedAt = const Value.absent(),
  }) => SyllabusProgressLog(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    topicId: topicId ?? this.topicId,
    taskId: taskId.present ? taskId.value : this.taskId,
    delta: delta ?? this.delta,
    timestamp: timestamp ?? this.timestamp,
    isDeleted: isDeleted ?? this.isDeleted,
    lastInteractedAt: lastInteractedAt.present
        ? lastInteractedAt.value
        : this.lastInteractedAt,
  );
  SyllabusProgressLog copyWithCompanion(SyllabusProgressLogsCompanion data) {
    return SyllabusProgressLog(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      delta: data.delta.present ? data.delta.value : this.delta,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastInteractedAt: data.lastInteractedAt.present
          ? data.lastInteractedAt.value
          : this.lastInteractedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusProgressLog(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('topicId: $topicId, ')
          ..write('taskId: $taskId, ')
          ..write('delta: $delta, ')
          ..write('timestamp: $timestamp, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    topicId,
    taskId,
    delta,
    timestamp,
    isDeleted,
    lastInteractedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyllabusProgressLog &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.topicId == this.topicId &&
          other.taskId == this.taskId &&
          other.delta == this.delta &&
          other.timestamp == this.timestamp &&
          other.isDeleted == this.isDeleted &&
          other.lastInteractedAt == this.lastInteractedAt);
}

class SyllabusProgressLogsCompanion
    extends UpdateCompanion<SyllabusProgressLog> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<int> topicId;
  final Value<int?> taskId;
  final Value<int> delta;
  final Value<DateTime> timestamp;
  final Value<bool> isDeleted;
  final Value<DateTime?> lastInteractedAt;
  const SyllabusProgressLogsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.delta = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  });
  SyllabusProgressLogsCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required int topicId,
    this.taskId = const Value.absent(),
    required int delta,
    required DateTime timestamp,
    this.isDeleted = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  }) : categoryId = Value(categoryId),
       topicId = Value(topicId),
       delta = Value(delta),
       timestamp = Value(timestamp);
  static Insertable<SyllabusProgressLog> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<int>? topicId,
    Expression<int>? taskId,
    Expression<int>? delta,
    Expression<DateTime>? timestamp,
    Expression<bool>? isDeleted,
    Expression<DateTime>? lastInteractedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (topicId != null) 'topic_id': topicId,
      if (taskId != null) 'task_id': taskId,
      if (delta != null) 'delta': delta,
      if (timestamp != null) 'timestamp': timestamp,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastInteractedAt != null) 'last_interacted_at': lastInteractedAt,
    });
  }

  SyllabusProgressLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? categoryId,
    Value<int>? topicId,
    Value<int?>? taskId,
    Value<int>? delta,
    Value<DateTime>? timestamp,
    Value<bool>? isDeleted,
    Value<DateTime?>? lastInteractedAt,
  }) {
    return SyllabusProgressLogsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      topicId: topicId ?? this.topicId,
      taskId: taskId ?? this.taskId,
      delta: delta ?? this.delta,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      lastInteractedAt: lastInteractedAt ?? this.lastInteractedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (lastInteractedAt.present) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusProgressLogsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('topicId: $topicId, ')
          ..write('taskId: $taskId, ')
          ..write('delta: $delta, ')
          ..write('timestamp: $timestamp, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyllabusCategoriesTable syllabusCategories =
      $SyllabusCategoriesTable(this);
  late final $SyllabusTopicsTable syllabusTopics = $SyllabusTopicsTable(this);
  late final $SyllabusTasksTable syllabusTasks = $SyllabusTasksTable(this);
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  late final $DailyHistoryTable dailyHistory = $DailyHistoryTable(this);
  late final $CustomTasksTable customTasks = $CustomTasksTable(this);
  late final $SyllabusProgressLogsTable syllabusProgressLogs =
      $SyllabusProgressLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syllabusCategories,
    syllabusTopics,
    syllabusTasks,
    focusSessions,
    dailyHistory,
    customTasks,
    syllabusProgressLogs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'syllabus_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('syllabus_topics', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'syllabus_topics',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('syllabus_tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'syllabus_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('syllabus_progress_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'syllabus_topics',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('syllabus_progress_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'syllabus_tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('syllabus_progress_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SyllabusCategoriesTableCreateCompanionBuilder =
    SyllabusCategoriesCompanion Function({
      Value<int> id,
      required String name,
      required int position,
      required int color,
      Value<DateTime?> lastInteractedAt,
      Value<bool> isDeleted,
    });
typedef $$SyllabusCategoriesTableUpdateCompanionBuilder =
    SyllabusCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> position,
      Value<int> color,
      Value<DateTime?> lastInteractedAt,
      Value<bool> isDeleted,
    });

final class $$SyllabusCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SyllabusCategoriesTable,
          SyllabusCategory
        > {
  $$SyllabusCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SyllabusTopicsTable, List<SyllabusTopic>>
  _syllabusTopicsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syllabusTopics,
    aliasName: 'syllabus_categories__id__syllabus_topics__category_id',
  );

  $$SyllabusTopicsTableProcessedTableManager get syllabusTopicsRefs {
    final manager = $$SyllabusTopicsTableTableManager(
      $_db,
      $_db.syllabusTopics,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_syllabusTopicsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FocusSessionsTable, List<FocusSession>>
  _focusSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.focusSessions,
    aliasName: 'syllabus_categories__id__focus_sessions__category_id',
  );

  $$FocusSessionsTableProcessedTableManager get focusSessionsRefs {
    final manager = $$FocusSessionsTableTableManager(
      $_db,
      $_db.focusSessions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_focusSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $SyllabusProgressLogsTable,
    List<SyllabusProgressLog>
  >
  _syllabusProgressLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syllabusProgressLogs,
        aliasName:
            'syllabus_categories__id__syllabus_progress_logs__category_id',
      );

  $$SyllabusProgressLogsTableProcessedTableManager
  get syllabusProgressLogsRefs {
    final manager = $$SyllabusProgressLogsTableTableManager(
      $_db,
      $_db.syllabusProgressLogs,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syllabusProgressLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyllabusCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyllabusCategoriesTable> {
  $$SyllabusCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> syllabusTopicsRefs(
    Expression<bool> Function($$SyllabusTopicsTableFilterComposer f) f,
  ) {
    final $$SyllabusTopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableFilterComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> focusSessionsRefs(
    Expression<bool> Function($$FocusSessionsTableFilterComposer f) f,
  ) {
    final $$FocusSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableFilterComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syllabusProgressLogsRefs(
    Expression<bool> Function($$SyllabusProgressLogsTableFilterComposer f) f,
  ) {
    final $$SyllabusProgressLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusProgressLogs,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusProgressLogsTableFilterComposer(
            $db: $db,
            $table: $db.syllabusProgressLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyllabusCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyllabusCategoriesTable> {
  $$SyllabusCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyllabusCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyllabusCategoriesTable> {
  $$SyllabusCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> syllabusTopicsRefs<T extends Object>(
    Expression<T> Function($$SyllabusTopicsTableAnnotationComposer a) f,
  ) {
    final $$SyllabusTopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> focusSessionsRefs<T extends Object>(
    Expression<T> Function($$FocusSessionsTableAnnotationComposer a) f,
  ) {
    final $$FocusSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.focusSessions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FocusSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.focusSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syllabusProgressLogsRefs<T extends Object>(
    Expression<T> Function($$SyllabusProgressLogsTableAnnotationComposer a) f,
  ) {
    final $$SyllabusProgressLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.syllabusProgressLogs,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyllabusProgressLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.syllabusProgressLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SyllabusCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyllabusCategoriesTable,
          SyllabusCategory,
          $$SyllabusCategoriesTableFilterComposer,
          $$SyllabusCategoriesTableOrderingComposer,
          $$SyllabusCategoriesTableAnnotationComposer,
          $$SyllabusCategoriesTableCreateCompanionBuilder,
          $$SyllabusCategoriesTableUpdateCompanionBuilder,
          (SyllabusCategory, $$SyllabusCategoriesTableReferences),
          SyllabusCategory,
          PrefetchHooks Function({
            bool syllabusTopicsRefs,
            bool focusSessionsRefs,
            bool syllabusProgressLogsRefs,
          })
        > {
  $$SyllabusCategoriesTableTableManager(
    _$AppDatabase db,
    $SyllabusCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyllabusCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyllabusCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyllabusCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => SyllabusCategoriesCompanion(
                id: id,
                name: name,
                position: position,
                color: color,
                lastInteractedAt: lastInteractedAt,
                isDeleted: isDeleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int position,
                required int color,
                Value<DateTime?> lastInteractedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => SyllabusCategoriesCompanion.insert(
                id: id,
                name: name,
                position: position,
                color: color,
                lastInteractedAt: lastInteractedAt,
                isDeleted: isDeleted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyllabusCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                syllabusTopicsRefs = false,
                focusSessionsRefs = false,
                syllabusProgressLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (syllabusTopicsRefs) db.syllabusTopics,
                    if (focusSessionsRefs) db.focusSessions,
                    if (syllabusProgressLogsRefs) db.syllabusProgressLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syllabusTopicsRefs)
                        await $_getPrefetchedData<
                          SyllabusCategory,
                          $SyllabusCategoriesTable,
                          SyllabusTopic
                        >(
                          currentTable: table,
                          referencedTable: $$SyllabusCategoriesTableReferences
                              ._syllabusTopicsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyllabusCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).syllabusTopicsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (focusSessionsRefs)
                        await $_getPrefetchedData<
                          SyllabusCategory,
                          $SyllabusCategoriesTable,
                          FocusSession
                        >(
                          currentTable: table,
                          referencedTable: $$SyllabusCategoriesTableReferences
                              ._focusSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyllabusCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).focusSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syllabusProgressLogsRefs)
                        await $_getPrefetchedData<
                          SyllabusCategory,
                          $SyllabusCategoriesTable,
                          SyllabusProgressLog
                        >(
                          currentTable: table,
                          referencedTable: $$SyllabusCategoriesTableReferences
                              ._syllabusProgressLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyllabusCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).syllabusProgressLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SyllabusCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyllabusCategoriesTable,
      SyllabusCategory,
      $$SyllabusCategoriesTableFilterComposer,
      $$SyllabusCategoriesTableOrderingComposer,
      $$SyllabusCategoriesTableAnnotationComposer,
      $$SyllabusCategoriesTableCreateCompanionBuilder,
      $$SyllabusCategoriesTableUpdateCompanionBuilder,
      (SyllabusCategory, $$SyllabusCategoriesTableReferences),
      SyllabusCategory,
      PrefetchHooks Function({
        bool syllabusTopicsRefs,
        bool focusSessionsRefs,
        bool syllabusProgressLogsRefs,
      })
    >;
typedef $$SyllabusTopicsTableCreateCompanionBuilder =
    SyllabusTopicsCompanion Function({
      Value<int> id,
      required int categoryId,
      required String name,
      required int position,
      Value<bool> isCounter,
      Value<int> currentCount,
      Value<int> maxCount,
      Value<String?> resourceUrl,
      Value<bool> isDeleted,
      Value<DateTime?> lastInteractedAt,
    });
typedef $$SyllabusTopicsTableUpdateCompanionBuilder =
    SyllabusTopicsCompanion Function({
      Value<int> id,
      Value<int> categoryId,
      Value<String> name,
      Value<int> position,
      Value<bool> isCounter,
      Value<int> currentCount,
      Value<int> maxCount,
      Value<String?> resourceUrl,
      Value<bool> isDeleted,
      Value<DateTime?> lastInteractedAt,
    });

final class $$SyllabusTopicsTableReferences
    extends BaseReferences<_$AppDatabase, $SyllabusTopicsTable, SyllabusTopic> {
  $$SyllabusTopicsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyllabusCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .syllabusCategories
      .createAlias('syllabus_topics__category_id__syllabus_categories__id');

  $$SyllabusCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$SyllabusCategoriesTableTableManager(
      $_db,
      $_db.syllabusCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SyllabusTasksTable, List<SyllabusTask>>
  _syllabusTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syllabusTasks,
    aliasName: 'syllabus_topics__id__syllabus_tasks__topic_id',
  );

  $$SyllabusTasksTableProcessedTableManager get syllabusTasksRefs {
    final manager = $$SyllabusTasksTableTableManager(
      $_db,
      $_db.syllabusTasks,
    ).filter((f) => f.topicId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_syllabusTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $SyllabusProgressLogsTable,
    List<SyllabusProgressLog>
  >
  _syllabusProgressLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syllabusProgressLogs,
        aliasName: 'syllabus_topics__id__syllabus_progress_logs__topic_id',
      );

  $$SyllabusProgressLogsTableProcessedTableManager
  get syllabusProgressLogsRefs {
    final manager = $$SyllabusProgressLogsTableTableManager(
      $_db,
      $_db.syllabusProgressLogs,
    ).filter((f) => f.topicId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syllabusProgressLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyllabusTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $SyllabusTopicsTable> {
  $$SyllabusTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCounter => $composableBuilder(
    column: $table.isCounter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxCount => $composableBuilder(
    column: $table.maxCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceUrl => $composableBuilder(
    column: $table.resourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SyllabusCategoriesTableFilterComposer get categoryId {
    final $$SyllabusCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.syllabusCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.syllabusCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> syllabusTasksRefs(
    Expression<bool> Function($$SyllabusTasksTableFilterComposer f) f,
  ) {
    final $$SyllabusTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusTasks,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTasksTableFilterComposer(
            $db: $db,
            $table: $db.syllabusTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syllabusProgressLogsRefs(
    Expression<bool> Function($$SyllabusProgressLogsTableFilterComposer f) f,
  ) {
    final $$SyllabusProgressLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusProgressLogs,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusProgressLogsTableFilterComposer(
            $db: $db,
            $table: $db.syllabusProgressLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyllabusTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyllabusTopicsTable> {
  $$SyllabusTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCounter => $composableBuilder(
    column: $table.isCounter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxCount => $composableBuilder(
    column: $table.maxCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceUrl => $composableBuilder(
    column: $table.resourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyllabusCategoriesTableOrderingComposer get categoryId {
    final $$SyllabusCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.syllabusCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.syllabusCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyllabusTopicsTable> {
  $$SyllabusTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isCounter =>
      $composableBuilder(column: $table.isCounter, builder: (column) => column);

  GeneratedColumn<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxCount =>
      $composableBuilder(column: $table.maxCount, builder: (column) => column);

  GeneratedColumn<String> get resourceUrl => $composableBuilder(
    column: $table.resourceUrl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => column,
  );

  $$SyllabusCategoriesTableAnnotationComposer get categoryId {
    final $$SyllabusCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.syllabusCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyllabusCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.syllabusCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> syllabusTasksRefs<T extends Object>(
    Expression<T> Function($$SyllabusTasksTableAnnotationComposer a) f,
  ) {
    final $$SyllabusTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusTasks,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.syllabusTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syllabusProgressLogsRefs<T extends Object>(
    Expression<T> Function($$SyllabusProgressLogsTableAnnotationComposer a) f,
  ) {
    final $$SyllabusProgressLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.syllabusProgressLogs,
          getReferencedColumn: (t) => t.topicId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyllabusProgressLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.syllabusProgressLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SyllabusTopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyllabusTopicsTable,
          SyllabusTopic,
          $$SyllabusTopicsTableFilterComposer,
          $$SyllabusTopicsTableOrderingComposer,
          $$SyllabusTopicsTableAnnotationComposer,
          $$SyllabusTopicsTableCreateCompanionBuilder,
          $$SyllabusTopicsTableUpdateCompanionBuilder,
          (SyllabusTopic, $$SyllabusTopicsTableReferences),
          SyllabusTopic,
          PrefetchHooks Function({
            bool categoryId,
            bool syllabusTasksRefs,
            bool syllabusProgressLogsRefs,
          })
        > {
  $$SyllabusTopicsTableTableManager(
    _$AppDatabase db,
    $SyllabusTopicsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyllabusTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyllabusTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyllabusTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isCounter = const Value.absent(),
                Value<int> currentCount = const Value.absent(),
                Value<int> maxCount = const Value.absent(),
                Value<String?> resourceUrl = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => SyllabusTopicsCompanion(
                id: id,
                categoryId: categoryId,
                name: name,
                position: position,
                isCounter: isCounter,
                currentCount: currentCount,
                maxCount: maxCount,
                resourceUrl: resourceUrl,
                isDeleted: isDeleted,
                lastInteractedAt: lastInteractedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int categoryId,
                required String name,
                required int position,
                Value<bool> isCounter = const Value.absent(),
                Value<int> currentCount = const Value.absent(),
                Value<int> maxCount = const Value.absent(),
                Value<String?> resourceUrl = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => SyllabusTopicsCompanion.insert(
                id: id,
                categoryId: categoryId,
                name: name,
                position: position,
                isCounter: isCounter,
                currentCount: currentCount,
                maxCount: maxCount,
                resourceUrl: resourceUrl,
                isDeleted: isDeleted,
                lastInteractedAt: lastInteractedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyllabusTopicsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                syllabusTasksRefs = false,
                syllabusProgressLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (syllabusTasksRefs) db.syllabusTasks,
                    if (syllabusProgressLogsRefs) db.syllabusProgressLogs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$SyllabusTopicsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$SyllabusTopicsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syllabusTasksRefs)
                        await $_getPrefetchedData<
                          SyllabusTopic,
                          $SyllabusTopicsTable,
                          SyllabusTask
                        >(
                          currentTable: table,
                          referencedTable: $$SyllabusTopicsTableReferences
                              ._syllabusTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyllabusTopicsTableReferences(
                                db,
                                table,
                                p0,
                              ).syllabusTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.topicId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syllabusProgressLogsRefs)
                        await $_getPrefetchedData<
                          SyllabusTopic,
                          $SyllabusTopicsTable,
                          SyllabusProgressLog
                        >(
                          currentTable: table,
                          referencedTable: $$SyllabusTopicsTableReferences
                              ._syllabusProgressLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyllabusTopicsTableReferences(
                                db,
                                table,
                                p0,
                              ).syllabusProgressLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.topicId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SyllabusTopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyllabusTopicsTable,
      SyllabusTopic,
      $$SyllabusTopicsTableFilterComposer,
      $$SyllabusTopicsTableOrderingComposer,
      $$SyllabusTopicsTableAnnotationComposer,
      $$SyllabusTopicsTableCreateCompanionBuilder,
      $$SyllabusTopicsTableUpdateCompanionBuilder,
      (SyllabusTopic, $$SyllabusTopicsTableReferences),
      SyllabusTopic,
      PrefetchHooks Function({
        bool categoryId,
        bool syllabusTasksRefs,
        bool syllabusProgressLogsRefs,
      })
    >;
typedef $$SyllabusTasksTableCreateCompanionBuilder =
    SyllabusTasksCompanion Function({
      Value<int> id,
      required int topicId,
      required String name,
      Value<bool> isCompleted,
      required int position,
      Value<DateTime?> completedAt,
      Value<bool> isDeleted,
      Value<DateTime?> lastInteractedAt,
    });
typedef $$SyllabusTasksTableUpdateCompanionBuilder =
    SyllabusTasksCompanion Function({
      Value<int> id,
      Value<int> topicId,
      Value<String> name,
      Value<bool> isCompleted,
      Value<int> position,
      Value<DateTime?> completedAt,
      Value<bool> isDeleted,
      Value<DateTime?> lastInteractedAt,
    });

final class $$SyllabusTasksTableReferences
    extends BaseReferences<_$AppDatabase, $SyllabusTasksTable, SyllabusTask> {
  $$SyllabusTasksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyllabusTopicsTable _topicIdTable(_$AppDatabase db) => db
      .syllabusTopics
      .createAlias('syllabus_tasks__topic_id__syllabus_topics__id');

  $$SyllabusTopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<int>('topic_id')!;

    final manager = $$SyllabusTopicsTableTableManager(
      $_db,
      $_db.syllabusTopics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SyllabusProgressLogsTable,
    List<SyllabusProgressLog>
  >
  _syllabusProgressLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syllabusProgressLogs,
        aliasName: 'syllabus_tasks__id__syllabus_progress_logs__task_id',
      );

  $$SyllabusProgressLogsTableProcessedTableManager
  get syllabusProgressLogsRefs {
    final manager = $$SyllabusProgressLogsTableTableManager(
      $_db,
      $_db.syllabusProgressLogs,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syllabusProgressLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyllabusTasksTableFilterComposer
    extends Composer<_$AppDatabase, $SyllabusTasksTable> {
  $$SyllabusTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SyllabusTopicsTableFilterComposer get topicId {
    final $$SyllabusTopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableFilterComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> syllabusProgressLogsRefs(
    Expression<bool> Function($$SyllabusProgressLogsTableFilterComposer f) f,
  ) {
    final $$SyllabusProgressLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusProgressLogs,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusProgressLogsTableFilterComposer(
            $db: $db,
            $table: $db.syllabusProgressLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyllabusTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SyllabusTasksTable> {
  $$SyllabusTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyllabusTopicsTableOrderingComposer get topicId {
    final $$SyllabusTopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableOrderingComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyllabusTasksTable> {
  $$SyllabusTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => column,
  );

  $$SyllabusTopicsTableAnnotationComposer get topicId {
    final $$SyllabusTopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> syllabusProgressLogsRefs<T extends Object>(
    Expression<T> Function($$SyllabusProgressLogsTableAnnotationComposer a) f,
  ) {
    final $$SyllabusProgressLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.syllabusProgressLogs,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyllabusProgressLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.syllabusProgressLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SyllabusTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyllabusTasksTable,
          SyllabusTask,
          $$SyllabusTasksTableFilterComposer,
          $$SyllabusTasksTableOrderingComposer,
          $$SyllabusTasksTableAnnotationComposer,
          $$SyllabusTasksTableCreateCompanionBuilder,
          $$SyllabusTasksTableUpdateCompanionBuilder,
          (SyllabusTask, $$SyllabusTasksTableReferences),
          SyllabusTask,
          PrefetchHooks Function({bool topicId, bool syllabusProgressLogsRefs})
        > {
  $$SyllabusTasksTableTableManager(_$AppDatabase db, $SyllabusTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyllabusTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyllabusTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyllabusTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> topicId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => SyllabusTasksCompanion(
                id: id,
                topicId: topicId,
                name: name,
                isCompleted: isCompleted,
                position: position,
                completedAt: completedAt,
                isDeleted: isDeleted,
                lastInteractedAt: lastInteractedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int topicId,
                required String name,
                Value<bool> isCompleted = const Value.absent(),
                required int position,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => SyllabusTasksCompanion.insert(
                id: id,
                topicId: topicId,
                name: name,
                isCompleted: isCompleted,
                position: position,
                completedAt: completedAt,
                isDeleted: isDeleted,
                lastInteractedAt: lastInteractedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyllabusTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({topicId = false, syllabusProgressLogsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (syllabusProgressLogsRefs) db.syllabusProgressLogs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (topicId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.topicId,
                                    referencedTable:
                                        $$SyllabusTasksTableReferences
                                            ._topicIdTable(db),
                                    referencedColumn:
                                        $$SyllabusTasksTableReferences
                                            ._topicIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syllabusProgressLogsRefs)
                        await $_getPrefetchedData<
                          SyllabusTask,
                          $SyllabusTasksTable,
                          SyllabusProgressLog
                        >(
                          currentTable: table,
                          referencedTable: $$SyllabusTasksTableReferences
                              ._syllabusProgressLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyllabusTasksTableReferences(
                                db,
                                table,
                                p0,
                              ).syllabusProgressLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SyllabusTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyllabusTasksTable,
      SyllabusTask,
      $$SyllabusTasksTableFilterComposer,
      $$SyllabusTasksTableOrderingComposer,
      $$SyllabusTasksTableAnnotationComposer,
      $$SyllabusTasksTableCreateCompanionBuilder,
      $$SyllabusTasksTableUpdateCompanionBuilder,
      (SyllabusTask, $$SyllabusTasksTableReferences),
      SyllabusTask,
      PrefetchHooks Function({bool topicId, bool syllabusProgressLogsRefs})
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<int> id,
      required String method,
      required DateTime startTime,
      required int durationSeconds,
      Value<String?> accomplishments,
      Value<double> progressDelta,
      Value<int?> categoryId,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<int> id,
      Value<String> method,
      Value<DateTime> startTime,
      Value<int> durationSeconds,
      Value<String?> accomplishments,
      Value<double> progressDelta,
      Value<int?> categoryId,
    });

final class $$FocusSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession> {
  $$FocusSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyllabusCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .syllabusCategories
      .createAlias('focus_sessions__category_id__syllabus_categories__id');

  $$SyllabusCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$SyllabusCategoriesTableTableManager(
      $_db,
      $_db.syllabusCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accomplishments => $composableBuilder(
    column: $table.accomplishments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressDelta => $composableBuilder(
    column: $table.progressDelta,
    builder: (column) => ColumnFilters(column),
  );

  $$SyllabusCategoriesTableFilterComposer get categoryId {
    final $$SyllabusCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.syllabusCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.syllabusCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accomplishments => $composableBuilder(
    column: $table.accomplishments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressDelta => $composableBuilder(
    column: $table.progressDelta,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyllabusCategoriesTableOrderingComposer get categoryId {
    final $$SyllabusCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.syllabusCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.syllabusCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accomplishments => $composableBuilder(
    column: $table.accomplishments,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progressDelta => $composableBuilder(
    column: $table.progressDelta,
    builder: (column) => column,
  );

  $$SyllabusCategoriesTableAnnotationComposer get categoryId {
    final $$SyllabusCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.syllabusCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyllabusCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.syllabusCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionsTable,
          FocusSession,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (FocusSession, $$FocusSessionsTableReferences),
          FocusSession,
          PrefetchHooks Function({bool categoryId})
        > {
  $$FocusSessionsTableTableManager(_$AppDatabase db, $FocusSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String?> accomplishments = const Value.absent(),
                Value<double> progressDelta = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                method: method,
                startTime: startTime,
                durationSeconds: durationSeconds,
                accomplishments: accomplishments,
                progressDelta: progressDelta,
                categoryId: categoryId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String method,
                required DateTime startTime,
                required int durationSeconds,
                Value<String?> accomplishments = const Value.absent(),
                Value<double> progressDelta = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                method: method,
                startTime: startTime,
                durationSeconds: durationSeconds,
                accomplishments: accomplishments,
                progressDelta: progressDelta,
                categoryId: categoryId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FocusSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$FocusSessionsTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$FocusSessionsTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionsTable,
      FocusSession,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (FocusSession, $$FocusSessionsTableReferences),
      FocusSession,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$DailyHistoryTableCreateCompanionBuilder =
    DailyHistoryCompanion Function({
      required String dateStr,
      Value<int> totalFocusSeconds,
      Value<int> targetGoalSeconds,
      Value<bool> isGoalCompleted,
      Value<double> syllabusProgressPct,
      Value<int> tasksCompletedTotal,
      Value<int> rowid,
    });
typedef $$DailyHistoryTableUpdateCompanionBuilder =
    DailyHistoryCompanion Function({
      Value<String> dateStr,
      Value<int> totalFocusSeconds,
      Value<int> targetGoalSeconds,
      Value<bool> isGoalCompleted,
      Value<double> syllabusProgressPct,
      Value<int> tasksCompletedTotal,
      Value<int> rowid,
    });

class $$DailyHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $DailyHistoryTable> {
  $$DailyHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dateStr => $composableBuilder(
    column: $table.dateStr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalFocusSeconds => $composableBuilder(
    column: $table.totalFocusSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetGoalSeconds => $composableBuilder(
    column: $table.targetGoalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGoalCompleted => $composableBuilder(
    column: $table.isGoalCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get syllabusProgressPct => $composableBuilder(
    column: $table.syllabusProgressPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tasksCompletedTotal => $composableBuilder(
    column: $table.tasksCompletedTotal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyHistoryTable> {
  $$DailyHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dateStr => $composableBuilder(
    column: $table.dateStr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalFocusSeconds => $composableBuilder(
    column: $table.totalFocusSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetGoalSeconds => $composableBuilder(
    column: $table.targetGoalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGoalCompleted => $composableBuilder(
    column: $table.isGoalCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get syllabusProgressPct => $composableBuilder(
    column: $table.syllabusProgressPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tasksCompletedTotal => $composableBuilder(
    column: $table.tasksCompletedTotal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyHistoryTable> {
  $$DailyHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dateStr =>
      $composableBuilder(column: $table.dateStr, builder: (column) => column);

  GeneratedColumn<int> get totalFocusSeconds => $composableBuilder(
    column: $table.totalFocusSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetGoalSeconds => $composableBuilder(
    column: $table.targetGoalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGoalCompleted => $composableBuilder(
    column: $table.isGoalCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<double> get syllabusProgressPct => $composableBuilder(
    column: $table.syllabusProgressPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tasksCompletedTotal => $composableBuilder(
    column: $table.tasksCompletedTotal,
    builder: (column) => column,
  );
}

class $$DailyHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyHistoryTable,
          DailyHistoryData,
          $$DailyHistoryTableFilterComposer,
          $$DailyHistoryTableOrderingComposer,
          $$DailyHistoryTableAnnotationComposer,
          $$DailyHistoryTableCreateCompanionBuilder,
          $$DailyHistoryTableUpdateCompanionBuilder,
          (
            DailyHistoryData,
            BaseReferences<_$AppDatabase, $DailyHistoryTable, DailyHistoryData>,
          ),
          DailyHistoryData,
          PrefetchHooks Function()
        > {
  $$DailyHistoryTableTableManager(_$AppDatabase db, $DailyHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dateStr = const Value.absent(),
                Value<int> totalFocusSeconds = const Value.absent(),
                Value<int> targetGoalSeconds = const Value.absent(),
                Value<bool> isGoalCompleted = const Value.absent(),
                Value<double> syllabusProgressPct = const Value.absent(),
                Value<int> tasksCompletedTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyHistoryCompanion(
                dateStr: dateStr,
                totalFocusSeconds: totalFocusSeconds,
                targetGoalSeconds: targetGoalSeconds,
                isGoalCompleted: isGoalCompleted,
                syllabusProgressPct: syllabusProgressPct,
                tasksCompletedTotal: tasksCompletedTotal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dateStr,
                Value<int> totalFocusSeconds = const Value.absent(),
                Value<int> targetGoalSeconds = const Value.absent(),
                Value<bool> isGoalCompleted = const Value.absent(),
                Value<double> syllabusProgressPct = const Value.absent(),
                Value<int> tasksCompletedTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyHistoryCompanion.insert(
                dateStr: dateStr,
                totalFocusSeconds: totalFocusSeconds,
                targetGoalSeconds: targetGoalSeconds,
                isGoalCompleted: isGoalCompleted,
                syllabusProgressPct: syllabusProgressPct,
                tasksCompletedTotal: tasksCompletedTotal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyHistoryTable,
      DailyHistoryData,
      $$DailyHistoryTableFilterComposer,
      $$DailyHistoryTableOrderingComposer,
      $$DailyHistoryTableAnnotationComposer,
      $$DailyHistoryTableCreateCompanionBuilder,
      $$DailyHistoryTableUpdateCompanionBuilder,
      (
        DailyHistoryData,
        BaseReferences<_$AppDatabase, $DailyHistoryTable, DailyHistoryData>,
      ),
      DailyHistoryData,
      PrefetchHooks Function()
    >;
typedef $$CustomTasksTableCreateCompanionBuilder =
    CustomTasksCompanion Function({
      Value<int> id,
      required String content,
      Value<bool> isCompleted,
      required DateTime createdAt,
      Value<int> position,
      Value<bool> isDeleted,
      Value<DateTime?> lastInteractedAt,
    });
typedef $$CustomTasksTableUpdateCompanionBuilder =
    CustomTasksCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<bool> isCompleted,
      Value<DateTime> createdAt,
      Value<int> position,
      Value<bool> isDeleted,
      Value<DateTime?> lastInteractedAt,
    });

class $$CustomTasksTableFilterComposer
    extends Composer<_$AppDatabase, $CustomTasksTable> {
  $$CustomTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomTasksTable> {
  $$CustomTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomTasksTable> {
  $$CustomTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => column,
  );
}

class $$CustomTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomTasksTable,
          CustomTask,
          $$CustomTasksTableFilterComposer,
          $$CustomTasksTableOrderingComposer,
          $$CustomTasksTableAnnotationComposer,
          $$CustomTasksTableCreateCompanionBuilder,
          $$CustomTasksTableUpdateCompanionBuilder,
          (
            CustomTask,
            BaseReferences<_$AppDatabase, $CustomTasksTable, CustomTask>,
          ),
          CustomTask,
          PrefetchHooks Function()
        > {
  $$CustomTasksTableTableManager(_$AppDatabase db, $CustomTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => CustomTasksCompanion(
                id: id,
                content: content,
                isCompleted: isCompleted,
                createdAt: createdAt,
                position: position,
                isDeleted: isDeleted,
                lastInteractedAt: lastInteractedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                Value<bool> isCompleted = const Value.absent(),
                required DateTime createdAt,
                Value<int> position = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => CustomTasksCompanion.insert(
                id: id,
                content: content,
                isCompleted: isCompleted,
                createdAt: createdAt,
                position: position,
                isDeleted: isDeleted,
                lastInteractedAt: lastInteractedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomTasksTable,
      CustomTask,
      $$CustomTasksTableFilterComposer,
      $$CustomTasksTableOrderingComposer,
      $$CustomTasksTableAnnotationComposer,
      $$CustomTasksTableCreateCompanionBuilder,
      $$CustomTasksTableUpdateCompanionBuilder,
      (
        CustomTask,
        BaseReferences<_$AppDatabase, $CustomTasksTable, CustomTask>,
      ),
      CustomTask,
      PrefetchHooks Function()
    >;
typedef $$SyllabusProgressLogsTableCreateCompanionBuilder =
    SyllabusProgressLogsCompanion Function({
      Value<int> id,
      required int categoryId,
      required int topicId,
      Value<int?> taskId,
      required int delta,
      required DateTime timestamp,
      Value<bool> isDeleted,
      Value<DateTime?> lastInteractedAt,
    });
typedef $$SyllabusProgressLogsTableUpdateCompanionBuilder =
    SyllabusProgressLogsCompanion Function({
      Value<int> id,
      Value<int> categoryId,
      Value<int> topicId,
      Value<int?> taskId,
      Value<int> delta,
      Value<DateTime> timestamp,
      Value<bool> isDeleted,
      Value<DateTime?> lastInteractedAt,
    });

final class $$SyllabusProgressLogsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SyllabusProgressLogsTable,
          SyllabusProgressLog
        > {
  $$SyllabusProgressLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyllabusCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.syllabusCategories.createAlias(
        'syllabus_progress_logs__category_id__syllabus_categories__id',
      );

  $$SyllabusCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$SyllabusCategoriesTableTableManager(
      $_db,
      $_db.syllabusCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SyllabusTopicsTable _topicIdTable(_$AppDatabase db) => db
      .syllabusTopics
      .createAlias('syllabus_progress_logs__topic_id__syllabus_topics__id');

  $$SyllabusTopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<int>('topic_id')!;

    final manager = $$SyllabusTopicsTableTableManager(
      $_db,
      $_db.syllabusTopics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SyllabusTasksTable _taskIdTable(_$AppDatabase db) => db.syllabusTasks
      .createAlias('syllabus_progress_logs__task_id__syllabus_tasks__id');

  $$SyllabusTasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<int>('task_id');
    if ($_column == null) return null;
    final manager = $$SyllabusTasksTableTableManager(
      $_db,
      $_db.syllabusTasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyllabusProgressLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SyllabusProgressLogsTable> {
  $$SyllabusProgressLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SyllabusCategoriesTableFilterComposer get categoryId {
    final $$SyllabusCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.syllabusCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.syllabusCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SyllabusTopicsTableFilterComposer get topicId {
    final $$SyllabusTopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableFilterComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SyllabusTasksTableFilterComposer get taskId {
    final $$SyllabusTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.syllabusTasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTasksTableFilterComposer(
            $db: $db,
            $table: $db.syllabusTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusProgressLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyllabusProgressLogsTable> {
  $$SyllabusProgressLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyllabusCategoriesTableOrderingComposer get categoryId {
    final $$SyllabusCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.syllabusCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.syllabusCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SyllabusTopicsTableOrderingComposer get topicId {
    final $$SyllabusTopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableOrderingComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SyllabusTasksTableOrderingComposer get taskId {
    final $$SyllabusTasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.syllabusTasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTasksTableOrderingComposer(
            $db: $db,
            $table: $db.syllabusTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusProgressLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyllabusProgressLogsTable> {
  $$SyllabusProgressLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => column,
  );

  $$SyllabusCategoriesTableAnnotationComposer get categoryId {
    final $$SyllabusCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.syllabusCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyllabusCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.syllabusCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$SyllabusTopicsTableAnnotationComposer get topicId {
    final $$SyllabusTopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SyllabusTasksTableAnnotationComposer get taskId {
    final $$SyllabusTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.syllabusTasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.syllabusTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusProgressLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyllabusProgressLogsTable,
          SyllabusProgressLog,
          $$SyllabusProgressLogsTableFilterComposer,
          $$SyllabusProgressLogsTableOrderingComposer,
          $$SyllabusProgressLogsTableAnnotationComposer,
          $$SyllabusProgressLogsTableCreateCompanionBuilder,
          $$SyllabusProgressLogsTableUpdateCompanionBuilder,
          (SyllabusProgressLog, $$SyllabusProgressLogsTableReferences),
          SyllabusProgressLog,
          PrefetchHooks Function({bool categoryId, bool topicId, bool taskId})
        > {
  $$SyllabusProgressLogsTableTableManager(
    _$AppDatabase db,
    $SyllabusProgressLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyllabusProgressLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyllabusProgressLogsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyllabusProgressLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> topicId = const Value.absent(),
                Value<int?> taskId = const Value.absent(),
                Value<int> delta = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => SyllabusProgressLogsCompanion(
                id: id,
                categoryId: categoryId,
                topicId: topicId,
                taskId: taskId,
                delta: delta,
                timestamp: timestamp,
                isDeleted: isDeleted,
                lastInteractedAt: lastInteractedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int categoryId,
                required int topicId,
                Value<int?> taskId = const Value.absent(),
                required int delta,
                required DateTime timestamp,
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => SyllabusProgressLogsCompanion.insert(
                id: id,
                categoryId: categoryId,
                topicId: topicId,
                taskId: taskId,
                delta: delta,
                timestamp: timestamp,
                isDeleted: isDeleted,
                lastInteractedAt: lastInteractedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyllabusProgressLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, topicId = false, taskId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$SyllabusProgressLogsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$SyllabusProgressLogsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (topicId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.topicId,
                                    referencedTable:
                                        $$SyllabusProgressLogsTableReferences
                                            ._topicIdTable(db),
                                    referencedColumn:
                                        $$SyllabusProgressLogsTableReferences
                                            ._topicIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (taskId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.taskId,
                                    referencedTable:
                                        $$SyllabusProgressLogsTableReferences
                                            ._taskIdTable(db),
                                    referencedColumn:
                                        $$SyllabusProgressLogsTableReferences
                                            ._taskIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$SyllabusProgressLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyllabusProgressLogsTable,
      SyllabusProgressLog,
      $$SyllabusProgressLogsTableFilterComposer,
      $$SyllabusProgressLogsTableOrderingComposer,
      $$SyllabusProgressLogsTableAnnotationComposer,
      $$SyllabusProgressLogsTableCreateCompanionBuilder,
      $$SyllabusProgressLogsTableUpdateCompanionBuilder,
      (SyllabusProgressLog, $$SyllabusProgressLogsTableReferences),
      SyllabusProgressLog,
      PrefetchHooks Function({bool categoryId, bool topicId, bool taskId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyllabusCategoriesTableTableManager get syllabusCategories =>
      $$SyllabusCategoriesTableTableManager(_db, _db.syllabusCategories);
  $$SyllabusTopicsTableTableManager get syllabusTopics =>
      $$SyllabusTopicsTableTableManager(_db, _db.syllabusTopics);
  $$SyllabusTasksTableTableManager get syllabusTasks =>
      $$SyllabusTasksTableTableManager(_db, _db.syllabusTasks);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
  $$DailyHistoryTableTableManager get dailyHistory =>
      $$DailyHistoryTableTableManager(_db, _db.dailyHistory);
  $$CustomTasksTableTableManager get customTasks =>
      $$CustomTasksTableTableManager(_db, _db.customTasks);
  $$SyllabusProgressLogsTableTableManager get syllabusProgressLogs =>
      $$SyllabusProgressLogsTableTableManager(_db, _db.syllabusProgressLogs);
}
