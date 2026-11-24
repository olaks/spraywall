// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WallsTable extends Walls with TableInfo<$WallsTable, Wall> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WallsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GradeScale, int> gradeScale =
      GeneratedColumn<int>(
        'grade_scale',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<GradeScale>($WallsTable.$convertergradeScale);
  static const VerificationMeta _createdOnMeta = const VerificationMeta(
    'createdOn',
  );
  @override
  late final GeneratedColumn<String> createdOn = GeneratedColumn<String>(
    'created_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    gradeScale,
    createdOn,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'walls';
  @override
  VerificationContext validateIntegrity(
    Insertable<Wall> instance, {
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
    if (data.containsKey('created_on')) {
      context.handle(
        _createdOnMeta,
        createdOn.isAcceptableOrUnknown(data['created_on']!, _createdOnMeta),
      );
    } else if (isInserting) {
      context.missing(_createdOnMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Wall map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Wall(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gradeScale: $WallsTable.$convertergradeScale.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}grade_scale'],
        )!,
      ),
      createdOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_on'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WallsTable createAlias(String alias) {
    return $WallsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GradeScale, int, int> $convertergradeScale =
      const EnumIndexConverter<GradeScale>(GradeScale.values);
}

class Wall extends DataClass implements Insertable<Wall> {
  final String id;
  final String name;
  final GradeScale gradeScale;
  final String createdOn;
  final int sortOrder;
  const Wall({
    required this.id,
    required this.name,
    required this.gradeScale,
    required this.createdOn,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['grade_scale'] = Variable<int>(
        $WallsTable.$convertergradeScale.toSql(gradeScale),
      );
    }
    map['created_on'] = Variable<String>(createdOn);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WallsCompanion toCompanion(bool nullToAbsent) {
    return WallsCompanion(
      id: Value(id),
      name: Value(name),
      gradeScale: Value(gradeScale),
      createdOn: Value(createdOn),
      sortOrder: Value(sortOrder),
    );
  }

  factory Wall.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Wall(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gradeScale: $WallsTable.$convertergradeScale.fromJson(
        serializer.fromJson<int>(json['gradeScale']),
      ),
      createdOn: serializer.fromJson<String>(json['createdOn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'gradeScale': serializer.toJson<int>(
        $WallsTable.$convertergradeScale.toJson(gradeScale),
      ),
      'createdOn': serializer.toJson<String>(createdOn),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Wall copyWith({
    String? id,
    String? name,
    GradeScale? gradeScale,
    String? createdOn,
    int? sortOrder,
  }) => Wall(
    id: id ?? this.id,
    name: name ?? this.name,
    gradeScale: gradeScale ?? this.gradeScale,
    createdOn: createdOn ?? this.createdOn,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Wall copyWithCompanion(WallsCompanion data) {
    return Wall(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gradeScale: data.gradeScale.present
          ? data.gradeScale.value
          : this.gradeScale,
      createdOn: data.createdOn.present ? data.createdOn.value : this.createdOn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Wall(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gradeScale: $gradeScale, ')
          ..write('createdOn: $createdOn, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, gradeScale, createdOn, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wall &&
          other.id == this.id &&
          other.name == this.name &&
          other.gradeScale == this.gradeScale &&
          other.createdOn == this.createdOn &&
          other.sortOrder == this.sortOrder);
}

class WallsCompanion extends UpdateCompanion<Wall> {
  final Value<String> id;
  final Value<String> name;
  final Value<GradeScale> gradeScale;
  final Value<String> createdOn;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WallsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gradeScale = const Value.absent(),
    this.createdOn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WallsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required GradeScale gradeScale,
    required String createdOn,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       gradeScale = Value(gradeScale),
       createdOn = Value(createdOn),
       sortOrder = Value(sortOrder);
  static Insertable<Wall> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? gradeScale,
    Expression<String>? createdOn,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gradeScale != null) 'grade_scale': gradeScale,
      if (createdOn != null) 'created_on': createdOn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WallsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<GradeScale>? gradeScale,
    Value<String>? createdOn,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WallsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gradeScale: gradeScale ?? this.gradeScale,
      createdOn: createdOn ?? this.createdOn,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gradeScale.present) {
      map['grade_scale'] = Variable<int>(
        $WallsTable.$convertergradeScale.toSql(gradeScale.value),
      );
    }
    if (createdOn.present) {
      map['created_on'] = Variable<String>(createdOn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WallsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gradeScale: $gradeScale, ')
          ..write('createdOn: $createdOn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LayoutsTable extends Layouts with TableInfo<$LayoutsTable, Layout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LayoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _wallIdMeta = const VerificationMeta('wallId');
  @override
  late final GeneratedColumn<String> wallId = GeneratedColumn<String>(
    'wall_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES walls (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedOnMeta = const VerificationMeta(
    'startedOn',
  );
  @override
  late final GeneratedColumn<String> startedOn = GeneratedColumn<String>(
    'started_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedOnMeta = const VerificationMeta(
    'endedOn',
  );
  @override
  late final GeneratedColumn<String> endedOn = GeneratedColumn<String>(
    'ended_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, wallId, name, startedOn, endedOn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'layouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Layout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wall_id')) {
      context.handle(
        _wallIdMeta,
        wallId.isAcceptableOrUnknown(data['wall_id']!, _wallIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wallIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('started_on')) {
      context.handle(
        _startedOnMeta,
        startedOn.isAcceptableOrUnknown(data['started_on']!, _startedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_startedOnMeta);
    }
    if (data.containsKey('ended_on')) {
      context.handle(
        _endedOnMeta,
        endedOn.isAcceptableOrUnknown(data['ended_on']!, _endedOnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Layout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Layout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      wallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wall_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      startedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_on'],
      )!,
      endedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ended_on'],
      ),
    );
  }

  @override
  $LayoutsTable createAlias(String alias) {
    return $LayoutsTable(attachedDatabase, alias);
  }
}

class Layout extends DataClass implements Insertable<Layout> {
  final String id;
  final String wallId;
  final String? name;
  final String startedOn;
  final String? endedOn;
  const Layout({
    required this.id,
    required this.wallId,
    this.name,
    required this.startedOn,
    this.endedOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['wall_id'] = Variable<String>(wallId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['started_on'] = Variable<String>(startedOn);
    if (!nullToAbsent || endedOn != null) {
      map['ended_on'] = Variable<String>(endedOn);
    }
    return map;
  }

  LayoutsCompanion toCompanion(bool nullToAbsent) {
    return LayoutsCompanion(
      id: Value(id),
      wallId: Value(wallId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      startedOn: Value(startedOn),
      endedOn: endedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(endedOn),
    );
  }

  factory Layout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Layout(
      id: serializer.fromJson<String>(json['id']),
      wallId: serializer.fromJson<String>(json['wallId']),
      name: serializer.fromJson<String?>(json['name']),
      startedOn: serializer.fromJson<String>(json['startedOn']),
      endedOn: serializer.fromJson<String?>(json['endedOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wallId': serializer.toJson<String>(wallId),
      'name': serializer.toJson<String?>(name),
      'startedOn': serializer.toJson<String>(startedOn),
      'endedOn': serializer.toJson<String?>(endedOn),
    };
  }

  Layout copyWith({
    String? id,
    String? wallId,
    Value<String?> name = const Value.absent(),
    String? startedOn,
    Value<String?> endedOn = const Value.absent(),
  }) => Layout(
    id: id ?? this.id,
    wallId: wallId ?? this.wallId,
    name: name.present ? name.value : this.name,
    startedOn: startedOn ?? this.startedOn,
    endedOn: endedOn.present ? endedOn.value : this.endedOn,
  );
  Layout copyWithCompanion(LayoutsCompanion data) {
    return Layout(
      id: data.id.present ? data.id.value : this.id,
      wallId: data.wallId.present ? data.wallId.value : this.wallId,
      name: data.name.present ? data.name.value : this.name,
      startedOn: data.startedOn.present ? data.startedOn.value : this.startedOn,
      endedOn: data.endedOn.present ? data.endedOn.value : this.endedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Layout(')
          ..write('id: $id, ')
          ..write('wallId: $wallId, ')
          ..write('name: $name, ')
          ..write('startedOn: $startedOn, ')
          ..write('endedOn: $endedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wallId, name, startedOn, endedOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Layout &&
          other.id == this.id &&
          other.wallId == this.wallId &&
          other.name == this.name &&
          other.startedOn == this.startedOn &&
          other.endedOn == this.endedOn);
}

class LayoutsCompanion extends UpdateCompanion<Layout> {
  final Value<String> id;
  final Value<String> wallId;
  final Value<String?> name;
  final Value<String> startedOn;
  final Value<String?> endedOn;
  final Value<int> rowid;
  const LayoutsCompanion({
    this.id = const Value.absent(),
    this.wallId = const Value.absent(),
    this.name = const Value.absent(),
    this.startedOn = const Value.absent(),
    this.endedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LayoutsCompanion.insert({
    this.id = const Value.absent(),
    required String wallId,
    this.name = const Value.absent(),
    required String startedOn,
    this.endedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : wallId = Value(wallId),
       startedOn = Value(startedOn);
  static Insertable<Layout> custom({
    Expression<String>? id,
    Expression<String>? wallId,
    Expression<String>? name,
    Expression<String>? startedOn,
    Expression<String>? endedOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wallId != null) 'wall_id': wallId,
      if (name != null) 'name': name,
      if (startedOn != null) 'started_on': startedOn,
      if (endedOn != null) 'ended_on': endedOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LayoutsCompanion copyWith({
    Value<String>? id,
    Value<String>? wallId,
    Value<String?>? name,
    Value<String>? startedOn,
    Value<String?>? endedOn,
    Value<int>? rowid,
  }) {
    return LayoutsCompanion(
      id: id ?? this.id,
      wallId: wallId ?? this.wallId,
      name: name ?? this.name,
      startedOn: startedOn ?? this.startedOn,
      endedOn: endedOn ?? this.endedOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wallId.present) {
      map['wall_id'] = Variable<String>(wallId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startedOn.present) {
      map['started_on'] = Variable<String>(startedOn.value);
    }
    if (endedOn.present) {
      map['ended_on'] = Variable<String>(endedOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LayoutsCompanion(')
          ..write('id: $id, ')
          ..write('wallId: $wallId, ')
          ..write('name: $name, ')
          ..write('startedOn: $startedOn, ')
          ..write('endedOn: $endedOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WallPhotosTable extends WallPhotos
    with TableInfo<$WallPhotosTable, WallPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WallPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _layoutIdMeta = const VerificationMeta(
    'layoutId',
  );
  @override
  late final GeneratedColumn<String> layoutId = GeneratedColumn<String>(
    'layout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES layouts (id)',
    ),
  );
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
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedOnMeta = const VerificationMeta(
    'addedOn',
  );
  @override
  late final GeneratedColumn<String> addedOn = GeneratedColumn<String>(
    'added_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    layoutId,
    sortOrder,
    width,
    height,
    addedOn,
    label,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wall_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<WallPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('layout_id')) {
      context.handle(
        _layoutIdMeta,
        layoutId.isAcceptableOrUnknown(data['layout_id']!, _layoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('added_on')) {
      context.handle(
        _addedOnMeta,
        addedOn.isAcceptableOrUnknown(data['added_on']!, _addedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_addedOnMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WallPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WallPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      layoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      addedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_on'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
    );
  }

  @override
  $WallPhotosTable createAlias(String alias) {
    return $WallPhotosTable(attachedDatabase, alias);
  }
}

class WallPhoto extends DataClass implements Insertable<WallPhoto> {
  final String id;
  final String layoutId;
  final int sortOrder;
  final int width;
  final int height;
  final String addedOn;
  final String? label;
  const WallPhoto({
    required this.id,
    required this.layoutId,
    required this.sortOrder,
    required this.width,
    required this.height,
    required this.addedOn,
    this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['layout_id'] = Variable<String>(layoutId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['added_on'] = Variable<String>(addedOn);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  WallPhotosCompanion toCompanion(bool nullToAbsent) {
    return WallPhotosCompanion(
      id: Value(id),
      layoutId: Value(layoutId),
      sortOrder: Value(sortOrder),
      width: Value(width),
      height: Value(height),
      addedOn: Value(addedOn),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
    );
  }

  factory WallPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WallPhoto(
      id: serializer.fromJson<String>(json['id']),
      layoutId: serializer.fromJson<String>(json['layoutId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      addedOn: serializer.fromJson<String>(json['addedOn']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'layoutId': serializer.toJson<String>(layoutId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'addedOn': serializer.toJson<String>(addedOn),
      'label': serializer.toJson<String?>(label),
    };
  }

  WallPhoto copyWith({
    String? id,
    String? layoutId,
    int? sortOrder,
    int? width,
    int? height,
    String? addedOn,
    Value<String?> label = const Value.absent(),
  }) => WallPhoto(
    id: id ?? this.id,
    layoutId: layoutId ?? this.layoutId,
    sortOrder: sortOrder ?? this.sortOrder,
    width: width ?? this.width,
    height: height ?? this.height,
    addedOn: addedOn ?? this.addedOn,
    label: label.present ? label.value : this.label,
  );
  WallPhoto copyWithCompanion(WallPhotosCompanion data) {
    return WallPhoto(
      id: data.id.present ? data.id.value : this.id,
      layoutId: data.layoutId.present ? data.layoutId.value : this.layoutId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      addedOn: data.addedOn.present ? data.addedOn.value : this.addedOn,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WallPhoto(')
          ..write('id: $id, ')
          ..write('layoutId: $layoutId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('addedOn: $addedOn, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, layoutId, sortOrder, width, height, addedOn, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WallPhoto &&
          other.id == this.id &&
          other.layoutId == this.layoutId &&
          other.sortOrder == this.sortOrder &&
          other.width == this.width &&
          other.height == this.height &&
          other.addedOn == this.addedOn &&
          other.label == this.label);
}

class WallPhotosCompanion extends UpdateCompanion<WallPhoto> {
  final Value<String> id;
  final Value<String> layoutId;
  final Value<int> sortOrder;
  final Value<int> width;
  final Value<int> height;
  final Value<String> addedOn;
  final Value<String?> label;
  final Value<int> rowid;
  const WallPhotosCompanion({
    this.id = const Value.absent(),
    this.layoutId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.addedOn = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WallPhotosCompanion.insert({
    this.id = const Value.absent(),
    required String layoutId,
    required int sortOrder,
    required int width,
    required int height,
    required String addedOn,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : layoutId = Value(layoutId),
       sortOrder = Value(sortOrder),
       width = Value(width),
       height = Value(height),
       addedOn = Value(addedOn);
  static Insertable<WallPhoto> custom({
    Expression<String>? id,
    Expression<String>? layoutId,
    Expression<int>? sortOrder,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? addedOn,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (layoutId != null) 'layout_id': layoutId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (addedOn != null) 'added_on': addedOn,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WallPhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? layoutId,
    Value<int>? sortOrder,
    Value<int>? width,
    Value<int>? height,
    Value<String>? addedOn,
    Value<String?>? label,
    Value<int>? rowid,
  }) {
    return WallPhotosCompanion(
      id: id ?? this.id,
      layoutId: layoutId ?? this.layoutId,
      sortOrder: sortOrder ?? this.sortOrder,
      width: width ?? this.width,
      height: height ?? this.height,
      addedOn: addedOn ?? this.addedOn,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (layoutId.present) {
      map['layout_id'] = Variable<String>(layoutId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (addedOn.present) {
      map['added_on'] = Variable<String>(addedOn.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WallPhotosCompanion(')
          ..write('id: $id, ')
          ..write('layoutId: $layoutId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('addedOn: $addedOn, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WallPhotoBytesTable extends WallPhotoBytes
    with TableInfo<$WallPhotoBytesTable, WallPhotoImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WallPhotoBytesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wall_photos (id)',
    ),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbMeta = const VerificationMeta('thumb');
  @override
  late final GeneratedColumn<Uint8List> thumb = GeneratedColumn<Uint8List>(
    'thumb',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [photoId, data, thumb];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wall_photo_bytes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WallPhotoImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('thumb')) {
      context.handle(
        _thumbMeta,
        thumb.isAcceptableOrUnknown(data['thumb']!, _thumbMeta),
      );
    } else if (isInserting) {
      context.missing(_thumbMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId};
  @override
  WallPhotoImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WallPhotoImage(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}data'],
      )!,
      thumb: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}thumb'],
      )!,
    );
  }

  @override
  $WallPhotoBytesTable createAlias(String alias) {
    return $WallPhotoBytesTable(attachedDatabase, alias);
  }
}

class WallPhotoImage extends DataClass implements Insertable<WallPhotoImage> {
  final String photoId;
  final Uint8List data;
  final Uint8List thumb;
  const WallPhotoImage({
    required this.photoId,
    required this.data,
    required this.thumb,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<String>(photoId);
    map['data'] = Variable<Uint8List>(data);
    map['thumb'] = Variable<Uint8List>(thumb);
    return map;
  }

  WallPhotoBytesCompanion toCompanion(bool nullToAbsent) {
    return WallPhotoBytesCompanion(
      photoId: Value(photoId),
      data: Value(data),
      thumb: Value(thumb),
    );
  }

  factory WallPhotoImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WallPhotoImage(
      photoId: serializer.fromJson<String>(json['photoId']),
      data: serializer.fromJson<Uint8List>(json['data']),
      thumb: serializer.fromJson<Uint8List>(json['thumb']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<String>(photoId),
      'data': serializer.toJson<Uint8List>(data),
      'thumb': serializer.toJson<Uint8List>(thumb),
    };
  }

  WallPhotoImage copyWith({
    String? photoId,
    Uint8List? data,
    Uint8List? thumb,
  }) => WallPhotoImage(
    photoId: photoId ?? this.photoId,
    data: data ?? this.data,
    thumb: thumb ?? this.thumb,
  );
  WallPhotoImage copyWithCompanion(WallPhotoBytesCompanion data) {
    return WallPhotoImage(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      data: data.data.present ? data.data.value : this.data,
      thumb: data.thumb.present ? data.thumb.value : this.thumb,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WallPhotoImage(')
          ..write('photoId: $photoId, ')
          ..write('data: $data, ')
          ..write('thumb: $thumb')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    photoId,
    $driftBlobEquality.hash(data),
    $driftBlobEquality.hash(thumb),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WallPhotoImage &&
          other.photoId == this.photoId &&
          $driftBlobEquality.equals(other.data, this.data) &&
          $driftBlobEquality.equals(other.thumb, this.thumb));
}

class WallPhotoBytesCompanion extends UpdateCompanion<WallPhotoImage> {
  final Value<String> photoId;
  final Value<Uint8List> data;
  final Value<Uint8List> thumb;
  final Value<int> rowid;
  const WallPhotoBytesCompanion({
    this.photoId = const Value.absent(),
    this.data = const Value.absent(),
    this.thumb = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WallPhotoBytesCompanion.insert({
    required String photoId,
    required Uint8List data,
    required Uint8List thumb,
    this.rowid = const Value.absent(),
  }) : photoId = Value(photoId),
       data = Value(data),
       thumb = Value(thumb);
  static Insertable<WallPhotoImage> custom({
    Expression<String>? photoId,
    Expression<Uint8List>? data,
    Expression<Uint8List>? thumb,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (data != null) 'data': data,
      if (thumb != null) 'thumb': thumb,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WallPhotoBytesCompanion copyWith({
    Value<String>? photoId,
    Value<Uint8List>? data,
    Value<Uint8List>? thumb,
    Value<int>? rowid,
  }) {
    return WallPhotoBytesCompanion(
      photoId: photoId ?? this.photoId,
      data: data ?? this.data,
      thumb: thumb ?? this.thumb,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (thumb.present) {
      map['thumb'] = Variable<Uint8List>(thumb.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WallPhotoBytesCompanion(')
          ..write('photoId: $photoId, ')
          ..write('data: $data, ')
          ..write('thumb: $thumb, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProblemsTable extends Problems with TableInfo<$ProblemsTable, Problem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProblemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _layoutIdMeta = const VerificationMeta(
    'layoutId',
  );
  @override
  late final GeneratedColumn<String> layoutId = GeneratedColumn<String>(
    'layout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES layouts (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _setOnMeta = const VerificationMeta('setOn');
  @override
  late final GeneratedColumn<String> setOn = GeneratedColumn<String>(
    'set_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retiredOnMeta = const VerificationMeta(
    'retiredOn',
  );
  @override
  late final GeneratedColumn<String> retiredOn = GeneratedColumn<String>(
    'retired_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    layoutId,
    name,
    grade,
    description,
    setOn,
    retiredOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'problems';
  @override
  VerificationContext validateIntegrity(
    Insertable<Problem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('layout_id')) {
      context.handle(
        _layoutIdMeta,
        layoutId.isAcceptableOrUnknown(data['layout_id']!, _layoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('set_on')) {
      context.handle(
        _setOnMeta,
        setOn.isAcceptableOrUnknown(data['set_on']!, _setOnMeta),
      );
    } else if (isInserting) {
      context.missing(_setOnMeta);
    }
    if (data.containsKey('retired_on')) {
      context.handle(
        _retiredOnMeta,
        retiredOn.isAcceptableOrUnknown(data['retired_on']!, _retiredOnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Problem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Problem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      layoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      setOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_on'],
      )!,
      retiredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}retired_on'],
      ),
    );
  }

  @override
  $ProblemsTable createAlias(String alias) {
    return $ProblemsTable(attachedDatabase, alias);
  }
}

class Problem extends DataClass implements Insertable<Problem> {
  final String id;
  final String layoutId;
  final String name;
  final String? grade;
  final String description;
  final String setOn;
  final String? retiredOn;
  const Problem({
    required this.id,
    required this.layoutId,
    required this.name,
    this.grade,
    required this.description,
    required this.setOn,
    this.retiredOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['layout_id'] = Variable<String>(layoutId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || grade != null) {
      map['grade'] = Variable<String>(grade);
    }
    map['description'] = Variable<String>(description);
    map['set_on'] = Variable<String>(setOn);
    if (!nullToAbsent || retiredOn != null) {
      map['retired_on'] = Variable<String>(retiredOn);
    }
    return map;
  }

  ProblemsCompanion toCompanion(bool nullToAbsent) {
    return ProblemsCompanion(
      id: Value(id),
      layoutId: Value(layoutId),
      name: Value(name),
      grade: grade == null && nullToAbsent
          ? const Value.absent()
          : Value(grade),
      description: Value(description),
      setOn: Value(setOn),
      retiredOn: retiredOn == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredOn),
    );
  }

  factory Problem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Problem(
      id: serializer.fromJson<String>(json['id']),
      layoutId: serializer.fromJson<String>(json['layoutId']),
      name: serializer.fromJson<String>(json['name']),
      grade: serializer.fromJson<String?>(json['grade']),
      description: serializer.fromJson<String>(json['description']),
      setOn: serializer.fromJson<String>(json['setOn']),
      retiredOn: serializer.fromJson<String?>(json['retiredOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'layoutId': serializer.toJson<String>(layoutId),
      'name': serializer.toJson<String>(name),
      'grade': serializer.toJson<String?>(grade),
      'description': serializer.toJson<String>(description),
      'setOn': serializer.toJson<String>(setOn),
      'retiredOn': serializer.toJson<String?>(retiredOn),
    };
  }

  Problem copyWith({
    String? id,
    String? layoutId,
    String? name,
    Value<String?> grade = const Value.absent(),
    String? description,
    String? setOn,
    Value<String?> retiredOn = const Value.absent(),
  }) => Problem(
    id: id ?? this.id,
    layoutId: layoutId ?? this.layoutId,
    name: name ?? this.name,
    grade: grade.present ? grade.value : this.grade,
    description: description ?? this.description,
    setOn: setOn ?? this.setOn,
    retiredOn: retiredOn.present ? retiredOn.value : this.retiredOn,
  );
  Problem copyWithCompanion(ProblemsCompanion data) {
    return Problem(
      id: data.id.present ? data.id.value : this.id,
      layoutId: data.layoutId.present ? data.layoutId.value : this.layoutId,
      name: data.name.present ? data.name.value : this.name,
      grade: data.grade.present ? data.grade.value : this.grade,
      description: data.description.present
          ? data.description.value
          : this.description,
      setOn: data.setOn.present ? data.setOn.value : this.setOn,
      retiredOn: data.retiredOn.present ? data.retiredOn.value : this.retiredOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Problem(')
          ..write('id: $id, ')
          ..write('layoutId: $layoutId, ')
          ..write('name: $name, ')
          ..write('grade: $grade, ')
          ..write('description: $description, ')
          ..write('setOn: $setOn, ')
          ..write('retiredOn: $retiredOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, layoutId, name, grade, description, setOn, retiredOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Problem &&
          other.id == this.id &&
          other.layoutId == this.layoutId &&
          other.name == this.name &&
          other.grade == this.grade &&
          other.description == this.description &&
          other.setOn == this.setOn &&
          other.retiredOn == this.retiredOn);
}

class ProblemsCompanion extends UpdateCompanion<Problem> {
  final Value<String> id;
  final Value<String> layoutId;
  final Value<String> name;
  final Value<String?> grade;
  final Value<String> description;
  final Value<String> setOn;
  final Value<String?> retiredOn;
  final Value<int> rowid;
  const ProblemsCompanion({
    this.id = const Value.absent(),
    this.layoutId = const Value.absent(),
    this.name = const Value.absent(),
    this.grade = const Value.absent(),
    this.description = const Value.absent(),
    this.setOn = const Value.absent(),
    this.retiredOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProblemsCompanion.insert({
    this.id = const Value.absent(),
    required String layoutId,
    required String name,
    this.grade = const Value.absent(),
    this.description = const Value.absent(),
    required String setOn,
    this.retiredOn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : layoutId = Value(layoutId),
       name = Value(name),
       setOn = Value(setOn);
  static Insertable<Problem> custom({
    Expression<String>? id,
    Expression<String>? layoutId,
    Expression<String>? name,
    Expression<String>? grade,
    Expression<String>? description,
    Expression<String>? setOn,
    Expression<String>? retiredOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (layoutId != null) 'layout_id': layoutId,
      if (name != null) 'name': name,
      if (grade != null) 'grade': grade,
      if (description != null) 'description': description,
      if (setOn != null) 'set_on': setOn,
      if (retiredOn != null) 'retired_on': retiredOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProblemsCompanion copyWith({
    Value<String>? id,
    Value<String>? layoutId,
    Value<String>? name,
    Value<String?>? grade,
    Value<String>? description,
    Value<String>? setOn,
    Value<String?>? retiredOn,
    Value<int>? rowid,
  }) {
    return ProblemsCompanion(
      id: id ?? this.id,
      layoutId: layoutId ?? this.layoutId,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      description: description ?? this.description,
      setOn: setOn ?? this.setOn,
      retiredOn: retiredOn ?? this.retiredOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (layoutId.present) {
      map['layout_id'] = Variable<String>(layoutId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (setOn.present) {
      map['set_on'] = Variable<String>(setOn.value);
    }
    if (retiredOn.present) {
      map['retired_on'] = Variable<String>(retiredOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProblemsCompanion(')
          ..write('id: $id, ')
          ..write('layoutId: $layoutId, ')
          ..write('name: $name, ')
          ..write('grade: $grade, ')
          ..write('description: $description, ')
          ..write('setOn: $setOn, ')
          ..write('retiredOn: $retiredOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MarksTable extends Marks with TableInfo<$MarksTable, Mark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _problemIdMeta = const VerificationMeta(
    'problemId',
  );
  @override
  late final GeneratedColumn<String> problemId = GeneratedColumn<String>(
    'problem_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES problems (id)',
    ),
  );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wall_photos (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Role, int> role =
      GeneratedColumn<int>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Role>($MarksTable.$converterrole);
  static const VerificationMeta _cxMeta = const VerificationMeta('cx');
  @override
  late final GeneratedColumn<double> cx = GeneratedColumn<double>(
    'cx',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cyMeta = const VerificationMeta('cy');
  @override
  late final GeneratedColumn<double> cy = GeneratedColumn<double>(
    'cy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rMeta = const VerificationMeta('r');
  @override
  late final GeneratedColumn<double> r = GeneratedColumn<double>(
    'r',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outlineMeta = const VerificationMeta(
    'outline',
  );
  @override
  late final GeneratedColumn<String> outline = GeneratedColumn<String>(
    'outline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    problemId,
    photoId,
    role,
    cx,
    cy,
    r,
    outline,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Mark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('problem_id')) {
      context.handle(
        _problemIdMeta,
        problemId.isAcceptableOrUnknown(data['problem_id']!, _problemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_problemIdMeta);
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('cx')) {
      context.handle(_cxMeta, cx.isAcceptableOrUnknown(data['cx']!, _cxMeta));
    } else if (isInserting) {
      context.missing(_cxMeta);
    }
    if (data.containsKey('cy')) {
      context.handle(_cyMeta, cy.isAcceptableOrUnknown(data['cy']!, _cyMeta));
    } else if (isInserting) {
      context.missing(_cyMeta);
    }
    if (data.containsKey('r')) {
      context.handle(_rMeta, r.isAcceptableOrUnknown(data['r']!, _rMeta));
    } else if (isInserting) {
      context.missing(_rMeta);
    }
    if (data.containsKey('outline')) {
      context.handle(
        _outlineMeta,
        outline.isAcceptableOrUnknown(data['outline']!, _outlineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      problemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}problem_id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      role: $MarksTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}role'],
        )!,
      ),
      cx: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cx'],
      )!,
      cy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cy'],
      )!,
      r: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}r'],
      )!,
      outline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outline'],
      ),
    );
  }

  @override
  $MarksTable createAlias(String alias) {
    return $MarksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Role, int, int> $converterrole =
      const EnumIndexConverter<Role>(Role.values);
}

class Mark extends DataClass implements Insertable<Mark> {
  final String id;
  final String problemId;
  final String photoId;
  final Role role;
  final double cx;
  final double cy;
  final double r;
  final String? outline;
  const Mark({
    required this.id,
    required this.problemId,
    required this.photoId,
    required this.role,
    required this.cx,
    required this.cy,
    required this.r,
    this.outline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['problem_id'] = Variable<String>(problemId);
    map['photo_id'] = Variable<String>(photoId);
    {
      map['role'] = Variable<int>($MarksTable.$converterrole.toSql(role));
    }
    map['cx'] = Variable<double>(cx);
    map['cy'] = Variable<double>(cy);
    map['r'] = Variable<double>(r);
    if (!nullToAbsent || outline != null) {
      map['outline'] = Variable<String>(outline);
    }
    return map;
  }

  MarksCompanion toCompanion(bool nullToAbsent) {
    return MarksCompanion(
      id: Value(id),
      problemId: Value(problemId),
      photoId: Value(photoId),
      role: Value(role),
      cx: Value(cx),
      cy: Value(cy),
      r: Value(r),
      outline: outline == null && nullToAbsent
          ? const Value.absent()
          : Value(outline),
    );
  }

  factory Mark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mark(
      id: serializer.fromJson<String>(json['id']),
      problemId: serializer.fromJson<String>(json['problemId']),
      photoId: serializer.fromJson<String>(json['photoId']),
      role: $MarksTable.$converterrole.fromJson(
        serializer.fromJson<int>(json['role']),
      ),
      cx: serializer.fromJson<double>(json['cx']),
      cy: serializer.fromJson<double>(json['cy']),
      r: serializer.fromJson<double>(json['r']),
      outline: serializer.fromJson<String?>(json['outline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'problemId': serializer.toJson<String>(problemId),
      'photoId': serializer.toJson<String>(photoId),
      'role': serializer.toJson<int>($MarksTable.$converterrole.toJson(role)),
      'cx': serializer.toJson<double>(cx),
      'cy': serializer.toJson<double>(cy),
      'r': serializer.toJson<double>(r),
      'outline': serializer.toJson<String?>(outline),
    };
  }

  Mark copyWith({
    String? id,
    String? problemId,
    String? photoId,
    Role? role,
    double? cx,
    double? cy,
    double? r,
    Value<String?> outline = const Value.absent(),
  }) => Mark(
    id: id ?? this.id,
    problemId: problemId ?? this.problemId,
    photoId: photoId ?? this.photoId,
    role: role ?? this.role,
    cx: cx ?? this.cx,
    cy: cy ?? this.cy,
    r: r ?? this.r,
    outline: outline.present ? outline.value : this.outline,
  );
  Mark copyWithCompanion(MarksCompanion data) {
    return Mark(
      id: data.id.present ? data.id.value : this.id,
      problemId: data.problemId.present ? data.problemId.value : this.problemId,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      role: data.role.present ? data.role.value : this.role,
      cx: data.cx.present ? data.cx.value : this.cx,
      cy: data.cy.present ? data.cy.value : this.cy,
      r: data.r.present ? data.r.value : this.r,
      outline: data.outline.present ? data.outline.value : this.outline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mark(')
          ..write('id: $id, ')
          ..write('problemId: $problemId, ')
          ..write('photoId: $photoId, ')
          ..write('role: $role, ')
          ..write('cx: $cx, ')
          ..write('cy: $cy, ')
          ..write('r: $r, ')
          ..write('outline: $outline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, problemId, photoId, role, cx, cy, r, outline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mark &&
          other.id == this.id &&
          other.problemId == this.problemId &&
          other.photoId == this.photoId &&
          other.role == this.role &&
          other.cx == this.cx &&
          other.cy == this.cy &&
          other.r == this.r &&
          other.outline == this.outline);
}

class MarksCompanion extends UpdateCompanion<Mark> {
  final Value<String> id;
  final Value<String> problemId;
  final Value<String> photoId;
  final Value<Role> role;
  final Value<double> cx;
  final Value<double> cy;
  final Value<double> r;
  final Value<String?> outline;
  final Value<int> rowid;
  const MarksCompanion({
    this.id = const Value.absent(),
    this.problemId = const Value.absent(),
    this.photoId = const Value.absent(),
    this.role = const Value.absent(),
    this.cx = const Value.absent(),
    this.cy = const Value.absent(),
    this.r = const Value.absent(),
    this.outline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MarksCompanion.insert({
    this.id = const Value.absent(),
    required String problemId,
    required String photoId,
    required Role role,
    required double cx,
    required double cy,
    required double r,
    this.outline = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : problemId = Value(problemId),
       photoId = Value(photoId),
       role = Value(role),
       cx = Value(cx),
       cy = Value(cy),
       r = Value(r);
  static Insertable<Mark> custom({
    Expression<String>? id,
    Expression<String>? problemId,
    Expression<String>? photoId,
    Expression<int>? role,
    Expression<double>? cx,
    Expression<double>? cy,
    Expression<double>? r,
    Expression<String>? outline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (problemId != null) 'problem_id': problemId,
      if (photoId != null) 'photo_id': photoId,
      if (role != null) 'role': role,
      if (cx != null) 'cx': cx,
      if (cy != null) 'cy': cy,
      if (r != null) 'r': r,
      if (outline != null) 'outline': outline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MarksCompanion copyWith({
    Value<String>? id,
    Value<String>? problemId,
    Value<String>? photoId,
    Value<Role>? role,
    Value<double>? cx,
    Value<double>? cy,
    Value<double>? r,
    Value<String?>? outline,
    Value<int>? rowid,
  }) {
    return MarksCompanion(
      id: id ?? this.id,
      problemId: problemId ?? this.problemId,
      photoId: photoId ?? this.photoId,
      role: role ?? this.role,
      cx: cx ?? this.cx,
      cy: cy ?? this.cy,
      r: r ?? this.r,
      outline: outline ?? this.outline,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (problemId.present) {
      map['problem_id'] = Variable<String>(problemId.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (role.present) {
      map['role'] = Variable<int>($MarksTable.$converterrole.toSql(role.value));
    }
    if (cx.present) {
      map['cx'] = Variable<double>(cx.value);
    }
    if (cy.present) {
      map['cy'] = Variable<double>(cy.value);
    }
    if (r.present) {
      map['r'] = Variable<double>(r.value);
    }
    if (outline.present) {
      map['outline'] = Variable<String>(outline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarksCompanion(')
          ..write('id: $id, ')
          ..write('problemId: $problemId, ')
          ..write('photoId: $photoId, ')
          ..write('role: $role, ')
          ..write('cx: $cx, ')
          ..write('cy: $cy, ')
          ..write('r: $r, ')
          ..write('outline: $outline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WallsTable walls = $WallsTable(this);
  late final $LayoutsTable layouts = $LayoutsTable(this);
  late final $WallPhotosTable wallPhotos = $WallPhotosTable(this);
  late final $WallPhotoBytesTable wallPhotoBytes = $WallPhotoBytesTable(this);
  late final $ProblemsTable problems = $ProblemsTable(this);
  late final $MarksTable marks = $MarksTable(this);
  late final Index wallsName = Index(
    'walls_name',
    'CREATE UNIQUE INDEX walls_name ON walls (name COLLATE NOCASE)',
  );
  late final Index layoutsWall = Index(
    'layouts_wall',
    'CREATE INDEX layouts_wall ON layouts (wall_id)',
  );
  late final Index layoutsOneCurrent = Index(
    'layouts_one_current',
    'CREATE UNIQUE INDEX layouts_one_current ON layouts (wall_id) WHERE ended_on IS NULL',
  );
  late final Index wallPhotosLayout = Index(
    'wall_photos_layout',
    'CREATE INDEX wall_photos_layout ON wall_photos (layout_id)',
  );
  late final Index problemsLayout = Index(
    'problems_layout',
    'CREATE INDEX problems_layout ON problems (layout_id)',
  );
  late final Index problemsName = Index(
    'problems_name',
    'CREATE UNIQUE INDEX problems_name ON problems (layout_id, name COLLATE NOCASE)',
  );
  late final Index marksProblem = Index(
    'marks_problem',
    'CREATE INDEX marks_problem ON marks (problem_id)',
  );
  late final Index marksPhoto = Index(
    'marks_photo',
    'CREATE INDEX marks_photo ON marks (photo_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    walls,
    layouts,
    wallPhotos,
    wallPhotoBytes,
    problems,
    marks,
    wallsName,
    layoutsWall,
    layoutsOneCurrent,
    wallPhotosLayout,
    problemsLayout,
    problemsName,
    marksProblem,
    marksPhoto,
  ];
}

typedef $$WallsTableCreateCompanionBuilder =
    WallsCompanion Function({
      Value<String> id,
      required String name,
      required GradeScale gradeScale,
      required String createdOn,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$WallsTableUpdateCompanionBuilder =
    WallsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<GradeScale> gradeScale,
      Value<String> createdOn,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$WallsTableReferences
    extends BaseReferences<_$AppDatabase, $WallsTable, Wall> {
  $$WallsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LayoutsTable, List<Layout>> _layoutsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.layouts,
    aliasName: 'walls__id__layouts__wall_id',
  );

  $$LayoutsTableProcessedTableManager get layoutsRefs {
    final manager = $$LayoutsTableTableManager(
      $_db,
      $_db.layouts,
    ).filter((f) => f.wallId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_layoutsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WallsTableFilterComposer extends Composer<_$AppDatabase, $WallsTable> {
  $$WallsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GradeScale, GradeScale, int> get gradeScale =>
      $composableBuilder(
        column: $table.gradeScale,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get createdOn => $composableBuilder(
    column: $table.createdOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> layoutsRefs(
    Expression<bool> Function($$LayoutsTableFilterComposer f) f,
  ) {
    final $$LayoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.layouts,
      getReferencedColumn: (t) => t.wallId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayoutsTableFilterComposer(
            $db: $db,
            $table: $db.layouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WallsTableOrderingComposer
    extends Composer<_$AppDatabase, $WallsTable> {
  $$WallsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gradeScale => $composableBuilder(
    column: $table.gradeScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdOn => $composableBuilder(
    column: $table.createdOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WallsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WallsTable> {
  $$WallsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GradeScale, int> get gradeScale =>
      $composableBuilder(
        column: $table.gradeScale,
        builder: (column) => column,
      );

  GeneratedColumn<String> get createdOn =>
      $composableBuilder(column: $table.createdOn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> layoutsRefs<T extends Object>(
    Expression<T> Function($$LayoutsTableAnnotationComposer a) f,
  ) {
    final $$LayoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.layouts,
      getReferencedColumn: (t) => t.wallId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.layouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WallsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WallsTable,
          Wall,
          $$WallsTableFilterComposer,
          $$WallsTableOrderingComposer,
          $$WallsTableAnnotationComposer,
          $$WallsTableCreateCompanionBuilder,
          $$WallsTableUpdateCompanionBuilder,
          (Wall, $$WallsTableReferences),
          Wall,
          PrefetchHooks Function({bool layoutsRefs})
        > {
  $$WallsTableTableManager(_$AppDatabase db, $WallsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WallsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WallsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WallsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<GradeScale> gradeScale = const Value.absent(),
                Value<String> createdOn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WallsCompanion(
                id: id,
                name: name,
                gradeScale: gradeScale,
                createdOn: createdOn,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required GradeScale gradeScale,
                required String createdOn,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => WallsCompanion.insert(
                id: id,
                name: name,
                gradeScale: gradeScale,
                createdOn: createdOn,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WallsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({layoutsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (layoutsRefs) db.layouts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (layoutsRefs)
                    await $_getPrefetchedData<Wall, $WallsTable, Layout>(
                      currentTable: table,
                      referencedTable: $$WallsTableReferences._layoutsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$WallsTableReferences(db, table, p0).layoutsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.wallId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WallsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WallsTable,
      Wall,
      $$WallsTableFilterComposer,
      $$WallsTableOrderingComposer,
      $$WallsTableAnnotationComposer,
      $$WallsTableCreateCompanionBuilder,
      $$WallsTableUpdateCompanionBuilder,
      (Wall, $$WallsTableReferences),
      Wall,
      PrefetchHooks Function({bool layoutsRefs})
    >;
typedef $$LayoutsTableCreateCompanionBuilder =
    LayoutsCompanion Function({
      Value<String> id,
      required String wallId,
      Value<String?> name,
      required String startedOn,
      Value<String?> endedOn,
      Value<int> rowid,
    });
typedef $$LayoutsTableUpdateCompanionBuilder =
    LayoutsCompanion Function({
      Value<String> id,
      Value<String> wallId,
      Value<String?> name,
      Value<String> startedOn,
      Value<String?> endedOn,
      Value<int> rowid,
    });

final class $$LayoutsTableReferences
    extends BaseReferences<_$AppDatabase, $LayoutsTable, Layout> {
  $$LayoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WallsTable _wallIdTable(_$AppDatabase db) =>
      db.walls.createAlias('layouts__wall_id__walls__id');

  $$WallsTableProcessedTableManager get wallId {
    final $_column = $_itemColumn<String>('wall_id')!;

    final manager = $$WallsTableTableManager(
      $_db,
      $_db.walls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wallIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WallPhotosTable, List<WallPhoto>>
  _wallPhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wallPhotos,
    aliasName: 'layouts__id__wall_photos__layout_id',
  );

  $$WallPhotosTableProcessedTableManager get wallPhotosRefs {
    final manager = $$WallPhotosTableTableManager(
      $_db,
      $_db.wallPhotos,
    ).filter((f) => f.layoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_wallPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProblemsTable, List<Problem>> _problemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.problems,
    aliasName: 'layouts__id__problems__layout_id',
  );

  $$ProblemsTableProcessedTableManager get problemsRefs {
    final manager = $$ProblemsTableTableManager(
      $_db,
      $_db.problems,
    ).filter((f) => f.layoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_problemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LayoutsTableFilterComposer
    extends Composer<_$AppDatabase, $LayoutsTable> {
  $$LayoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedOn => $composableBuilder(
    column: $table.startedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endedOn => $composableBuilder(
    column: $table.endedOn,
    builder: (column) => ColumnFilters(column),
  );

  $$WallsTableFilterComposer get wallId {
    final $$WallsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wallId,
      referencedTable: $db.walls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallsTableFilterComposer(
            $db: $db,
            $table: $db.walls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> wallPhotosRefs(
    Expression<bool> Function($$WallPhotosTableFilterComposer f) f,
  ) {
    final $$WallPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wallPhotos,
      getReferencedColumn: (t) => t.layoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotosTableFilterComposer(
            $db: $db,
            $table: $db.wallPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> problemsRefs(
    Expression<bool> Function($$ProblemsTableFilterComposer f) f,
  ) {
    final $$ProblemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.problems,
      getReferencedColumn: (t) => t.layoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProblemsTableFilterComposer(
            $db: $db,
            $table: $db.problems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LayoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $LayoutsTable> {
  $$LayoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedOn => $composableBuilder(
    column: $table.startedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endedOn => $composableBuilder(
    column: $table.endedOn,
    builder: (column) => ColumnOrderings(column),
  );

  $$WallsTableOrderingComposer get wallId {
    final $$WallsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wallId,
      referencedTable: $db.walls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallsTableOrderingComposer(
            $db: $db,
            $table: $db.walls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LayoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LayoutsTable> {
  $$LayoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startedOn =>
      $composableBuilder(column: $table.startedOn, builder: (column) => column);

  GeneratedColumn<String> get endedOn =>
      $composableBuilder(column: $table.endedOn, builder: (column) => column);

  $$WallsTableAnnotationComposer get wallId {
    final $$WallsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wallId,
      referencedTable: $db.walls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallsTableAnnotationComposer(
            $db: $db,
            $table: $db.walls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> wallPhotosRefs<T extends Object>(
    Expression<T> Function($$WallPhotosTableAnnotationComposer a) f,
  ) {
    final $$WallPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wallPhotos,
      getReferencedColumn: (t) => t.layoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.wallPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> problemsRefs<T extends Object>(
    Expression<T> Function($$ProblemsTableAnnotationComposer a) f,
  ) {
    final $$ProblemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.problems,
      getReferencedColumn: (t) => t.layoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProblemsTableAnnotationComposer(
            $db: $db,
            $table: $db.problems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LayoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LayoutsTable,
          Layout,
          $$LayoutsTableFilterComposer,
          $$LayoutsTableOrderingComposer,
          $$LayoutsTableAnnotationComposer,
          $$LayoutsTableCreateCompanionBuilder,
          $$LayoutsTableUpdateCompanionBuilder,
          (Layout, $$LayoutsTableReferences),
          Layout,
          PrefetchHooks Function({
            bool wallId,
            bool wallPhotosRefs,
            bool problemsRefs,
          })
        > {
  $$LayoutsTableTableManager(_$AppDatabase db, $LayoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LayoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LayoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LayoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> wallId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> startedOn = const Value.absent(),
                Value<String?> endedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LayoutsCompanion(
                id: id,
                wallId: wallId,
                name: name,
                startedOn: startedOn,
                endedOn: endedOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String wallId,
                Value<String?> name = const Value.absent(),
                required String startedOn,
                Value<String?> endedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LayoutsCompanion.insert(
                id: id,
                wallId: wallId,
                name: name,
                startedOn: startedOn,
                endedOn: endedOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LayoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({wallId = false, wallPhotosRefs = false, problemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wallPhotosRefs) db.wallPhotos,
                    if (problemsRefs) db.problems,
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
                        if (wallId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.wallId,
                                    referencedTable: $$LayoutsTableReferences
                                        ._wallIdTable(db),
                                    referencedColumn: $$LayoutsTableReferences
                                        ._wallIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wallPhotosRefs)
                        await $_getPrefetchedData<
                          Layout,
                          $LayoutsTable,
                          WallPhoto
                        >(
                          currentTable: table,
                          referencedTable: $$LayoutsTableReferences
                              ._wallPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LayoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).wallPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.layoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (problemsRefs)
                        await $_getPrefetchedData<
                          Layout,
                          $LayoutsTable,
                          Problem
                        >(
                          currentTable: table,
                          referencedTable: $$LayoutsTableReferences
                              ._problemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LayoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).problemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.layoutId == item.id,
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

typedef $$LayoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LayoutsTable,
      Layout,
      $$LayoutsTableFilterComposer,
      $$LayoutsTableOrderingComposer,
      $$LayoutsTableAnnotationComposer,
      $$LayoutsTableCreateCompanionBuilder,
      $$LayoutsTableUpdateCompanionBuilder,
      (Layout, $$LayoutsTableReferences),
      Layout,
      PrefetchHooks Function({
        bool wallId,
        bool wallPhotosRefs,
        bool problemsRefs,
      })
    >;
typedef $$WallPhotosTableCreateCompanionBuilder =
    WallPhotosCompanion Function({
      Value<String> id,
      required String layoutId,
      required int sortOrder,
      required int width,
      required int height,
      required String addedOn,
      Value<String?> label,
      Value<int> rowid,
    });
typedef $$WallPhotosTableUpdateCompanionBuilder =
    WallPhotosCompanion Function({
      Value<String> id,
      Value<String> layoutId,
      Value<int> sortOrder,
      Value<int> width,
      Value<int> height,
      Value<String> addedOn,
      Value<String?> label,
      Value<int> rowid,
    });

final class $$WallPhotosTableReferences
    extends BaseReferences<_$AppDatabase, $WallPhotosTable, WallPhoto> {
  $$WallPhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LayoutsTable _layoutIdTable(_$AppDatabase db) =>
      db.layouts.createAlias('wall_photos__layout_id__layouts__id');

  $$LayoutsTableProcessedTableManager get layoutId {
    final $_column = $_itemColumn<String>('layout_id')!;

    final manager = $$LayoutsTableTableManager(
      $_db,
      $_db.layouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_layoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WallPhotoBytesTable, List<WallPhotoImage>>
  _wallPhotoBytesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wallPhotoBytes,
    aliasName: 'wall_photos__id__wall_photo_bytes__photo_id',
  );

  $$WallPhotoBytesTableProcessedTableManager get wallPhotoBytesRefs {
    final manager = $$WallPhotoBytesTableTableManager(
      $_db,
      $_db.wallPhotoBytes,
    ).filter((f) => f.photoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_wallPhotoBytesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MarksTable, List<Mark>> _marksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.marks,
    aliasName: 'wall_photos__id__marks__photo_id',
  );

  $$MarksTableProcessedTableManager get marksRefs {
    final manager = $$MarksTableTableManager(
      $_db,
      $_db.marks,
    ).filter((f) => f.photoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_marksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WallPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $WallPhotosTable> {
  $$WallPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedOn => $composableBuilder(
    column: $table.addedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  $$LayoutsTableFilterComposer get layoutId {
    final $$LayoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layoutId,
      referencedTable: $db.layouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayoutsTableFilterComposer(
            $db: $db,
            $table: $db.layouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> wallPhotoBytesRefs(
    Expression<bool> Function($$WallPhotoBytesTableFilterComposer f) f,
  ) {
    final $$WallPhotoBytesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wallPhotoBytes,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotoBytesTableFilterComposer(
            $db: $db,
            $table: $db.wallPhotoBytes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> marksRefs(
    Expression<bool> Function($$MarksTableFilterComposer f) f,
  ) {
    final $$MarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.marks,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarksTableFilterComposer(
            $db: $db,
            $table: $db.marks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WallPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $WallPhotosTable> {
  $$WallPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedOn => $composableBuilder(
    column: $table.addedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  $$LayoutsTableOrderingComposer get layoutId {
    final $$LayoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layoutId,
      referencedTable: $db.layouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayoutsTableOrderingComposer(
            $db: $db,
            $table: $db.layouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WallPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $WallPhotosTable> {
  $$WallPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get addedOn =>
      $composableBuilder(column: $table.addedOn, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  $$LayoutsTableAnnotationComposer get layoutId {
    final $$LayoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layoutId,
      referencedTable: $db.layouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.layouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> wallPhotoBytesRefs<T extends Object>(
    Expression<T> Function($$WallPhotoBytesTableAnnotationComposer a) f,
  ) {
    final $$WallPhotoBytesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wallPhotoBytes,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotoBytesTableAnnotationComposer(
            $db: $db,
            $table: $db.wallPhotoBytes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> marksRefs<T extends Object>(
    Expression<T> Function($$MarksTableAnnotationComposer a) f,
  ) {
    final $$MarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.marks,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarksTableAnnotationComposer(
            $db: $db,
            $table: $db.marks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WallPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WallPhotosTable,
          WallPhoto,
          $$WallPhotosTableFilterComposer,
          $$WallPhotosTableOrderingComposer,
          $$WallPhotosTableAnnotationComposer,
          $$WallPhotosTableCreateCompanionBuilder,
          $$WallPhotosTableUpdateCompanionBuilder,
          (WallPhoto, $$WallPhotosTableReferences),
          WallPhoto,
          PrefetchHooks Function({
            bool layoutId,
            bool wallPhotoBytesRefs,
            bool marksRefs,
          })
        > {
  $$WallPhotosTableTableManager(_$AppDatabase db, $WallPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WallPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WallPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WallPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> layoutId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String> addedOn = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WallPhotosCompanion(
                id: id,
                layoutId: layoutId,
                sortOrder: sortOrder,
                width: width,
                height: height,
                addedOn: addedOn,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String layoutId,
                required int sortOrder,
                required int width,
                required int height,
                required String addedOn,
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WallPhotosCompanion.insert(
                id: id,
                layoutId: layoutId,
                sortOrder: sortOrder,
                width: width,
                height: height,
                addedOn: addedOn,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WallPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                layoutId = false,
                wallPhotoBytesRefs = false,
                marksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wallPhotoBytesRefs) db.wallPhotoBytes,
                    if (marksRefs) db.marks,
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
                        if (layoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.layoutId,
                                    referencedTable: $$WallPhotosTableReferences
                                        ._layoutIdTable(db),
                                    referencedColumn:
                                        $$WallPhotosTableReferences
                                            ._layoutIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wallPhotoBytesRefs)
                        await $_getPrefetchedData<
                          WallPhoto,
                          $WallPhotosTable,
                          WallPhotoImage
                        >(
                          currentTable: table,
                          referencedTable: $$WallPhotosTableReferences
                              ._wallPhotoBytesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WallPhotosTableReferences(
                                db,
                                table,
                                p0,
                              ).wallPhotoBytesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.photoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (marksRefs)
                        await $_getPrefetchedData<
                          WallPhoto,
                          $WallPhotosTable,
                          Mark
                        >(
                          currentTable: table,
                          referencedTable: $$WallPhotosTableReferences
                              ._marksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WallPhotosTableReferences(
                                db,
                                table,
                                p0,
                              ).marksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.photoId == item.id,
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

typedef $$WallPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WallPhotosTable,
      WallPhoto,
      $$WallPhotosTableFilterComposer,
      $$WallPhotosTableOrderingComposer,
      $$WallPhotosTableAnnotationComposer,
      $$WallPhotosTableCreateCompanionBuilder,
      $$WallPhotosTableUpdateCompanionBuilder,
      (WallPhoto, $$WallPhotosTableReferences),
      WallPhoto,
      PrefetchHooks Function({
        bool layoutId,
        bool wallPhotoBytesRefs,
        bool marksRefs,
      })
    >;
typedef $$WallPhotoBytesTableCreateCompanionBuilder =
    WallPhotoBytesCompanion Function({
      required String photoId,
      required Uint8List data,
      required Uint8List thumb,
      Value<int> rowid,
    });
typedef $$WallPhotoBytesTableUpdateCompanionBuilder =
    WallPhotoBytesCompanion Function({
      Value<String> photoId,
      Value<Uint8List> data,
      Value<Uint8List> thumb,
      Value<int> rowid,
    });

final class $$WallPhotoBytesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WallPhotoBytesTable, WallPhotoImage> {
  $$WallPhotoBytesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WallPhotosTable _photoIdTable(_$AppDatabase db) =>
      db.wallPhotos.createAlias('wall_photo_bytes__photo_id__wall_photos__id');

  $$WallPhotosTableProcessedTableManager get photoId {
    final $_column = $_itemColumn<String>('photo_id')!;

    final manager = $$WallPhotosTableTableManager(
      $_db,
      $_db.wallPhotos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_photoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WallPhotoBytesTableFilterComposer
    extends Composer<_$AppDatabase, $WallPhotoBytesTable> {
  $$WallPhotoBytesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnFilters(column),
  );

  $$WallPhotosTableFilterComposer get photoId {
    final $$WallPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.wallPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotosTableFilterComposer(
            $db: $db,
            $table: $db.wallPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WallPhotoBytesTableOrderingComposer
    extends Composer<_$AppDatabase, $WallPhotoBytesTable> {
  $$WallPhotoBytesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnOrderings(column),
  );

  $$WallPhotosTableOrderingComposer get photoId {
    final $$WallPhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.wallPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotosTableOrderingComposer(
            $db: $db,
            $table: $db.wallPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WallPhotoBytesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WallPhotoBytesTable> {
  $$WallPhotoBytesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<Uint8List> get thumb =>
      $composableBuilder(column: $table.thumb, builder: (column) => column);

  $$WallPhotosTableAnnotationComposer get photoId {
    final $$WallPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.wallPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.wallPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WallPhotoBytesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WallPhotoBytesTable,
          WallPhotoImage,
          $$WallPhotoBytesTableFilterComposer,
          $$WallPhotoBytesTableOrderingComposer,
          $$WallPhotoBytesTableAnnotationComposer,
          $$WallPhotoBytesTableCreateCompanionBuilder,
          $$WallPhotoBytesTableUpdateCompanionBuilder,
          (WallPhotoImage, $$WallPhotoBytesTableReferences),
          WallPhotoImage,
          PrefetchHooks Function({bool photoId})
        > {
  $$WallPhotoBytesTableTableManager(
    _$AppDatabase db,
    $WallPhotoBytesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WallPhotoBytesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WallPhotoBytesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WallPhotoBytesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> photoId = const Value.absent(),
                Value<Uint8List> data = const Value.absent(),
                Value<Uint8List> thumb = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WallPhotoBytesCompanion(
                photoId: photoId,
                data: data,
                thumb: thumb,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String photoId,
                required Uint8List data,
                required Uint8List thumb,
                Value<int> rowid = const Value.absent(),
              }) => WallPhotoBytesCompanion.insert(
                photoId: photoId,
                data: data,
                thumb: thumb,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WallPhotoBytesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({photoId = false}) {
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
                    if (photoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.photoId,
                                referencedTable: $$WallPhotoBytesTableReferences
                                    ._photoIdTable(db),
                                referencedColumn:
                                    $$WallPhotoBytesTableReferences
                                        ._photoIdTable(db)
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

typedef $$WallPhotoBytesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WallPhotoBytesTable,
      WallPhotoImage,
      $$WallPhotoBytesTableFilterComposer,
      $$WallPhotoBytesTableOrderingComposer,
      $$WallPhotoBytesTableAnnotationComposer,
      $$WallPhotoBytesTableCreateCompanionBuilder,
      $$WallPhotoBytesTableUpdateCompanionBuilder,
      (WallPhotoImage, $$WallPhotoBytesTableReferences),
      WallPhotoImage,
      PrefetchHooks Function({bool photoId})
    >;
typedef $$ProblemsTableCreateCompanionBuilder =
    ProblemsCompanion Function({
      Value<String> id,
      required String layoutId,
      required String name,
      Value<String?> grade,
      Value<String> description,
      required String setOn,
      Value<String?> retiredOn,
      Value<int> rowid,
    });
typedef $$ProblemsTableUpdateCompanionBuilder =
    ProblemsCompanion Function({
      Value<String> id,
      Value<String> layoutId,
      Value<String> name,
      Value<String?> grade,
      Value<String> description,
      Value<String> setOn,
      Value<String?> retiredOn,
      Value<int> rowid,
    });

final class $$ProblemsTableReferences
    extends BaseReferences<_$AppDatabase, $ProblemsTable, Problem> {
  $$ProblemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LayoutsTable _layoutIdTable(_$AppDatabase db) =>
      db.layouts.createAlias('problems__layout_id__layouts__id');

  $$LayoutsTableProcessedTableManager get layoutId {
    final $_column = $_itemColumn<String>('layout_id')!;

    final manager = $$LayoutsTableTableManager(
      $_db,
      $_db.layouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_layoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MarksTable, List<Mark>> _marksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.marks,
    aliasName: 'problems__id__marks__problem_id',
  );

  $$MarksTableProcessedTableManager get marksRefs {
    final manager = $$MarksTableTableManager(
      $_db,
      $_db.marks,
    ).filter((f) => f.problemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_marksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProblemsTableFilterComposer
    extends Composer<_$AppDatabase, $ProblemsTable> {
  $$ProblemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setOn => $composableBuilder(
    column: $table.setOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get retiredOn => $composableBuilder(
    column: $table.retiredOn,
    builder: (column) => ColumnFilters(column),
  );

  $$LayoutsTableFilterComposer get layoutId {
    final $$LayoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layoutId,
      referencedTable: $db.layouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayoutsTableFilterComposer(
            $db: $db,
            $table: $db.layouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> marksRefs(
    Expression<bool> Function($$MarksTableFilterComposer f) f,
  ) {
    final $$MarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.marks,
      getReferencedColumn: (t) => t.problemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarksTableFilterComposer(
            $db: $db,
            $table: $db.marks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProblemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProblemsTable> {
  $$ProblemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setOn => $composableBuilder(
    column: $table.setOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retiredOn => $composableBuilder(
    column: $table.retiredOn,
    builder: (column) => ColumnOrderings(column),
  );

  $$LayoutsTableOrderingComposer get layoutId {
    final $$LayoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layoutId,
      referencedTable: $db.layouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayoutsTableOrderingComposer(
            $db: $db,
            $table: $db.layouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProblemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProblemsTable> {
  $$ProblemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get setOn =>
      $composableBuilder(column: $table.setOn, builder: (column) => column);

  GeneratedColumn<String> get retiredOn =>
      $composableBuilder(column: $table.retiredOn, builder: (column) => column);

  $$LayoutsTableAnnotationComposer get layoutId {
    final $$LayoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.layoutId,
      referencedTable: $db.layouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LayoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.layouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> marksRefs<T extends Object>(
    Expression<T> Function($$MarksTableAnnotationComposer a) f,
  ) {
    final $$MarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.marks,
      getReferencedColumn: (t) => t.problemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MarksTableAnnotationComposer(
            $db: $db,
            $table: $db.marks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProblemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProblemsTable,
          Problem,
          $$ProblemsTableFilterComposer,
          $$ProblemsTableOrderingComposer,
          $$ProblemsTableAnnotationComposer,
          $$ProblemsTableCreateCompanionBuilder,
          $$ProblemsTableUpdateCompanionBuilder,
          (Problem, $$ProblemsTableReferences),
          Problem,
          PrefetchHooks Function({bool layoutId, bool marksRefs})
        > {
  $$ProblemsTableTableManager(_$AppDatabase db, $ProblemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProblemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProblemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProblemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> layoutId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> grade = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> setOn = const Value.absent(),
                Value<String?> retiredOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProblemsCompanion(
                id: id,
                layoutId: layoutId,
                name: name,
                grade: grade,
                description: description,
                setOn: setOn,
                retiredOn: retiredOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String layoutId,
                required String name,
                Value<String?> grade = const Value.absent(),
                Value<String> description = const Value.absent(),
                required String setOn,
                Value<String?> retiredOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProblemsCompanion.insert(
                id: id,
                layoutId: layoutId,
                name: name,
                grade: grade,
                description: description,
                setOn: setOn,
                retiredOn: retiredOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProblemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({layoutId = false, marksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (marksRefs) db.marks],
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
                    if (layoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.layoutId,
                                referencedTable: $$ProblemsTableReferences
                                    ._layoutIdTable(db),
                                referencedColumn: $$ProblemsTableReferences
                                    ._layoutIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (marksRefs)
                    await $_getPrefetchedData<Problem, $ProblemsTable, Mark>(
                      currentTable: table,
                      referencedTable: $$ProblemsTableReferences
                          ._marksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProblemsTableReferences(db, table, p0).marksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.problemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProblemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProblemsTable,
      Problem,
      $$ProblemsTableFilterComposer,
      $$ProblemsTableOrderingComposer,
      $$ProblemsTableAnnotationComposer,
      $$ProblemsTableCreateCompanionBuilder,
      $$ProblemsTableUpdateCompanionBuilder,
      (Problem, $$ProblemsTableReferences),
      Problem,
      PrefetchHooks Function({bool layoutId, bool marksRefs})
    >;
typedef $$MarksTableCreateCompanionBuilder =
    MarksCompanion Function({
      Value<String> id,
      required String problemId,
      required String photoId,
      required Role role,
      required double cx,
      required double cy,
      required double r,
      Value<String?> outline,
      Value<int> rowid,
    });
typedef $$MarksTableUpdateCompanionBuilder =
    MarksCompanion Function({
      Value<String> id,
      Value<String> problemId,
      Value<String> photoId,
      Value<Role> role,
      Value<double> cx,
      Value<double> cy,
      Value<double> r,
      Value<String?> outline,
      Value<int> rowid,
    });

final class $$MarksTableReferences
    extends BaseReferences<_$AppDatabase, $MarksTable, Mark> {
  $$MarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProblemsTable _problemIdTable(_$AppDatabase db) =>
      db.problems.createAlias('marks__problem_id__problems__id');

  $$ProblemsTableProcessedTableManager get problemId {
    final $_column = $_itemColumn<String>('problem_id')!;

    final manager = $$ProblemsTableTableManager(
      $_db,
      $_db.problems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_problemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WallPhotosTable _photoIdTable(_$AppDatabase db) =>
      db.wallPhotos.createAlias('marks__photo_id__wall_photos__id');

  $$WallPhotosTableProcessedTableManager get photoId {
    final $_column = $_itemColumn<String>('photo_id')!;

    final manager = $$WallPhotosTableTableManager(
      $_db,
      $_db.wallPhotos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_photoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MarksTableFilterComposer extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Role, Role, int> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get cx => $composableBuilder(
    column: $table.cx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cy => $composableBuilder(
    column: $table.cy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get r => $composableBuilder(
    column: $table.r,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outline => $composableBuilder(
    column: $table.outline,
    builder: (column) => ColumnFilters(column),
  );

  $$ProblemsTableFilterComposer get problemId {
    final $$ProblemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.problemId,
      referencedTable: $db.problems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProblemsTableFilterComposer(
            $db: $db,
            $table: $db.problems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WallPhotosTableFilterComposer get photoId {
    final $$WallPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.wallPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotosTableFilterComposer(
            $db: $db,
            $table: $db.wallPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableOrderingComposer
    extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cx => $composableBuilder(
    column: $table.cx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cy => $composableBuilder(
    column: $table.cy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get r => $composableBuilder(
    column: $table.r,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outline => $composableBuilder(
    column: $table.outline,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProblemsTableOrderingComposer get problemId {
    final $$ProblemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.problemId,
      referencedTable: $db.problems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProblemsTableOrderingComposer(
            $db: $db,
            $table: $db.problems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WallPhotosTableOrderingComposer get photoId {
    final $$WallPhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.wallPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotosTableOrderingComposer(
            $db: $db,
            $table: $db.wallPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $MarksTable> {
  $$MarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Role, int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<double> get cx =>
      $composableBuilder(column: $table.cx, builder: (column) => column);

  GeneratedColumn<double> get cy =>
      $composableBuilder(column: $table.cy, builder: (column) => column);

  GeneratedColumn<double> get r =>
      $composableBuilder(column: $table.r, builder: (column) => column);

  GeneratedColumn<String> get outline =>
      $composableBuilder(column: $table.outline, builder: (column) => column);

  $$ProblemsTableAnnotationComposer get problemId {
    final $$ProblemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.problemId,
      referencedTable: $db.problems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProblemsTableAnnotationComposer(
            $db: $db,
            $table: $db.problems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WallPhotosTableAnnotationComposer get photoId {
    final $$WallPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.wallPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WallPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.wallPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MarksTable,
          Mark,
          $$MarksTableFilterComposer,
          $$MarksTableOrderingComposer,
          $$MarksTableAnnotationComposer,
          $$MarksTableCreateCompanionBuilder,
          $$MarksTableUpdateCompanionBuilder,
          (Mark, $$MarksTableReferences),
          Mark,
          PrefetchHooks Function({bool problemId, bool photoId})
        > {
  $$MarksTableTableManager(_$AppDatabase db, $MarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> problemId = const Value.absent(),
                Value<String> photoId = const Value.absent(),
                Value<Role> role = const Value.absent(),
                Value<double> cx = const Value.absent(),
                Value<double> cy = const Value.absent(),
                Value<double> r = const Value.absent(),
                Value<String?> outline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MarksCompanion(
                id: id,
                problemId: problemId,
                photoId: photoId,
                role: role,
                cx: cx,
                cy: cy,
                r: r,
                outline: outline,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String problemId,
                required String photoId,
                required Role role,
                required double cx,
                required double cy,
                required double r,
                Value<String?> outline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MarksCompanion.insert(
                id: id,
                problemId: problemId,
                photoId: photoId,
                role: role,
                cx: cx,
                cy: cy,
                r: r,
                outline: outline,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MarksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({problemId = false, photoId = false}) {
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
                    if (problemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.problemId,
                                referencedTable: $$MarksTableReferences
                                    ._problemIdTable(db),
                                referencedColumn: $$MarksTableReferences
                                    ._problemIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (photoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.photoId,
                                referencedTable: $$MarksTableReferences
                                    ._photoIdTable(db),
                                referencedColumn: $$MarksTableReferences
                                    ._photoIdTable(db)
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

typedef $$MarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MarksTable,
      Mark,
      $$MarksTableFilterComposer,
      $$MarksTableOrderingComposer,
      $$MarksTableAnnotationComposer,
      $$MarksTableCreateCompanionBuilder,
      $$MarksTableUpdateCompanionBuilder,
      (Mark, $$MarksTableReferences),
      Mark,
      PrefetchHooks Function({bool problemId, bool photoId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WallsTableTableManager get walls =>
      $$WallsTableTableManager(_db, _db.walls);
  $$LayoutsTableTableManager get layouts =>
      $$LayoutsTableTableManager(_db, _db.layouts);
  $$WallPhotosTableTableManager get wallPhotos =>
      $$WallPhotosTableTableManager(_db, _db.wallPhotos);
  $$WallPhotoBytesTableTableManager get wallPhotoBytes =>
      $$WallPhotoBytesTableTableManager(_db, _db.wallPhotoBytes);
  $$ProblemsTableTableManager get problems =>
      $$ProblemsTableTableManager(_db, _db.problems);
  $$MarksTableTableManager get marks =>
      $$MarksTableTableManager(_db, _db.marks);
}
