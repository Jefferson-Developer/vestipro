import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for `organizations/{organizationId}/companies/{id}`
/// (TASK-027). [id] is never one of the map's keys in [toJson] — Firestore
/// already keys the document by it — so it must always be supplied
/// out-of-band (the document snapshot's own id) when building one from
/// [fromJson]. [organizationId] *is* stored as a field (redundant with the
/// document's path) so Firestore Security Rules (TASK-030) can validate it
/// without reading the path.
final class CompanyDto {
  const CompanyDto({
    required this.id,
    required this.organizationId,
    required this.name,
    this.legalName,
    this.taxId,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });

  factory CompanyDto.fromJson(Map<String, dynamic> json, {required String id}) {
    final organizationId = json['organizationId'];
    final name = json['name'];
    final legalName = json['legalName'];
    final taxId = json['taxId'];
    final status = json['status'];
    final version = json['version'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];

    if (organizationId is! String ||
        name is! String ||
        (legalName != null && legalName is! String) ||
        (taxId != null && taxId is! String) ||
        status is! String ||
        version is! int ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid company payload.',
        code: 'invalid_company_payload',
      );
    }

    return CompanyDto(
      id: id,
      organizationId: organizationId,
      name: name,
      legalName: legalName as String?,
      taxId: taxId as String?,
      status: status,
      version: version,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String name;
  final String? legalName;
  final String? taxId;
  final String status;
  final int version;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'name': name,
      'legalName': legalName,
      'taxId': taxId,
      'status': status,
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
    };
  }
}
