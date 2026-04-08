// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $LocalInventoryItemsTable extends LocalInventoryItems
    with TableInfo<$LocalInventoryItemsTable, LocalInventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientNameMeta = const VerificationMeta(
    'ingredientName',
  );
  @override
  late final GeneratedColumn<String> ingredientName = GeneratedColumn<String>(
    'ingredient_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<String> expiryDate = GeneratedColumn<String>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsSyncMeta = const VerificationMeta(
    'needsSync',
  );
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
    'needs_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    ingredientName,
    quantity,
    unit,
    category,
    location,
    expiryDate,
    barcode,
    notes,
    updatedAt,
    needsSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInventoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('ingredient_name')) {
      context.handle(
        _ingredientNameMeta,
        ingredientName.isAcceptableOrUnknown(
          data['ingredient_name']!,
          _ingredientNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
    if (data.containsKey('needs_sync')) {
      context.handle(
        _needsSyncMeta,
        needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInventoryItem(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      ingredientName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}ingredient_name'],
          )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expiry_date'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}updated_at'],
          )!,
      needsSync:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}needs_sync'],
          )!,
    );
  }

  @override
  $LocalInventoryItemsTable createAlias(String alias) {
    return $LocalInventoryItemsTable(attachedDatabase, alias);
  }
}

class LocalInventoryItem extends DataClass
    implements Insertable<LocalInventoryItem> {
  final String id;
  final String userId;
  final String ingredientName;
  final double? quantity;
  final String? unit;
  final String? category;
  final String? location;
  final String? expiryDate;
  final String? barcode;
  final String? notes;
  final int updatedAt;
  final bool needsSync;
  const LocalInventoryItem({
    required this.id,
    required this.userId,
    required this.ingredientName,
    this.quantity,
    this.unit,
    this.category,
    this.location,
    this.expiryDate,
    this.barcode,
    this.notes,
    required this.updatedAt,
    required this.needsSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['ingredient_name'] = Variable<String>(ingredientName);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<String>(expiryDate);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  LocalInventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoryItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      ingredientName: Value(ingredientName),
      quantity:
          quantity == null && nullToAbsent
              ? const Value.absent()
              : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      category:
          category == null && nullToAbsent
              ? const Value.absent()
              : Value(category),
      location:
          location == null && nullToAbsent
              ? const Value.absent()
              : Value(location),
      expiryDate:
          expiryDate == null && nullToAbsent
              ? const Value.absent()
              : Value(expiryDate),
      barcode:
          barcode == null && nullToAbsent
              ? const Value.absent()
              : Value(barcode),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
    );
  }

  factory LocalInventoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInventoryItem(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      ingredientName: serializer.fromJson<String>(json['ingredientName']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      category: serializer.fromJson<String?>(json['category']),
      location: serializer.fromJson<String?>(json['location']),
      expiryDate: serializer.fromJson<String?>(json['expiryDate']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      notes: serializer.fromJson<String?>(json['notes']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'ingredientName': serializer.toJson<String>(ingredientName),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'category': serializer.toJson<String?>(category),
      'location': serializer.toJson<String?>(location),
      'expiryDate': serializer.toJson<String?>(expiryDate),
      'barcode': serializer.toJson<String?>(barcode),
      'notes': serializer.toJson<String?>(notes),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  LocalInventoryItem copyWith({
    String? id,
    String? userId,
    String? ingredientName,
    Value<double?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> expiryDate = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? updatedAt,
    bool? needsSync,
  }) => LocalInventoryItem(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    ingredientName: ingredientName ?? this.ingredientName,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    category: category.present ? category.value : this.category,
    location: location.present ? location.value : this.location,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    barcode: barcode.present ? barcode.value : this.barcode,
    notes: notes.present ? notes.value : this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
    needsSync: needsSync ?? this.needsSync,
  );
  LocalInventoryItem copyWithCompanion(LocalInventoryItemsCompanion data) {
    return LocalInventoryItem(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      ingredientName:
          data.ingredientName.present
              ? data.ingredientName.value
              : this.ingredientName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      category: data.category.present ? data.category.value : this.category,
      location: data.location.present ? data.location.value : this.location,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      notes: data.notes.present ? data.notes.value : this.notes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryItem(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('ingredientName: $ingredientName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('category: $category, ')
          ..write('location: $location, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('barcode: $barcode, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    ingredientName,
    quantity,
    unit,
    category,
    location,
    expiryDate,
    barcode,
    notes,
    updatedAt,
    needsSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInventoryItem &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.ingredientName == this.ingredientName &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.category == this.category &&
          other.location == this.location &&
          other.expiryDate == this.expiryDate &&
          other.barcode == this.barcode &&
          other.notes == this.notes &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync);
}

class LocalInventoryItemsCompanion extends UpdateCompanion<LocalInventoryItem> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> ingredientName;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<String?> category;
  final Value<String?> location;
  final Value<String?> expiryDate;
  final Value<String?> barcode;
  final Value<String?> notes;
  final Value<int> updatedAt;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const LocalInventoryItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.ingredientName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.category = const Value.absent(),
    this.location = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.barcode = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoryItemsCompanion.insert({
    required String id,
    required String userId,
    required String ingredientName,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.category = const Value.absent(),
    this.location = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.barcode = const Value.absent(),
    this.notes = const Value.absent(),
    required int updatedAt,
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       ingredientName = Value(ingredientName),
       updatedAt = Value(updatedAt);
  static Insertable<LocalInventoryItem> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? ingredientName,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? category,
    Expression<String>? location,
    Expression<String>? expiryDate,
    Expression<String>? barcode,
    Expression<String>? notes,
    Expression<int>? updatedAt,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (ingredientName != null) 'ingredient_name': ingredientName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      if (location != null) 'location': location,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (barcode != null) 'barcode': barcode,
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? ingredientName,
    Value<double?>? quantity,
    Value<String?>? unit,
    Value<String?>? category,
    Value<String?>? location,
    Value<String?>? expiryDate,
    Value<String?>? barcode,
    Value<String?>? notes,
    Value<int>? updatedAt,
    Value<bool>? needsSync,
    Value<int>? rowid,
  }) {
    return LocalInventoryItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      location: location ?? this.location,
      expiryDate: expiryDate ?? this.expiryDate,
      barcode: barcode ?? this.barcode,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (ingredientName.present) {
      map['ingredient_name'] = Variable<String>(ingredientName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<String>(expiryDate.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('ingredientName: $ingredientName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('category: $category, ')
          ..write('location: $location, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('barcode: $barcode, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShoppingListsTable extends LocalShoppingLists
    with TableInfo<$LocalShoppingListsTable, LocalShoppingList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsSyncMeta = const VerificationMeta(
    'needsSync',
  );
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
    'needs_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    householdId,
    name,
    isCompleted,
    updatedAt,
    needsSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shopping_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShoppingList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('needs_sync')) {
      context.handle(
        _needsSyncMeta,
        needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalShoppingList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShoppingList(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      ),
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      isCompleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_completed'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}updated_at'],
          )!,
      needsSync:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}needs_sync'],
          )!,
    );
  }

  @override
  $LocalShoppingListsTable createAlias(String alias) {
    return $LocalShoppingListsTable(attachedDatabase, alias);
  }
}

class LocalShoppingList extends DataClass
    implements Insertable<LocalShoppingList> {
  final String id;
  final String? userId;
  final String? householdId;
  final String name;
  final bool isCompleted;
  final int updatedAt;
  final bool needsSync;
  const LocalShoppingList({
    required this.id,
    this.userId,
    this.householdId,
    required this.name,
    required this.isCompleted,
    required this.updatedAt,
    required this.needsSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    map['name'] = Variable<String>(name);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['updated_at'] = Variable<int>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  LocalShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return LocalShoppingListsCompanion(
      id: Value(id),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      householdId:
          householdId == null && nullToAbsent
              ? const Value.absent()
              : Value(householdId),
      name: Value(name),
      isCompleted: Value(isCompleted),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
    );
  }

  factory LocalShoppingList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShoppingList(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'name': serializer.toJson<String>(name),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  LocalShoppingList copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> householdId = const Value.absent(),
    String? name,
    bool? isCompleted,
    int? updatedAt,
    bool? needsSync,
  }) => LocalShoppingList(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    householdId: householdId.present ? householdId.value : this.householdId,
    name: name ?? this.name,
    isCompleted: isCompleted ?? this.isCompleted,
    updatedAt: updatedAt ?? this.updatedAt,
    needsSync: needsSync ?? this.needsSync,
  );
  LocalShoppingList copyWithCompanion(LocalShoppingListsCompanion data) {
    return LocalShoppingList(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingList(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    householdId,
    name,
    isCompleted,
    updatedAt,
    needsSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShoppingList &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.isCompleted == this.isCompleted &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync);
}

class LocalShoppingListsCompanion extends UpdateCompanion<LocalShoppingList> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<String> name;
  final Value<bool> isCompleted;
  final Value<int> updatedAt;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const LocalShoppingListsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShoppingListsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    required String name,
    this.isCompleted = const Value.absent(),
    required int updatedAt,
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<LocalShoppingList> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<bool>? isCompleted,
    Expression<int>? updatedAt,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShoppingListsCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? householdId,
    Value<String>? name,
    Value<bool>? isCompleted,
    Value<int>? updatedAt,
    Value<bool>? needsSync,
    Value<int>? rowid,
  }) {
    return LocalShoppingListsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalShoppingItemsTable extends LocalShoppingItems
    with TableInfo<$LocalShoppingItemsTable, LocalShoppingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCheckedMeta = const VerificationMeta(
    'isChecked',
  );
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
    'is_checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsSyncMeta = const VerificationMeta(
    'needsSync',
  );
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
    'needs_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    name,
    quantity,
    isChecked,
    category,
    sortOrder,
    updatedAt,
    needsSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shopping_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShoppingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('is_checked')) {
      context.handle(
        _isCheckedMeta,
        isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
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
    if (data.containsKey('needs_sync')) {
      context.handle(
        _needsSyncMeta,
        needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalShoppingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShoppingItem(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      listId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}list_id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      ),
      isChecked:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_checked'],
          )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}updated_at'],
          )!,
      needsSync:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}needs_sync'],
          )!,
    );
  }

  @override
  $LocalShoppingItemsTable createAlias(String alias) {
    return $LocalShoppingItemsTable(attachedDatabase, alias);
  }
}

class LocalShoppingItem extends DataClass
    implements Insertable<LocalShoppingItem> {
  final String id;
  final String listId;
  final String name;
  final String? quantity;
  final bool isChecked;
  final String? category;
  final int sortOrder;
  final int updatedAt;
  final bool needsSync;
  const LocalShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    required this.isChecked,
    this.category,
    required this.sortOrder,
    required this.updatedAt,
    required this.needsSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<String>(quantity);
    }
    map['is_checked'] = Variable<bool>(isChecked);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<int>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  LocalShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalShoppingItemsCompanion(
      id: Value(id),
      listId: Value(listId),
      name: Value(name),
      quantity:
          quantity == null && nullToAbsent
              ? const Value.absent()
              : Value(quantity),
      isChecked: Value(isChecked),
      category:
          category == null && nullToAbsent
              ? const Value.absent()
              : Value(category),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
    );
  }

  factory LocalShoppingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShoppingItem(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<String?>(json['quantity']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      category: serializer.fromJson<String?>(json['category']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<String?>(quantity),
      'isChecked': serializer.toJson<bool>(isChecked),
      'category': serializer.toJson<String?>(category),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  LocalShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    Value<String?> quantity = const Value.absent(),
    bool? isChecked,
    Value<String?> category = const Value.absent(),
    int? sortOrder,
    int? updatedAt,
    bool? needsSync,
  }) => LocalShoppingItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    name: name ?? this.name,
    quantity: quantity.present ? quantity.value : this.quantity,
    isChecked: isChecked ?? this.isChecked,
    category: category.present ? category.value : this.category,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
    needsSync: needsSync ?? this.needsSync,
  );
  LocalShoppingItem copyWithCompanion(LocalShoppingItemsCompanion data) {
    return LocalShoppingItem(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      category: data.category.present ? data.category.value : this.category,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingItem(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('isChecked: $isChecked, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    name,
    quantity,
    isChecked,
    category,
    sortOrder,
    updatedAt,
    needsSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShoppingItem &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.isChecked == this.isChecked &&
          other.category == this.category &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync);
}

class LocalShoppingItemsCompanion extends UpdateCompanion<LocalShoppingItem> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> name;
  final Value<String?> quantity;
  final Value<bool> isChecked;
  final Value<String?> category;
  final Value<int> sortOrder;
  final Value<int> updatedAt;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const LocalShoppingItemsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShoppingItemsCompanion.insert({
    required String id,
    required String listId,
    required String name,
    this.quantity = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int updatedAt,
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listId = Value(listId),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<LocalShoppingItem> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? name,
    Expression<String>? quantity,
    Expression<bool>? isChecked,
    Expression<String>? category,
    Expression<int>? sortOrder,
    Expression<int>? updatedAt,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (isChecked != null) 'is_checked': isChecked,
      if (category != null) 'category': category,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShoppingItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? listId,
    Value<String>? name,
    Value<String?>? quantity,
    Value<bool>? isChecked,
    Value<String?>? category,
    Value<int>? sortOrder,
    Value<int>? updatedAt,
    Value<bool>? needsSync,
    Value<int>? rowid,
  }) {
    return LocalShoppingItemsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShoppingItemsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('isChecked: $isChecked, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSavedRecipesTable extends LocalSavedRecipes
    with TableInfo<$LocalSavedRecipesTable, LocalSavedRecipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSavedRecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeJsonMeta = const VerificationMeta(
    'recipeJson',
  );
  @override
  late final GeneratedColumn<String> recipeJson = GeneratedColumn<String>(
    'recipe_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<int> savedAt = GeneratedColumn<int>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, userId, recipeJson, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_saved_recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSavedRecipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('recipe_json')) {
      context.handle(
        _recipeJsonMeta,
        recipeJson.isAcceptableOrUnknown(data['recipe_json']!, _recipeJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeJsonMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSavedRecipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSavedRecipe(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      userId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_id'],
          )!,
      recipeJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}recipe_json'],
          )!,
      savedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}saved_at'],
          )!,
    );
  }

  @override
  $LocalSavedRecipesTable createAlias(String alias) {
    return $LocalSavedRecipesTable(attachedDatabase, alias);
  }
}

class LocalSavedRecipe extends DataClass
    implements Insertable<LocalSavedRecipe> {
  final String id;
  final String userId;
  final String recipeJson;
  final int savedAt;
  const LocalSavedRecipe({
    required this.id,
    required this.userId,
    required this.recipeJson,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['recipe_json'] = Variable<String>(recipeJson);
    map['saved_at'] = Variable<int>(savedAt);
    return map;
  }

  LocalSavedRecipesCompanion toCompanion(bool nullToAbsent) {
    return LocalSavedRecipesCompanion(
      id: Value(id),
      userId: Value(userId),
      recipeJson: Value(recipeJson),
      savedAt: Value(savedAt),
    );
  }

  factory LocalSavedRecipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSavedRecipe(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      recipeJson: serializer.fromJson<String>(json['recipeJson']),
      savedAt: serializer.fromJson<int>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'recipeJson': serializer.toJson<String>(recipeJson),
      'savedAt': serializer.toJson<int>(savedAt),
    };
  }

  LocalSavedRecipe copyWith({
    String? id,
    String? userId,
    String? recipeJson,
    int? savedAt,
  }) => LocalSavedRecipe(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    recipeJson: recipeJson ?? this.recipeJson,
    savedAt: savedAt ?? this.savedAt,
  );
  LocalSavedRecipe copyWithCompanion(LocalSavedRecipesCompanion data) {
    return LocalSavedRecipe(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      recipeJson:
          data.recipeJson.present ? data.recipeJson.value : this.recipeJson,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSavedRecipe(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('recipeJson: $recipeJson, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, recipeJson, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSavedRecipe &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.recipeJson == this.recipeJson &&
          other.savedAt == this.savedAt);
}

class LocalSavedRecipesCompanion extends UpdateCompanion<LocalSavedRecipe> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> recipeJson;
  final Value<int> savedAt;
  final Value<int> rowid;
  const LocalSavedRecipesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.recipeJson = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSavedRecipesCompanion.insert({
    required String id,
    required String userId,
    required String recipeJson,
    required int savedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       recipeJson = Value(recipeJson),
       savedAt = Value(savedAt);
  static Insertable<LocalSavedRecipe> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? recipeJson,
    Expression<int>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (recipeJson != null) 'recipe_json': recipeJson,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSavedRecipesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? recipeJson,
    Value<int>? savedAt,
    Value<int>? rowid,
  }) {
    return LocalSavedRecipesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipeJson: recipeJson ?? this.recipeJson,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (recipeJson.present) {
      map['recipe_json'] = Variable<String>(recipeJson.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<int>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSavedRecipesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('recipeJson: $recipeJson, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $LocalInventoryItemsTable localInventoryItems =
      $LocalInventoryItemsTable(this);
  late final $LocalShoppingListsTable localShoppingLists =
      $LocalShoppingListsTable(this);
  late final $LocalShoppingItemsTable localShoppingItems =
      $LocalShoppingItemsTable(this);
  late final $LocalSavedRecipesTable localSavedRecipes =
      $LocalSavedRecipesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localInventoryItems,
    localShoppingLists,
    localShoppingItems,
    localSavedRecipes,
  ];
}

typedef $$LocalInventoryItemsTableCreateCompanionBuilder =
    LocalInventoryItemsCompanion Function({
      required String id,
      required String userId,
      required String ingredientName,
      Value<double?> quantity,
      Value<String?> unit,
      Value<String?> category,
      Value<String?> location,
      Value<String?> expiryDate,
      Value<String?> barcode,
      Value<String?> notes,
      required int updatedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });
typedef $$LocalInventoryItemsTableUpdateCompanionBuilder =
    LocalInventoryItemsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> ingredientName,
      Value<double?> quantity,
      Value<String?> unit,
      Value<String?> category,
      Value<String?> location,
      Value<String?> expiryDate,
      Value<String?> barcode,
      Value<String?> notes,
      Value<int> updatedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });

class $$LocalInventoryItemsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalInventoryItemsTable> {
  $$LocalInventoryItemsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoryItemsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalInventoryItemsTable> {
  $$LocalInventoryItemsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoryItemsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalInventoryItemsTable> {
  $$LocalInventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
}

class $$LocalInventoryItemsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalInventoryItemsTable,
          LocalInventoryItem,
          $$LocalInventoryItemsTableFilterComposer,
          $$LocalInventoryItemsTableOrderingComposer,
          $$LocalInventoryItemsTableAnnotationComposer,
          $$LocalInventoryItemsTableCreateCompanionBuilder,
          $$LocalInventoryItemsTableUpdateCompanionBuilder,
          (
            LocalInventoryItem,
            BaseReferences<
              _$LocalDatabase,
              $LocalInventoryItemsTable,
              LocalInventoryItem
            >,
          ),
          LocalInventoryItem,
          PrefetchHooks Function()
        > {
  $$LocalInventoryItemsTableTableManager(
    _$LocalDatabase db,
    $LocalInventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalInventoryItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalInventoryItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalInventoryItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> ingredientName = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> expiryDate = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryItemsCompanion(
                id: id,
                userId: userId,
                ingredientName: ingredientName,
                quantity: quantity,
                unit: unit,
                category: category,
                location: location,
                expiryDate: expiryDate,
                barcode: barcode,
                notes: notes,
                updatedAt: updatedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String ingredientName,
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> expiryDate = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int updatedAt,
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryItemsCompanion.insert(
                id: id,
                userId: userId,
                ingredientName: ingredientName,
                quantity: quantity,
                unit: unit,
                category: category,
                location: location,
                expiryDate: expiryDate,
                barcode: barcode,
                notes: notes,
                updatedAt: updatedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalInventoryItemsTable,
      LocalInventoryItem,
      $$LocalInventoryItemsTableFilterComposer,
      $$LocalInventoryItemsTableOrderingComposer,
      $$LocalInventoryItemsTableAnnotationComposer,
      $$LocalInventoryItemsTableCreateCompanionBuilder,
      $$LocalInventoryItemsTableUpdateCompanionBuilder,
      (
        LocalInventoryItem,
        BaseReferences<
          _$LocalDatabase,
          $LocalInventoryItemsTable,
          LocalInventoryItem
        >,
      ),
      LocalInventoryItem,
      PrefetchHooks Function()
    >;
typedef $$LocalShoppingListsTableCreateCompanionBuilder =
    LocalShoppingListsCompanion Function({
      required String id,
      Value<String?> userId,
      Value<String?> householdId,
      required String name,
      Value<bool> isCompleted,
      required int updatedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });
typedef $$LocalShoppingListsTableUpdateCompanionBuilder =
    LocalShoppingListsCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> householdId,
      Value<String> name,
      Value<bool> isCompleted,
      Value<int> updatedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });

class $$LocalShoppingListsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShoppingListsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShoppingListsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalShoppingListsTable> {
  $$LocalShoppingListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
}

class $$LocalShoppingListsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalShoppingListsTable,
          LocalShoppingList,
          $$LocalShoppingListsTableFilterComposer,
          $$LocalShoppingListsTableOrderingComposer,
          $$LocalShoppingListsTableAnnotationComposer,
          $$LocalShoppingListsTableCreateCompanionBuilder,
          $$LocalShoppingListsTableUpdateCompanionBuilder,
          (
            LocalShoppingList,
            BaseReferences<
              _$LocalDatabase,
              $LocalShoppingListsTable,
              LocalShoppingList
            >,
          ),
          LocalShoppingList,
          PrefetchHooks Function()
        > {
  $$LocalShoppingListsTableTableManager(
    _$LocalDatabase db,
    $LocalShoppingListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalShoppingListsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalShoppingListsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalShoppingListsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingListsCompanion(
                id: id,
                userId: userId,
                householdId: householdId,
                name: name,
                isCompleted: isCompleted,
                updatedAt: updatedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<String?> householdId = const Value.absent(),
                required String name,
                Value<bool> isCompleted = const Value.absent(),
                required int updatedAt,
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingListsCompanion.insert(
                id: id,
                userId: userId,
                householdId: householdId,
                name: name,
                isCompleted: isCompleted,
                updatedAt: updatedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShoppingListsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalShoppingListsTable,
      LocalShoppingList,
      $$LocalShoppingListsTableFilterComposer,
      $$LocalShoppingListsTableOrderingComposer,
      $$LocalShoppingListsTableAnnotationComposer,
      $$LocalShoppingListsTableCreateCompanionBuilder,
      $$LocalShoppingListsTableUpdateCompanionBuilder,
      (
        LocalShoppingList,
        BaseReferences<
          _$LocalDatabase,
          $LocalShoppingListsTable,
          LocalShoppingList
        >,
      ),
      LocalShoppingList,
      PrefetchHooks Function()
    >;
typedef $$LocalShoppingItemsTableCreateCompanionBuilder =
    LocalShoppingItemsCompanion Function({
      required String id,
      required String listId,
      required String name,
      Value<String?> quantity,
      Value<bool> isChecked,
      Value<String?> category,
      Value<int> sortOrder,
      required int updatedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });
typedef $$LocalShoppingItemsTableUpdateCompanionBuilder =
    LocalShoppingItemsCompanion Function({
      Value<String> id,
      Value<String> listId,
      Value<String> name,
      Value<String?> quantity,
      Value<bool> isChecked,
      Value<String?> category,
      Value<int> sortOrder,
      Value<int> updatedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });

class $$LocalShoppingItemsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalShoppingItemsTable> {
  $$LocalShoppingItemsTableFilterComposer({
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

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalShoppingItemsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalShoppingItemsTable> {
  $$LocalShoppingItemsTableOrderingComposer({
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

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShoppingItemsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalShoppingItemsTable> {
  $$LocalShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
}

class $$LocalShoppingItemsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalShoppingItemsTable,
          LocalShoppingItem,
          $$LocalShoppingItemsTableFilterComposer,
          $$LocalShoppingItemsTableOrderingComposer,
          $$LocalShoppingItemsTableAnnotationComposer,
          $$LocalShoppingItemsTableCreateCompanionBuilder,
          $$LocalShoppingItemsTableUpdateCompanionBuilder,
          (
            LocalShoppingItem,
            BaseReferences<
              _$LocalDatabase,
              $LocalShoppingItemsTable,
              LocalShoppingItem
            >,
          ),
          LocalShoppingItem,
          PrefetchHooks Function()
        > {
  $$LocalShoppingItemsTableTableManager(
    _$LocalDatabase db,
    $LocalShoppingItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalShoppingItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalShoppingItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalShoppingItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> quantity = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingItemsCompanion(
                id: id,
                listId: listId,
                name: name,
                quantity: quantity,
                isChecked: isChecked,
                category: category,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listId,
                required String name,
                Value<String?> quantity = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int updatedAt,
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShoppingItemsCompanion.insert(
                id: id,
                listId: listId,
                name: name,
                quantity: quantity,
                isChecked: isChecked,
                category: category,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalShoppingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalShoppingItemsTable,
      LocalShoppingItem,
      $$LocalShoppingItemsTableFilterComposer,
      $$LocalShoppingItemsTableOrderingComposer,
      $$LocalShoppingItemsTableAnnotationComposer,
      $$LocalShoppingItemsTableCreateCompanionBuilder,
      $$LocalShoppingItemsTableUpdateCompanionBuilder,
      (
        LocalShoppingItem,
        BaseReferences<
          _$LocalDatabase,
          $LocalShoppingItemsTable,
          LocalShoppingItem
        >,
      ),
      LocalShoppingItem,
      PrefetchHooks Function()
    >;
typedef $$LocalSavedRecipesTableCreateCompanionBuilder =
    LocalSavedRecipesCompanion Function({
      required String id,
      required String userId,
      required String recipeJson,
      required int savedAt,
      Value<int> rowid,
    });
typedef $$LocalSavedRecipesTableUpdateCompanionBuilder =
    LocalSavedRecipesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> recipeJson,
      Value<int> savedAt,
      Value<int> rowid,
    });

class $$LocalSavedRecipesTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalSavedRecipesTable> {
  $$LocalSavedRecipesTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSavedRecipesTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalSavedRecipesTable> {
  $$LocalSavedRecipesTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSavedRecipesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalSavedRecipesTable> {
  $$LocalSavedRecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get recipeJson => $composableBuilder(
    column: $table.recipeJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$LocalSavedRecipesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalSavedRecipesTable,
          LocalSavedRecipe,
          $$LocalSavedRecipesTableFilterComposer,
          $$LocalSavedRecipesTableOrderingComposer,
          $$LocalSavedRecipesTableAnnotationComposer,
          $$LocalSavedRecipesTableCreateCompanionBuilder,
          $$LocalSavedRecipesTableUpdateCompanionBuilder,
          (
            LocalSavedRecipe,
            BaseReferences<
              _$LocalDatabase,
              $LocalSavedRecipesTable,
              LocalSavedRecipe
            >,
          ),
          LocalSavedRecipe,
          PrefetchHooks Function()
        > {
  $$LocalSavedRecipesTableTableManager(
    _$LocalDatabase db,
    $LocalSavedRecipesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LocalSavedRecipesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$LocalSavedRecipesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$LocalSavedRecipesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> recipeJson = const Value.absent(),
                Value<int> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSavedRecipesCompanion(
                id: id,
                userId: userId,
                recipeJson: recipeJson,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String recipeJson,
                required int savedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSavedRecipesCompanion.insert(
                id: id,
                userId: userId,
                recipeJson: recipeJson,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSavedRecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalSavedRecipesTable,
      LocalSavedRecipe,
      $$LocalSavedRecipesTableFilterComposer,
      $$LocalSavedRecipesTableOrderingComposer,
      $$LocalSavedRecipesTableAnnotationComposer,
      $$LocalSavedRecipesTableCreateCompanionBuilder,
      $$LocalSavedRecipesTableUpdateCompanionBuilder,
      (
        LocalSavedRecipe,
        BaseReferences<
          _$LocalDatabase,
          $LocalSavedRecipesTable,
          LocalSavedRecipe
        >,
      ),
      LocalSavedRecipe,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$LocalInventoryItemsTableTableManager get localInventoryItems =>
      $$LocalInventoryItemsTableTableManager(_db, _db.localInventoryItems);
  $$LocalShoppingListsTableTableManager get localShoppingLists =>
      $$LocalShoppingListsTableTableManager(_db, _db.localShoppingLists);
  $$LocalShoppingItemsTableTableManager get localShoppingItems =>
      $$LocalShoppingItemsTableTableManager(_db, _db.localShoppingItems);
  $$LocalSavedRecipesTableTableManager get localSavedRecipes =>
      $$LocalSavedRecipesTableTableManager(_db, _db.localSavedRecipes);
}
