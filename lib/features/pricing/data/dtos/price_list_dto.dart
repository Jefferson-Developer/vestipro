import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for a Price List scoped by organization
/// (EPIC-11, TASK-083), modeling
/// `organizations/{organizationId}/priceLists/{priceListId}`
/// (`docs/architecture/firestore-schema.md`).
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] and [companyId] remain duplicated in the
/// payload so Security Rules and queries can validate tenant scope without
/// trusting a client value — same contract [CustomerDto]/[ProductDto]
/// already follow.
final class PriceListDto {
  const PriceListDto({
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

  factory PriceListDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final name = json['name'];
    final currency = json['currency'];
    final validFrom = json['validFrom'];
    final validTo = json['validTo'];
    final status = json['status'];
    final scope = json['scope'];
    final scopeValue = json['scopeValue'];
    final priority = json['priority'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];
    final version = json['version'];
    final syncStatus = json['syncStatus'];

    if (organizationId is! String ||
        companyId is! String ||
        name is! String ||
        currency is! String ||
        validFrom is! Timestamp ||
        (validTo != null && validTo is! Timestamp) ||
        status is! String ||
        scope is! String ||
        (scopeValue != null && scopeValue is! String) ||
        priority is! int ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp) ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid price list payload.',
        code: 'invalid_price_list_payload',
      );
    }

    return PriceListDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      name: name,
      currency: currency,
      validFrom: validFrom.toDate(),
      validTo: (validTo as Timestamp?)?.toDate(),
      status: status,
      scope: scope,
      scopeValue: scopeValue as String?,
      priority: priority,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
      version: version,
      syncStatus: syncStatus,
    );
  }

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'name': name,
      'currency': currency,
      'validFrom': Timestamp.fromDate(validFrom),
      'validTo': validTo == null ? null : Timestamp.fromDate(validTo!),
      'status': status,
      'scope': scope,
      'scopeValue': scopeValue,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'version': version,
      'syncStatus': syncStatus,
    };
  }
}
