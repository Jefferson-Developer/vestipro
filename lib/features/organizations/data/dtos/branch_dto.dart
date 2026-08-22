import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
import 'branch_address_dto.dart';

/// Firestore document shape for `organizations/{organizationId}/branches/{id}`
/// (TASK-027). [id] is never one of the map's keys in [toJson] — Firestore
/// already keys the document by it — so it must always be supplied
/// out-of-band (the document snapshot's own id) when building one from
/// [fromJson]. [organizationId] and [companyId] *are* stored as fields
/// (redundant with the document's path/scope) so Firestore Security Rules
/// (TASK-030) and `listByCompany` queries can filter on them.
final class BranchDto {
  const BranchDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.name,
    required this.type,
    this.address,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json, {required String id}) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final name = json['name'];
    final type = json['type'];
    final addressJson = json['address'];
    final status = json['status'];
    final version = json['version'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];

    if (organizationId is! String ||
        companyId is! String ||
        name is! String ||
        type is! String ||
        (addressJson != null && addressJson is! Map<String, dynamic>) ||
        status is! String ||
        version is! int ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid branch payload.',
        code: 'invalid_branch_payload',
      );
    }

    return BranchDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      name: name,
      type: type,
      address: addressJson == null
          ? null
          : BranchAddressDto.fromJson(addressJson as Map<String, dynamic>),
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
  final String companyId;
  final String name;
  final String type;
  final BranchAddressDto? address;
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
      'companyId': companyId,
      'name': name,
      'type': type,
      'address': address?.toJson(),
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
