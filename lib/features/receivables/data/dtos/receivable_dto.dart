import 'package:cloud_firestore/cloud_firestore.dart';

/// `organizations/{organizationId}/receivables/{receivableId}` document
/// shape (TASK-213) — mirrors the server's own `mapReceivable`
/// (`receivables-shared.ts`) field for field, defaulting safely on a
/// missing/partial field rather than throwing.
final class ReceivableDto {
  const ReceivableDto({
    required this.id,
    required this.organizationId,
    required this.customerId,
    required this.invoiceId,
    this.orderId,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.paidAmount,
    required this.currency,
    required this.status,
  });

  factory ReceivableDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final dueDate = json['dueDate'];
    return ReceivableDto(
      id: id,
      organizationId: json['organizationId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      invoiceId: json['invoiceId'] as String? ?? '',
      orderId: json['orderId'] as String?,
      installmentNumber: (json['installmentNumber'] as num?)?.toInt() ?? 1,
      dueDate: dueDate is Timestamp ? dueDate.toDate() : DateTime.now(),
      amount: _asDouble(json['amount']),
      paidAmount: _asDouble(json['paidAmount']),
      currency: json['currency'] as String? ?? 'BRL',
      status: json['status'] as String? ?? 'open',
    );
  }

  final String id;
  final String organizationId;
  final String customerId;
  final String invoiceId;
  final String? orderId;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final double paidAmount;
  final String currency;
  final String status;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'customerId': customerId,
    'invoiceId': invoiceId,
    'orderId': orderId,
    'installmentNumber': installmentNumber,
    'dueDate': Timestamp.fromDate(dueDate),
    'amount': amount,
    'paidAmount': paidAmount,
    'currency': currency,
    'status': status,
  };
}

double _asDouble(Object? value) => value is num ? value.toDouble() : 0;
