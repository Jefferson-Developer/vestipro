// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CustomersTableTable extends CustomersTable
    with TableInfo<$CustomersTableTable, CustomersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentMeta = const VerificationMeta(
    'document',
  );
  @override
  late final GeneratedColumn<String> document = GeneratedColumn<String>(
    'document',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legalNameMeta = const VerificationMeta(
    'legalName',
  );
  @override
  late final GeneratedColumn<String> legalName = GeneratedColumn<String>(
    'legal_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tradeNameMeta = const VerificationMeta(
    'tradeName',
  );
  @override
  late final GeneratedColumn<String> tradeName = GeneratedColumn<String>(
    'trade_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateRegistrationMeta = const VerificationMeta(
    'stateRegistration',
  );
  @override
  late final GeneratedColumn<String> stateRegistration =
      GeneratedColumn<String>(
        'state_registration',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _primaryEmailMeta = const VerificationMeta(
    'primaryEmail',
  );
  @override
  late final GeneratedColumn<String> primaryEmail = GeneratedColumn<String>(
    'primary_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryPhoneMeta = const VerificationMeta(
    'primaryPhone',
  );
  @override
  late final GeneratedColumn<String> primaryPhone = GeneratedColumn<String>(
    'primary_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classificationMeta = const VerificationMeta(
    'classification',
  );
  @override
  late final GeneratedColumn<String> classification = GeneratedColumn<String>(
    'classification',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _potentialMeta = const VerificationMeta(
    'potential',
  );
  @override
  late final GeneratedColumn<String> potential = GeneratedColumn<String>(
    'potential',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segmentMeta = const VerificationMeta(
    'segment',
  );
  @override
  late final GeneratedColumn<String> segment = GeneratedColumn<String>(
    'segment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originChannelMeta = const VerificationMeta(
    'originChannel',
  );
  @override
  late final GeneratedColumn<String> originChannel = GeneratedColumn<String>(
    'origin_channel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _responsibleSellerIdMeta =
      const VerificationMeta('responsibleSellerId');
  @override
  late final GeneratedColumn<String> responsibleSellerId =
      GeneratedColumn<String>(
        'responsible_seller_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _registeredAtMeta = const VerificationMeta(
    'registeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> registeredAt = GeneratedColumn<DateTime>(
    'registered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPurchaseAtMeta = const VerificationMeta(
    'lastPurchaseAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPurchaseAt =
      GeneratedColumn<DateTime>(
        'last_purchase_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customFieldsJsonMeta = const VerificationMeta(
    'customFieldsJson',
  );
  @override
  late final GeneratedColumn<String> customFieldsJson = GeneratedColumn<String>(
    'custom_fields_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    organizationId,
    companyId,
    type,
    document,
    legalName,
    tradeName,
    fullName,
    stateRegistration,
    primaryEmail,
    primaryPhone,
    status,
    classification,
    potential,
    segment,
    originChannel,
    responsibleSellerId,
    registeredAt,
    lastPurchaseAt,
    tagsJson,
    customFieldsJson,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    deletedAt,
    version,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('document')) {
      context.handle(
        _documentMeta,
        document.isAcceptableOrUnknown(data['document']!, _documentMeta),
      );
    } else if (isInserting) {
      context.missing(_documentMeta);
    }
    if (data.containsKey('legal_name')) {
      context.handle(
        _legalNameMeta,
        legalName.isAcceptableOrUnknown(data['legal_name']!, _legalNameMeta),
      );
    }
    if (data.containsKey('trade_name')) {
      context.handle(
        _tradeNameMeta,
        tradeName.isAcceptableOrUnknown(data['trade_name']!, _tradeNameMeta),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('state_registration')) {
      context.handle(
        _stateRegistrationMeta,
        stateRegistration.isAcceptableOrUnknown(
          data['state_registration']!,
          _stateRegistrationMeta,
        ),
      );
    }
    if (data.containsKey('primary_email')) {
      context.handle(
        _primaryEmailMeta,
        primaryEmail.isAcceptableOrUnknown(
          data['primary_email']!,
          _primaryEmailMeta,
        ),
      );
    }
    if (data.containsKey('primary_phone')) {
      context.handle(
        _primaryPhoneMeta,
        primaryPhone.isAcceptableOrUnknown(
          data['primary_phone']!,
          _primaryPhoneMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('classification')) {
      context.handle(
        _classificationMeta,
        classification.isAcceptableOrUnknown(
          data['classification']!,
          _classificationMeta,
        ),
      );
    }
    if (data.containsKey('potential')) {
      context.handle(
        _potentialMeta,
        potential.isAcceptableOrUnknown(data['potential']!, _potentialMeta),
      );
    }
    if (data.containsKey('segment')) {
      context.handle(
        _segmentMeta,
        segment.isAcceptableOrUnknown(data['segment']!, _segmentMeta),
      );
    }
    if (data.containsKey('origin_channel')) {
      context.handle(
        _originChannelMeta,
        originChannel.isAcceptableOrUnknown(
          data['origin_channel']!,
          _originChannelMeta,
        ),
      );
    }
    if (data.containsKey('responsible_seller_id')) {
      context.handle(
        _responsibleSellerIdMeta,
        responsibleSellerId.isAcceptableOrUnknown(
          data['responsible_seller_id']!,
          _responsibleSellerIdMeta,
        ),
      );
    }
    if (data.containsKey('registered_at')) {
      context.handle(
        _registeredAtMeta,
        registeredAt.isAcceptableOrUnknown(
          data['registered_at']!,
          _registeredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registeredAtMeta);
    }
    if (data.containsKey('last_purchase_at')) {
      context.handle(
        _lastPurchaseAtMeta,
        lastPurchaseAt.isAcceptableOrUnknown(
          data['last_purchase_at']!,
          _lastPurchaseAtMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('custom_fields_json')) {
      context.handle(
        _customFieldsJsonMeta,
        customFieldsJson.isAcceptableOrUnknown(
          data['custom_fields_json']!,
          _customFieldsJsonMeta,
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      document: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document'],
      )!,
      legalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_name'],
      ),
      tradeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_name'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      ),
      stateRegistration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_registration'],
      ),
      primaryEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_email'],
      ),
      primaryPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_phone'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      classification: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classification'],
      ),
      potential: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}potential'],
      ),
      segment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment'],
      ),
      originChannel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_channel'],
      ),
      responsibleSellerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}responsible_seller_id'],
      ),
      registeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}registered_at'],
      )!,
      lastPurchaseAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_purchase_at'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      ),
      customFieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_fields_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $CustomersTableTable createAlias(String alias) {
    return $CustomersTableTable(attachedDatabase, alias);
  }
}

class CustomersTableData extends DataClass
    implements Insertable<CustomersTableData> {
  final String id;
  final String organizationId;
  final String companyId;
  final String type;
  final String document;
  final String? legalName;
  final String? tradeName;
  final String? fullName;
  final String? stateRegistration;
  final String? primaryEmail;
  final String? primaryPhone;
  final String status;
  final String? classification;
  final String? potential;
  final String? segment;
  final String? originChannel;
  final String? responsibleSellerId;
  final DateTime registeredAt;
  final DateTime? lastPurchaseAt;
  final String? tagsJson;
  final String? customFieldsJson;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;
  const CustomersTableData({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.type,
    required this.document,
    this.legalName,
    this.tradeName,
    this.fullName,
    this.stateRegistration,
    this.primaryEmail,
    this.primaryPhone,
    required this.status,
    this.classification,
    this.potential,
    this.segment,
    this.originChannel,
    this.responsibleSellerId,
    required this.registeredAt,
    this.lastPurchaseAt,
    this.tagsJson,
    this.customFieldsJson,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['company_id'] = Variable<String>(companyId);
    map['type'] = Variable<String>(type);
    map['document'] = Variable<String>(document);
    if (!nullToAbsent || legalName != null) {
      map['legal_name'] = Variable<String>(legalName);
    }
    if (!nullToAbsent || tradeName != null) {
      map['trade_name'] = Variable<String>(tradeName);
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    if (!nullToAbsent || stateRegistration != null) {
      map['state_registration'] = Variable<String>(stateRegistration);
    }
    if (!nullToAbsent || primaryEmail != null) {
      map['primary_email'] = Variable<String>(primaryEmail);
    }
    if (!nullToAbsent || primaryPhone != null) {
      map['primary_phone'] = Variable<String>(primaryPhone);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || classification != null) {
      map['classification'] = Variable<String>(classification);
    }
    if (!nullToAbsent || potential != null) {
      map['potential'] = Variable<String>(potential);
    }
    if (!nullToAbsent || segment != null) {
      map['segment'] = Variable<String>(segment);
    }
    if (!nullToAbsent || originChannel != null) {
      map['origin_channel'] = Variable<String>(originChannel);
    }
    if (!nullToAbsent || responsibleSellerId != null) {
      map['responsible_seller_id'] = Variable<String>(responsibleSellerId);
    }
    map['registered_at'] = Variable<DateTime>(registeredAt);
    if (!nullToAbsent || lastPurchaseAt != null) {
      map['last_purchase_at'] = Variable<DateTime>(lastPurchaseAt);
    }
    if (!nullToAbsent || tagsJson != null) {
      map['tags_json'] = Variable<String>(tagsJson);
    }
    if (!nullToAbsent || customFieldsJson != null) {
      map['custom_fields_json'] = Variable<String>(customFieldsJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['created_by'] = Variable<String>(createdBy);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  CustomersTableCompanion toCompanion(bool nullToAbsent) {
    return CustomersTableCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      companyId: Value(companyId),
      type: Value(type),
      document: Value(document),
      legalName: legalName == null && nullToAbsent
          ? const Value.absent()
          : Value(legalName),
      tradeName: tradeName == null && nullToAbsent
          ? const Value.absent()
          : Value(tradeName),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      stateRegistration: stateRegistration == null && nullToAbsent
          ? const Value.absent()
          : Value(stateRegistration),
      primaryEmail: primaryEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryEmail),
      primaryPhone: primaryPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryPhone),
      status: Value(status),
      classification: classification == null && nullToAbsent
          ? const Value.absent()
          : Value(classification),
      potential: potential == null && nullToAbsent
          ? const Value.absent()
          : Value(potential),
      segment: segment == null && nullToAbsent
          ? const Value.absent()
          : Value(segment),
      originChannel: originChannel == null && nullToAbsent
          ? const Value.absent()
          : Value(originChannel),
      responsibleSellerId: responsibleSellerId == null && nullToAbsent
          ? const Value.absent()
          : Value(responsibleSellerId),
      registeredAt: Value(registeredAt),
      lastPurchaseAt: lastPurchaseAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPurchaseAt),
      tagsJson: tagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsJson),
      customFieldsJson: customFieldsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(customFieldsJson),
      createdAt: Value(createdAt),
      createdBy: Value(createdBy),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      version: Value(version),
      syncStatus: Value(syncStatus),
    );
  }

  factory CustomersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomersTableData(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      type: serializer.fromJson<String>(json['type']),
      document: serializer.fromJson<String>(json['document']),
      legalName: serializer.fromJson<String?>(json['legalName']),
      tradeName: serializer.fromJson<String?>(json['tradeName']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      stateRegistration: serializer.fromJson<String?>(
        json['stateRegistration'],
      ),
      primaryEmail: serializer.fromJson<String?>(json['primaryEmail']),
      primaryPhone: serializer.fromJson<String?>(json['primaryPhone']),
      status: serializer.fromJson<String>(json['status']),
      classification: serializer.fromJson<String?>(json['classification']),
      potential: serializer.fromJson<String?>(json['potential']),
      segment: serializer.fromJson<String?>(json['segment']),
      originChannel: serializer.fromJson<String?>(json['originChannel']),
      responsibleSellerId: serializer.fromJson<String?>(
        json['responsibleSellerId'],
      ),
      registeredAt: serializer.fromJson<DateTime>(json['registeredAt']),
      lastPurchaseAt: serializer.fromJson<DateTime?>(json['lastPurchaseAt']),
      tagsJson: serializer.fromJson<String?>(json['tagsJson']),
      customFieldsJson: serializer.fromJson<String?>(json['customFieldsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'companyId': serializer.toJson<String>(companyId),
      'type': serializer.toJson<String>(type),
      'document': serializer.toJson<String>(document),
      'legalName': serializer.toJson<String?>(legalName),
      'tradeName': serializer.toJson<String?>(tradeName),
      'fullName': serializer.toJson<String?>(fullName),
      'stateRegistration': serializer.toJson<String?>(stateRegistration),
      'primaryEmail': serializer.toJson<String?>(primaryEmail),
      'primaryPhone': serializer.toJson<String?>(primaryPhone),
      'status': serializer.toJson<String>(status),
      'classification': serializer.toJson<String?>(classification),
      'potential': serializer.toJson<String?>(potential),
      'segment': serializer.toJson<String?>(segment),
      'originChannel': serializer.toJson<String?>(originChannel),
      'responsibleSellerId': serializer.toJson<String?>(responsibleSellerId),
      'registeredAt': serializer.toJson<DateTime>(registeredAt),
      'lastPurchaseAt': serializer.toJson<DateTime?>(lastPurchaseAt),
      'tagsJson': serializer.toJson<String?>(tagsJson),
      'customFieldsJson': serializer.toJson<String?>(customFieldsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  CustomersTableData copyWith({
    String? id,
    String? organizationId,
    String? companyId,
    String? type,
    String? document,
    Value<String?> legalName = const Value.absent(),
    Value<String?> tradeName = const Value.absent(),
    Value<String?> fullName = const Value.absent(),
    Value<String?> stateRegistration = const Value.absent(),
    Value<String?> primaryEmail = const Value.absent(),
    Value<String?> primaryPhone = const Value.absent(),
    String? status,
    Value<String?> classification = const Value.absent(),
    Value<String?> potential = const Value.absent(),
    Value<String?> segment = const Value.absent(),
    Value<String?> originChannel = const Value.absent(),
    Value<String?> responsibleSellerId = const Value.absent(),
    DateTime? registeredAt,
    Value<DateTime?> lastPurchaseAt = const Value.absent(),
    Value<String?> tagsJson = const Value.absent(),
    Value<String?> customFieldsJson = const Value.absent(),
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? version,
    String? syncStatus,
  }) => CustomersTableData(
    id: id ?? this.id,
    organizationId: organizationId ?? this.organizationId,
    companyId: companyId ?? this.companyId,
    type: type ?? this.type,
    document: document ?? this.document,
    legalName: legalName.present ? legalName.value : this.legalName,
    tradeName: tradeName.present ? tradeName.value : this.tradeName,
    fullName: fullName.present ? fullName.value : this.fullName,
    stateRegistration: stateRegistration.present
        ? stateRegistration.value
        : this.stateRegistration,
    primaryEmail: primaryEmail.present ? primaryEmail.value : this.primaryEmail,
    primaryPhone: primaryPhone.present ? primaryPhone.value : this.primaryPhone,
    status: status ?? this.status,
    classification: classification.present
        ? classification.value
        : this.classification,
    potential: potential.present ? potential.value : this.potential,
    segment: segment.present ? segment.value : this.segment,
    originChannel: originChannel.present
        ? originChannel.value
        : this.originChannel,
    responsibleSellerId: responsibleSellerId.present
        ? responsibleSellerId.value
        : this.responsibleSellerId,
    registeredAt: registeredAt ?? this.registeredAt,
    lastPurchaseAt: lastPurchaseAt.present
        ? lastPurchaseAt.value
        : this.lastPurchaseAt,
    tagsJson: tagsJson.present ? tagsJson.value : this.tagsJson,
    customFieldsJson: customFieldsJson.present
        ? customFieldsJson.value
        : this.customFieldsJson,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy ?? this.createdBy,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  CustomersTableData copyWithCompanion(CustomersTableCompanion data) {
    return CustomersTableData(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      type: data.type.present ? data.type.value : this.type,
      document: data.document.present ? data.document.value : this.document,
      legalName: data.legalName.present ? data.legalName.value : this.legalName,
      tradeName: data.tradeName.present ? data.tradeName.value : this.tradeName,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      stateRegistration: data.stateRegistration.present
          ? data.stateRegistration.value
          : this.stateRegistration,
      primaryEmail: data.primaryEmail.present
          ? data.primaryEmail.value
          : this.primaryEmail,
      primaryPhone: data.primaryPhone.present
          ? data.primaryPhone.value
          : this.primaryPhone,
      status: data.status.present ? data.status.value : this.status,
      classification: data.classification.present
          ? data.classification.value
          : this.classification,
      potential: data.potential.present ? data.potential.value : this.potential,
      segment: data.segment.present ? data.segment.value : this.segment,
      originChannel: data.originChannel.present
          ? data.originChannel.value
          : this.originChannel,
      responsibleSellerId: data.responsibleSellerId.present
          ? data.responsibleSellerId.value
          : this.responsibleSellerId,
      registeredAt: data.registeredAt.present
          ? data.registeredAt.value
          : this.registeredAt,
      lastPurchaseAt: data.lastPurchaseAt.present
          ? data.lastPurchaseAt.value
          : this.lastPurchaseAt,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      customFieldsJson: data.customFieldsJson.present
          ? data.customFieldsJson.value
          : this.customFieldsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableData(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('type: $type, ')
          ..write('document: $document, ')
          ..write('legalName: $legalName, ')
          ..write('tradeName: $tradeName, ')
          ..write('fullName: $fullName, ')
          ..write('stateRegistration: $stateRegistration, ')
          ..write('primaryEmail: $primaryEmail, ')
          ..write('primaryPhone: $primaryPhone, ')
          ..write('status: $status, ')
          ..write('classification: $classification, ')
          ..write('potential: $potential, ')
          ..write('segment: $segment, ')
          ..write('originChannel: $originChannel, ')
          ..write('responsibleSellerId: $responsibleSellerId, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('lastPurchaseAt: $lastPurchaseAt, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('customFieldsJson: $customFieldsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    organizationId,
    companyId,
    type,
    document,
    legalName,
    tradeName,
    fullName,
    stateRegistration,
    primaryEmail,
    primaryPhone,
    status,
    classification,
    potential,
    segment,
    originChannel,
    responsibleSellerId,
    registeredAt,
    lastPurchaseAt,
    tagsJson,
    customFieldsJson,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    deletedAt,
    version,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomersTableData &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.companyId == this.companyId &&
          other.type == this.type &&
          other.document == this.document &&
          other.legalName == this.legalName &&
          other.tradeName == this.tradeName &&
          other.fullName == this.fullName &&
          other.stateRegistration == this.stateRegistration &&
          other.primaryEmail == this.primaryEmail &&
          other.primaryPhone == this.primaryPhone &&
          other.status == this.status &&
          other.classification == this.classification &&
          other.potential == this.potential &&
          other.segment == this.segment &&
          other.originChannel == this.originChannel &&
          other.responsibleSellerId == this.responsibleSellerId &&
          other.registeredAt == this.registeredAt &&
          other.lastPurchaseAt == this.lastPurchaseAt &&
          other.tagsJson == this.tagsJson &&
          other.customFieldsJson == this.customFieldsJson &&
          other.createdAt == this.createdAt &&
          other.createdBy == this.createdBy &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus);
}

class CustomersTableCompanion extends UpdateCompanion<CustomersTableData> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> companyId;
  final Value<String> type;
  final Value<String> document;
  final Value<String?> legalName;
  final Value<String?> tradeName;
  final Value<String?> fullName;
  final Value<String?> stateRegistration;
  final Value<String?> primaryEmail;
  final Value<String?> primaryPhone;
  final Value<String> status;
  final Value<String?> classification;
  final Value<String?> potential;
  final Value<String?> segment;
  final Value<String?> originChannel;
  final Value<String?> responsibleSellerId;
  final Value<DateTime> registeredAt;
  final Value<DateTime?> lastPurchaseAt;
  final Value<String?> tagsJson;
  final Value<String?> customFieldsJson;
  final Value<DateTime> createdAt;
  final Value<String> createdBy;
  final Value<DateTime> updatedAt;
  final Value<String> updatedBy;
  final Value<DateTime?> deletedAt;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const CustomersTableCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.type = const Value.absent(),
    this.document = const Value.absent(),
    this.legalName = const Value.absent(),
    this.tradeName = const Value.absent(),
    this.fullName = const Value.absent(),
    this.stateRegistration = const Value.absent(),
    this.primaryEmail = const Value.absent(),
    this.primaryPhone = const Value.absent(),
    this.status = const Value.absent(),
    this.classification = const Value.absent(),
    this.potential = const Value.absent(),
    this.segment = const Value.absent(),
    this.originChannel = const Value.absent(),
    this.responsibleSellerId = const Value.absent(),
    this.registeredAt = const Value.absent(),
    this.lastPurchaseAt = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.customFieldsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersTableCompanion.insert({
    required String id,
    required String organizationId,
    required String companyId,
    required String type,
    required String document,
    this.legalName = const Value.absent(),
    this.tradeName = const Value.absent(),
    this.fullName = const Value.absent(),
    this.stateRegistration = const Value.absent(),
    this.primaryEmail = const Value.absent(),
    this.primaryPhone = const Value.absent(),
    required String status,
    this.classification = const Value.absent(),
    this.potential = const Value.absent(),
    this.segment = const Value.absent(),
    this.originChannel = const Value.absent(),
    this.responsibleSellerId = const Value.absent(),
    required DateTime registeredAt,
    this.lastPurchaseAt = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.customFieldsJson = const Value.absent(),
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required int version,
    required String syncStatus,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       organizationId = Value(organizationId),
       companyId = Value(companyId),
       type = Value(type),
       document = Value(document),
       status = Value(status),
       registeredAt = Value(registeredAt),
       createdAt = Value(createdAt),
       createdBy = Value(createdBy),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       version = Value(version),
       syncStatus = Value(syncStatus);
  static Insertable<CustomersTableData> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? companyId,
    Expression<String>? type,
    Expression<String>? document,
    Expression<String>? legalName,
    Expression<String>? tradeName,
    Expression<String>? fullName,
    Expression<String>? stateRegistration,
    Expression<String>? primaryEmail,
    Expression<String>? primaryPhone,
    Expression<String>? status,
    Expression<String>? classification,
    Expression<String>? potential,
    Expression<String>? segment,
    Expression<String>? originChannel,
    Expression<String>? responsibleSellerId,
    Expression<DateTime>? registeredAt,
    Expression<DateTime>? lastPurchaseAt,
    Expression<String>? tagsJson,
    Expression<String>? customFieldsJson,
    Expression<DateTime>? createdAt,
    Expression<String>? createdBy,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedBy,
    Expression<DateTime>? deletedAt,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (companyId != null) 'company_id': companyId,
      if (type != null) 'type': type,
      if (document != null) 'document': document,
      if (legalName != null) 'legal_name': legalName,
      if (tradeName != null) 'trade_name': tradeName,
      if (fullName != null) 'full_name': fullName,
      if (stateRegistration != null) 'state_registration': stateRegistration,
      if (primaryEmail != null) 'primary_email': primaryEmail,
      if (primaryPhone != null) 'primary_phone': primaryPhone,
      if (status != null) 'status': status,
      if (classification != null) 'classification': classification,
      if (potential != null) 'potential': potential,
      if (segment != null) 'segment': segment,
      if (originChannel != null) 'origin_channel': originChannel,
      if (responsibleSellerId != null)
        'responsible_seller_id': responsibleSellerId,
      if (registeredAt != null) 'registered_at': registeredAt,
      if (lastPurchaseAt != null) 'last_purchase_at': lastPurchaseAt,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (customFieldsJson != null) 'custom_fields_json': customFieldsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? organizationId,
    Value<String>? companyId,
    Value<String>? type,
    Value<String>? document,
    Value<String?>? legalName,
    Value<String?>? tradeName,
    Value<String?>? fullName,
    Value<String?>? stateRegistration,
    Value<String?>? primaryEmail,
    Value<String?>? primaryPhone,
    Value<String>? status,
    Value<String?>? classification,
    Value<String?>? potential,
    Value<String?>? segment,
    Value<String?>? originChannel,
    Value<String?>? responsibleSellerId,
    Value<DateTime>? registeredAt,
    Value<DateTime?>? lastPurchaseAt,
    Value<String?>? tagsJson,
    Value<String?>? customFieldsJson,
    Value<DateTime>? createdAt,
    Value<String>? createdBy,
    Value<DateTime>? updatedAt,
    Value<String>? updatedBy,
    Value<DateTime?>? deletedAt,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return CustomersTableCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      type: type ?? this.type,
      document: document ?? this.document,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      fullName: fullName ?? this.fullName,
      stateRegistration: stateRegistration ?? this.stateRegistration,
      primaryEmail: primaryEmail ?? this.primaryEmail,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      status: status ?? this.status,
      classification: classification ?? this.classification,
      potential: potential ?? this.potential,
      segment: segment ?? this.segment,
      originChannel: originChannel ?? this.originChannel,
      responsibleSellerId: responsibleSellerId ?? this.responsibleSellerId,
      registeredAt: registeredAt ?? this.registeredAt,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      tagsJson: tagsJson ?? this.tagsJson,
      customFieldsJson: customFieldsJson ?? this.customFieldsJson,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (document.present) {
      map['document'] = Variable<String>(document.value);
    }
    if (legalName.present) {
      map['legal_name'] = Variable<String>(legalName.value);
    }
    if (tradeName.present) {
      map['trade_name'] = Variable<String>(tradeName.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (stateRegistration.present) {
      map['state_registration'] = Variable<String>(stateRegistration.value);
    }
    if (primaryEmail.present) {
      map['primary_email'] = Variable<String>(primaryEmail.value);
    }
    if (primaryPhone.present) {
      map['primary_phone'] = Variable<String>(primaryPhone.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (classification.present) {
      map['classification'] = Variable<String>(classification.value);
    }
    if (potential.present) {
      map['potential'] = Variable<String>(potential.value);
    }
    if (segment.present) {
      map['segment'] = Variable<String>(segment.value);
    }
    if (originChannel.present) {
      map['origin_channel'] = Variable<String>(originChannel.value);
    }
    if (responsibleSellerId.present) {
      map['responsible_seller_id'] = Variable<String>(
        responsibleSellerId.value,
      );
    }
    if (registeredAt.present) {
      map['registered_at'] = Variable<DateTime>(registeredAt.value);
    }
    if (lastPurchaseAt.present) {
      map['last_purchase_at'] = Variable<DateTime>(lastPurchaseAt.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (customFieldsJson.present) {
      map['custom_fields_json'] = Variable<String>(customFieldsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('type: $type, ')
          ..write('document: $document, ')
          ..write('legalName: $legalName, ')
          ..write('tradeName: $tradeName, ')
          ..write('fullName: $fullName, ')
          ..write('stateRegistration: $stateRegistration, ')
          ..write('primaryEmail: $primaryEmail, ')
          ..write('primaryPhone: $primaryPhone, ')
          ..write('status: $status, ')
          ..write('classification: $classification, ')
          ..write('potential: $potential, ')
          ..write('segment: $segment, ')
          ..write('originChannel: $originChannel, ')
          ..write('responsibleSellerId: $responsibleSellerId, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('lastPurchaseAt: $lastPurchaseAt, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('customFieldsJson: $customFieldsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerAddressesTableTable extends CustomerAddressesTable
    with TableInfo<$CustomerAddressesTableTable, CustomerAddressesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerAddressesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeCodeMeta = const VerificationMeta(
    'typeCode',
  );
  @override
  late final GeneratedColumn<String> typeCode = GeneratedColumn<String>(
    'type_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeLabelMeta = const VerificationMeta(
    'typeLabel',
  );
  @override
  late final GeneratedColumn<String> typeLabel = GeneratedColumn<String>(
    'type_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streetMeta = const VerificationMeta('street');
  @override
  late final GeneratedColumn<String> street = GeneratedColumn<String>(
    'street',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _complementMeta = const VerificationMeta(
    'complement',
  );
  @override
  late final GeneratedColumn<String> complement = GeneratedColumn<String>(
    'complement',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zipCodeMeta = const VerificationMeta(
    'zipCode',
  );
  @override
  late final GeneratedColumn<String> zipCode = GeneratedColumn<String>(
    'zip_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    organizationId,
    companyId,
    typeCode,
    typeLabel,
    street,
    number,
    complement,
    district,
    city,
    state,
    zipCode,
    country,
    isPrimary,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_addresses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerAddressesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('type_code')) {
      context.handle(
        _typeCodeMeta,
        typeCode.isAcceptableOrUnknown(data['type_code']!, _typeCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeCodeMeta);
    }
    if (data.containsKey('type_label')) {
      context.handle(
        _typeLabelMeta,
        typeLabel.isAcceptableOrUnknown(data['type_label']!, _typeLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_typeLabelMeta);
    }
    if (data.containsKey('street')) {
      context.handle(
        _streetMeta,
        street.isAcceptableOrUnknown(data['street']!, _streetMeta),
      );
    } else if (isInserting) {
      context.missing(_streetMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('complement')) {
      context.handle(
        _complementMeta,
        complement.isAcceptableOrUnknown(data['complement']!, _complementMeta),
      );
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('zip_code')) {
      context.handle(
        _zipCodeMeta,
        zipCode.isAcceptableOrUnknown(data['zip_code']!, _zipCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_zipCodeMeta);
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    } else if (isInserting) {
      context.missing(_countryMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerAddressesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerAddressesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      typeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_code'],
      )!,
      typeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_label'],
      )!,
      street: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}street'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      ),
      complement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}complement'],
      ),
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      zipCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zip_code'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CustomerAddressesTableTable createAlias(String alias) {
    return $CustomerAddressesTableTable(attachedDatabase, alias);
  }
}

class CustomerAddressesTableData extends DataClass
    implements Insertable<CustomerAddressesTableData> {
  final String id;
  final String customerId;
  final String organizationId;
  final String companyId;
  final String typeCode;
  final String typeLabel;
  final String street;
  final String? number;
  final String? complement;
  final String? district;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isPrimary;
  final int position;
  const CustomerAddressesTableData({
    required this.id,
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.typeCode,
    required this.typeLabel,
    required this.street,
    this.number,
    this.complement,
    this.district,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.isPrimary,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['organization_id'] = Variable<String>(organizationId);
    map['company_id'] = Variable<String>(companyId);
    map['type_code'] = Variable<String>(typeCode);
    map['type_label'] = Variable<String>(typeLabel);
    map['street'] = Variable<String>(street);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<String>(number);
    }
    if (!nullToAbsent || complement != null) {
      map['complement'] = Variable<String>(complement);
    }
    if (!nullToAbsent || district != null) {
      map['district'] = Variable<String>(district);
    }
    map['city'] = Variable<String>(city);
    map['state'] = Variable<String>(state);
    map['zip_code'] = Variable<String>(zipCode);
    map['country'] = Variable<String>(country);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['position'] = Variable<int>(position);
    return map;
  }

  CustomerAddressesTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerAddressesTableCompanion(
      id: Value(id),
      customerId: Value(customerId),
      organizationId: Value(organizationId),
      companyId: Value(companyId),
      typeCode: Value(typeCode),
      typeLabel: Value(typeLabel),
      street: Value(street),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      complement: complement == null && nullToAbsent
          ? const Value.absent()
          : Value(complement),
      district: district == null && nullToAbsent
          ? const Value.absent()
          : Value(district),
      city: Value(city),
      state: Value(state),
      zipCode: Value(zipCode),
      country: Value(country),
      isPrimary: Value(isPrimary),
      position: Value(position),
    );
  }

  factory CustomerAddressesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerAddressesTableData(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      typeCode: serializer.fromJson<String>(json['typeCode']),
      typeLabel: serializer.fromJson<String>(json['typeLabel']),
      street: serializer.fromJson<String>(json['street']),
      number: serializer.fromJson<String?>(json['number']),
      complement: serializer.fromJson<String?>(json['complement']),
      district: serializer.fromJson<String?>(json['district']),
      city: serializer.fromJson<String>(json['city']),
      state: serializer.fromJson<String>(json['state']),
      zipCode: serializer.fromJson<String>(json['zipCode']),
      country: serializer.fromJson<String>(json['country']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'organizationId': serializer.toJson<String>(organizationId),
      'companyId': serializer.toJson<String>(companyId),
      'typeCode': serializer.toJson<String>(typeCode),
      'typeLabel': serializer.toJson<String>(typeLabel),
      'street': serializer.toJson<String>(street),
      'number': serializer.toJson<String?>(number),
      'complement': serializer.toJson<String?>(complement),
      'district': serializer.toJson<String?>(district),
      'city': serializer.toJson<String>(city),
      'state': serializer.toJson<String>(state),
      'zipCode': serializer.toJson<String>(zipCode),
      'country': serializer.toJson<String>(country),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'position': serializer.toJson<int>(position),
    };
  }

  CustomerAddressesTableData copyWith({
    String? id,
    String? customerId,
    String? organizationId,
    String? companyId,
    String? typeCode,
    String? typeLabel,
    String? street,
    Value<String?> number = const Value.absent(),
    Value<String?> complement = const Value.absent(),
    Value<String?> district = const Value.absent(),
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool? isPrimary,
    int? position,
  }) => CustomerAddressesTableData(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    organizationId: organizationId ?? this.organizationId,
    companyId: companyId ?? this.companyId,
    typeCode: typeCode ?? this.typeCode,
    typeLabel: typeLabel ?? this.typeLabel,
    street: street ?? this.street,
    number: number.present ? number.value : this.number,
    complement: complement.present ? complement.value : this.complement,
    district: district.present ? district.value : this.district,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
    country: country ?? this.country,
    isPrimary: isPrimary ?? this.isPrimary,
    position: position ?? this.position,
  );
  CustomerAddressesTableData copyWithCompanion(
    CustomerAddressesTableCompanion data,
  ) {
    return CustomerAddressesTableData(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      typeCode: data.typeCode.present ? data.typeCode.value : this.typeCode,
      typeLabel: data.typeLabel.present ? data.typeLabel.value : this.typeLabel,
      street: data.street.present ? data.street.value : this.street,
      number: data.number.present ? data.number.value : this.number,
      complement: data.complement.present
          ? data.complement.value
          : this.complement,
      district: data.district.present ? data.district.value : this.district,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      zipCode: data.zipCode.present ? data.zipCode.value : this.zipCode,
      country: data.country.present ? data.country.value : this.country,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAddressesTableData(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('typeCode: $typeCode, ')
          ..write('typeLabel: $typeLabel, ')
          ..write('street: $street, ')
          ..write('number: $number, ')
          ..write('complement: $complement, ')
          ..write('district: $district, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('zipCode: $zipCode, ')
          ..write('country: $country, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    organizationId,
    companyId,
    typeCode,
    typeLabel,
    street,
    number,
    complement,
    district,
    city,
    state,
    zipCode,
    country,
    isPrimary,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerAddressesTableData &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.organizationId == this.organizationId &&
          other.companyId == this.companyId &&
          other.typeCode == this.typeCode &&
          other.typeLabel == this.typeLabel &&
          other.street == this.street &&
          other.number == this.number &&
          other.complement == this.complement &&
          other.district == this.district &&
          other.city == this.city &&
          other.state == this.state &&
          other.zipCode == this.zipCode &&
          other.country == this.country &&
          other.isPrimary == this.isPrimary &&
          other.position == this.position);
}

class CustomerAddressesTableCompanion
    extends UpdateCompanion<CustomerAddressesTableData> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> organizationId;
  final Value<String> companyId;
  final Value<String> typeCode;
  final Value<String> typeLabel;
  final Value<String> street;
  final Value<String?> number;
  final Value<String?> complement;
  final Value<String?> district;
  final Value<String> city;
  final Value<String> state;
  final Value<String> zipCode;
  final Value<String> country;
  final Value<bool> isPrimary;
  final Value<int> position;
  final Value<int> rowid;
  const CustomerAddressesTableCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.typeCode = const Value.absent(),
    this.typeLabel = const Value.absent(),
    this.street = const Value.absent(),
    this.number = const Value.absent(),
    this.complement = const Value.absent(),
    this.district = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.zipCode = const Value.absent(),
    this.country = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerAddressesTableCompanion.insert({
    required String id,
    required String customerId,
    required String organizationId,
    required String companyId,
    required String typeCode,
    required String typeLabel,
    required String street,
    this.number = const Value.absent(),
    this.complement = const Value.absent(),
    this.district = const Value.absent(),
    required String city,
    required String state,
    required String zipCode,
    required String country,
    this.isPrimary = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       organizationId = Value(organizationId),
       companyId = Value(companyId),
       typeCode = Value(typeCode),
       typeLabel = Value(typeLabel),
       street = Value(street),
       city = Value(city),
       state = Value(state),
       zipCode = Value(zipCode),
       country = Value(country);
  static Insertable<CustomerAddressesTableData> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? organizationId,
    Expression<String>? companyId,
    Expression<String>? typeCode,
    Expression<String>? typeLabel,
    Expression<String>? street,
    Expression<String>? number,
    Expression<String>? complement,
    Expression<String>? district,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? zipCode,
    Expression<String>? country,
    Expression<bool>? isPrimary,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (organizationId != null) 'organization_id': organizationId,
      if (companyId != null) 'company_id': companyId,
      if (typeCode != null) 'type_code': typeCode,
      if (typeLabel != null) 'type_label': typeLabel,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (district != null) 'district': district,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zipCode != null) 'zip_code': zipCode,
      if (country != null) 'country': country,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerAddressesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String>? organizationId,
    Value<String>? companyId,
    Value<String>? typeCode,
    Value<String>? typeLabel,
    Value<String>? street,
    Value<String?>? number,
    Value<String?>? complement,
    Value<String?>? district,
    Value<String>? city,
    Value<String>? state,
    Value<String>? zipCode,
    Value<String>? country,
    Value<bool>? isPrimary,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CustomerAddressesTableCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      typeCode: typeCode ?? this.typeCode,
      typeLabel: typeLabel ?? this.typeLabel,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      district: district ?? this.district,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      isPrimary: isPrimary ?? this.isPrimary,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (typeCode.present) {
      map['type_code'] = Variable<String>(typeCode.value);
    }
    if (typeLabel.present) {
      map['type_label'] = Variable<String>(typeLabel.value);
    }
    if (street.present) {
      map['street'] = Variable<String>(street.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (complement.present) {
      map['complement'] = Variable<String>(complement.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (zipCode.present) {
      map['zip_code'] = Variable<String>(zipCode.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerAddressesTableCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('typeCode: $typeCode, ')
          ..write('typeLabel: $typeLabel, ')
          ..write('street: $street, ')
          ..write('number: $number, ')
          ..write('complement: $complement, ')
          ..write('district: $district, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('zipCode: $zipCode, ')
          ..write('country: $country, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomerContactsTableTable extends CustomerContactsTable
    with TableInfo<$CustomerContactsTableTable, CustomerContactsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomerContactsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeCodeMeta = const VerificationMeta(
    'typeCode',
  );
  @override
  late final GeneratedColumn<String> typeCode = GeneratedColumn<String>(
    'type_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeLabelMeta = const VerificationMeta(
    'typeLabel',
  );
  @override
  late final GeneratedColumn<String> typeLabel = GeneratedColumn<String>(
    'type_label',
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
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    organizationId,
    companyId,
    typeCode,
    typeLabel,
    name,
    role,
    phone,
    email,
    isPrimary,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customer_contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerContactsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('type_code')) {
      context.handle(
        _typeCodeMeta,
        typeCode.isAcceptableOrUnknown(data['type_code']!, _typeCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeCodeMeta);
    }
    if (data.containsKey('type_label')) {
      context.handle(
        _typeLabelMeta,
        typeLabel.isAcceptableOrUnknown(data['type_label']!, _typeLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_typeLabelMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerContactsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerContactsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      typeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_code'],
      )!,
      typeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_label'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CustomerContactsTableTable createAlias(String alias) {
    return $CustomerContactsTableTable(attachedDatabase, alias);
  }
}

class CustomerContactsTableData extends DataClass
    implements Insertable<CustomerContactsTableData> {
  final String id;
  final String customerId;
  final String organizationId;
  final String companyId;
  final String typeCode;
  final String typeLabel;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final bool isPrimary;
  final int position;
  const CustomerContactsTableData({
    required this.id,
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.typeCode,
    required this.typeLabel,
    required this.name,
    this.role,
    this.phone,
    this.email,
    required this.isPrimary,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['organization_id'] = Variable<String>(organizationId);
    map['company_id'] = Variable<String>(companyId);
    map['type_code'] = Variable<String>(typeCode);
    map['type_label'] = Variable<String>(typeLabel);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['position'] = Variable<int>(position);
    return map;
  }

  CustomerContactsTableCompanion toCompanion(bool nullToAbsent) {
    return CustomerContactsTableCompanion(
      id: Value(id),
      customerId: Value(customerId),
      organizationId: Value(organizationId),
      companyId: Value(companyId),
      typeCode: Value(typeCode),
      typeLabel: Value(typeLabel),
      name: Value(name),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      isPrimary: Value(isPrimary),
      position: Value(position),
    );
  }

  factory CustomerContactsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerContactsTableData(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      typeCode: serializer.fromJson<String>(json['typeCode']),
      typeLabel: serializer.fromJson<String>(json['typeLabel']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String?>(json['role']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'organizationId': serializer.toJson<String>(organizationId),
      'companyId': serializer.toJson<String>(companyId),
      'typeCode': serializer.toJson<String>(typeCode),
      'typeLabel': serializer.toJson<String>(typeLabel),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String?>(role),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'position': serializer.toJson<int>(position),
    };
  }

  CustomerContactsTableData copyWith({
    String? id,
    String? customerId,
    String? organizationId,
    String? companyId,
    String? typeCode,
    String? typeLabel,
    String? name,
    Value<String?> role = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    bool? isPrimary,
    int? position,
  }) => CustomerContactsTableData(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    organizationId: organizationId ?? this.organizationId,
    companyId: companyId ?? this.companyId,
    typeCode: typeCode ?? this.typeCode,
    typeLabel: typeLabel ?? this.typeLabel,
    name: name ?? this.name,
    role: role.present ? role.value : this.role,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    isPrimary: isPrimary ?? this.isPrimary,
    position: position ?? this.position,
  );
  CustomerContactsTableData copyWithCompanion(
    CustomerContactsTableCompanion data,
  ) {
    return CustomerContactsTableData(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      typeCode: data.typeCode.present ? data.typeCode.value : this.typeCode,
      typeLabel: data.typeLabel.present ? data.typeLabel.value : this.typeLabel,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerContactsTableData(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('typeCode: $typeCode, ')
          ..write('typeLabel: $typeLabel, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    organizationId,
    companyId,
    typeCode,
    typeLabel,
    name,
    role,
    phone,
    email,
    isPrimary,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerContactsTableData &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.organizationId == this.organizationId &&
          other.companyId == this.companyId &&
          other.typeCode == this.typeCode &&
          other.typeLabel == this.typeLabel &&
          other.name == this.name &&
          other.role == this.role &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.isPrimary == this.isPrimary &&
          other.position == this.position);
}

class CustomerContactsTableCompanion
    extends UpdateCompanion<CustomerContactsTableData> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> organizationId;
  final Value<String> companyId;
  final Value<String> typeCode;
  final Value<String> typeLabel;
  final Value<String> name;
  final Value<String?> role;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<bool> isPrimary;
  final Value<int> position;
  final Value<int> rowid;
  const CustomerContactsTableCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.typeCode = const Value.absent(),
    this.typeLabel = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomerContactsTableCompanion.insert({
    required String id,
    required String customerId,
    required String organizationId,
    required String companyId,
    required String typeCode,
    required String typeLabel,
    required String name,
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       organizationId = Value(organizationId),
       companyId = Value(companyId),
       typeCode = Value(typeCode),
       typeLabel = Value(typeLabel),
       name = Value(name);
  static Insertable<CustomerContactsTableData> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? organizationId,
    Expression<String>? companyId,
    Expression<String>? typeCode,
    Expression<String>? typeLabel,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<bool>? isPrimary,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (organizationId != null) 'organization_id': organizationId,
      if (companyId != null) 'company_id': companyId,
      if (typeCode != null) 'type_code': typeCode,
      if (typeLabel != null) 'type_label': typeLabel,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomerContactsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String>? organizationId,
    Value<String>? companyId,
    Value<String>? typeCode,
    Value<String>? typeLabel,
    Value<String>? name,
    Value<String?>? role,
    Value<String?>? phone,
    Value<String?>? email,
    Value<bool>? isPrimary,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CustomerContactsTableCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      typeCode: typeCode ?? this.typeCode,
      typeLabel: typeLabel ?? this.typeLabel,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (typeCode.present) {
      map['type_code'] = Variable<String>(typeCode.value);
    }
    if (typeLabel.present) {
      map['type_label'] = Variable<String>(typeLabel.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomerContactsTableCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('typeCode: $typeCode, ')
          ..write('typeLabel: $typeLabel, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomersTableTable customersTable = $CustomersTableTable(this);
  late final $CustomerAddressesTableTable customerAddressesTable =
      $CustomerAddressesTableTable(this);
  late final $CustomerContactsTableTable customerContactsTable =
      $CustomerContactsTableTable(this);
  late final Index idxCustomersOrgCompany = Index(
    'idx_customers_org_company',
    'CREATE INDEX idx_customers_org_company ON customers (organization_id, company_id)',
  );
  late final Index idxCustomerAddressesCustomer = Index(
    'idx_customer_addresses_customer',
    'CREATE INDEX idx_customer_addresses_customer ON customer_addresses (customer_id)',
  );
  late final Index idxCustomerContactsCustomer = Index(
    'idx_customer_contacts_customer',
    'CREATE INDEX idx_customer_contacts_customer ON customer_contacts (customer_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customersTable,
    customerAddressesTable,
    customerContactsTable,
    idxCustomersOrgCompany,
    idxCustomerAddressesCustomer,
    idxCustomerContactsCustomer,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'customers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('customer_addresses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'customers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('customer_contacts', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CustomersTableTableCreateCompanionBuilder =
    CustomersTableCompanion Function({
      required String id,
      required String organizationId,
      required String companyId,
      required String type,
      required String document,
      Value<String?> legalName,
      Value<String?> tradeName,
      Value<String?> fullName,
      Value<String?> stateRegistration,
      Value<String?> primaryEmail,
      Value<String?> primaryPhone,
      required String status,
      Value<String?> classification,
      Value<String?> potential,
      Value<String?> segment,
      Value<String?> originChannel,
      Value<String?> responsibleSellerId,
      required DateTime registeredAt,
      Value<DateTime?> lastPurchaseAt,
      Value<String?> tagsJson,
      Value<String?> customFieldsJson,
      required DateTime createdAt,
      required String createdBy,
      required DateTime updatedAt,
      required String updatedBy,
      Value<DateTime?> deletedAt,
      required int version,
      required String syncStatus,
      Value<int> rowid,
    });
typedef $$CustomersTableTableUpdateCompanionBuilder =
    CustomersTableCompanion Function({
      Value<String> id,
      Value<String> organizationId,
      Value<String> companyId,
      Value<String> type,
      Value<String> document,
      Value<String?> legalName,
      Value<String?> tradeName,
      Value<String?> fullName,
      Value<String?> stateRegistration,
      Value<String?> primaryEmail,
      Value<String?> primaryPhone,
      Value<String> status,
      Value<String?> classification,
      Value<String?> potential,
      Value<String?> segment,
      Value<String?> originChannel,
      Value<String?> responsibleSellerId,
      Value<DateTime> registeredAt,
      Value<DateTime?> lastPurchaseAt,
      Value<String?> tagsJson,
      Value<String?> customFieldsJson,
      Value<DateTime> createdAt,
      Value<String> createdBy,
      Value<DateTime> updatedAt,
      Value<String> updatedBy,
      Value<DateTime?> deletedAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$CustomersTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomersTableTable,
          CustomersTableData
        > {
  $$CustomersTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CustomerAddressesTableTable,
    List<CustomerAddressesTableData>
  >
  _customerAddressesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerAddressesTable,
        aliasName: 'customers__id__customer_addresses__customer_id',
      );

  $$CustomerAddressesTableTableProcessedTableManager
  get customerAddressesTableRefs {
    final manager = $$CustomerAddressesTableTableTableManager(
      $_db,
      $_db.customerAddressesTable,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customerAddressesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CustomerContactsTableTable,
    List<CustomerContactsTableData>
  >
  _customerContactsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customerContactsTable,
        aliasName: 'customers__id__customer_contacts__customer_id',
      );

  $$CustomerContactsTableTableProcessedTableManager
  get customerContactsTableRefs {
    final manager = $$CustomerContactsTableTableTableManager(
      $_db,
      $_db.customerContactsTable,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customerContactsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomersTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableFilterComposer({
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

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tradeName => $composableBuilder(
    column: $table.tradeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateRegistration => $composableBuilder(
    column: $table.stateRegistration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryEmail => $composableBuilder(
    column: $table.primaryEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryPhone => $composableBuilder(
    column: $table.primaryPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get potential => $composableBuilder(
    column: $table.potential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originChannel => $composableBuilder(
    column: $table.originChannel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responsibleSellerId => $composableBuilder(
    column: $table.responsibleSellerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPurchaseAt => $composableBuilder(
    column: $table.lastPurchaseAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> customerAddressesTableRefs(
    Expression<bool> Function($$CustomerAddressesTableTableFilterComposer f) f,
  ) {
    final $$CustomerAddressesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.customerAddressesTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAddressesTableTableFilterComposer(
                $db: $db,
                $table: $db.customerAddressesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> customerContactsTableRefs(
    Expression<bool> Function($$CustomerContactsTableTableFilterComposer f) f,
  ) {
    final $$CustomerContactsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.customerContactsTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerContactsTableTableFilterComposer(
                $db: $db,
                $table: $db.customerContactsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CustomersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableOrderingComposer({
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

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tradeName => $composableBuilder(
    column: $table.tradeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateRegistration => $composableBuilder(
    column: $table.stateRegistration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryEmail => $composableBuilder(
    column: $table.primaryEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryPhone => $composableBuilder(
    column: $table.primaryPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get potential => $composableBuilder(
    column: $table.potential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originChannel => $composableBuilder(
    column: $table.originChannel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responsibleSellerId => $composableBuilder(
    column: $table.responsibleSellerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPurchaseAt => $composableBuilder(
    column: $table.lastPurchaseAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get document =>
      $composableBuilder(column: $table.document, builder: (column) => column);

  GeneratedColumn<String> get legalName =>
      $composableBuilder(column: $table.legalName, builder: (column) => column);

  GeneratedColumn<String> get tradeName =>
      $composableBuilder(column: $table.tradeName, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get stateRegistration => $composableBuilder(
    column: $table.stateRegistration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryEmail => $composableBuilder(
    column: $table.primaryEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryPhone => $composableBuilder(
    column: $table.primaryPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get classification => $composableBuilder(
    column: $table.classification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get potential =>
      $composableBuilder(column: $table.potential, builder: (column) => column);

  GeneratedColumn<String> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => column);

  GeneratedColumn<String> get originChannel => $composableBuilder(
    column: $table.originChannel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responsibleSellerId => $composableBuilder(
    column: $table.responsibleSellerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPurchaseAt => $composableBuilder(
    column: $table.lastPurchaseAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get customFieldsJson => $composableBuilder(
    column: $table.customFieldsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> customerAddressesTableRefs<T extends Object>(
    Expression<T> Function($$CustomerAddressesTableTableAnnotationComposer a) f,
  ) {
    final $$CustomerAddressesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.customerAddressesTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerAddressesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerAddressesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> customerContactsTableRefs<T extends Object>(
    Expression<T> Function($$CustomerContactsTableTableAnnotationComposer a) f,
  ) {
    final $$CustomerContactsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.customerContactsTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomerContactsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.customerContactsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CustomersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTableTable,
          CustomersTableData,
          $$CustomersTableTableFilterComposer,
          $$CustomersTableTableOrderingComposer,
          $$CustomersTableTableAnnotationComposer,
          $$CustomersTableTableCreateCompanionBuilder,
          $$CustomersTableTableUpdateCompanionBuilder,
          (CustomersTableData, $$CustomersTableTableReferences),
          CustomersTableData,
          PrefetchHooks Function({
            bool customerAddressesTableRefs,
            bool customerContactsTableRefs,
          })
        > {
  $$CustomersTableTableTableManager(
    _$AppDatabase db,
    $CustomersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> document = const Value.absent(),
                Value<String?> legalName = const Value.absent(),
                Value<String?> tradeName = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> stateRegistration = const Value.absent(),
                Value<String?> primaryEmail = const Value.absent(),
                Value<String?> primaryPhone = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> classification = const Value.absent(),
                Value<String?> potential = const Value.absent(),
                Value<String?> segment = const Value.absent(),
                Value<String?> originChannel = const Value.absent(),
                Value<String?> responsibleSellerId = const Value.absent(),
                Value<DateTime> registeredAt = const Value.absent(),
                Value<DateTime?> lastPurchaseAt = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<String?> customFieldsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion(
                id: id,
                organizationId: organizationId,
                companyId: companyId,
                type: type,
                document: document,
                legalName: legalName,
                tradeName: tradeName,
                fullName: fullName,
                stateRegistration: stateRegistration,
                primaryEmail: primaryEmail,
                primaryPhone: primaryPhone,
                status: status,
                classification: classification,
                potential: potential,
                segment: segment,
                originChannel: originChannel,
                responsibleSellerId: responsibleSellerId,
                registeredAt: registeredAt,
                lastPurchaseAt: lastPurchaseAt,
                tagsJson: tagsJson,
                customFieldsJson: customFieldsJson,
                createdAt: createdAt,
                createdBy: createdBy,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                version: version,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String organizationId,
                required String companyId,
                required String type,
                required String document,
                Value<String?> legalName = const Value.absent(),
                Value<String?> tradeName = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> stateRegistration = const Value.absent(),
                Value<String?> primaryEmail = const Value.absent(),
                Value<String?> primaryPhone = const Value.absent(),
                required String status,
                Value<String?> classification = const Value.absent(),
                Value<String?> potential = const Value.absent(),
                Value<String?> segment = const Value.absent(),
                Value<String?> originChannel = const Value.absent(),
                Value<String?> responsibleSellerId = const Value.absent(),
                required DateTime registeredAt,
                Value<DateTime?> lastPurchaseAt = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<String?> customFieldsJson = const Value.absent(),
                required DateTime createdAt,
                required String createdBy,
                required DateTime updatedAt,
                required String updatedBy,
                Value<DateTime?> deletedAt = const Value.absent(),
                required int version,
                required String syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => CustomersTableCompanion.insert(
                id: id,
                organizationId: organizationId,
                companyId: companyId,
                type: type,
                document: document,
                legalName: legalName,
                tradeName: tradeName,
                fullName: fullName,
                stateRegistration: stateRegistration,
                primaryEmail: primaryEmail,
                primaryPhone: primaryPhone,
                status: status,
                classification: classification,
                potential: potential,
                segment: segment,
                originChannel: originChannel,
                responsibleSellerId: responsibleSellerId,
                registeredAt: registeredAt,
                lastPurchaseAt: lastPurchaseAt,
                tagsJson: tagsJson,
                customFieldsJson: customFieldsJson,
                createdAt: createdAt,
                createdBy: createdBy,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                version: version,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customerAddressesTableRefs = false,
                customerContactsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (customerAddressesTableRefs) db.customerAddressesTable,
                    if (customerContactsTableRefs) db.customerContactsTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (customerAddressesTableRefs)
                        await $_getPrefetchedData<
                          CustomersTableData,
                          $CustomersTableTable,
                          CustomerAddressesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomersTableTableReferences
                              ._customerAddressesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerAddressesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (customerContactsTableRefs)
                        await $_getPrefetchedData<
                          CustomersTableData,
                          $CustomersTableTable,
                          CustomerContactsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomersTableTableReferences
                              ._customerContactsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customerContactsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.id,
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

typedef $$CustomersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTableTable,
      CustomersTableData,
      $$CustomersTableTableFilterComposer,
      $$CustomersTableTableOrderingComposer,
      $$CustomersTableTableAnnotationComposer,
      $$CustomersTableTableCreateCompanionBuilder,
      $$CustomersTableTableUpdateCompanionBuilder,
      (CustomersTableData, $$CustomersTableTableReferences),
      CustomersTableData,
      PrefetchHooks Function({
        bool customerAddressesTableRefs,
        bool customerContactsTableRefs,
      })
    >;
typedef $$CustomerAddressesTableTableCreateCompanionBuilder =
    CustomerAddressesTableCompanion Function({
      required String id,
      required String customerId,
      required String organizationId,
      required String companyId,
      required String typeCode,
      required String typeLabel,
      required String street,
      Value<String?> number,
      Value<String?> complement,
      Value<String?> district,
      required String city,
      required String state,
      required String zipCode,
      required String country,
      Value<bool> isPrimary,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$CustomerAddressesTableTableUpdateCompanionBuilder =
    CustomerAddressesTableCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<String> organizationId,
      Value<String> companyId,
      Value<String> typeCode,
      Value<String> typeLabel,
      Value<String> street,
      Value<String?> number,
      Value<String?> complement,
      Value<String?> district,
      Value<String> city,
      Value<String> state,
      Value<String> zipCode,
      Value<String> country,
      Value<bool> isPrimary,
      Value<int> position,
      Value<int> rowid,
    });

final class $$CustomerAddressesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomerAddressesTableTable,
          CustomerAddressesTableData
        > {
  $$CustomerAddressesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomersTableTable _customerIdTable(_$AppDatabase db) => db
      .customersTable
      .createAlias('customer_addresses__customer_id__customers__id');

  $$CustomersTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomersTableTableTableManager(
      $_db,
      $_db.customersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomerAddressesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerAddressesTableTable> {
  $$CustomerAddressesTableTableFilterComposer({
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

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeCode => $composableBuilder(
    column: $table.typeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeLabel => $composableBuilder(
    column: $table.typeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get complement => $composableBuilder(
    column: $table.complement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zipCode => $composableBuilder(
    column: $table.zipCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomersTableTableFilterComposer get customerId {
    final $$CustomersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableFilterComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerAddressesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerAddressesTableTable> {
  $$CustomerAddressesTableTableOrderingComposer({
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

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeCode => $composableBuilder(
    column: $table.typeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeLabel => $composableBuilder(
    column: $table.typeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get complement => $composableBuilder(
    column: $table.complement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zipCode => $composableBuilder(
    column: $table.zipCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomersTableTableOrderingComposer get customerId {
    final $$CustomersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableOrderingComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerAddressesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerAddressesTableTable> {
  $$CustomerAddressesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get typeCode =>
      $composableBuilder(column: $table.typeCode, builder: (column) => column);

  GeneratedColumn<String> get typeLabel =>
      $composableBuilder(column: $table.typeLabel, builder: (column) => column);

  GeneratedColumn<String> get street =>
      $composableBuilder(column: $table.street, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get complement => $composableBuilder(
    column: $table.complement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get zipCode =>
      $composableBuilder(column: $table.zipCode, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$CustomersTableTableAnnotationComposer get customerId {
    final $$CustomersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerAddressesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerAddressesTableTable,
          CustomerAddressesTableData,
          $$CustomerAddressesTableTableFilterComposer,
          $$CustomerAddressesTableTableOrderingComposer,
          $$CustomerAddressesTableTableAnnotationComposer,
          $$CustomerAddressesTableTableCreateCompanionBuilder,
          $$CustomerAddressesTableTableUpdateCompanionBuilder,
          (CustomerAddressesTableData, $$CustomerAddressesTableTableReferences),
          CustomerAddressesTableData,
          PrefetchHooks Function({bool customerId})
        > {
  $$CustomerAddressesTableTableTableManager(
    _$AppDatabase db,
    $CustomerAddressesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerAddressesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomerAddressesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerAddressesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> typeCode = const Value.absent(),
                Value<String> typeLabel = const Value.absent(),
                Value<String> street = const Value.absent(),
                Value<String?> number = const Value.absent(),
                Value<String?> complement = const Value.absent(),
                Value<String?> district = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> zipCode = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAddressesTableCompanion(
                id: id,
                customerId: customerId,
                organizationId: organizationId,
                companyId: companyId,
                typeCode: typeCode,
                typeLabel: typeLabel,
                street: street,
                number: number,
                complement: complement,
                district: district,
                city: city,
                state: state,
                zipCode: zipCode,
                country: country,
                isPrimary: isPrimary,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required String organizationId,
                required String companyId,
                required String typeCode,
                required String typeLabel,
                required String street,
                Value<String?> number = const Value.absent(),
                Value<String?> complement = const Value.absent(),
                Value<String?> district = const Value.absent(),
                required String city,
                required String state,
                required String zipCode,
                required String country,
                Value<bool> isPrimary = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerAddressesTableCompanion.insert(
                id: id,
                customerId: customerId,
                organizationId: organizationId,
                companyId: companyId,
                typeCode: typeCode,
                typeLabel: typeLabel,
                street: street,
                number: number,
                complement: complement,
                district: district,
                city: city,
                state: state,
                zipCode: zipCode,
                country: country,
                isPrimary: isPrimary,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomerAddressesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customerId = false}) {
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
                    if (customerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customerId,
                                referencedTable:
                                    $$CustomerAddressesTableTableReferences
                                        ._customerIdTable(db),
                                referencedColumn:
                                    $$CustomerAddressesTableTableReferences
                                        ._customerIdTable(db)
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

typedef $$CustomerAddressesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerAddressesTableTable,
      CustomerAddressesTableData,
      $$CustomerAddressesTableTableFilterComposer,
      $$CustomerAddressesTableTableOrderingComposer,
      $$CustomerAddressesTableTableAnnotationComposer,
      $$CustomerAddressesTableTableCreateCompanionBuilder,
      $$CustomerAddressesTableTableUpdateCompanionBuilder,
      (CustomerAddressesTableData, $$CustomerAddressesTableTableReferences),
      CustomerAddressesTableData,
      PrefetchHooks Function({bool customerId})
    >;
typedef $$CustomerContactsTableTableCreateCompanionBuilder =
    CustomerContactsTableCompanion Function({
      required String id,
      required String customerId,
      required String organizationId,
      required String companyId,
      required String typeCode,
      required String typeLabel,
      required String name,
      Value<String?> role,
      Value<String?> phone,
      Value<String?> email,
      Value<bool> isPrimary,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$CustomerContactsTableTableUpdateCompanionBuilder =
    CustomerContactsTableCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<String> organizationId,
      Value<String> companyId,
      Value<String> typeCode,
      Value<String> typeLabel,
      Value<String> name,
      Value<String?> role,
      Value<String?> phone,
      Value<String?> email,
      Value<bool> isPrimary,
      Value<int> position,
      Value<int> rowid,
    });

final class $$CustomerContactsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomerContactsTableTable,
          CustomerContactsTableData
        > {
  $$CustomerContactsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomersTableTable _customerIdTable(_$AppDatabase db) => db
      .customersTable
      .createAlias('customer_contacts__customer_id__customers__id');

  $$CustomersTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomersTableTableTableManager(
      $_db,
      $_db.customersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomerContactsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomerContactsTableTable> {
  $$CustomerContactsTableTableFilterComposer({
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

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeCode => $composableBuilder(
    column: $table.typeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeLabel => $composableBuilder(
    column: $table.typeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomersTableTableFilterComposer get customerId {
    final $$CustomersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableFilterComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerContactsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomerContactsTableTable> {
  $$CustomerContactsTableTableOrderingComposer({
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

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeCode => $composableBuilder(
    column: $table.typeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeLabel => $composableBuilder(
    column: $table.typeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomersTableTableOrderingComposer get customerId {
    final $$CustomersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableOrderingComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerContactsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomerContactsTableTable> {
  $$CustomerContactsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get typeCode =>
      $composableBuilder(column: $table.typeCode, builder: (column) => column);

  GeneratedColumn<String> get typeLabel =>
      $composableBuilder(column: $table.typeLabel, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$CustomersTableTableAnnotationComposer get customerId {
    final $$CustomersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomerContactsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomerContactsTableTable,
          CustomerContactsTableData,
          $$CustomerContactsTableTableFilterComposer,
          $$CustomerContactsTableTableOrderingComposer,
          $$CustomerContactsTableTableAnnotationComposer,
          $$CustomerContactsTableTableCreateCompanionBuilder,
          $$CustomerContactsTableTableUpdateCompanionBuilder,
          (CustomerContactsTableData, $$CustomerContactsTableTableReferences),
          CustomerContactsTableData,
          PrefetchHooks Function({bool customerId})
        > {
  $$CustomerContactsTableTableTableManager(
    _$AppDatabase db,
    $CustomerContactsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomerContactsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomerContactsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomerContactsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> typeCode = const Value.absent(),
                Value<String> typeLabel = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerContactsTableCompanion(
                id: id,
                customerId: customerId,
                organizationId: organizationId,
                companyId: companyId,
                typeCode: typeCode,
                typeLabel: typeLabel,
                name: name,
                role: role,
                phone: phone,
                email: email,
                isPrimary: isPrimary,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required String organizationId,
                required String companyId,
                required String typeCode,
                required String typeLabel,
                required String name,
                Value<String?> role = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomerContactsTableCompanion.insert(
                id: id,
                customerId: customerId,
                organizationId: organizationId,
                companyId: companyId,
                typeCode: typeCode,
                typeLabel: typeLabel,
                name: name,
                role: role,
                phone: phone,
                email: email,
                isPrimary: isPrimary,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomerContactsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customerId = false}) {
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
                    if (customerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customerId,
                                referencedTable:
                                    $$CustomerContactsTableTableReferences
                                        ._customerIdTable(db),
                                referencedColumn:
                                    $$CustomerContactsTableTableReferences
                                        ._customerIdTable(db)
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

typedef $$CustomerContactsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomerContactsTableTable,
      CustomerContactsTableData,
      $$CustomerContactsTableTableFilterComposer,
      $$CustomerContactsTableTableOrderingComposer,
      $$CustomerContactsTableTableAnnotationComposer,
      $$CustomerContactsTableTableCreateCompanionBuilder,
      $$CustomerContactsTableTableUpdateCompanionBuilder,
      (CustomerContactsTableData, $$CustomerContactsTableTableReferences),
      CustomerContactsTableData,
      PrefetchHooks Function({bool customerId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomersTableTableTableManager get customersTable =>
      $$CustomersTableTableTableManager(_db, _db.customersTable);
  $$CustomerAddressesTableTableTableManager get customerAddressesTable =>
      $$CustomerAddressesTableTableTableManager(
        _db,
        _db.customerAddressesTable,
      );
  $$CustomerContactsTableTableTableManager get customerContactsTable =>
      $$CustomerContactsTableTableTableManager(_db, _db.customerContactsTable);
}
