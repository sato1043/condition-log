// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DailyLogsTable extends DailyLogs
    with TableInfo<$DailyLogsTable, DailyLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    check: () => isDay(day),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overallMeta = const VerificationMeta(
    'overall',
  );
  @override
  late final GeneratedColumn<int> overall = GeneratedColumn<int>(
    'overall',
    aliasedName,
    true,
    check: () => isScore(overall),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _painMeta = const VerificationMeta('pain');
  @override
  late final GeneratedColumn<int> pain = GeneratedColumn<int>(
    'pain',
    aliasedName,
    true,
    check: () => isScore(pain),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatigueMeta = const VerificationMeta(
    'fatigue',
  );
  @override
  late final GeneratedColumn<int> fatigue = GeneratedColumn<int>(
    'fatigue',
    aliasedName,
    true,
    check: () => isScore(fatigue),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sleepMeta = const VerificationMeta('sleep');
  @override
  late final GeneratedColumn<int> sleep = GeneratedColumn<int>(
    'sleep',
    aliasedName,
    true,
    check: () => isScore(sleep),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appetiteMeta = const VerificationMeta(
    'appetite',
  );
  @override
  late final GeneratedColumn<int> appetite = GeneratedColumn<int>(
    'appetite',
    aliasedName,
    true,
    check: () => isScore(appetite),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    true,
    check: () => isScore(mood),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    overall,
    pain,
    fatigue,
    sleep,
    appetite,
    mood,
    memo,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('overall')) {
      context.handle(
        _overallMeta,
        overall.isAcceptableOrUnknown(data['overall']!, _overallMeta),
      );
    }
    if (data.containsKey('pain')) {
      context.handle(
        _painMeta,
        pain.isAcceptableOrUnknown(data['pain']!, _painMeta),
      );
    }
    if (data.containsKey('fatigue')) {
      context.handle(
        _fatigueMeta,
        fatigue.isAcceptableOrUnknown(data['fatigue']!, _fatigueMeta),
      );
    }
    if (data.containsKey('sleep')) {
      context.handle(
        _sleepMeta,
        sleep.isAcceptableOrUnknown(data['sleep']!, _sleepMeta),
      );
    }
    if (data.containsKey('appetite')) {
      context.handle(
        _appetiteMeta,
        appetite.isAcceptableOrUnknown(data['appetite']!, _appetiteMeta),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DailyLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyLogRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      overall: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall'],
      ),
      pain: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pain'],
      ),
      fatigue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fatigue'],
      ),
      sleep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep'],
      ),
      appetite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}appetite'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DailyLogsTable createAlias(String alias) {
    return $DailyLogsTable(attachedDatabase, alias);
  }
}

class DailyLogRow extends DataClass implements Insertable<DailyLogRow> {
  final String day;
  final int? overall;
  final int? pain;
  final int? fatigue;
  final int? sleep;
  final int? appetite;
  final int? mood;
  final String? memo;

  /// When the row was last written. Nothing reads it yet.
  final DateTime updatedAt;
  const DailyLogRow({
    required this.day,
    this.overall,
    this.pain,
    this.fatigue,
    this.sleep,
    this.appetite,
    this.mood,
    this.memo,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    if (!nullToAbsent || overall != null) {
      map['overall'] = Variable<int>(overall);
    }
    if (!nullToAbsent || pain != null) {
      map['pain'] = Variable<int>(pain);
    }
    if (!nullToAbsent || fatigue != null) {
      map['fatigue'] = Variable<int>(fatigue);
    }
    if (!nullToAbsent || sleep != null) {
      map['sleep'] = Variable<int>(sleep);
    }
    if (!nullToAbsent || appetite != null) {
      map['appetite'] = Variable<int>(appetite);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyLogsCompanion toCompanion(bool nullToAbsent) {
    return DailyLogsCompanion(
      day: Value(day),
      overall: overall == null && nullToAbsent
          ? const Value.absent()
          : Value(overall),
      pain: pain == null && nullToAbsent ? const Value.absent() : Value(pain),
      fatigue: fatigue == null && nullToAbsent
          ? const Value.absent()
          : Value(fatigue),
      sleep: sleep == null && nullToAbsent
          ? const Value.absent()
          : Value(sleep),
      appetite: appetite == null && nullToAbsent
          ? const Value.absent()
          : Value(appetite),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyLogRow(
      day: serializer.fromJson<String>(json['day']),
      overall: serializer.fromJson<int?>(json['overall']),
      pain: serializer.fromJson<int?>(json['pain']),
      fatigue: serializer.fromJson<int?>(json['fatigue']),
      sleep: serializer.fromJson<int?>(json['sleep']),
      appetite: serializer.fromJson<int?>(json['appetite']),
      mood: serializer.fromJson<int?>(json['mood']),
      memo: serializer.fromJson<String?>(json['memo']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'overall': serializer.toJson<int?>(overall),
      'pain': serializer.toJson<int?>(pain),
      'fatigue': serializer.toJson<int?>(fatigue),
      'sleep': serializer.toJson<int?>(sleep),
      'appetite': serializer.toJson<int?>(appetite),
      'mood': serializer.toJson<int?>(mood),
      'memo': serializer.toJson<String?>(memo),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyLogRow copyWith({
    String? day,
    Value<int?> overall = const Value.absent(),
    Value<int?> pain = const Value.absent(),
    Value<int?> fatigue = const Value.absent(),
    Value<int?> sleep = const Value.absent(),
    Value<int?> appetite = const Value.absent(),
    Value<int?> mood = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    DateTime? updatedAt,
  }) => DailyLogRow(
    day: day ?? this.day,
    overall: overall.present ? overall.value : this.overall,
    pain: pain.present ? pain.value : this.pain,
    fatigue: fatigue.present ? fatigue.value : this.fatigue,
    sleep: sleep.present ? sleep.value : this.sleep,
    appetite: appetite.present ? appetite.value : this.appetite,
    mood: mood.present ? mood.value : this.mood,
    memo: memo.present ? memo.value : this.memo,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyLogRow copyWithCompanion(DailyLogsCompanion data) {
    return DailyLogRow(
      day: data.day.present ? data.day.value : this.day,
      overall: data.overall.present ? data.overall.value : this.overall,
      pain: data.pain.present ? data.pain.value : this.pain,
      fatigue: data.fatigue.present ? data.fatigue.value : this.fatigue,
      sleep: data.sleep.present ? data.sleep.value : this.sleep,
      appetite: data.appetite.present ? data.appetite.value : this.appetite,
      mood: data.mood.present ? data.mood.value : this.mood,
      memo: data.memo.present ? data.memo.value : this.memo,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogRow(')
          ..write('day: $day, ')
          ..write('overall: $overall, ')
          ..write('pain: $pain, ')
          ..write('fatigue: $fatigue, ')
          ..write('sleep: $sleep, ')
          ..write('appetite: $appetite, ')
          ..write('mood: $mood, ')
          ..write('memo: $memo, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    day,
    overall,
    pain,
    fatigue,
    sleep,
    appetite,
    mood,
    memo,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyLogRow &&
          other.day == this.day &&
          other.overall == this.overall &&
          other.pain == this.pain &&
          other.fatigue == this.fatigue &&
          other.sleep == this.sleep &&
          other.appetite == this.appetite &&
          other.mood == this.mood &&
          other.memo == this.memo &&
          other.updatedAt == this.updatedAt);
}

class DailyLogsCompanion extends UpdateCompanion<DailyLogRow> {
  final Value<String> day;
  final Value<int?> overall;
  final Value<int?> pain;
  final Value<int?> fatigue;
  final Value<int?> sleep;
  final Value<int?> appetite;
  final Value<int?> mood;
  final Value<String?> memo;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyLogsCompanion({
    this.day = const Value.absent(),
    this.overall = const Value.absent(),
    this.pain = const Value.absent(),
    this.fatigue = const Value.absent(),
    this.sleep = const Value.absent(),
    this.appetite = const Value.absent(),
    this.mood = const Value.absent(),
    this.memo = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyLogsCompanion.insert({
    required String day,
    this.overall = const Value.absent(),
    this.pain = const Value.absent(),
    this.fatigue = const Value.absent(),
    this.sleep = const Value.absent(),
    this.appetite = const Value.absent(),
    this.mood = const Value.absent(),
    this.memo = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       updatedAt = Value(updatedAt);
  static Insertable<DailyLogRow> custom({
    Expression<String>? day,
    Expression<int>? overall,
    Expression<int>? pain,
    Expression<int>? fatigue,
    Expression<int>? sleep,
    Expression<int>? appetite,
    Expression<int>? mood,
    Expression<String>? memo,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (overall != null) 'overall': overall,
      if (pain != null) 'pain': pain,
      if (fatigue != null) 'fatigue': fatigue,
      if (sleep != null) 'sleep': sleep,
      if (appetite != null) 'appetite': appetite,
      if (mood != null) 'mood': mood,
      if (memo != null) 'memo': memo,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyLogsCompanion copyWith({
    Value<String>? day,
    Value<int?>? overall,
    Value<int?>? pain,
    Value<int?>? fatigue,
    Value<int?>? sleep,
    Value<int?>? appetite,
    Value<int?>? mood,
    Value<String?>? memo,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DailyLogsCompanion(
      day: day ?? this.day,
      overall: overall ?? this.overall,
      pain: pain ?? this.pain,
      fatigue: fatigue ?? this.fatigue,
      sleep: sleep ?? this.sleep,
      appetite: appetite ?? this.appetite,
      mood: mood ?? this.mood,
      memo: memo ?? this.memo,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (overall.present) {
      map['overall'] = Variable<int>(overall.value);
    }
    if (pain.present) {
      map['pain'] = Variable<int>(pain.value);
    }
    if (fatigue.present) {
      map['fatigue'] = Variable<int>(fatigue.value);
    }
    if (sleep.present) {
      map['sleep'] = Variable<int>(sleep.value);
    }
    if (appetite.present) {
      map['appetite'] = Variable<int>(appetite.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogsCompanion(')
          ..write('day: $day, ')
          ..write('overall: $overall, ')
          ..write('pain: $pain, ')
          ..write('fatigue: $fatigue, ')
          ..write('sleep: $sleep, ')
          ..write('appetite: $appetite, ')
          ..write('mood: $mood, ')
          ..write('memo: $memo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrecautionsTable extends Precautions
    with TableInfo<$PrecautionsTable, PrecautionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrecautionsTable(this.attachedDatabase, [this._alias]);
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
    check: () => isNamed(name),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PrecautionManner, String> manner =
      GeneratedColumn<String>(
        'manner',
        aliasedName,
        false,
        check: () =>
            manner.isIn([for (final m in PrecautionManner.values) m.name]),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PrecautionManner>($PrecautionsTable.$convertermanner);
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inUseMeta = const VerificationMeta('inUse');
  @override
  late final GeneratedColumn<bool> inUse = GeneratedColumn<bool>(
    'in_use',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_use" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, manner, sortOrder, inUse];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'precautions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrecautionRow> instance, {
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
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('in_use')) {
      context.handle(
        _inUseMeta,
        inUse.isAcceptableOrUnknown(data['in_use']!, _inUseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name, manner},
  ];
  @override
  PrecautionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrecautionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      manner: $PrecautionsTable.$convertermanner.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}manner'],
        )!,
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      inUse: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_use'],
      )!,
    );
  }

  @override
  $PrecautionsTable createAlias(String alias) {
    return $PrecautionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PrecautionManner, String, String> $convertermanner =
      const EnumNameConverter<PrecautionManner>(PrecautionManner.values);
}

class PrecautionRow extends DataClass implements Insertable<PrecautionRow> {
  final int id;

  /// Held to a name with more than spaces against any other writer; the
  /// repository takes names through the domain's rule (`nameOf`) already.
  final String name;

  /// Kept as the name of the value, and held to those names: a value renamed
  /// in the code no longer matches the exported schema.
  final PrecautionManner manner;
  final int sortOrder;
  final bool inUse;
  const PrecautionRow({
    required this.id,
    required this.name,
    required this.manner,
    required this.sortOrder,
    required this.inUse,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['manner'] = Variable<String>(
        $PrecautionsTable.$convertermanner.toSql(manner),
      );
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['in_use'] = Variable<bool>(inUse);
    return map;
  }

  PrecautionsCompanion toCompanion(bool nullToAbsent) {
    return PrecautionsCompanion(
      id: Value(id),
      name: Value(name),
      manner: Value(manner),
      sortOrder: Value(sortOrder),
      inUse: Value(inUse),
    );
  }

  factory PrecautionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrecautionRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      manner: $PrecautionsTable.$convertermanner.fromJson(
        serializer.fromJson<String>(json['manner']),
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      inUse: serializer.fromJson<bool>(json['inUse']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'manner': serializer.toJson<String>(
        $PrecautionsTable.$convertermanner.toJson(manner),
      ),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'inUse': serializer.toJson<bool>(inUse),
    };
  }

  PrecautionRow copyWith({
    int? id,
    String? name,
    PrecautionManner? manner,
    int? sortOrder,
    bool? inUse,
  }) => PrecautionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    manner: manner ?? this.manner,
    sortOrder: sortOrder ?? this.sortOrder,
    inUse: inUse ?? this.inUse,
  );
  PrecautionRow copyWithCompanion(PrecautionsCompanion data) {
    return PrecautionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      manner: data.manner.present ? data.manner.value : this.manner,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      inUse: data.inUse.present ? data.inUse.value : this.inUse,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrecautionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('manner: $manner, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('inUse: $inUse')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, manner, sortOrder, inUse);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrecautionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.manner == this.manner &&
          other.sortOrder == this.sortOrder &&
          other.inUse == this.inUse);
}

class PrecautionsCompanion extends UpdateCompanion<PrecautionRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<PrecautionManner> manner;
  final Value<int> sortOrder;
  final Value<bool> inUse;
  const PrecautionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.manner = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.inUse = const Value.absent(),
  });
  PrecautionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required PrecautionManner manner,
    required int sortOrder,
    this.inUse = const Value.absent(),
  }) : name = Value(name),
       manner = Value(manner),
       sortOrder = Value(sortOrder);
  static Insertable<PrecautionRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? manner,
    Expression<int>? sortOrder,
    Expression<bool>? inUse,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (manner != null) 'manner': manner,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (inUse != null) 'in_use': inUse,
    });
  }

  PrecautionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<PrecautionManner>? manner,
    Value<int>? sortOrder,
    Value<bool>? inUse,
  }) {
    return PrecautionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      manner: manner ?? this.manner,
      sortOrder: sortOrder ?? this.sortOrder,
      inUse: inUse ?? this.inUse,
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
    if (manner.present) {
      map['manner'] = Variable<String>(
        $PrecautionsTable.$convertermanner.toSql(manner.value),
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (inUse.present) {
      map['in_use'] = Variable<bool>(inUse.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrecautionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('manner: $manner, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('inUse: $inUse')
          ..write(')'))
        .toString();
  }
}

class $PrecautionMarksTable extends PrecautionMarks
    with TableInfo<$PrecautionMarksTable, PrecautionMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrecautionMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    check: () => isDay(day),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precautionIdMeta = const VerificationMeta(
    'precautionId',
  );
  @override
  late final GeneratedColumn<int> precautionId = GeneratedColumn<int>(
    'precaution_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES precautions (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [day, precautionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'precaution_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrecautionMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('precaution_id')) {
      context.handle(
        _precautionIdMeta,
        precautionId.isAcceptableOrUnknown(
          data['precaution_id']!,
          _precautionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precautionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day, precautionId};
  @override
  PrecautionMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrecautionMarkRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      precautionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precaution_id'],
      )!,
    );
  }

  @override
  $PrecautionMarksTable createAlias(String alias) {
    return $PrecautionMarksTable(attachedDatabase, alias);
  }
}

class PrecautionMarkRow extends DataClass
    implements Insertable<PrecautionMarkRow> {
  final String day;
  final int precautionId;
  const PrecautionMarkRow({required this.day, required this.precautionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['precaution_id'] = Variable<int>(precautionId);
    return map;
  }

  PrecautionMarksCompanion toCompanion(bool nullToAbsent) {
    return PrecautionMarksCompanion(
      day: Value(day),
      precautionId: Value(precautionId),
    );
  }

  factory PrecautionMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrecautionMarkRow(
      day: serializer.fromJson<String>(json['day']),
      precautionId: serializer.fromJson<int>(json['precautionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'precautionId': serializer.toJson<int>(precautionId),
    };
  }

  PrecautionMarkRow copyWith({String? day, int? precautionId}) =>
      PrecautionMarkRow(
        day: day ?? this.day,
        precautionId: precautionId ?? this.precautionId,
      );
  PrecautionMarkRow copyWithCompanion(PrecautionMarksCompanion data) {
    return PrecautionMarkRow(
      day: data.day.present ? data.day.value : this.day,
      precautionId: data.precautionId.present
          ? data.precautionId.value
          : this.precautionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrecautionMarkRow(')
          ..write('day: $day, ')
          ..write('precautionId: $precautionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, precautionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrecautionMarkRow &&
          other.day == this.day &&
          other.precautionId == this.precautionId);
}

class PrecautionMarksCompanion extends UpdateCompanion<PrecautionMarkRow> {
  final Value<String> day;
  final Value<int> precautionId;
  final Value<int> rowid;
  const PrecautionMarksCompanion({
    this.day = const Value.absent(),
    this.precautionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrecautionMarksCompanion.insert({
    required String day,
    required int precautionId,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       precautionId = Value(precautionId);
  static Insertable<PrecautionMarkRow> custom({
    Expression<String>? day,
    Expression<int>? precautionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (precautionId != null) 'precaution_id': precautionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrecautionMarksCompanion copyWith({
    Value<String>? day,
    Value<int>? precautionId,
    Value<int>? rowid,
  }) {
    return PrecautionMarksCompanion(
      day: day ?? this.day,
      precautionId: precautionId ?? this.precautionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (precautionId.present) {
      map['precaution_id'] = Variable<int>(precautionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrecautionMarksCompanion(')
          ..write('day: $day, ')
          ..write('precautionId: $precautionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) =>
      AppSettingRow(key: key ?? this.key, value: value ?? this.value);
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareProvidersTable extends CareProviders
    with TableInfo<$CareProvidersTable, CareProviderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareProvidersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _hospitalMeta = const VerificationMeta(
    'hospital',
  );
  @override
  late final GeneratedColumn<String> hospital = GeneratedColumn<String>(
    'hospital',
    aliasedName,
    true,
    check: () => isNoneOrNamed(hospital),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _departmentMeta = const VerificationMeta(
    'department',
  );
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
    'department',
    aliasedName,
    true,
    check: () => isNoneOrNamed(department),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doctorMeta = const VerificationMeta('doctor');
  @override
  late final GeneratedColumn<String> doctor = GeneratedColumn<String>(
    'doctor',
    aliasedName,
    true,
    check: () => isNoneOrNamed(doctor),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inUseMeta = const VerificationMeta('inUse');
  @override
  late final GeneratedColumn<bool> inUse = GeneratedColumn<bool>(
    'in_use',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_use" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hospital,
    department,
    doctor,
    inUse,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareProviderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('hospital')) {
      context.handle(
        _hospitalMeta,
        hospital.isAcceptableOrUnknown(data['hospital']!, _hospitalMeta),
      );
    }
    if (data.containsKey('department')) {
      context.handle(
        _departmentMeta,
        department.isAcceptableOrUnknown(data['department']!, _departmentMeta),
      );
    }
    if (data.containsKey('doctor')) {
      context.handle(
        _doctorMeta,
        doctor.isAcceptableOrUnknown(data['doctor']!, _doctorMeta),
      );
    }
    if (data.containsKey('in_use')) {
      context.handle(
        _inUseMeta,
        inUse.isAcceptableOrUnknown(data['in_use']!, _inUseMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareProviderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareProviderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      hospital: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hospital'],
      ),
      department: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department'],
      ),
      doctor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor'],
      ),
      inUse: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_use'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CareProvidersTable createAlias(String alias) {
    return $CareProvidersTable(attachedDatabase, alias);
  }
}

class CareProviderRow extends DataClass implements Insertable<CareProviderRow> {
  final int id;
  final String? hospital;
  final String? department;
  final String? doctor;
  final bool inUse;

  /// When the row was last written. Nothing reads it yet.
  final DateTime updatedAt;
  const CareProviderRow({
    required this.id,
    this.hospital,
    this.department,
    this.doctor,
    required this.inUse,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || hospital != null) {
      map['hospital'] = Variable<String>(hospital);
    }
    if (!nullToAbsent || department != null) {
      map['department'] = Variable<String>(department);
    }
    if (!nullToAbsent || doctor != null) {
      map['doctor'] = Variable<String>(doctor);
    }
    map['in_use'] = Variable<bool>(inUse);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CareProvidersCompanion toCompanion(bool nullToAbsent) {
    return CareProvidersCompanion(
      id: Value(id),
      hospital: hospital == null && nullToAbsent
          ? const Value.absent()
          : Value(hospital),
      department: department == null && nullToAbsent
          ? const Value.absent()
          : Value(department),
      doctor: doctor == null && nullToAbsent
          ? const Value.absent()
          : Value(doctor),
      inUse: Value(inUse),
      updatedAt: Value(updatedAt),
    );
  }

  factory CareProviderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareProviderRow(
      id: serializer.fromJson<int>(json['id']),
      hospital: serializer.fromJson<String?>(json['hospital']),
      department: serializer.fromJson<String?>(json['department']),
      doctor: serializer.fromJson<String?>(json['doctor']),
      inUse: serializer.fromJson<bool>(json['inUse']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'hospital': serializer.toJson<String?>(hospital),
      'department': serializer.toJson<String?>(department),
      'doctor': serializer.toJson<String?>(doctor),
      'inUse': serializer.toJson<bool>(inUse),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CareProviderRow copyWith({
    int? id,
    Value<String?> hospital = const Value.absent(),
    Value<String?> department = const Value.absent(),
    Value<String?> doctor = const Value.absent(),
    bool? inUse,
    DateTime? updatedAt,
  }) => CareProviderRow(
    id: id ?? this.id,
    hospital: hospital.present ? hospital.value : this.hospital,
    department: department.present ? department.value : this.department,
    doctor: doctor.present ? doctor.value : this.doctor,
    inUse: inUse ?? this.inUse,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CareProviderRow copyWithCompanion(CareProvidersCompanion data) {
    return CareProviderRow(
      id: data.id.present ? data.id.value : this.id,
      hospital: data.hospital.present ? data.hospital.value : this.hospital,
      department: data.department.present
          ? data.department.value
          : this.department,
      doctor: data.doctor.present ? data.doctor.value : this.doctor,
      inUse: data.inUse.present ? data.inUse.value : this.inUse,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareProviderRow(')
          ..write('id: $id, ')
          ..write('hospital: $hospital, ')
          ..write('department: $department, ')
          ..write('doctor: $doctor, ')
          ..write('inUse: $inUse, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hospital, department, doctor, inUse, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareProviderRow &&
          other.id == this.id &&
          other.hospital == this.hospital &&
          other.department == this.department &&
          other.doctor == this.doctor &&
          other.inUse == this.inUse &&
          other.updatedAt == this.updatedAt);
}

class CareProvidersCompanion extends UpdateCompanion<CareProviderRow> {
  final Value<int> id;
  final Value<String?> hospital;
  final Value<String?> department;
  final Value<String?> doctor;
  final Value<bool> inUse;
  final Value<DateTime> updatedAt;
  const CareProvidersCompanion({
    this.id = const Value.absent(),
    this.hospital = const Value.absent(),
    this.department = const Value.absent(),
    this.doctor = const Value.absent(),
    this.inUse = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CareProvidersCompanion.insert({
    this.id = const Value.absent(),
    this.hospital = const Value.absent(),
    this.department = const Value.absent(),
    this.doctor = const Value.absent(),
    this.inUse = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<CareProviderRow> custom({
    Expression<int>? id,
    Expression<String>? hospital,
    Expression<String>? department,
    Expression<String>? doctor,
    Expression<bool>? inUse,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hospital != null) 'hospital': hospital,
      if (department != null) 'department': department,
      if (doctor != null) 'doctor': doctor,
      if (inUse != null) 'in_use': inUse,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CareProvidersCompanion copyWith({
    Value<int>? id,
    Value<String?>? hospital,
    Value<String?>? department,
    Value<String?>? doctor,
    Value<bool>? inUse,
    Value<DateTime>? updatedAt,
  }) {
    return CareProvidersCompanion(
      id: id ?? this.id,
      hospital: hospital ?? this.hospital,
      department: department ?? this.department,
      doctor: doctor ?? this.doctor,
      inUse: inUse ?? this.inUse,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (hospital.present) {
      map['hospital'] = Variable<String>(hospital.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (doctor.present) {
      map['doctor'] = Variable<String>(doctor.value);
    }
    if (inUse.present) {
      map['in_use'] = Variable<bool>(inUse.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareProvidersCompanion(')
          ..write('id: $id, ')
          ..write('hospital: $hospital, ')
          ..write('department: $department, ')
          ..write('doctor: $doctor, ')
          ..write('inUse: $inUse, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, VisitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    check: () => isDay(day),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAskMeta = const VerificationMeta('toAsk');
  @override
  late final GeneratedColumn<String> toAsk = GeneratedColumn<String>(
    'to_ask',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heardMeta = const VerificationMeta('heard');
  @override
  late final GeneratedColumn<String> heard = GeneratedColumn<String>(
    'heard',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _careProviderIdMeta = const VerificationMeta(
    'careProviderId',
  );
  @override
  late final GeneratedColumn<int> careProviderId = GeneratedColumn<int>(
    'care_provider_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES care_providers (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    toAsk,
    heard,
    updatedAt,
    careProviderId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('to_ask')) {
      context.handle(
        _toAskMeta,
        toAsk.isAcceptableOrUnknown(data['to_ask']!, _toAskMeta),
      );
    }
    if (data.containsKey('heard')) {
      context.handle(
        _heardMeta,
        heard.isAcceptableOrUnknown(data['heard']!, _heardMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('care_provider_id')) {
      context.handle(
        _careProviderIdMeta,
        careProviderId.isAcceptableOrUnknown(
          data['care_provider_id']!,
          _careProviderIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      toAsk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_ask'],
      ),
      heard: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heard'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      careProviderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}care_provider_id'],
      ),
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class VisitRow extends DataClass implements Insertable<VisitRow> {
  final int id;
  final String day;

  /// What to ask the doctor, written before the visit.
  final String? toAsk;

  /// What was heard from the doctor, written after the visit.
  final String? heard;

  /// When the row was last written. Nothing reads it yet.
  final DateTime updatedAt;

  /// Where the visit was had; null when none was chosen. Care providers are
  /// never deleted, only taken out of use, so the reference has no rule for
  /// a deletion.
  final int? careProviderId;
  const VisitRow({
    required this.id,
    required this.day,
    this.toAsk,
    this.heard,
    required this.updatedAt,
    this.careProviderId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<String>(day);
    if (!nullToAbsent || toAsk != null) {
      map['to_ask'] = Variable<String>(toAsk);
    }
    if (!nullToAbsent || heard != null) {
      map['heard'] = Variable<String>(heard);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || careProviderId != null) {
      map['care_provider_id'] = Variable<int>(careProviderId);
    }
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      day: Value(day),
      toAsk: toAsk == null && nullToAbsent
          ? const Value.absent()
          : Value(toAsk),
      heard: heard == null && nullToAbsent
          ? const Value.absent()
          : Value(heard),
      updatedAt: Value(updatedAt),
      careProviderId: careProviderId == null && nullToAbsent
          ? const Value.absent()
          : Value(careProviderId),
    );
  }

  factory VisitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitRow(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      toAsk: serializer.fromJson<String?>(json['toAsk']),
      heard: serializer.fromJson<String?>(json['heard']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      careProviderId: serializer.fromJson<int?>(json['careProviderId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<String>(day),
      'toAsk': serializer.toJson<String?>(toAsk),
      'heard': serializer.toJson<String?>(heard),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'careProviderId': serializer.toJson<int?>(careProviderId),
    };
  }

  VisitRow copyWith({
    int? id,
    String? day,
    Value<String?> toAsk = const Value.absent(),
    Value<String?> heard = const Value.absent(),
    DateTime? updatedAt,
    Value<int?> careProviderId = const Value.absent(),
  }) => VisitRow(
    id: id ?? this.id,
    day: day ?? this.day,
    toAsk: toAsk.present ? toAsk.value : this.toAsk,
    heard: heard.present ? heard.value : this.heard,
    updatedAt: updatedAt ?? this.updatedAt,
    careProviderId: careProviderId.present
        ? careProviderId.value
        : this.careProviderId,
  );
  VisitRow copyWithCompanion(VisitsCompanion data) {
    return VisitRow(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      toAsk: data.toAsk.present ? data.toAsk.value : this.toAsk,
      heard: data.heard.present ? data.heard.value : this.heard,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      careProviderId: data.careProviderId.present
          ? data.careProviderId.value
          : this.careProviderId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitRow(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('toAsk: $toAsk, ')
          ..write('heard: $heard, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('careProviderId: $careProviderId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, day, toAsk, heard, updatedAt, careProviderId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitRow &&
          other.id == this.id &&
          other.day == this.day &&
          other.toAsk == this.toAsk &&
          other.heard == this.heard &&
          other.updatedAt == this.updatedAt &&
          other.careProviderId == this.careProviderId);
}

class VisitsCompanion extends UpdateCompanion<VisitRow> {
  final Value<int> id;
  final Value<String> day;
  final Value<String?> toAsk;
  final Value<String?> heard;
  final Value<DateTime> updatedAt;
  final Value<int?> careProviderId;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.toAsk = const Value.absent(),
    this.heard = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.careProviderId = const Value.absent(),
  });
  VisitsCompanion.insert({
    this.id = const Value.absent(),
    required String day,
    this.toAsk = const Value.absent(),
    this.heard = const Value.absent(),
    required DateTime updatedAt,
    this.careProviderId = const Value.absent(),
  }) : day = Value(day),
       updatedAt = Value(updatedAt);
  static Insertable<VisitRow> custom({
    Expression<int>? id,
    Expression<String>? day,
    Expression<String>? toAsk,
    Expression<String>? heard,
    Expression<DateTime>? updatedAt,
    Expression<int>? careProviderId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (toAsk != null) 'to_ask': toAsk,
      if (heard != null) 'heard': heard,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (careProviderId != null) 'care_provider_id': careProviderId,
    });
  }

  VisitsCompanion copyWith({
    Value<int>? id,
    Value<String>? day,
    Value<String?>? toAsk,
    Value<String?>? heard,
    Value<DateTime>? updatedAt,
    Value<int?>? careProviderId,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      toAsk: toAsk ?? this.toAsk,
      heard: heard ?? this.heard,
      updatedAt: updatedAt ?? this.updatedAt,
      careProviderId: careProviderId ?? this.careProviderId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (toAsk.present) {
      map['to_ask'] = Variable<String>(toAsk.value);
    }
    if (heard.present) {
      map['heard'] = Variable<String>(heard.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (careProviderId.present) {
      map['care_provider_id'] = Variable<int>(careProviderId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('toAsk: $toAsk, ')
          ..write('heard: $heard, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('careProviderId: $careProviderId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DailyLogsTable dailyLogs = $DailyLogsTable(this);
  late final $PrecautionsTable precautions = $PrecautionsTable(this);
  late final $PrecautionMarksTable precautionMarks = $PrecautionMarksTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $CareProvidersTable careProviders = $CareProvidersTable(this);
  late final $VisitsTable visits = $VisitsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dailyLogs,
    precautions,
    precautionMarks,
    appSettings,
    careProviders,
    visits,
  ];
}

typedef $$DailyLogsTableCreateCompanionBuilder = DailyLogsCompanion Function({
  required String day,
  Value<int?> overall,
  Value<int?> pain,
  Value<int?> fatigue,
  Value<int?> sleep,
  Value<int?> appetite,
  Value<int?> mood,
  Value<String?> memo,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DailyLogsTableUpdateCompanionBuilder = DailyLogsCompanion Function({
  Value<String> day,
  Value<int?> overall,
  Value<int?> pain,
  Value<int?> fatigue,
  Value<int?> sleep,
  Value<int?> appetite,
  Value<int?> mood,
  Value<String?> memo,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DailyLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overall => $composableBuilder(
    column: $table.overall,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pain => $composableBuilder(
    column: $table.pain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatigue => $composableBuilder(
    column: $table.fatigue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleep => $composableBuilder(
    column: $table.sleep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appetite => $composableBuilder(
    column: $table.appetite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overall => $composableBuilder(
    column: $table.overall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pain => $composableBuilder(
    column: $table.pain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatigue => $composableBuilder(
    column: $table.fatigue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleep => $composableBuilder(
    column: $table.sleep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appetite => $composableBuilder(
    column: $table.appetite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get overall =>
      $composableBuilder(column: $table.overall, builder: (column) => column);

  GeneratedColumn<int> get pain =>
      $composableBuilder(column: $table.pain, builder: (column) => column);

  GeneratedColumn<int> get fatigue =>
      $composableBuilder(column: $table.fatigue, builder: (column) => column);

  GeneratedColumn<int> get sleep =>
      $composableBuilder(column: $table.sleep, builder: (column) => column);

  GeneratedColumn<int> get appetite =>
      $composableBuilder(column: $table.appetite, builder: (column) => column);

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyLogsTable,
          DailyLogRow,
          $$DailyLogsTableFilterComposer,
          $$DailyLogsTableOrderingComposer,
          $$DailyLogsTableAnnotationComposer,
          $$DailyLogsTableCreateCompanionBuilder,
          $$DailyLogsTableUpdateCompanionBuilder,
          (
            DailyLogRow,
            BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLogRow>,
          ),
          DailyLogRow,
          PrefetchHooks Function()
        > {
  $$DailyLogsTableTableManager(_$AppDatabase db, $DailyLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<int?> overall = const Value.absent(),
                Value<int?> pain = const Value.absent(),
                Value<int?> fatigue = const Value.absent(),
                Value<int?> sleep = const Value.absent(),
                Value<int?> appetite = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyLogsCompanion(
                day: day,
                overall: overall,
                pain: pain,
                fatigue: fatigue,
                sleep: sleep,
                appetite: appetite,
                mood: mood,
                memo: memo,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                Value<int?> overall = const Value.absent(),
                Value<int?> pain = const Value.absent(),
                Value<int?> fatigue = const Value.absent(),
                Value<int?> sleep = const Value.absent(),
                Value<int?> appetite = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyLogsCompanion.insert(
                day: day,
                overall: overall,
                pain: pain,
                fatigue: fatigue,
                sleep: sleep,
                appetite: appetite,
                mood: mood,
                memo: memo,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyLogsTable, DailyLogRow>(table),
                  BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyLogsTable,
      DailyLogRow,
      $$DailyLogsTableFilterComposer,
      $$DailyLogsTableOrderingComposer,
      $$DailyLogsTableAnnotationComposer,
      $$DailyLogsTableCreateCompanionBuilder,
      $$DailyLogsTableUpdateCompanionBuilder,
      (
        DailyLogRow,
        BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLogRow>,
      ),
      DailyLogRow,
      PrefetchHooks Function()
    >;
typedef $$PrecautionsTableCreateCompanionBuilder =
    PrecautionsCompanion Function({
      Value<int> id,
      required String name,
      required PrecautionManner manner,
      required int sortOrder,
      Value<bool> inUse,
    });
typedef $$PrecautionsTableUpdateCompanionBuilder =
    PrecautionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<PrecautionManner> manner,
      Value<int> sortOrder,
      Value<bool> inUse,
    });

final class $$PrecautionsTableReferences
    extends BaseReferences<_$AppDatabase, $PrecautionsTable, PrecautionRow> {
  $$PrecautionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PrecautionMarksTable, List<PrecautionMarkRow>>
  _precautionMarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.precautionMarks,
    aliasName: 'precautions__id__precaution_marks__precaution_id',
  );

  $$PrecautionMarksTableProcessedTableManager get precautionMarksRefs {
    final manager = $$PrecautionMarksTableTableManager(
      $_db,
      $_db.precautionMarks,
    ).filter((f) => f.precautionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _precautionMarksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PrecautionsTableFilterComposer
    extends Composer<_$AppDatabase, $PrecautionsTable> {
  $$PrecautionsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<PrecautionManner, PrecautionManner, String>
  get manner => $composableBuilder(
    column: $table.manner,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inUse => $composableBuilder(
    column: $table.inUse,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> precautionMarksRefs(
    Expression<bool> Function($$PrecautionMarksTableFilterComposer f) f,
  ) {
    final $$PrecautionMarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.precautionMarks,
      getReferencedColumn: (t) => t.precautionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrecautionMarksTableFilterComposer(
            $db: $db,
            $table: $db.precautionMarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrecautionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrecautionsTable> {
  $$PrecautionsTableOrderingComposer({
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

  ColumnOrderings<String> get manner => $composableBuilder(
    column: $table.manner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inUse => $composableBuilder(
    column: $table.inUse,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrecautionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrecautionsTable> {
  $$PrecautionsTableAnnotationComposer({
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

  GeneratedColumnWithTypeConverter<PrecautionManner, String> get manner =>
      $composableBuilder(column: $table.manner, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get inUse =>
      $composableBuilder(column: $table.inUse, builder: (column) => column);

  Expression<T> precautionMarksRefs<T extends Object>(
    Expression<T> Function($$PrecautionMarksTableAnnotationComposer a) f,
  ) {
    final $$PrecautionMarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.precautionMarks,
      getReferencedColumn: (t) => t.precautionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrecautionMarksTableAnnotationComposer(
            $db: $db,
            $table: $db.precautionMarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrecautionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrecautionsTable,
          PrecautionRow,
          $$PrecautionsTableFilterComposer,
          $$PrecautionsTableOrderingComposer,
          $$PrecautionsTableAnnotationComposer,
          $$PrecautionsTableCreateCompanionBuilder,
          $$PrecautionsTableUpdateCompanionBuilder,
          (PrecautionRow, $$PrecautionsTableReferences),
          PrecautionRow,
          PrefetchHooks Function({bool precautionMarksRefs})
        > {
  $$PrecautionsTableTableManager(_$AppDatabase db, $PrecautionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrecautionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrecautionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrecautionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<PrecautionManner> manner = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> inUse = const Value.absent(),
              }) => PrecautionsCompanion(
                id: id,
                name: name,
                manner: manner,
                sortOrder: sortOrder,
                inUse: inUse,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required PrecautionManner manner,
                required int sortOrder,
                Value<bool> inUse = const Value.absent(),
              }) => PrecautionsCompanion.insert(
                id: id,
                name: name,
                manner: manner,
                sortOrder: sortOrder,
                inUse: inUse,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrecautionsTable, PrecautionRow>(table),
                  $$PrecautionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({precautionMarksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (precautionMarksRefs) db.precautionMarks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (precautionMarksRefs)
                    await $_getPrefetchedData<
                      PrecautionRow,
                      $PrecautionsTable,
                      PrecautionMarkRow
                    >(
                      currentTable: table,
                      referencedTable: $$PrecautionsTableReferences
                          ._precautionMarksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PrecautionsTableReferences(
                            db,
                            table,
                            p0,
                          ).precautionMarksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.precautionId == item.id,
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

typedef $$PrecautionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrecautionsTable,
      PrecautionRow,
      $$PrecautionsTableFilterComposer,
      $$PrecautionsTableOrderingComposer,
      $$PrecautionsTableAnnotationComposer,
      $$PrecautionsTableCreateCompanionBuilder,
      $$PrecautionsTableUpdateCompanionBuilder,
      (PrecautionRow, $$PrecautionsTableReferences),
      PrecautionRow,
      PrefetchHooks Function({bool precautionMarksRefs})
    >;
typedef $$PrecautionMarksTableCreateCompanionBuilder =
    PrecautionMarksCompanion Function({
      required String day,
      required int precautionId,
      Value<int> rowid,
    });
typedef $$PrecautionMarksTableUpdateCompanionBuilder =
    PrecautionMarksCompanion Function({
      Value<String> day,
      Value<int> precautionId,
      Value<int> rowid,
    });

final class $$PrecautionMarksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PrecautionMarksTable,
          PrecautionMarkRow
        > {
  $$PrecautionMarksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PrecautionsTable _precautionIdTable(_$AppDatabase db) => db
      .precautions
      .createAlias('precaution_marks__precaution_id__precautions__id');

  $$PrecautionsTableProcessedTableManager get precautionId {
    final $_column = $_itemColumn<int>('precaution_id')!;

    final manager = $$PrecautionsTableTableManager(
      $_db,
      $_db.precautions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_precautionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PrecautionMarksTableFilterComposer
    extends Composer<_$AppDatabase, $PrecautionMarksTable> {
  $$PrecautionMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  $$PrecautionsTableFilterComposer get precautionId {
    final $$PrecautionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.precautionId,
      referencedTable: $db.precautions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrecautionsTableFilterComposer(
            $db: $db,
            $table: $db.precautions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrecautionMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $PrecautionMarksTable> {
  $$PrecautionMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  $$PrecautionsTableOrderingComposer get precautionId {
    final $$PrecautionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.precautionId,
      referencedTable: $db.precautions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrecautionsTableOrderingComposer(
            $db: $db,
            $table: $db.precautions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrecautionMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrecautionMarksTable> {
  $$PrecautionMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  $$PrecautionsTableAnnotationComposer get precautionId {
    final $$PrecautionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.precautionId,
      referencedTable: $db.precautions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrecautionsTableAnnotationComposer(
            $db: $db,
            $table: $db.precautions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrecautionMarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrecautionMarksTable,
          PrecautionMarkRow,
          $$PrecautionMarksTableFilterComposer,
          $$PrecautionMarksTableOrderingComposer,
          $$PrecautionMarksTableAnnotationComposer,
          $$PrecautionMarksTableCreateCompanionBuilder,
          $$PrecautionMarksTableUpdateCompanionBuilder,
          (PrecautionMarkRow, $$PrecautionMarksTableReferences),
          PrecautionMarkRow,
          PrefetchHooks Function({bool precautionId})
        > {
  $$PrecautionMarksTableTableManager(
    _$AppDatabase db,
    $PrecautionMarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrecautionMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrecautionMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrecautionMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<int> precautionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrecautionMarksCompanion(
                day: day,
                precautionId: precautionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required int precautionId,
                Value<int> rowid = const Value.absent(),
              }) => PrecautionMarksCompanion.insert(
                day: day,
                precautionId: precautionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrecautionMarksTable, PrecautionMarkRow>(table),
                  $$PrecautionMarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({precautionId = false}) {
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
                    if (precautionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.precautionId,
                        referencedTable: $$PrecautionMarksTableReferences
                            ._precautionIdTable(db),
                        referencedColumn: $$PrecautionMarksTableReferences
                            ._precautionIdTable(db)
                            .id,
                      ) as T;
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

typedef $$PrecautionMarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrecautionMarksTable,
      PrecautionMarkRow,
      $$PrecautionMarksTableFilterComposer,
      $$PrecautionMarksTableOrderingComposer,
      $$PrecautionMarksTableAnnotationComposer,
      $$PrecautionMarksTableCreateCompanionBuilder,
      $$PrecautionMarksTableUpdateCompanionBuilder,
      (PrecautionMarkRow, $$PrecautionMarksTableReferences),
      PrecautionMarkRow,
      PrefetchHooks Function({bool precautionId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $$CareProvidersTableCreateCompanionBuilder =
    CareProvidersCompanion Function({
      Value<int> id,
      Value<String?> hospital,
      Value<String?> department,
      Value<String?> doctor,
      Value<bool> inUse,
      required DateTime updatedAt,
    });
typedef $$CareProvidersTableUpdateCompanionBuilder =
    CareProvidersCompanion Function({
      Value<int> id,
      Value<String?> hospital,
      Value<String?> department,
      Value<String?> doctor,
      Value<bool> inUse,
      Value<DateTime> updatedAt,
    });

final class $$CareProvidersTableReferences
    extends
        BaseReferences<_$AppDatabase, $CareProvidersTable, CareProviderRow> {
  $$CareProvidersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$VisitsTable, List<VisitRow>> _visitsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.visits,
    aliasName: 'care_providers__id__visits__care_provider_id',
  );

  $$VisitsTableProcessedTableManager get visitsRefs {
    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.careProviderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CareProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $CareProvidersTable> {
  $$CareProvidersTableFilterComposer({
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

  ColumnFilters<String> get hospital => $composableBuilder(
    column: $table.hospital,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doctor => $composableBuilder(
    column: $table.doctor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inUse => $composableBuilder(
    column: $table.inUse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> visitsRefs(
    Expression<bool> Function($$VisitsTableFilterComposer f) f,
  ) {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.careProviderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CareProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $CareProvidersTable> {
  $$CareProvidersTableOrderingComposer({
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

  ColumnOrderings<String> get hospital => $composableBuilder(
    column: $table.hospital,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doctor => $composableBuilder(
    column: $table.doctor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inUse => $composableBuilder(
    column: $table.inUse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareProvidersTable> {
  $$CareProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hospital =>
      $composableBuilder(column: $table.hospital, builder: (column) => column);

  GeneratedColumn<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doctor =>
      $composableBuilder(column: $table.doctor, builder: (column) => column);

  GeneratedColumn<bool> get inUse =>
      $composableBuilder(column: $table.inUse, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> visitsRefs<T extends Object>(
    Expression<T> Function($$VisitsTableAnnotationComposer a) f,
  ) {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.careProviderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CareProvidersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareProvidersTable,
          CareProviderRow,
          $$CareProvidersTableFilterComposer,
          $$CareProvidersTableOrderingComposer,
          $$CareProvidersTableAnnotationComposer,
          $$CareProvidersTableCreateCompanionBuilder,
          $$CareProvidersTableUpdateCompanionBuilder,
          (CareProviderRow, $$CareProvidersTableReferences),
          CareProviderRow,
          PrefetchHooks Function({bool visitsRefs})
        > {
  $$CareProvidersTableTableManager(_$AppDatabase db, $CareProvidersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> hospital = const Value.absent(),
                Value<String?> department = const Value.absent(),
                Value<String?> doctor = const Value.absent(),
                Value<bool> inUse = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CareProvidersCompanion(
                id: id,
                hospital: hospital,
                department: department,
                doctor: doctor,
                inUse: inUse,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> hospital = const Value.absent(),
                Value<String?> department = const Value.absent(),
                Value<String?> doctor = const Value.absent(),
                Value<bool> inUse = const Value.absent(),
                required DateTime updatedAt,
              }) => CareProvidersCompanion.insert(
                id: id,
                hospital: hospital,
                department: department,
                doctor: doctor,
                inUse: inUse,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareProvidersTable, CareProviderRow>(table),
                  $$CareProvidersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (visitsRefs) db.visits],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (visitsRefs)
                    await $_getPrefetchedData<
                      CareProviderRow,
                      $CareProvidersTable,
                      VisitRow
                    >(
                      currentTable: table,
                      referencedTable: $$CareProvidersTableReferences
                          ._visitsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CareProvidersTableReferences(
                            db,
                            table,
                            p0,
                          ).visitsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.careProviderId == item.id,
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

typedef $$CareProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareProvidersTable,
      CareProviderRow,
      $$CareProvidersTableFilterComposer,
      $$CareProvidersTableOrderingComposer,
      $$CareProvidersTableAnnotationComposer,
      $$CareProvidersTableCreateCompanionBuilder,
      $$CareProvidersTableUpdateCompanionBuilder,
      (CareProviderRow, $$CareProvidersTableReferences),
      CareProviderRow,
      PrefetchHooks Function({bool visitsRefs})
    >;
typedef $$VisitsTableCreateCompanionBuilder = VisitsCompanion Function({
  Value<int> id,
  required String day,
  Value<String?> toAsk,
  Value<String?> heard,
  required DateTime updatedAt,
  Value<int?> careProviderId,
});
typedef $$VisitsTableUpdateCompanionBuilder = VisitsCompanion Function({
  Value<int> id,
  Value<String> day,
  Value<String?> toAsk,
  Value<String?> heard,
  Value<DateTime> updatedAt,
  Value<int?> careProviderId,
});

final class $$VisitsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitsTable, VisitRow> {
  $$VisitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CareProvidersTable _careProviderIdTable(_$AppDatabase db) => db
      .careProviders
      .createAlias('visits__care_provider_id__care_providers__id');

  $$CareProvidersTableProcessedTableManager? get careProviderId {
    final $_column = $_itemColumn<int>('care_provider_id');
    if ($_column == null) return null;
    final manager = $$CareProvidersTableTableManager(
      $_db,
      $_db.careProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_careProviderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
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

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAsk => $composableBuilder(
    column: $table.toAsk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heard => $composableBuilder(
    column: $table.heard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CareProvidersTableFilterComposer get careProviderId {
    final $$CareProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.careProviderId,
      referencedTable: $db.careProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CareProvidersTableFilterComposer(
            $db: $db,
            $table: $db.careProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
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

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAsk => $composableBuilder(
    column: $table.toAsk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heard => $composableBuilder(
    column: $table.heard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CareProvidersTableOrderingComposer get careProviderId {
    final $$CareProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.careProviderId,
      referencedTable: $db.careProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CareProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.careProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get toAsk =>
      $composableBuilder(column: $table.toAsk, builder: (column) => column);

  GeneratedColumn<String> get heard =>
      $composableBuilder(column: $table.heard, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CareProvidersTableAnnotationComposer get careProviderId {
    final $$CareProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.careProviderId,
      referencedTable: $db.careProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CareProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.careProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTable,
          VisitRow,
          $$VisitsTableFilterComposer,
          $$VisitsTableOrderingComposer,
          $$VisitsTableAnnotationComposer,
          $$VisitsTableCreateCompanionBuilder,
          $$VisitsTableUpdateCompanionBuilder,
          (VisitRow, $$VisitsTableReferences),
          VisitRow,
          PrefetchHooks Function({bool careProviderId})
        > {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String?> toAsk = const Value.absent(),
                Value<String?> heard = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int?> careProviderId = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                day: day,
                toAsk: toAsk,
                heard: heard,
                updatedAt: updatedAt,
                careProviderId: careProviderId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String day,
                Value<String?> toAsk = const Value.absent(),
                Value<String?> heard = const Value.absent(),
                required DateTime updatedAt,
                Value<int?> careProviderId = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                day: day,
                toAsk: toAsk,
                heard: heard,
                updatedAt: updatedAt,
                careProviderId: careProviderId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VisitsTable, VisitRow>(table),
                  $$VisitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({careProviderId = false}) {
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
                    if (careProviderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.careProviderId,
                        referencedTable: $$VisitsTableReferences
                            ._careProviderIdTable(db),
                        referencedColumn: $$VisitsTableReferences
                            ._careProviderIdTable(db)
                            .id,
                      ) as T;
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

typedef $$VisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTable,
      VisitRow,
      $$VisitsTableFilterComposer,
      $$VisitsTableOrderingComposer,
      $$VisitsTableAnnotationComposer,
      $$VisitsTableCreateCompanionBuilder,
      $$VisitsTableUpdateCompanionBuilder,
      (VisitRow, $$VisitsTableReferences),
      VisitRow,
      PrefetchHooks Function({bool careProviderId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DailyLogsTableTableManager get dailyLogs =>
      $$DailyLogsTableTableManager(_db, _db.dailyLogs);
  $$PrecautionsTableTableManager get precautions =>
      $$PrecautionsTableTableManager(_db, _db.precautions);
  $$PrecautionMarksTableTableManager get precautionMarks =>
      $$PrecautionMarksTableTableManager(_db, _db.precautionMarks);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$CareProvidersTableTableManager get careProviders =>
      $$CareProvidersTableTableManager(_db, _db.careProviders);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
}
