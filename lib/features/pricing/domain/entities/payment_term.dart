import '../value_objects/payment_term_status.dart';
import '../value_objects/payment_term_sync_status.dart';
import 'payment_installment.dart';

final class PaymentTerm {
  const PaymentTerm({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.name,
    required this.installments,
    required this.averageTermDays,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.priceListIds = const <String>[],
    this.deletedAt,
    this.version = 1,
    this.syncStatus = PaymentTermSyncStatus.pending,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String name;
  final List<PaymentInstallment> installments;
  final double averageTermDays;
  final PaymentTermStatus status;
  final List<String> priceListIds;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final PaymentTermSyncStatus syncStatus;

  bool get isActive => status == PaymentTermStatus.active && deletedAt == null;

  bool isCompatibleWithPriceList(String? priceListId) {
    if (priceListIds.isEmpty) return true;
    if (priceListId == null || priceListId.trim().isEmpty) return false;
    return priceListIds.contains(priceListId.trim());
  }

  PaymentTerm copyWith({
    String? id,
    String? organizationId,
    String? companyId,
    String? name,
    List<PaymentInstallment>? installments,
    double? averageTermDays,
    PaymentTermStatus? status,
    List<String>? priceListIds,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    PaymentTermSyncStatus? syncStatus,
  }) {
    return PaymentTerm(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      installments: installments ?? this.installments,
      averageTermDays: averageTermDays ?? this.averageTermDays,
      status: status ?? this.status,
      priceListIds: priceListIds ?? this.priceListIds,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, Object?> toAuditMap() {
    return <String, Object?>{
      'name': name,
      'status': status.name,
      'averageTermDays': averageTermDays,
      'priceListIds': priceListIds,
      'installments': installments
          .map((installment) => installment.toJson())
          .toList(growable: false),
    };
  }
}
