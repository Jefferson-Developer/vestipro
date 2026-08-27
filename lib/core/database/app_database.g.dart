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
  static const VerificationMeta _commercialScoreMeta = const VerificationMeta(
    'commercialScore',
  );
  @override
  late final GeneratedColumn<int> commercialScore = GeneratedColumn<int>(
    'commercial_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthScoreMeta = const VerificationMeta(
    'healthScore',
  );
  @override
  late final GeneratedColumn<int> healthScore = GeneratedColumn<int>(
    'health_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthScoreBandMeta = const VerificationMeta(
    'healthScoreBand',
  );
  @override
  late final GeneratedColumn<String> healthScoreBand = GeneratedColumn<String>(
    'health_score_band',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoreUpdatedAtMeta = const VerificationMeta(
    'scoreUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> scoreUpdatedAt =
      GeneratedColumn<DateTime>(
        'score_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scoreFormulaVersionMeta =
      const VerificationMeta('scoreFormulaVersion');
  @override
  late final GeneratedColumn<String> scoreFormulaVersion =
      GeneratedColumn<String>(
        'score_formula_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scoreDataCoverageMeta = const VerificationMeta(
    'scoreDataCoverage',
  );
  @override
  late final GeneratedColumn<String> scoreDataCoverage =
      GeneratedColumn<String>(
        'score_data_coverage',
        aliasedName,
        true,
        type: DriftSqlType.string,
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
    commercialScore,
    healthScore,
    healthScoreBand,
    scoreUpdatedAt,
    scoreFormulaVersion,
    scoreDataCoverage,
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
    if (data.containsKey('commercial_score')) {
      context.handle(
        _commercialScoreMeta,
        commercialScore.isAcceptableOrUnknown(
          data['commercial_score']!,
          _commercialScoreMeta,
        ),
      );
    }
    if (data.containsKey('health_score')) {
      context.handle(
        _healthScoreMeta,
        healthScore.isAcceptableOrUnknown(
          data['health_score']!,
          _healthScoreMeta,
        ),
      );
    }
    if (data.containsKey('health_score_band')) {
      context.handle(
        _healthScoreBandMeta,
        healthScoreBand.isAcceptableOrUnknown(
          data['health_score_band']!,
          _healthScoreBandMeta,
        ),
      );
    }
    if (data.containsKey('score_updated_at')) {
      context.handle(
        _scoreUpdatedAtMeta,
        scoreUpdatedAt.isAcceptableOrUnknown(
          data['score_updated_at']!,
          _scoreUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('score_formula_version')) {
      context.handle(
        _scoreFormulaVersionMeta,
        scoreFormulaVersion.isAcceptableOrUnknown(
          data['score_formula_version']!,
          _scoreFormulaVersionMeta,
        ),
      );
    }
    if (data.containsKey('score_data_coverage')) {
      context.handle(
        _scoreDataCoverageMeta,
        scoreDataCoverage.isAcceptableOrUnknown(
          data['score_data_coverage']!,
          _scoreDataCoverageMeta,
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
      commercialScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}commercial_score'],
      ),
      healthScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health_score'],
      ),
      healthScoreBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_score_band'],
      ),
      scoreUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}score_updated_at'],
      ),
      scoreFormulaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_formula_version'],
      ),
      scoreDataCoverage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_data_coverage'],
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
  final int? commercialScore;
  final int? healthScore;
  final String? healthScoreBand;
  final DateTime? scoreUpdatedAt;
  final String? scoreFormulaVersion;
  final String? scoreDataCoverage;
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
    this.commercialScore,
    this.healthScore,
    this.healthScoreBand,
    this.scoreUpdatedAt,
    this.scoreFormulaVersion,
    this.scoreDataCoverage,
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
    if (!nullToAbsent || commercialScore != null) {
      map['commercial_score'] = Variable<int>(commercialScore);
    }
    if (!nullToAbsent || healthScore != null) {
      map['health_score'] = Variable<int>(healthScore);
    }
    if (!nullToAbsent || healthScoreBand != null) {
      map['health_score_band'] = Variable<String>(healthScoreBand);
    }
    if (!nullToAbsent || scoreUpdatedAt != null) {
      map['score_updated_at'] = Variable<DateTime>(scoreUpdatedAt);
    }
    if (!nullToAbsent || scoreFormulaVersion != null) {
      map['score_formula_version'] = Variable<String>(scoreFormulaVersion);
    }
    if (!nullToAbsent || scoreDataCoverage != null) {
      map['score_data_coverage'] = Variable<String>(scoreDataCoverage);
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
      commercialScore: commercialScore == null && nullToAbsent
          ? const Value.absent()
          : Value(commercialScore),
      healthScore: healthScore == null && nullToAbsent
          ? const Value.absent()
          : Value(healthScore),
      healthScoreBand: healthScoreBand == null && nullToAbsent
          ? const Value.absent()
          : Value(healthScoreBand),
      scoreUpdatedAt: scoreUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(scoreUpdatedAt),
      scoreFormulaVersion: scoreFormulaVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(scoreFormulaVersion),
      scoreDataCoverage: scoreDataCoverage == null && nullToAbsent
          ? const Value.absent()
          : Value(scoreDataCoverage),
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
      commercialScore: serializer.fromJson<int?>(json['commercialScore']),
      healthScore: serializer.fromJson<int?>(json['healthScore']),
      healthScoreBand: serializer.fromJson<String?>(json['healthScoreBand']),
      scoreUpdatedAt: serializer.fromJson<DateTime?>(json['scoreUpdatedAt']),
      scoreFormulaVersion: serializer.fromJson<String?>(
        json['scoreFormulaVersion'],
      ),
      scoreDataCoverage: serializer.fromJson<String?>(
        json['scoreDataCoverage'],
      ),
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
      'commercialScore': serializer.toJson<int?>(commercialScore),
      'healthScore': serializer.toJson<int?>(healthScore),
      'healthScoreBand': serializer.toJson<String?>(healthScoreBand),
      'scoreUpdatedAt': serializer.toJson<DateTime?>(scoreUpdatedAt),
      'scoreFormulaVersion': serializer.toJson<String?>(scoreFormulaVersion),
      'scoreDataCoverage': serializer.toJson<String?>(scoreDataCoverage),
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
    Value<int?> commercialScore = const Value.absent(),
    Value<int?> healthScore = const Value.absent(),
    Value<String?> healthScoreBand = const Value.absent(),
    Value<DateTime?> scoreUpdatedAt = const Value.absent(),
    Value<String?> scoreFormulaVersion = const Value.absent(),
    Value<String?> scoreDataCoverage = const Value.absent(),
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
    commercialScore: commercialScore.present
        ? commercialScore.value
        : this.commercialScore,
    healthScore: healthScore.present ? healthScore.value : this.healthScore,
    healthScoreBand: healthScoreBand.present
        ? healthScoreBand.value
        : this.healthScoreBand,
    scoreUpdatedAt: scoreUpdatedAt.present
        ? scoreUpdatedAt.value
        : this.scoreUpdatedAt,
    scoreFormulaVersion: scoreFormulaVersion.present
        ? scoreFormulaVersion.value
        : this.scoreFormulaVersion,
    scoreDataCoverage: scoreDataCoverage.present
        ? scoreDataCoverage.value
        : this.scoreDataCoverage,
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
      commercialScore: data.commercialScore.present
          ? data.commercialScore.value
          : this.commercialScore,
      healthScore: data.healthScore.present
          ? data.healthScore.value
          : this.healthScore,
      healthScoreBand: data.healthScoreBand.present
          ? data.healthScoreBand.value
          : this.healthScoreBand,
      scoreUpdatedAt: data.scoreUpdatedAt.present
          ? data.scoreUpdatedAt.value
          : this.scoreUpdatedAt,
      scoreFormulaVersion: data.scoreFormulaVersion.present
          ? data.scoreFormulaVersion.value
          : this.scoreFormulaVersion,
      scoreDataCoverage: data.scoreDataCoverage.present
          ? data.scoreDataCoverage.value
          : this.scoreDataCoverage,
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
          ..write('commercialScore: $commercialScore, ')
          ..write('healthScore: $healthScore, ')
          ..write('healthScoreBand: $healthScoreBand, ')
          ..write('scoreUpdatedAt: $scoreUpdatedAt, ')
          ..write('scoreFormulaVersion: $scoreFormulaVersion, ')
          ..write('scoreDataCoverage: $scoreDataCoverage, ')
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
    commercialScore,
    healthScore,
    healthScoreBand,
    scoreUpdatedAt,
    scoreFormulaVersion,
    scoreDataCoverage,
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
          other.commercialScore == this.commercialScore &&
          other.healthScore == this.healthScore &&
          other.healthScoreBand == this.healthScoreBand &&
          other.scoreUpdatedAt == this.scoreUpdatedAt &&
          other.scoreFormulaVersion == this.scoreFormulaVersion &&
          other.scoreDataCoverage == this.scoreDataCoverage &&
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
  final Value<int?> commercialScore;
  final Value<int?> healthScore;
  final Value<String?> healthScoreBand;
  final Value<DateTime?> scoreUpdatedAt;
  final Value<String?> scoreFormulaVersion;
  final Value<String?> scoreDataCoverage;
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
    this.commercialScore = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.healthScoreBand = const Value.absent(),
    this.scoreUpdatedAt = const Value.absent(),
    this.scoreFormulaVersion = const Value.absent(),
    this.scoreDataCoverage = const Value.absent(),
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
    this.commercialScore = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.healthScoreBand = const Value.absent(),
    this.scoreUpdatedAt = const Value.absent(),
    this.scoreFormulaVersion = const Value.absent(),
    this.scoreDataCoverage = const Value.absent(),
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
    Expression<int>? commercialScore,
    Expression<int>? healthScore,
    Expression<String>? healthScoreBand,
    Expression<DateTime>? scoreUpdatedAt,
    Expression<String>? scoreFormulaVersion,
    Expression<String>? scoreDataCoverage,
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
      if (commercialScore != null) 'commercial_score': commercialScore,
      if (healthScore != null) 'health_score': healthScore,
      if (healthScoreBand != null) 'health_score_band': healthScoreBand,
      if (scoreUpdatedAt != null) 'score_updated_at': scoreUpdatedAt,
      if (scoreFormulaVersion != null)
        'score_formula_version': scoreFormulaVersion,
      if (scoreDataCoverage != null) 'score_data_coverage': scoreDataCoverage,
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
    Value<int?>? commercialScore,
    Value<int?>? healthScore,
    Value<String?>? healthScoreBand,
    Value<DateTime?>? scoreUpdatedAt,
    Value<String?>? scoreFormulaVersion,
    Value<String?>? scoreDataCoverage,
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
      commercialScore: commercialScore ?? this.commercialScore,
      healthScore: healthScore ?? this.healthScore,
      healthScoreBand: healthScoreBand ?? this.healthScoreBand,
      scoreUpdatedAt: scoreUpdatedAt ?? this.scoreUpdatedAt,
      scoreFormulaVersion: scoreFormulaVersion ?? this.scoreFormulaVersion,
      scoreDataCoverage: scoreDataCoverage ?? this.scoreDataCoverage,
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
    if (commercialScore.present) {
      map['commercial_score'] = Variable<int>(commercialScore.value);
    }
    if (healthScore.present) {
      map['health_score'] = Variable<int>(healthScore.value);
    }
    if (healthScoreBand.present) {
      map['health_score_band'] = Variable<String>(healthScoreBand.value);
    }
    if (scoreUpdatedAt.present) {
      map['score_updated_at'] = Variable<DateTime>(scoreUpdatedAt.value);
    }
    if (scoreFormulaVersion.present) {
      map['score_formula_version'] = Variable<String>(
        scoreFormulaVersion.value,
      );
    }
    if (scoreDataCoverage.present) {
      map['score_data_coverage'] = Variable<String>(scoreDataCoverage.value);
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
          ..write('commercialScore: $commercialScore, ')
          ..write('healthScore: $healthScore, ')
          ..write('healthScoreBand: $healthScoreBand, ')
          ..write('scoreUpdatedAt: $scoreUpdatedAt, ')
          ..write('scoreFormulaVersion: $scoreFormulaVersion, ')
          ..write('scoreDataCoverage: $scoreDataCoverage, ')
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

class $ProductSearchIndexTableTable extends ProductSearchIndexTable
    with TableInfo<$ProductSearchIndexTableTable, ProductSearchIndexTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductSearchIndexTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
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
  static const VerificationMeta _shortDescriptionMeta = const VerificationMeta(
    'shortDescription',
  );
  @override
  late final GeneratedColumn<String> shortDescription = GeneratedColumn<String>(
    'short_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullDescriptionMeta = const VerificationMeta(
    'fullDescription',
  );
  @override
  late final GeneratedColumn<String> fullDescription = GeneratedColumn<String>(
    'full_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<String> line = GeneratedColumn<String>(
    'line',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subcategoryIdMeta = const VerificationMeta(
    'subcategoryId',
  );
  @override
  late final GeneratedColumn<String> subcategoryId = GeneratedColumn<String>(
    'subcategory_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetAudienceMeta = const VerificationMeta(
    'targetAudience',
  );
  @override
  late final GeneratedColumn<String> targetAudience = GeneratedColumn<String>(
    'target_audience',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fabricMeta = const VerificationMeta('fabric');
  @override
  late final GeneratedColumn<String> fabric = GeneratedColumn<String>(
    'fabric',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _compositionMeta = const VerificationMeta(
    'composition',
  );
  @override
  late final GeneratedColumn<String> composition = GeneratedColumn<String>(
    'composition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ncmMeta = const VerificationMeta('ncm');
  @override
  late final GeneratedColumn<String> ncm = GeneratedColumn<String>(
    'ncm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eanMeta = const VerificationMeta('ean');
  @override
  late final GeneratedColumn<String> ean = GeneratedColumn<String>(
    'ean',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _launchDateMeta = const VerificationMeta(
    'launchDate',
  );
  @override
  late final GeneratedColumn<DateTime> launchDate = GeneratedColumn<DateTime>(
    'launch_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seoTitleMeta = const VerificationMeta(
    'seoTitle',
  );
  @override
  late final GeneratedColumn<String> seoTitle = GeneratedColumn<String>(
    'seo_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seoDescriptionMeta = const VerificationMeta(
    'seoDescription',
  );
  @override
  late final GeneratedColumn<String> seoDescription = GeneratedColumn<String>(
    'seo_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seoSlugMeta = const VerificationMeta(
    'seoSlug',
  );
  @override
  late final GeneratedColumn<String> seoSlug = GeneratedColumn<String>(
    'seo_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaJsonMeta = const VerificationMeta(
    'mediaJson',
  );
  @override
  late final GeneratedColumn<String> mediaJson = GeneratedColumn<String>(
    'media_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customFieldValuesJsonMeta =
      const VerificationMeta('customFieldValuesJson');
  @override
  late final GeneratedColumn<String> customFieldValuesJson =
      GeneratedColumn<String>(
        'custom_field_values_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
  static const VerificationMeta _normalizedSearchTextMeta =
      const VerificationMeta('normalizedSearchText');
  @override
  late final GeneratedColumn<String> normalizedSearchText =
      GeneratedColumn<String>(
        'normalized_search_text',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    organizationId,
    companyId,
    sku,
    reference,
    name,
    shortDescription,
    fullDescription,
    brand,
    collectionId,
    seasonId,
    line,
    categoryId,
    subcategoryId,
    gender,
    targetAudience,
    fabric,
    composition,
    supplierId,
    ncm,
    ean,
    tagsJson,
    status,
    launchDate,
    seoTitle,
    seoDescription,
    seoSlug,
    mediaJson,
    customFieldValuesJson,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    deletedAt,
    version,
    syncStatus,
    normalizedSearchText,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_search_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductSearchIndexTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
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
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('short_description')) {
      context.handle(
        _shortDescriptionMeta,
        shortDescription.isAcceptableOrUnknown(
          data['short_description']!,
          _shortDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('full_description')) {
      context.handle(
        _fullDescriptionMeta,
        fullDescription.isAcceptableOrUnknown(
          data['full_description']!,
          _fullDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('subcategory_id')) {
      context.handle(
        _subcategoryIdMeta,
        subcategoryId.isAcceptableOrUnknown(
          data['subcategory_id']!,
          _subcategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('target_audience')) {
      context.handle(
        _targetAudienceMeta,
        targetAudience.isAcceptableOrUnknown(
          data['target_audience']!,
          _targetAudienceMeta,
        ),
      );
    }
    if (data.containsKey('fabric')) {
      context.handle(
        _fabricMeta,
        fabric.isAcceptableOrUnknown(data['fabric']!, _fabricMeta),
      );
    }
    if (data.containsKey('composition')) {
      context.handle(
        _compositionMeta,
        composition.isAcceptableOrUnknown(
          data['composition']!,
          _compositionMeta,
        ),
      );
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    }
    if (data.containsKey('ncm')) {
      context.handle(
        _ncmMeta,
        ncm.isAcceptableOrUnknown(data['ncm']!, _ncmMeta),
      );
    }
    if (data.containsKey('ean')) {
      context.handle(
        _eanMeta,
        ean.isAcceptableOrUnknown(data['ean']!, _eanMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('launch_date')) {
      context.handle(
        _launchDateMeta,
        launchDate.isAcceptableOrUnknown(data['launch_date']!, _launchDateMeta),
      );
    }
    if (data.containsKey('seo_title')) {
      context.handle(
        _seoTitleMeta,
        seoTitle.isAcceptableOrUnknown(data['seo_title']!, _seoTitleMeta),
      );
    }
    if (data.containsKey('seo_description')) {
      context.handle(
        _seoDescriptionMeta,
        seoDescription.isAcceptableOrUnknown(
          data['seo_description']!,
          _seoDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('seo_slug')) {
      context.handle(
        _seoSlugMeta,
        seoSlug.isAcceptableOrUnknown(data['seo_slug']!, _seoSlugMeta),
      );
    }
    if (data.containsKey('media_json')) {
      context.handle(
        _mediaJsonMeta,
        mediaJson.isAcceptableOrUnknown(data['media_json']!, _mediaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaJsonMeta);
    }
    if (data.containsKey('custom_field_values_json')) {
      context.handle(
        _customFieldValuesJsonMeta,
        customFieldValuesJson.isAcceptableOrUnknown(
          data['custom_field_values_json']!,
          _customFieldValuesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customFieldValuesJsonMeta);
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
    if (data.containsKey('normalized_search_text')) {
      context.handle(
        _normalizedSearchTextMeta,
        normalizedSearchText.isAcceptableOrUnknown(
          data['normalized_search_text']!,
          _normalizedSearchTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedSearchTextMeta);
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_indexedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, productId};
  @override
  ProductSearchIndexTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductSearchIndexTableData(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shortDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_description'],
      ),
      fullDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_description'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      ),
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      ),
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      subcategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subcategory_id'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      targetAudience: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_audience'],
      ),
      fabric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fabric'],
      ),
      composition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composition'],
      ),
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      ),
      ncm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ncm'],
      ),
      ean: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ean'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      launchDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}launch_date'],
      ),
      seoTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seo_title'],
      ),
      seoDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seo_description'],
      ),
      seoSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seo_slug'],
      ),
      mediaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_json'],
      )!,
      customFieldValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_field_values_json'],
      )!,
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
      normalizedSearchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_search_text'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
    );
  }

  @override
  $ProductSearchIndexTableTable createAlias(String alias) {
    return $ProductSearchIndexTableTable(attachedDatabase, alias);
  }
}

class ProductSearchIndexTableData extends DataClass
    implements Insertable<ProductSearchIndexTableData> {
  final String productId;
  final String organizationId;
  final String? companyId;
  final String sku;
  final String reference;
  final String name;
  final String? shortDescription;
  final String? fullDescription;
  final String? brand;
  final String? collectionId;
  final String? seasonId;
  final String? line;
  final String? categoryId;
  final String? subcategoryId;
  final String? gender;
  final String? targetAudience;
  final String? fabric;
  final String? composition;
  final String? supplierId;
  final String? ncm;
  final String? ean;
  final String tagsJson;
  final String status;
  final DateTime? launchDate;
  final String? seoTitle;
  final String? seoDescription;
  final String? seoSlug;
  final String mediaJson;
  final String customFieldValuesJson;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;
  final String normalizedSearchText;
  final DateTime indexedAt;
  const ProductSearchIndexTableData({
    required this.productId,
    required this.organizationId,
    this.companyId,
    required this.sku,
    required this.reference,
    required this.name,
    this.shortDescription,
    this.fullDescription,
    this.brand,
    this.collectionId,
    this.seasonId,
    this.line,
    this.categoryId,
    this.subcategoryId,
    this.gender,
    this.targetAudience,
    this.fabric,
    this.composition,
    this.supplierId,
    this.ncm,
    this.ean,
    required this.tagsJson,
    required this.status,
    this.launchDate,
    this.seoTitle,
    this.seoDescription,
    this.seoSlug,
    required this.mediaJson,
    required this.customFieldValuesJson,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
    required this.normalizedSearchText,
    required this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    map['sku'] = Variable<String>(sku);
    map['reference'] = Variable<String>(reference);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || shortDescription != null) {
      map['short_description'] = Variable<String>(shortDescription);
    }
    if (!nullToAbsent || fullDescription != null) {
      map['full_description'] = Variable<String>(fullDescription);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || collectionId != null) {
      map['collection_id'] = Variable<String>(collectionId);
    }
    if (!nullToAbsent || seasonId != null) {
      map['season_id'] = Variable<String>(seasonId);
    }
    if (!nullToAbsent || line != null) {
      map['line'] = Variable<String>(line);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || subcategoryId != null) {
      map['subcategory_id'] = Variable<String>(subcategoryId);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || targetAudience != null) {
      map['target_audience'] = Variable<String>(targetAudience);
    }
    if (!nullToAbsent || fabric != null) {
      map['fabric'] = Variable<String>(fabric);
    }
    if (!nullToAbsent || composition != null) {
      map['composition'] = Variable<String>(composition);
    }
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<String>(supplierId);
    }
    if (!nullToAbsent || ncm != null) {
      map['ncm'] = Variable<String>(ncm);
    }
    if (!nullToAbsent || ean != null) {
      map['ean'] = Variable<String>(ean);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || launchDate != null) {
      map['launch_date'] = Variable<DateTime>(launchDate);
    }
    if (!nullToAbsent || seoTitle != null) {
      map['seo_title'] = Variable<String>(seoTitle);
    }
    if (!nullToAbsent || seoDescription != null) {
      map['seo_description'] = Variable<String>(seoDescription);
    }
    if (!nullToAbsent || seoSlug != null) {
      map['seo_slug'] = Variable<String>(seoSlug);
    }
    map['media_json'] = Variable<String>(mediaJson);
    map['custom_field_values_json'] = Variable<String>(customFieldValuesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['created_by'] = Variable<String>(createdBy);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    map['normalized_search_text'] = Variable<String>(normalizedSearchText);
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  ProductSearchIndexTableCompanion toCompanion(bool nullToAbsent) {
    return ProductSearchIndexTableCompanion(
      productId: Value(productId),
      organizationId: Value(organizationId),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      sku: Value(sku),
      reference: Value(reference),
      name: Value(name),
      shortDescription: shortDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(shortDescription),
      fullDescription: fullDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(fullDescription),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      collectionId: collectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(collectionId),
      seasonId: seasonId == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonId),
      line: line == null && nullToAbsent ? const Value.absent() : Value(line),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      subcategoryId: subcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryId),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      targetAudience: targetAudience == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAudience),
      fabric: fabric == null && nullToAbsent
          ? const Value.absent()
          : Value(fabric),
      composition: composition == null && nullToAbsent
          ? const Value.absent()
          : Value(composition),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      ncm: ncm == null && nullToAbsent ? const Value.absent() : Value(ncm),
      ean: ean == null && nullToAbsent ? const Value.absent() : Value(ean),
      tagsJson: Value(tagsJson),
      status: Value(status),
      launchDate: launchDate == null && nullToAbsent
          ? const Value.absent()
          : Value(launchDate),
      seoTitle: seoTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(seoTitle),
      seoDescription: seoDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(seoDescription),
      seoSlug: seoSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(seoSlug),
      mediaJson: Value(mediaJson),
      customFieldValuesJson: Value(customFieldValuesJson),
      createdAt: Value(createdAt),
      createdBy: Value(createdBy),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      version: Value(version),
      syncStatus: Value(syncStatus),
      normalizedSearchText: Value(normalizedSearchText),
      indexedAt: Value(indexedAt),
    );
  }

  factory ProductSearchIndexTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductSearchIndexTableData(
      productId: serializer.fromJson<String>(json['productId']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      sku: serializer.fromJson<String>(json['sku']),
      reference: serializer.fromJson<String>(json['reference']),
      name: serializer.fromJson<String>(json['name']),
      shortDescription: serializer.fromJson<String?>(json['shortDescription']),
      fullDescription: serializer.fromJson<String?>(json['fullDescription']),
      brand: serializer.fromJson<String?>(json['brand']),
      collectionId: serializer.fromJson<String?>(json['collectionId']),
      seasonId: serializer.fromJson<String?>(json['seasonId']),
      line: serializer.fromJson<String?>(json['line']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      subcategoryId: serializer.fromJson<String?>(json['subcategoryId']),
      gender: serializer.fromJson<String?>(json['gender']),
      targetAudience: serializer.fromJson<String?>(json['targetAudience']),
      fabric: serializer.fromJson<String?>(json['fabric']),
      composition: serializer.fromJson<String?>(json['composition']),
      supplierId: serializer.fromJson<String?>(json['supplierId']),
      ncm: serializer.fromJson<String?>(json['ncm']),
      ean: serializer.fromJson<String?>(json['ean']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      status: serializer.fromJson<String>(json['status']),
      launchDate: serializer.fromJson<DateTime?>(json['launchDate']),
      seoTitle: serializer.fromJson<String?>(json['seoTitle']),
      seoDescription: serializer.fromJson<String?>(json['seoDescription']),
      seoSlug: serializer.fromJson<String?>(json['seoSlug']),
      mediaJson: serializer.fromJson<String>(json['mediaJson']),
      customFieldValuesJson: serializer.fromJson<String>(
        json['customFieldValuesJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      normalizedSearchText: serializer.fromJson<String>(
        json['normalizedSearchText'],
      ),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'organizationId': serializer.toJson<String>(organizationId),
      'companyId': serializer.toJson<String?>(companyId),
      'sku': serializer.toJson<String>(sku),
      'reference': serializer.toJson<String>(reference),
      'name': serializer.toJson<String>(name),
      'shortDescription': serializer.toJson<String?>(shortDescription),
      'fullDescription': serializer.toJson<String?>(fullDescription),
      'brand': serializer.toJson<String?>(brand),
      'collectionId': serializer.toJson<String?>(collectionId),
      'seasonId': serializer.toJson<String?>(seasonId),
      'line': serializer.toJson<String?>(line),
      'categoryId': serializer.toJson<String?>(categoryId),
      'subcategoryId': serializer.toJson<String?>(subcategoryId),
      'gender': serializer.toJson<String?>(gender),
      'targetAudience': serializer.toJson<String?>(targetAudience),
      'fabric': serializer.toJson<String?>(fabric),
      'composition': serializer.toJson<String?>(composition),
      'supplierId': serializer.toJson<String?>(supplierId),
      'ncm': serializer.toJson<String?>(ncm),
      'ean': serializer.toJson<String?>(ean),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'status': serializer.toJson<String>(status),
      'launchDate': serializer.toJson<DateTime?>(launchDate),
      'seoTitle': serializer.toJson<String?>(seoTitle),
      'seoDescription': serializer.toJson<String?>(seoDescription),
      'seoSlug': serializer.toJson<String?>(seoSlug),
      'mediaJson': serializer.toJson<String>(mediaJson),
      'customFieldValuesJson': serializer.toJson<String>(customFieldValuesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'normalizedSearchText': serializer.toJson<String>(normalizedSearchText),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  ProductSearchIndexTableData copyWith({
    String? productId,
    String? organizationId,
    Value<String?> companyId = const Value.absent(),
    String? sku,
    String? reference,
    String? name,
    Value<String?> shortDescription = const Value.absent(),
    Value<String?> fullDescription = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> collectionId = const Value.absent(),
    Value<String?> seasonId = const Value.absent(),
    Value<String?> line = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> subcategoryId = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<String?> targetAudience = const Value.absent(),
    Value<String?> fabric = const Value.absent(),
    Value<String?> composition = const Value.absent(),
    Value<String?> supplierId = const Value.absent(),
    Value<String?> ncm = const Value.absent(),
    Value<String?> ean = const Value.absent(),
    String? tagsJson,
    String? status,
    Value<DateTime?> launchDate = const Value.absent(),
    Value<String?> seoTitle = const Value.absent(),
    Value<String?> seoDescription = const Value.absent(),
    Value<String?> seoSlug = const Value.absent(),
    String? mediaJson,
    String? customFieldValuesJson,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? version,
    String? syncStatus,
    String? normalizedSearchText,
    DateTime? indexedAt,
  }) => ProductSearchIndexTableData(
    productId: productId ?? this.productId,
    organizationId: organizationId ?? this.organizationId,
    companyId: companyId.present ? companyId.value : this.companyId,
    sku: sku ?? this.sku,
    reference: reference ?? this.reference,
    name: name ?? this.name,
    shortDescription: shortDescription.present
        ? shortDescription.value
        : this.shortDescription,
    fullDescription: fullDescription.present
        ? fullDescription.value
        : this.fullDescription,
    brand: brand.present ? brand.value : this.brand,
    collectionId: collectionId.present ? collectionId.value : this.collectionId,
    seasonId: seasonId.present ? seasonId.value : this.seasonId,
    line: line.present ? line.value : this.line,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    subcategoryId: subcategoryId.present
        ? subcategoryId.value
        : this.subcategoryId,
    gender: gender.present ? gender.value : this.gender,
    targetAudience: targetAudience.present
        ? targetAudience.value
        : this.targetAudience,
    fabric: fabric.present ? fabric.value : this.fabric,
    composition: composition.present ? composition.value : this.composition,
    supplierId: supplierId.present ? supplierId.value : this.supplierId,
    ncm: ncm.present ? ncm.value : this.ncm,
    ean: ean.present ? ean.value : this.ean,
    tagsJson: tagsJson ?? this.tagsJson,
    status: status ?? this.status,
    launchDate: launchDate.present ? launchDate.value : this.launchDate,
    seoTitle: seoTitle.present ? seoTitle.value : this.seoTitle,
    seoDescription: seoDescription.present
        ? seoDescription.value
        : this.seoDescription,
    seoSlug: seoSlug.present ? seoSlug.value : this.seoSlug,
    mediaJson: mediaJson ?? this.mediaJson,
    customFieldValuesJson: customFieldValuesJson ?? this.customFieldValuesJson,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy ?? this.createdBy,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    normalizedSearchText: normalizedSearchText ?? this.normalizedSearchText,
    indexedAt: indexedAt ?? this.indexedAt,
  );
  ProductSearchIndexTableData copyWithCompanion(
    ProductSearchIndexTableCompanion data,
  ) {
    return ProductSearchIndexTableData(
      productId: data.productId.present ? data.productId.value : this.productId,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      sku: data.sku.present ? data.sku.value : this.sku,
      reference: data.reference.present ? data.reference.value : this.reference,
      name: data.name.present ? data.name.value : this.name,
      shortDescription: data.shortDescription.present
          ? data.shortDescription.value
          : this.shortDescription,
      fullDescription: data.fullDescription.present
          ? data.fullDescription.value
          : this.fullDescription,
      brand: data.brand.present ? data.brand.value : this.brand,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      line: data.line.present ? data.line.value : this.line,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
      gender: data.gender.present ? data.gender.value : this.gender,
      targetAudience: data.targetAudience.present
          ? data.targetAudience.value
          : this.targetAudience,
      fabric: data.fabric.present ? data.fabric.value : this.fabric,
      composition: data.composition.present
          ? data.composition.value
          : this.composition,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      ncm: data.ncm.present ? data.ncm.value : this.ncm,
      ean: data.ean.present ? data.ean.value : this.ean,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      status: data.status.present ? data.status.value : this.status,
      launchDate: data.launchDate.present
          ? data.launchDate.value
          : this.launchDate,
      seoTitle: data.seoTitle.present ? data.seoTitle.value : this.seoTitle,
      seoDescription: data.seoDescription.present
          ? data.seoDescription.value
          : this.seoDescription,
      seoSlug: data.seoSlug.present ? data.seoSlug.value : this.seoSlug,
      mediaJson: data.mediaJson.present ? data.mediaJson.value : this.mediaJson,
      customFieldValuesJson: data.customFieldValuesJson.present
          ? data.customFieldValuesJson.value
          : this.customFieldValuesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      normalizedSearchText: data.normalizedSearchText.present
          ? data.normalizedSearchText.value
          : this.normalizedSearchText,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductSearchIndexTableData(')
          ..write('productId: $productId, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('sku: $sku, ')
          ..write('reference: $reference, ')
          ..write('name: $name, ')
          ..write('shortDescription: $shortDescription, ')
          ..write('fullDescription: $fullDescription, ')
          ..write('brand: $brand, ')
          ..write('collectionId: $collectionId, ')
          ..write('seasonId: $seasonId, ')
          ..write('line: $line, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('gender: $gender, ')
          ..write('targetAudience: $targetAudience, ')
          ..write('fabric: $fabric, ')
          ..write('composition: $composition, ')
          ..write('supplierId: $supplierId, ')
          ..write('ncm: $ncm, ')
          ..write('ean: $ean, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('status: $status, ')
          ..write('launchDate: $launchDate, ')
          ..write('seoTitle: $seoTitle, ')
          ..write('seoDescription: $seoDescription, ')
          ..write('seoSlug: $seoSlug, ')
          ..write('mediaJson: $mediaJson, ')
          ..write('customFieldValuesJson: $customFieldValuesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('normalizedSearchText: $normalizedSearchText, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    productId,
    organizationId,
    companyId,
    sku,
    reference,
    name,
    shortDescription,
    fullDescription,
    brand,
    collectionId,
    seasonId,
    line,
    categoryId,
    subcategoryId,
    gender,
    targetAudience,
    fabric,
    composition,
    supplierId,
    ncm,
    ean,
    tagsJson,
    status,
    launchDate,
    seoTitle,
    seoDescription,
    seoSlug,
    mediaJson,
    customFieldValuesJson,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    deletedAt,
    version,
    syncStatus,
    normalizedSearchText,
    indexedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductSearchIndexTableData &&
          other.productId == this.productId &&
          other.organizationId == this.organizationId &&
          other.companyId == this.companyId &&
          other.sku == this.sku &&
          other.reference == this.reference &&
          other.name == this.name &&
          other.shortDescription == this.shortDescription &&
          other.fullDescription == this.fullDescription &&
          other.brand == this.brand &&
          other.collectionId == this.collectionId &&
          other.seasonId == this.seasonId &&
          other.line == this.line &&
          other.categoryId == this.categoryId &&
          other.subcategoryId == this.subcategoryId &&
          other.gender == this.gender &&
          other.targetAudience == this.targetAudience &&
          other.fabric == this.fabric &&
          other.composition == this.composition &&
          other.supplierId == this.supplierId &&
          other.ncm == this.ncm &&
          other.ean == this.ean &&
          other.tagsJson == this.tagsJson &&
          other.status == this.status &&
          other.launchDate == this.launchDate &&
          other.seoTitle == this.seoTitle &&
          other.seoDescription == this.seoDescription &&
          other.seoSlug == this.seoSlug &&
          other.mediaJson == this.mediaJson &&
          other.customFieldValuesJson == this.customFieldValuesJson &&
          other.createdAt == this.createdAt &&
          other.createdBy == this.createdBy &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.normalizedSearchText == this.normalizedSearchText &&
          other.indexedAt == this.indexedAt);
}

class ProductSearchIndexTableCompanion
    extends UpdateCompanion<ProductSearchIndexTableData> {
  final Value<String> productId;
  final Value<String> organizationId;
  final Value<String?> companyId;
  final Value<String> sku;
  final Value<String> reference;
  final Value<String> name;
  final Value<String?> shortDescription;
  final Value<String?> fullDescription;
  final Value<String?> brand;
  final Value<String?> collectionId;
  final Value<String?> seasonId;
  final Value<String?> line;
  final Value<String?> categoryId;
  final Value<String?> subcategoryId;
  final Value<String?> gender;
  final Value<String?> targetAudience;
  final Value<String?> fabric;
  final Value<String?> composition;
  final Value<String?> supplierId;
  final Value<String?> ncm;
  final Value<String?> ean;
  final Value<String> tagsJson;
  final Value<String> status;
  final Value<DateTime?> launchDate;
  final Value<String?> seoTitle;
  final Value<String?> seoDescription;
  final Value<String?> seoSlug;
  final Value<String> mediaJson;
  final Value<String> customFieldValuesJson;
  final Value<DateTime> createdAt;
  final Value<String> createdBy;
  final Value<DateTime> updatedAt;
  final Value<String> updatedBy;
  final Value<DateTime?> deletedAt;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<String> normalizedSearchText;
  final Value<DateTime> indexedAt;
  final Value<int> rowid;
  const ProductSearchIndexTableCompanion({
    this.productId = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.sku = const Value.absent(),
    this.reference = const Value.absent(),
    this.name = const Value.absent(),
    this.shortDescription = const Value.absent(),
    this.fullDescription = const Value.absent(),
    this.brand = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.line = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.gender = const Value.absent(),
    this.targetAudience = const Value.absent(),
    this.fabric = const Value.absent(),
    this.composition = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.ncm = const Value.absent(),
    this.ean = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.launchDate = const Value.absent(),
    this.seoTitle = const Value.absent(),
    this.seoDescription = const Value.absent(),
    this.seoSlug = const Value.absent(),
    this.mediaJson = const Value.absent(),
    this.customFieldValuesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.normalizedSearchText = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductSearchIndexTableCompanion.insert({
    required String productId,
    required String organizationId,
    this.companyId = const Value.absent(),
    required String sku,
    required String reference,
    required String name,
    this.shortDescription = const Value.absent(),
    this.fullDescription = const Value.absent(),
    this.brand = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.line = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.gender = const Value.absent(),
    this.targetAudience = const Value.absent(),
    this.fabric = const Value.absent(),
    this.composition = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.ncm = const Value.absent(),
    this.ean = const Value.absent(),
    required String tagsJson,
    required String status,
    this.launchDate = const Value.absent(),
    this.seoTitle = const Value.absent(),
    this.seoDescription = const Value.absent(),
    this.seoSlug = const Value.absent(),
    required String mediaJson,
    required String customFieldValuesJson,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    required int version,
    required String syncStatus,
    required String normalizedSearchText,
    required DateTime indexedAt,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       organizationId = Value(organizationId),
       sku = Value(sku),
       reference = Value(reference),
       name = Value(name),
       tagsJson = Value(tagsJson),
       status = Value(status),
       mediaJson = Value(mediaJson),
       customFieldValuesJson = Value(customFieldValuesJson),
       createdAt = Value(createdAt),
       createdBy = Value(createdBy),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       version = Value(version),
       syncStatus = Value(syncStatus),
       normalizedSearchText = Value(normalizedSearchText),
       indexedAt = Value(indexedAt);
  static Insertable<ProductSearchIndexTableData> custom({
    Expression<String>? productId,
    Expression<String>? organizationId,
    Expression<String>? companyId,
    Expression<String>? sku,
    Expression<String>? reference,
    Expression<String>? name,
    Expression<String>? shortDescription,
    Expression<String>? fullDescription,
    Expression<String>? brand,
    Expression<String>? collectionId,
    Expression<String>? seasonId,
    Expression<String>? line,
    Expression<String>? categoryId,
    Expression<String>? subcategoryId,
    Expression<String>? gender,
    Expression<String>? targetAudience,
    Expression<String>? fabric,
    Expression<String>? composition,
    Expression<String>? supplierId,
    Expression<String>? ncm,
    Expression<String>? ean,
    Expression<String>? tagsJson,
    Expression<String>? status,
    Expression<DateTime>? launchDate,
    Expression<String>? seoTitle,
    Expression<String>? seoDescription,
    Expression<String>? seoSlug,
    Expression<String>? mediaJson,
    Expression<String>? customFieldValuesJson,
    Expression<DateTime>? createdAt,
    Expression<String>? createdBy,
    Expression<DateTime>? updatedAt,
    Expression<String>? updatedBy,
    Expression<DateTime>? deletedAt,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<String>? normalizedSearchText,
    Expression<DateTime>? indexedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (organizationId != null) 'organization_id': organizationId,
      if (companyId != null) 'company_id': companyId,
      if (sku != null) 'sku': sku,
      if (reference != null) 'reference': reference,
      if (name != null) 'name': name,
      if (shortDescription != null) 'short_description': shortDescription,
      if (fullDescription != null) 'full_description': fullDescription,
      if (brand != null) 'brand': brand,
      if (collectionId != null) 'collection_id': collectionId,
      if (seasonId != null) 'season_id': seasonId,
      if (line != null) 'line': line,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (gender != null) 'gender': gender,
      if (targetAudience != null) 'target_audience': targetAudience,
      if (fabric != null) 'fabric': fabric,
      if (composition != null) 'composition': composition,
      if (supplierId != null) 'supplier_id': supplierId,
      if (ncm != null) 'ncm': ncm,
      if (ean != null) 'ean': ean,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (status != null) 'status': status,
      if (launchDate != null) 'launch_date': launchDate,
      if (seoTitle != null) 'seo_title': seoTitle,
      if (seoDescription != null) 'seo_description': seoDescription,
      if (seoSlug != null) 'seo_slug': seoSlug,
      if (mediaJson != null) 'media_json': mediaJson,
      if (customFieldValuesJson != null)
        'custom_field_values_json': customFieldValuesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (normalizedSearchText != null)
        'normalized_search_text': normalizedSearchText,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductSearchIndexTableCompanion copyWith({
    Value<String>? productId,
    Value<String>? organizationId,
    Value<String?>? companyId,
    Value<String>? sku,
    Value<String>? reference,
    Value<String>? name,
    Value<String?>? shortDescription,
    Value<String?>? fullDescription,
    Value<String?>? brand,
    Value<String?>? collectionId,
    Value<String?>? seasonId,
    Value<String?>? line,
    Value<String?>? categoryId,
    Value<String?>? subcategoryId,
    Value<String?>? gender,
    Value<String?>? targetAudience,
    Value<String?>? fabric,
    Value<String?>? composition,
    Value<String?>? supplierId,
    Value<String?>? ncm,
    Value<String?>? ean,
    Value<String>? tagsJson,
    Value<String>? status,
    Value<DateTime?>? launchDate,
    Value<String?>? seoTitle,
    Value<String?>? seoDescription,
    Value<String?>? seoSlug,
    Value<String>? mediaJson,
    Value<String>? customFieldValuesJson,
    Value<DateTime>? createdAt,
    Value<String>? createdBy,
    Value<DateTime>? updatedAt,
    Value<String>? updatedBy,
    Value<DateTime?>? deletedAt,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<String>? normalizedSearchText,
    Value<DateTime>? indexedAt,
    Value<int>? rowid,
  }) {
    return ProductSearchIndexTableCompanion(
      productId: productId ?? this.productId,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      sku: sku ?? this.sku,
      reference: reference ?? this.reference,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      brand: brand ?? this.brand,
      collectionId: collectionId ?? this.collectionId,
      seasonId: seasonId ?? this.seasonId,
      line: line ?? this.line,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      gender: gender ?? this.gender,
      targetAudience: targetAudience ?? this.targetAudience,
      fabric: fabric ?? this.fabric,
      composition: composition ?? this.composition,
      supplierId: supplierId ?? this.supplierId,
      ncm: ncm ?? this.ncm,
      ean: ean ?? this.ean,
      tagsJson: tagsJson ?? this.tagsJson,
      status: status ?? this.status,
      launchDate: launchDate ?? this.launchDate,
      seoTitle: seoTitle ?? this.seoTitle,
      seoDescription: seoDescription ?? this.seoDescription,
      seoSlug: seoSlug ?? this.seoSlug,
      mediaJson: mediaJson ?? this.mediaJson,
      customFieldValuesJson:
          customFieldValuesJson ?? this.customFieldValuesJson,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      normalizedSearchText: normalizedSearchText ?? this.normalizedSearchText,
      indexedAt: indexedAt ?? this.indexedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shortDescription.present) {
      map['short_description'] = Variable<String>(shortDescription.value);
    }
    if (fullDescription.present) {
      map['full_description'] = Variable<String>(fullDescription.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (line.present) {
      map['line'] = Variable<String>(line.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (subcategoryId.present) {
      map['subcategory_id'] = Variable<String>(subcategoryId.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (targetAudience.present) {
      map['target_audience'] = Variable<String>(targetAudience.value);
    }
    if (fabric.present) {
      map['fabric'] = Variable<String>(fabric.value);
    }
    if (composition.present) {
      map['composition'] = Variable<String>(composition.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (ncm.present) {
      map['ncm'] = Variable<String>(ncm.value);
    }
    if (ean.present) {
      map['ean'] = Variable<String>(ean.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (launchDate.present) {
      map['launch_date'] = Variable<DateTime>(launchDate.value);
    }
    if (seoTitle.present) {
      map['seo_title'] = Variable<String>(seoTitle.value);
    }
    if (seoDescription.present) {
      map['seo_description'] = Variable<String>(seoDescription.value);
    }
    if (seoSlug.present) {
      map['seo_slug'] = Variable<String>(seoSlug.value);
    }
    if (mediaJson.present) {
      map['media_json'] = Variable<String>(mediaJson.value);
    }
    if (customFieldValuesJson.present) {
      map['custom_field_values_json'] = Variable<String>(
        customFieldValuesJson.value,
      );
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
    if (normalizedSearchText.present) {
      map['normalized_search_text'] = Variable<String>(
        normalizedSearchText.value,
      );
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductSearchIndexTableCompanion(')
          ..write('productId: $productId, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('sku: $sku, ')
          ..write('reference: $reference, ')
          ..write('name: $name, ')
          ..write('shortDescription: $shortDescription, ')
          ..write('fullDescription: $fullDescription, ')
          ..write('brand: $brand, ')
          ..write('collectionId: $collectionId, ')
          ..write('seasonId: $seasonId, ')
          ..write('line: $line, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('gender: $gender, ')
          ..write('targetAudience: $targetAudience, ')
          ..write('fabric: $fabric, ')
          ..write('composition: $composition, ')
          ..write('supplierId: $supplierId, ')
          ..write('ncm: $ncm, ')
          ..write('ean: $ean, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('status: $status, ')
          ..write('launchDate: $launchDate, ')
          ..write('seoTitle: $seoTitle, ')
          ..write('seoDescription: $seoDescription, ')
          ..write('seoSlug: $seoSlug, ')
          ..write('mediaJson: $mediaJson, ')
          ..write('customFieldValuesJson: $customFieldValuesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('normalizedSearchText: $normalizedSearchText, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTableTable extends FavoritesTable
    with TableInfo<$FavoritesTableTable, FavoritesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
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
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    userId,
    productId,
    companyId,
    createdAt,
    syncStatus,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoritesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
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
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId, userId, productId};
  @override
  FavoritesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoritesTableData(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $FavoritesTableTable createAlias(String alias) {
    return $FavoritesTableTable(attachedDatabase, alias);
  }
}

class FavoritesTableData extends DataClass
    implements Insertable<FavoritesTableData> {
  final String organizationId;
  final String userId;
  final String productId;
  final String? companyId;
  final DateTime createdAt;
  final String syncStatus;
  final DateTime? deletedAt;
  const FavoritesTableData({
    required this.organizationId,
    required this.userId,
    required this.productId,
    this.companyId,
    required this.createdAt,
    required this.syncStatus,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['user_id'] = Variable<String>(userId);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  FavoritesTableCompanion toCompanion(bool nullToAbsent) {
    return FavoritesTableCompanion(
      organizationId: Value(organizationId),
      userId: Value(userId),
      productId: Value(productId),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FavoritesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoritesTableData(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      userId: serializer.fromJson<String>(json['userId']),
      productId: serializer.fromJson<String>(json['productId']),
      companyId: serializer.fromJson<String?>(json['companyId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'userId': serializer.toJson<String>(userId),
      'productId': serializer.toJson<String>(productId),
      'companyId': serializer.toJson<String?>(companyId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  FavoritesTableData copyWith({
    String? organizationId,
    String? userId,
    String? productId,
    Value<String?> companyId = const Value.absent(),
    DateTime? createdAt,
    String? syncStatus,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => FavoritesTableData(
    organizationId: organizationId ?? this.organizationId,
    userId: userId ?? this.userId,
    productId: productId ?? this.productId,
    companyId: companyId.present ? companyId.value : this.companyId,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  FavoritesTableData copyWithCompanion(FavoritesTableCompanion data) {
    return FavoritesTableData(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      userId: data.userId.present ? data.userId.value : this.userId,
      productId: data.productId.present ? data.productId.value : this.productId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesTableData(')
          ..write('organizationId: $organizationId, ')
          ..write('userId: $userId, ')
          ..write('productId: $productId, ')
          ..write('companyId: $companyId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    userId,
    productId,
    companyId,
    createdAt,
    syncStatus,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoritesTableData &&
          other.organizationId == this.organizationId &&
          other.userId == this.userId &&
          other.productId == this.productId &&
          other.companyId == this.companyId &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus &&
          other.deletedAt == this.deletedAt);
}

class FavoritesTableCompanion extends UpdateCompanion<FavoritesTableData> {
  final Value<String> organizationId;
  final Value<String> userId;
  final Value<String> productId;
  final Value<String?> companyId;
  final Value<DateTime> createdAt;
  final Value<String> syncStatus;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const FavoritesTableCompanion({
    this.organizationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.productId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesTableCompanion.insert({
    required String organizationId,
    required String userId,
    required String productId,
    this.companyId = const Value.absent(),
    required DateTime createdAt,
    required String syncStatus,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       userId = Value(userId),
       productId = Value(productId),
       createdAt = Value(createdAt),
       syncStatus = Value(syncStatus);
  static Insertable<FavoritesTableData> custom({
    Expression<String>? organizationId,
    Expression<String>? userId,
    Expression<String>? productId,
    Expression<String>? companyId,
    Expression<DateTime>? createdAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (userId != null) 'user_id': userId,
      if (productId != null) 'product_id': productId,
      if (companyId != null) 'company_id': companyId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesTableCompanion copyWith({
    Value<String>? organizationId,
    Value<String>? userId,
    Value<String>? productId,
    Value<String?>? companyId,
    Value<DateTime>? createdAt,
    Value<String>? syncStatus,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return FavoritesTableCompanion(
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesTableCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('userId: $userId, ')
          ..write('productId: $productId, ')
          ..write('companyId: $companyId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceListsTableTable extends PriceListsTable
    with TableInfo<$PriceListsTableTable, PriceListsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceListsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<DateTime> validFrom = GeneratedColumn<DateTime>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validToMeta = const VerificationMeta(
    'validTo',
  );
  @override
  late final GeneratedColumn<DateTime> validTo = GeneratedColumn<DateTime>(
    'valid_to',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeValueMeta = const VerificationMeta(
    'scopeValue',
  );
  @override
  late final GeneratedColumn<String> scopeValue = GeneratedColumn<String>(
    'scope_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    name,
    currency,
    validFrom,
    validTo,
    status,
    scope,
    scopeValue,
    priority,
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
  static const String $name = 'price_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceListsTableData> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('valid_to')) {
      context.handle(
        _validToMeta,
        validTo.isAcceptableOrUnknown(data['valid_to']!, _validToMeta),
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
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('scope_value')) {
      context.handle(
        _scopeValueMeta,
        scopeValue.isAcceptableOrUnknown(data['scope_value']!, _scopeValueMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
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
  PriceListsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceListsTableData(
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
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_from'],
      )!,
      validTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_to'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      scopeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_value'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
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
  $PriceListsTableTable createAlias(String alias) {
    return $PriceListsTableTable(attachedDatabase, alias);
  }
}

class PriceListsTableData extends DataClass
    implements Insertable<PriceListsTableData> {
  final String id;
  final String organizationId;
  final String companyId;
  final String name;
  final String currency;
  final DateTime validFrom;
  final DateTime? validTo;
  final String status;
  final String scope;
  final String? scopeValue;
  final int priority;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;
  const PriceListsTableData({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.name,
    required this.currency,
    required this.validFrom,
    this.validTo,
    required this.status,
    required this.scope,
    this.scopeValue,
    required this.priority,
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
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    map['valid_from'] = Variable<DateTime>(validFrom);
    if (!nullToAbsent || validTo != null) {
      map['valid_to'] = Variable<DateTime>(validTo);
    }
    map['status'] = Variable<String>(status);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || scopeValue != null) {
      map['scope_value'] = Variable<String>(scopeValue);
    }
    map['priority'] = Variable<int>(priority);
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

  PriceListsTableCompanion toCompanion(bool nullToAbsent) {
    return PriceListsTableCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      companyId: Value(companyId),
      name: Value(name),
      currency: Value(currency),
      validFrom: Value(validFrom),
      validTo: validTo == null && nullToAbsent
          ? const Value.absent()
          : Value(validTo),
      status: Value(status),
      scope: Value(scope),
      scopeValue: scopeValue == null && nullToAbsent
          ? const Value.absent()
          : Value(scopeValue),
      priority: Value(priority),
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

  factory PriceListsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceListsTableData(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      validFrom: serializer.fromJson<DateTime>(json['validFrom']),
      validTo: serializer.fromJson<DateTime?>(json['validTo']),
      status: serializer.fromJson<String>(json['status']),
      scope: serializer.fromJson<String>(json['scope']),
      scopeValue: serializer.fromJson<String?>(json['scopeValue']),
      priority: serializer.fromJson<int>(json['priority']),
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
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'validFrom': serializer.toJson<DateTime>(validFrom),
      'validTo': serializer.toJson<DateTime?>(validTo),
      'status': serializer.toJson<String>(status),
      'scope': serializer.toJson<String>(scope),
      'scopeValue': serializer.toJson<String?>(scopeValue),
      'priority': serializer.toJson<int>(priority),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  PriceListsTableData copyWith({
    String? id,
    String? organizationId,
    String? companyId,
    String? name,
    String? currency,
    DateTime? validFrom,
    Value<DateTime?> validTo = const Value.absent(),
    String? status,
    String? scope,
    Value<String?> scopeValue = const Value.absent(),
    int? priority,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? version,
    String? syncStatus,
  }) => PriceListsTableData(
    id: id ?? this.id,
    organizationId: organizationId ?? this.organizationId,
    companyId: companyId ?? this.companyId,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    validFrom: validFrom ?? this.validFrom,
    validTo: validTo.present ? validTo.value : this.validTo,
    status: status ?? this.status,
    scope: scope ?? this.scope,
    scopeValue: scopeValue.present ? scopeValue.value : this.scopeValue,
    priority: priority ?? this.priority,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy ?? this.createdBy,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  PriceListsTableData copyWithCompanion(PriceListsTableCompanion data) {
    return PriceListsTableData(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validTo: data.validTo.present ? data.validTo.value : this.validTo,
      status: data.status.present ? data.status.value : this.status,
      scope: data.scope.present ? data.scope.value : this.scope,
      scopeValue: data.scopeValue.present
          ? data.scopeValue.value
          : this.scopeValue,
      priority: data.priority.present ? data.priority.value : this.priority,
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
    return (StringBuffer('PriceListsTableData(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('status: $status, ')
          ..write('scope: $scope, ')
          ..write('scopeValue: $scopeValue, ')
          ..write('priority: $priority, ')
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
  int get hashCode => Object.hash(
    id,
    organizationId,
    companyId,
    name,
    currency,
    validFrom,
    validTo,
    status,
    scope,
    scopeValue,
    priority,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    deletedAt,
    version,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceListsTableData &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.companyId == this.companyId &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.validFrom == this.validFrom &&
          other.validTo == this.validTo &&
          other.status == this.status &&
          other.scope == this.scope &&
          other.scopeValue == this.scopeValue &&
          other.priority == this.priority &&
          other.createdAt == this.createdAt &&
          other.createdBy == this.createdBy &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus);
}

class PriceListsTableCompanion extends UpdateCompanion<PriceListsTableData> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> companyId;
  final Value<String> name;
  final Value<String> currency;
  final Value<DateTime> validFrom;
  final Value<DateTime?> validTo;
  final Value<String> status;
  final Value<String> scope;
  final Value<String?> scopeValue;
  final Value<int> priority;
  final Value<DateTime> createdAt;
  final Value<String> createdBy;
  final Value<DateTime> updatedAt;
  final Value<String> updatedBy;
  final Value<DateTime?> deletedAt;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const PriceListsTableCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validTo = const Value.absent(),
    this.status = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeValue = const Value.absent(),
    this.priority = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceListsTableCompanion.insert({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required String currency,
    required DateTime validFrom,
    this.validTo = const Value.absent(),
    required String status,
    required String scope,
    this.scopeValue = const Value.absent(),
    this.priority = const Value.absent(),
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
       name = Value(name),
       currency = Value(currency),
       validFrom = Value(validFrom),
       status = Value(status),
       scope = Value(scope),
       createdAt = Value(createdAt),
       createdBy = Value(createdBy),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       version = Value(version),
       syncStatus = Value(syncStatus);
  static Insertable<PriceListsTableData> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? companyId,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<DateTime>? validFrom,
    Expression<DateTime>? validTo,
    Expression<String>? status,
    Expression<String>? scope,
    Expression<String>? scopeValue,
    Expression<int>? priority,
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
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      if (status != null) 'status': status,
      if (scope != null) 'scope': scope,
      if (scopeValue != null) 'scope_value': scopeValue,
      if (priority != null) 'priority': priority,
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

  PriceListsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? organizationId,
    Value<String>? companyId,
    Value<String>? name,
    Value<String>? currency,
    Value<DateTime>? validFrom,
    Value<DateTime?>? validTo,
    Value<String>? status,
    Value<String>? scope,
    Value<String?>? scopeValue,
    Value<int>? priority,
    Value<DateTime>? createdAt,
    Value<String>? createdBy,
    Value<DateTime>? updatedAt,
    Value<String>? updatedBy,
    Value<DateTime?>? deletedAt,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return PriceListsTableCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      status: status ?? this.status,
      scope: scope ?? this.scope,
      scopeValue: scopeValue ?? this.scopeValue,
      priority: priority ?? this.priority,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<DateTime>(validFrom.value);
    }
    if (validTo.present) {
      map['valid_to'] = Variable<DateTime>(validTo.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (scopeValue.present) {
      map['scope_value'] = Variable<String>(scopeValue.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
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
    return (StringBuffer('PriceListsTableCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('companyId: $companyId, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('validFrom: $validFrom, ')
          ..write('validTo: $validTo, ')
          ..write('status: $status, ')
          ..write('scope: $scope, ')
          ..write('scopeValue: $scopeValue, ')
          ..write('priority: $priority, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomersTableTable customersTable = $CustomersTableTable(this);
  late final $CustomerAddressesTableTable customerAddressesTable =
      $CustomerAddressesTableTable(this);
  late final $CustomerContactsTableTable customerContactsTable =
      $CustomerContactsTableTable(this);
  late final $ProductSearchIndexTableTable productSearchIndexTable =
      $ProductSearchIndexTableTable(this);
  late final $FavoritesTableTable favoritesTable = $FavoritesTableTable(this);
  late final $PriceListsTableTable priceListsTable = $PriceListsTableTable(
    this,
  );
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
  late final Index idxProductSearchIndexOrgText = Index(
    'idx_product_search_index_org_text',
    'CREATE INDEX idx_product_search_index_org_text ON product_search_index (organization_id, normalized_search_text)',
  );
  late final Index idxFavoritesOrgUser = Index(
    'idx_favorites_org_user',
    'CREATE INDEX idx_favorites_org_user ON favorites (organization_id, user_id)',
  );
  late final Index idxPriceListsOrgCompany = Index(
    'idx_price_lists_org_company',
    'CREATE INDEX idx_price_lists_org_company ON price_lists (organization_id, company_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customersTable,
    customerAddressesTable,
    customerContactsTable,
    productSearchIndexTable,
    favoritesTable,
    priceListsTable,
    idxCustomersOrgCompany,
    idxCustomerAddressesCustomer,
    idxCustomerContactsCustomer,
    idxProductSearchIndexOrgText,
    idxFavoritesOrgUser,
    idxPriceListsOrgCompany,
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
      Value<int?> commercialScore,
      Value<int?> healthScore,
      Value<String?> healthScoreBand,
      Value<DateTime?> scoreUpdatedAt,
      Value<String?> scoreFormulaVersion,
      Value<String?> scoreDataCoverage,
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
      Value<int?> commercialScore,
      Value<int?> healthScore,
      Value<String?> healthScoreBand,
      Value<DateTime?> scoreUpdatedAt,
      Value<String?> scoreFormulaVersion,
      Value<String?> scoreDataCoverage,
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

  ColumnFilters<int> get commercialScore => $composableBuilder(
    column: $table.commercialScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthScoreBand => $composableBuilder(
    column: $table.healthScoreBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scoreUpdatedAt => $composableBuilder(
    column: $table.scoreUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoreFormulaVersion => $composableBuilder(
    column: $table.scoreFormulaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoreDataCoverage => $composableBuilder(
    column: $table.scoreDataCoverage,
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

  ColumnOrderings<int> get commercialScore => $composableBuilder(
    column: $table.commercialScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthScoreBand => $composableBuilder(
    column: $table.healthScoreBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scoreUpdatedAt => $composableBuilder(
    column: $table.scoreUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoreFormulaVersion => $composableBuilder(
    column: $table.scoreFormulaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoreDataCoverage => $composableBuilder(
    column: $table.scoreDataCoverage,
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

  GeneratedColumn<int> get commercialScore => $composableBuilder(
    column: $table.commercialScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthScoreBand => $composableBuilder(
    column: $table.healthScoreBand,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scoreUpdatedAt => $composableBuilder(
    column: $table.scoreUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scoreFormulaVersion => $composableBuilder(
    column: $table.scoreFormulaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scoreDataCoverage => $composableBuilder(
    column: $table.scoreDataCoverage,
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
                Value<int?> commercialScore = const Value.absent(),
                Value<int?> healthScore = const Value.absent(),
                Value<String?> healthScoreBand = const Value.absent(),
                Value<DateTime?> scoreUpdatedAt = const Value.absent(),
                Value<String?> scoreFormulaVersion = const Value.absent(),
                Value<String?> scoreDataCoverage = const Value.absent(),
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
                commercialScore: commercialScore,
                healthScore: healthScore,
                healthScoreBand: healthScoreBand,
                scoreUpdatedAt: scoreUpdatedAt,
                scoreFormulaVersion: scoreFormulaVersion,
                scoreDataCoverage: scoreDataCoverage,
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
                Value<int?> commercialScore = const Value.absent(),
                Value<int?> healthScore = const Value.absent(),
                Value<String?> healthScoreBand = const Value.absent(),
                Value<DateTime?> scoreUpdatedAt = const Value.absent(),
                Value<String?> scoreFormulaVersion = const Value.absent(),
                Value<String?> scoreDataCoverage = const Value.absent(),
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
                commercialScore: commercialScore,
                healthScore: healthScore,
                healthScoreBand: healthScoreBand,
                scoreUpdatedAt: scoreUpdatedAt,
                scoreFormulaVersion: scoreFormulaVersion,
                scoreDataCoverage: scoreDataCoverage,
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
typedef $$ProductSearchIndexTableTableCreateCompanionBuilder =
    ProductSearchIndexTableCompanion Function({
      required String productId,
      required String organizationId,
      Value<String?> companyId,
      required String sku,
      required String reference,
      required String name,
      Value<String?> shortDescription,
      Value<String?> fullDescription,
      Value<String?> brand,
      Value<String?> collectionId,
      Value<String?> seasonId,
      Value<String?> line,
      Value<String?> categoryId,
      Value<String?> subcategoryId,
      Value<String?> gender,
      Value<String?> targetAudience,
      Value<String?> fabric,
      Value<String?> composition,
      Value<String?> supplierId,
      Value<String?> ncm,
      Value<String?> ean,
      required String tagsJson,
      required String status,
      Value<DateTime?> launchDate,
      Value<String?> seoTitle,
      Value<String?> seoDescription,
      Value<String?> seoSlug,
      required String mediaJson,
      required String customFieldValuesJson,
      required DateTime createdAt,
      required String createdBy,
      required DateTime updatedAt,
      required String updatedBy,
      Value<DateTime?> deletedAt,
      required int version,
      required String syncStatus,
      required String normalizedSearchText,
      required DateTime indexedAt,
      Value<int> rowid,
    });
typedef $$ProductSearchIndexTableTableUpdateCompanionBuilder =
    ProductSearchIndexTableCompanion Function({
      Value<String> productId,
      Value<String> organizationId,
      Value<String?> companyId,
      Value<String> sku,
      Value<String> reference,
      Value<String> name,
      Value<String?> shortDescription,
      Value<String?> fullDescription,
      Value<String?> brand,
      Value<String?> collectionId,
      Value<String?> seasonId,
      Value<String?> line,
      Value<String?> categoryId,
      Value<String?> subcategoryId,
      Value<String?> gender,
      Value<String?> targetAudience,
      Value<String?> fabric,
      Value<String?> composition,
      Value<String?> supplierId,
      Value<String?> ncm,
      Value<String?> ean,
      Value<String> tagsJson,
      Value<String> status,
      Value<DateTime?> launchDate,
      Value<String?> seoTitle,
      Value<String?> seoDescription,
      Value<String?> seoSlug,
      Value<String> mediaJson,
      Value<String> customFieldValuesJson,
      Value<DateTime> createdAt,
      Value<String> createdBy,
      Value<DateTime> updatedAt,
      Value<String> updatedBy,
      Value<DateTime?> deletedAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<String> normalizedSearchText,
      Value<DateTime> indexedAt,
      Value<int> rowid,
    });

class $$ProductSearchIndexTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductSearchIndexTableTable> {
  $$ProductSearchIndexTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
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

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortDescription => $composableBuilder(
    column: $table.shortDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullDescription => $composableBuilder(
    column: $table.fullDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetAudience => $composableBuilder(
    column: $table.targetAudience,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fabric => $composableBuilder(
    column: $table.fabric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ncm => $composableBuilder(
    column: $table.ncm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ean => $composableBuilder(
    column: $table.ean,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get launchDate => $composableBuilder(
    column: $table.launchDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seoTitle => $composableBuilder(
    column: $table.seoTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seoDescription => $composableBuilder(
    column: $table.seoDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seoSlug => $composableBuilder(
    column: $table.seoSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaJson => $composableBuilder(
    column: $table.mediaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customFieldValuesJson => $composableBuilder(
    column: $table.customFieldValuesJson,
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

  ColumnFilters<String> get normalizedSearchText => $composableBuilder(
    column: $table.normalizedSearchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductSearchIndexTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductSearchIndexTableTable> {
  $$ProductSearchIndexTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
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

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortDescription => $composableBuilder(
    column: $table.shortDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullDescription => $composableBuilder(
    column: $table.fullDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetAudience => $composableBuilder(
    column: $table.targetAudience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fabric => $composableBuilder(
    column: $table.fabric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ncm => $composableBuilder(
    column: $table.ncm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ean => $composableBuilder(
    column: $table.ean,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get launchDate => $composableBuilder(
    column: $table.launchDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seoTitle => $composableBuilder(
    column: $table.seoTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seoDescription => $composableBuilder(
    column: $table.seoDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seoSlug => $composableBuilder(
    column: $table.seoSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaJson => $composableBuilder(
    column: $table.mediaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFieldValuesJson => $composableBuilder(
    column: $table.customFieldValuesJson,
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

  ColumnOrderings<String> get normalizedSearchText => $composableBuilder(
    column: $table.normalizedSearchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductSearchIndexTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductSearchIndexTableTable> {
  $$ProductSearchIndexTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get shortDescription => $composableBuilder(
    column: $table.shortDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullDescription => $composableBuilder(
    column: $table.fullDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<String> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get targetAudience => $composableBuilder(
    column: $table.targetAudience,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fabric =>
      $composableBuilder(column: $table.fabric, builder: (column) => column);

  GeneratedColumn<String> get composition => $composableBuilder(
    column: $table.composition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ncm =>
      $composableBuilder(column: $table.ncm, builder: (column) => column);

  GeneratedColumn<String> get ean =>
      $composableBuilder(column: $table.ean, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get launchDate => $composableBuilder(
    column: $table.launchDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seoTitle =>
      $composableBuilder(column: $table.seoTitle, builder: (column) => column);

  GeneratedColumn<String> get seoDescription => $composableBuilder(
    column: $table.seoDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seoSlug =>
      $composableBuilder(column: $table.seoSlug, builder: (column) => column);

  GeneratedColumn<String> get mediaJson =>
      $composableBuilder(column: $table.mediaJson, builder: (column) => column);

  GeneratedColumn<String> get customFieldValuesJson => $composableBuilder(
    column: $table.customFieldValuesJson,
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

  GeneratedColumn<String> get normalizedSearchText => $composableBuilder(
    column: $table.normalizedSearchText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);
}

class $$ProductSearchIndexTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductSearchIndexTableTable,
          ProductSearchIndexTableData,
          $$ProductSearchIndexTableTableFilterComposer,
          $$ProductSearchIndexTableTableOrderingComposer,
          $$ProductSearchIndexTableTableAnnotationComposer,
          $$ProductSearchIndexTableTableCreateCompanionBuilder,
          $$ProductSearchIndexTableTableUpdateCompanionBuilder,
          (
            ProductSearchIndexTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductSearchIndexTableTable,
              ProductSearchIndexTableData
            >,
          ),
          ProductSearchIndexTableData,
          PrefetchHooks Function()
        > {
  $$ProductSearchIndexTableTableTableManager(
    _$AppDatabase db,
    $ProductSearchIndexTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductSearchIndexTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProductSearchIndexTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductSearchIndexTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> shortDescription = const Value.absent(),
                Value<String?> fullDescription = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> collectionId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<String?> line = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> subcategoryId = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> targetAudience = const Value.absent(),
                Value<String?> fabric = const Value.absent(),
                Value<String?> composition = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> ncm = const Value.absent(),
                Value<String?> ean = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> launchDate = const Value.absent(),
                Value<String?> seoTitle = const Value.absent(),
                Value<String?> seoDescription = const Value.absent(),
                Value<String?> seoSlug = const Value.absent(),
                Value<String> mediaJson = const Value.absent(),
                Value<String> customFieldValuesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String> normalizedSearchText = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductSearchIndexTableCompanion(
                productId: productId,
                organizationId: organizationId,
                companyId: companyId,
                sku: sku,
                reference: reference,
                name: name,
                shortDescription: shortDescription,
                fullDescription: fullDescription,
                brand: brand,
                collectionId: collectionId,
                seasonId: seasonId,
                line: line,
                categoryId: categoryId,
                subcategoryId: subcategoryId,
                gender: gender,
                targetAudience: targetAudience,
                fabric: fabric,
                composition: composition,
                supplierId: supplierId,
                ncm: ncm,
                ean: ean,
                tagsJson: tagsJson,
                status: status,
                launchDate: launchDate,
                seoTitle: seoTitle,
                seoDescription: seoDescription,
                seoSlug: seoSlug,
                mediaJson: mediaJson,
                customFieldValuesJson: customFieldValuesJson,
                createdAt: createdAt,
                createdBy: createdBy,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                version: version,
                syncStatus: syncStatus,
                normalizedSearchText: normalizedSearchText,
                indexedAt: indexedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required String organizationId,
                Value<String?> companyId = const Value.absent(),
                required String sku,
                required String reference,
                required String name,
                Value<String?> shortDescription = const Value.absent(),
                Value<String?> fullDescription = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> collectionId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<String?> line = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> subcategoryId = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> targetAudience = const Value.absent(),
                Value<String?> fabric = const Value.absent(),
                Value<String?> composition = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> ncm = const Value.absent(),
                Value<String?> ean = const Value.absent(),
                required String tagsJson,
                required String status,
                Value<DateTime?> launchDate = const Value.absent(),
                Value<String?> seoTitle = const Value.absent(),
                Value<String?> seoDescription = const Value.absent(),
                Value<String?> seoSlug = const Value.absent(),
                required String mediaJson,
                required String customFieldValuesJson,
                required DateTime createdAt,
                required String createdBy,
                required DateTime updatedAt,
                required String updatedBy,
                Value<DateTime?> deletedAt = const Value.absent(),
                required int version,
                required String syncStatus,
                required String normalizedSearchText,
                required DateTime indexedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductSearchIndexTableCompanion.insert(
                productId: productId,
                organizationId: organizationId,
                companyId: companyId,
                sku: sku,
                reference: reference,
                name: name,
                shortDescription: shortDescription,
                fullDescription: fullDescription,
                brand: brand,
                collectionId: collectionId,
                seasonId: seasonId,
                line: line,
                categoryId: categoryId,
                subcategoryId: subcategoryId,
                gender: gender,
                targetAudience: targetAudience,
                fabric: fabric,
                composition: composition,
                supplierId: supplierId,
                ncm: ncm,
                ean: ean,
                tagsJson: tagsJson,
                status: status,
                launchDate: launchDate,
                seoTitle: seoTitle,
                seoDescription: seoDescription,
                seoSlug: seoSlug,
                mediaJson: mediaJson,
                customFieldValuesJson: customFieldValuesJson,
                createdAt: createdAt,
                createdBy: createdBy,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                version: version,
                syncStatus: syncStatus,
                normalizedSearchText: normalizedSearchText,
                indexedAt: indexedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductSearchIndexTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductSearchIndexTableTable,
      ProductSearchIndexTableData,
      $$ProductSearchIndexTableTableFilterComposer,
      $$ProductSearchIndexTableTableOrderingComposer,
      $$ProductSearchIndexTableTableAnnotationComposer,
      $$ProductSearchIndexTableTableCreateCompanionBuilder,
      $$ProductSearchIndexTableTableUpdateCompanionBuilder,
      (
        ProductSearchIndexTableData,
        BaseReferences<
          _$AppDatabase,
          $ProductSearchIndexTableTable,
          ProductSearchIndexTableData
        >,
      ),
      ProductSearchIndexTableData,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableTableCreateCompanionBuilder =
    FavoritesTableCompanion Function({
      required String organizationId,
      required String userId,
      required String productId,
      Value<String?> companyId,
      required DateTime createdAt,
      required String syncStatus,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$FavoritesTableTableUpdateCompanionBuilder =
    FavoritesTableCompanion Function({
      Value<String> organizationId,
      Value<String> userId,
      Value<String> productId,
      Value<String?> companyId,
      Value<DateTime> createdAt,
      Value<String> syncStatus,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$FavoritesTableTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTableTable> {
  $$FavoritesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$FavoritesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTableTable,
          FavoritesTableData,
          $$FavoritesTableTableFilterComposer,
          $$FavoritesTableTableOrderingComposer,
          $$FavoritesTableTableAnnotationComposer,
          $$FavoritesTableTableCreateCompanionBuilder,
          $$FavoritesTableTableUpdateCompanionBuilder,
          (
            FavoritesTableData,
            BaseReferences<
              _$AppDatabase,
              $FavoritesTableTable,
              FavoritesTableData
            >,
          ),
          FavoritesTableData,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableTableManager(
    _$AppDatabase db,
    $FavoritesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesTableCompanion(
                organizationId: organizationId,
                userId: userId,
                productId: productId,
                companyId: companyId,
                createdAt: createdAt,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                required String userId,
                required String productId,
                Value<String?> companyId = const Value.absent(),
                required DateTime createdAt,
                required String syncStatus,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesTableCompanion.insert(
                organizationId: organizationId,
                userId: userId,
                productId: productId,
                companyId: companyId,
                createdAt: createdAt,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTableTable,
      FavoritesTableData,
      $$FavoritesTableTableFilterComposer,
      $$FavoritesTableTableOrderingComposer,
      $$FavoritesTableTableAnnotationComposer,
      $$FavoritesTableTableCreateCompanionBuilder,
      $$FavoritesTableTableUpdateCompanionBuilder,
      (
        FavoritesTableData,
        BaseReferences<_$AppDatabase, $FavoritesTableTable, FavoritesTableData>,
      ),
      FavoritesTableData,
      PrefetchHooks Function()
    >;
typedef $$PriceListsTableTableCreateCompanionBuilder =
    PriceListsTableCompanion Function({
      required String id,
      required String organizationId,
      required String companyId,
      required String name,
      required String currency,
      required DateTime validFrom,
      Value<DateTime?> validTo,
      required String status,
      required String scope,
      Value<String?> scopeValue,
      Value<int> priority,
      required DateTime createdAt,
      required String createdBy,
      required DateTime updatedAt,
      required String updatedBy,
      Value<DateTime?> deletedAt,
      required int version,
      required String syncStatus,
      Value<int> rowid,
    });
typedef $$PriceListsTableTableUpdateCompanionBuilder =
    PriceListsTableCompanion Function({
      Value<String> id,
      Value<String> organizationId,
      Value<String> companyId,
      Value<String> name,
      Value<String> currency,
      Value<DateTime> validFrom,
      Value<DateTime?> validTo,
      Value<String> status,
      Value<String> scope,
      Value<String?> scopeValue,
      Value<int> priority,
      Value<DateTime> createdAt,
      Value<String> createdBy,
      Value<DateTime> updatedAt,
      Value<String> updatedBy,
      Value<DateTime?> deletedAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$PriceListsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PriceListsTableTable> {
  $$PriceListsTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeValue => $composableBuilder(
    column: $table.scopeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
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
}

class $$PriceListsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceListsTableTable> {
  $$PriceListsTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validTo => $composableBuilder(
    column: $table.validTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeValue => $composableBuilder(
    column: $table.scopeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
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

class $$PriceListsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceListsTableTable> {
  $$PriceListsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get validTo =>
      $composableBuilder(column: $table.validTo, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get scopeValue => $composableBuilder(
    column: $table.scopeValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

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
}

class $$PriceListsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceListsTableTable,
          PriceListsTableData,
          $$PriceListsTableTableFilterComposer,
          $$PriceListsTableTableOrderingComposer,
          $$PriceListsTableTableAnnotationComposer,
          $$PriceListsTableTableCreateCompanionBuilder,
          $$PriceListsTableTableUpdateCompanionBuilder,
          (
            PriceListsTableData,
            BaseReferences<
              _$AppDatabase,
              $PriceListsTableTable,
              PriceListsTableData
            >,
          ),
          PriceListsTableData,
          PrefetchHooks Function()
        > {
  $$PriceListsTableTableTableManager(
    _$AppDatabase db,
    $PriceListsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceListsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceListsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceListsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> validFrom = const Value.absent(),
                Value<DateTime?> validTo = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> scopeValue = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceListsTableCompanion(
                id: id,
                organizationId: organizationId,
                companyId: companyId,
                name: name,
                currency: currency,
                validFrom: validFrom,
                validTo: validTo,
                status: status,
                scope: scope,
                scopeValue: scopeValue,
                priority: priority,
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
                required String name,
                required String currency,
                required DateTime validFrom,
                Value<DateTime?> validTo = const Value.absent(),
                required String status,
                required String scope,
                Value<String?> scopeValue = const Value.absent(),
                Value<int> priority = const Value.absent(),
                required DateTime createdAt,
                required String createdBy,
                required DateTime updatedAt,
                required String updatedBy,
                Value<DateTime?> deletedAt = const Value.absent(),
                required int version,
                required String syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => PriceListsTableCompanion.insert(
                id: id,
                organizationId: organizationId,
                companyId: companyId,
                name: name,
                currency: currency,
                validFrom: validFrom,
                validTo: validTo,
                status: status,
                scope: scope,
                scopeValue: scopeValue,
                priority: priority,
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PriceListsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceListsTableTable,
      PriceListsTableData,
      $$PriceListsTableTableFilterComposer,
      $$PriceListsTableTableOrderingComposer,
      $$PriceListsTableTableAnnotationComposer,
      $$PriceListsTableTableCreateCompanionBuilder,
      $$PriceListsTableTableUpdateCompanionBuilder,
      (
        PriceListsTableData,
        BaseReferences<
          _$AppDatabase,
          $PriceListsTableTable,
          PriceListsTableData
        >,
      ),
      PriceListsTableData,
      PrefetchHooks Function()
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
  $$ProductSearchIndexTableTableTableManager get productSearchIndexTable =>
      $$ProductSearchIndexTableTableTableManager(
        _db,
        _db.productSearchIndexTable,
      );
  $$FavoritesTableTableTableManager get favoritesTable =>
      $$FavoritesTableTableTableManager(_db, _db.favoritesTable);
  $$PriceListsTableTableTableManager get priceListsTable =>
      $$PriceListsTableTableTableManager(_db, _db.priceListsTable);
}
