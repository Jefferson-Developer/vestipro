import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class WarehouseDto {
  const WarehouseDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    this.branchId,
    required this.code,
    required this.name,
    required this.type,
    required this.isActive,
    required this.priority,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
  });

  factory WarehouseDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final branchId = json['branchId'];
    final code = json['code'];
    final name = json['name'];
    final type = json['type'];
    final isActive = json['isActive'];
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
        (branchId != null && branchId is! String) ||
        code is! String ||
        name is! String ||
        type is! String ||
        isActive is! bool ||
        priority is! int ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp) ||
        version is! int ||
        syncStatus is! String) {
      throw const ValidationException(
        'Invalid warehouse payload.',
        code: 'invalid_warehouse_payload',
      );
    }

    return WarehouseDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      branchId: branchId as String?,
      code: code,
      name: name,
      type: type,
      isActive: isActive,
      priority: priority,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: deletedAt == null ? null : (deletedAt as Timestamp).toDate(),
      version: version,
      syncStatus: syncStatus,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String? branchId;
  final String code;
  final String name;
  final String type;
  final bool isActive;
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
      'branchId': branchId,
      'code': code,
      'name': name,
      'type': type,
      'isActive': isActive,
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
