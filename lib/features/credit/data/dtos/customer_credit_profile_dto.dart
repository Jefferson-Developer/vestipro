import 'package:cloud_firestore/cloud_firestore.dart';

final class CustomerCreditManualBlockDto {
  const CustomerCreditManualBlockDto({
    required this.active,
    this.reason,
    this.by,
    this.at,
  });

  factory CustomerCreditManualBlockDto.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final at = map['at'];
    return CustomerCreditManualBlockDto(
      active: map['active'] == true,
      reason: map['reason'] as String?,
      by: map['by'] as String?,
      at: at is Timestamp ? at.toDate() : null,
    );
  }

  final bool active;
  final String? reason;
  final String? by;
  final DateTime? at;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'active': active,
    'reason': reason,
    'by': by,
    'at': at == null ? null : Timestamp.fromDate(at!),
  };
}

final class CustomerCreditOverrideDto {
  const CustomerCreditOverrideDto({
    required this.active,
    this.reason,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.expiresAt,
  });

  factory CustomerCreditOverrideDto.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    final approvedAt = map['approvedAt'];
    final expiresAt = map['expiresAt'];
    return CustomerCreditOverrideDto(
      active: map['active'] == true,
      reason: map['reason'] as String?,
      approvedBy: map['approvedBy'] as String?,
      approvedByName: map['approvedByName'] as String?,
      approvedAt: approvedAt is Timestamp ? approvedAt.toDate() : null,
      expiresAt: expiresAt is Timestamp ? expiresAt.toDate() : null,
    );
  }

  final bool active;
  final String? reason;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'active': active,
    'reason': reason,
    'approvedBy': approvedBy,
    'approvedByName': approvedByName,
    'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
    'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
  };
}

/// `organizations/{organizationId}/creditProfiles/{customerId}` document
/// shape (TASK-212) — mirrors the server's own `mapCreditProfile`
/// (`credit-shared.ts`) field for field, including its safe defaults for a
/// missing/partial document (this DTO never throws on a missing optional
/// field, same "defaults to the safest value" precedent).
final class CustomerCreditProfileDto {
  const CustomerCreditProfileDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.creditLimit,
    required this.openBalance,
    required this.overdueBalance,
    required this.blockPolicy,
    this.financialScore,
    required this.dataSource,
    required this.dataUpdatedAt,
    required this.manualBlock,
    required this.creditOverride,
    required this.updatedAt,
    required this.version,
  });

  factory CustomerCreditProfileDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final dataUpdatedAt = json['dataUpdatedAt'];
    final updatedAt = json['updatedAt'];
    final rawFinancialScore = json['financialScore'];
    return CustomerCreditProfileDto(
      id: id,
      organizationId: json['organizationId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      creditLimit: _asDouble(json['creditLimit']),
      openBalance: _asDouble(json['openBalance']),
      overdueBalance: _asDouble(json['overdueBalance']),
      blockPolicy: json['blockPolicy'] as String? ?? 'none',
      financialScore: rawFinancialScore is num
          ? rawFinancialScore.toDouble()
          : null,
      dataSource: json['dataSource'] as String? ?? 'manual',
      dataUpdatedAt: dataUpdatedAt is Timestamp
          ? dataUpdatedAt.toDate()
          : DateTime.now(),
      manualBlock: CustomerCreditManualBlockDto.fromJson(
        json['manualBlock'] as Map<String, dynamic>?,
      ),
      creditOverride: CustomerCreditOverrideDto.fromJson(
        json['override'] as Map<String, dynamic>?,
      ),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final double creditLimit;
  final double openBalance;
  final double overdueBalance;
  final String blockPolicy;
  final double? financialScore;
  final String dataSource;
  final DateTime dataUpdatedAt;
  final CustomerCreditManualBlockDto manualBlock;
  final CustomerCreditOverrideDto creditOverride;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'companyId': companyId,
    'creditLimit': creditLimit,
    'openBalance': openBalance,
    'overdueBalance': overdueBalance,
    'blockPolicy': blockPolicy,
    'financialScore': financialScore,
    'dataSource': dataSource,
    'dataUpdatedAt': Timestamp.fromDate(dataUpdatedAt),
    'manualBlock': manualBlock.toJson(),
    'override': creditOverride.toJson(),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'version': version,
  };
}

double _asDouble(Object? value) => value is num ? value.toDouble() : 0;
