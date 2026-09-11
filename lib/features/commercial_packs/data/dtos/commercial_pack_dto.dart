import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
import 'assortment_rule_dto.dart';
import 'pack_component_dto.dart';

/// Firestore document shape for a `CommercialPack` scoped by organization
/// (TASK-207, EPIC-32), modeling
/// `organizations/{organizationId}/commercialPacks/{commercialPackId}`.
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] remains duplicated in the payload so Security
/// Rules and queries can validate tenant scope without trusting a client
/// value — same contract [CustomerDto]/[PriceListDto]/[OrderDto] already
/// follow. [components]/[assortmentRules] are embedded arrays (never their
/// own subcollection), same precedent [OrderDto.items] already sets — this
/// feature never needs to query into an individual component/rule at the
/// Firestore/SQL level, only load the whole pack.
final class CommercialPackDto {
  const CommercialPackDto({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.packCode,
    required this.version,
    required this.name,
    this.description,
    required this.packType,
    required this.status,
    required this.pricingPolicyType,
    this.fixedPrice,
    this.discountPercentage,
    this.bonusComponentId,
    required this.stockPolicyType,
    this.dedicatedWarehouseId,
    this.collectionId,
    this.campaignId,
    this.customerSegment,
    this.channel,
    required this.validFrom,
    this.validTo,
    this.components = const <PackComponentDto>[],
    this.assortmentRules = const <AssortmentRuleDto>[],
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    this.supersededByPackId,
    required this.syncStatus,
  });

  factory CommercialPackDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final packCode = json['packCode'];
    final version = json['version'];
    final name = json['name'];
    final description = json['description'];
    final packType = json['packType'];
    final status = json['status'];
    final pricingPolicyType = json['pricingPolicyType'];
    final fixedPrice = json['fixedPrice'];
    final discountPercentage = json['discountPercentage'];
    final bonusComponentId = json['bonusComponentId'];
    final stockPolicyType = json['stockPolicyType'];
    final dedicatedWarehouseId = json['dedicatedWarehouseId'];
    final collectionId = json['collectionId'];
    final campaignId = json['campaignId'];
    final customerSegment = json['customerSegment'];
    final channel = json['channel'];
    final validFrom = json['validFrom'];
    final validTo = json['validTo'];
    final rawComponents = json['components'];
    final rawAssortmentRules = json['assortmentRules'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];
    final supersededByPackId = json['supersededByPackId'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        (companyId != null && companyId is! String) ||
        packCode is! String ||
        version is! int ||
        name is! String ||
        (description != null && description is! String) ||
        packType is! String ||
        status is! String ||
        pricingPolicyType is! String ||
        (fixedPrice != null && fixedPrice is! num) ||
        (discountPercentage != null && discountPercentage is! num) ||
        (bonusComponentId != null && bonusComponentId is! String) ||
        stockPolicyType is! String ||
        (dedicatedWarehouseId != null && dedicatedWarehouseId is! String) ||
        (collectionId != null && collectionId is! String) ||
        (campaignId != null && campaignId is! String) ||
        (customerSegment != null && customerSegment is! String) ||
        (channel != null && channel is! String) ||
        validFrom is! Timestamp ||
        (validTo != null && validTo is! Timestamp) ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp) ||
        (supersededByPackId != null && supersededByPackId is! String) ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid commercial pack payload.',
        code: 'invalid_commercial_pack_payload',
      );
    }

    return CommercialPackDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId as String?,
      packCode: packCode,
      version: version,
      name: name,
      description: description as String?,
      packType: packType,
      status: status,
      pricingPolicyType: pricingPolicyType,
      fixedPrice: (fixedPrice as num?)?.toDouble(),
      discountPercentage: (discountPercentage as num?)?.toDouble(),
      bonusComponentId: bonusComponentId as String?,
      stockPolicyType: stockPolicyType,
      dedicatedWarehouseId: dedicatedWarehouseId as String?,
      collectionId: collectionId as String?,
      campaignId: campaignId as String?,
      customerSegment: customerSegment as String?,
      channel: channel as String?,
      validFrom: validFrom.toDate(),
      validTo: (validTo as Timestamp?)?.toDate(),
      components: _componentDtosFromJson(rawComponents),
      assortmentRules: _assortmentRuleDtosFromJson(rawAssortmentRules),
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
      supersededByPackId: supersededByPackId as String?,
      syncStatus: syncStatus,
    );
  }

  final String id;
  final String organizationId;
  final String? companyId;
  final String packCode;
  final int version;
  final String name;
  final String? description;
  final String packType;
  final String status;
  final String pricingPolicyType;
  final double? fixedPrice;
  final double? discountPercentage;
  final String? bonusComponentId;
  final String stockPolicyType;
  final String? dedicatedWarehouseId;
  final String? collectionId;
  final String? campaignId;
  final String? customerSegment;
  final String? channel;
  final DateTime validFrom;
  final DateTime? validTo;
  final List<PackComponentDto> components;
  final List<AssortmentRuleDto> assortmentRules;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final String? supersededByPackId;
  final String syncStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'packCode': packCode,
      'version': version,
      'name': name,
      'description': description,
      'packType': packType,
      'status': status,
      'pricingPolicyType': pricingPolicyType,
      'fixedPrice': fixedPrice,
      'discountPercentage': discountPercentage,
      'bonusComponentId': bonusComponentId,
      'stockPolicyType': stockPolicyType,
      'dedicatedWarehouseId': dedicatedWarehouseId,
      'collectionId': collectionId,
      'campaignId': campaignId,
      'customerSegment': customerSegment,
      'channel': channel,
      'validFrom': Timestamp.fromDate(validFrom),
      'validTo': validTo == null ? null : Timestamp.fromDate(validTo!),
      'components': components
          .map((component) => component.toJson())
          .toList(growable: false),
      'assortmentRules': assortmentRules
          .map((rule) => rule.toJson())
          .toList(growable: false),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'supersededByPackId': supersededByPackId,
      'syncStatus': syncStatus,
    };
  }
}

List<PackComponentDto> _componentDtosFromJson(Object? value) {
  if (value == null) return const <PackComponentDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid commercial pack components payload.',
      code: 'invalid_commercial_pack_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid pack component payload.',
            code: 'invalid_commercial_pack_payload',
          );
        }
        return PackComponentDto.fromJson(item);
      })
      .toList(growable: false);
}

List<AssortmentRuleDto> _assortmentRuleDtosFromJson(Object? value) {
  if (value == null) return const <AssortmentRuleDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid commercial pack assortment rules payload.',
      code: 'invalid_commercial_pack_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid assortment rule payload.',
            code: 'invalid_commercial_pack_payload',
          );
        }
        return AssortmentRuleDto.fromJson(item);
      })
      .toList(growable: false);
}
