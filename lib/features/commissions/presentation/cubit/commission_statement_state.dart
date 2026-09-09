import '../../domain/entities/commission_entry.dart';

enum CommissionStatementStatus { initial, loading, ready, empty, error }

final class CommissionStatementState {
  const CommissionStatementState({
    this.status = CommissionStatementStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.from,
    this.to,
    this.sellerId,
    this.statusFilter,
    this.entries = const <CommissionEntry>[],
    this.failureMessage,
  });

  final CommissionStatementStatus status;
  final String organizationId;
  final String companyId;
  final String userId;
  final DateTime? from;
  final DateTime? to;
  final String? sellerId;
  final CommissionEntryStatus? statusFilter;
  final List<CommissionEntry> entries;
  final String? failureMessage;

  double get provisionedTotal => entries
      .where((entry) => entry.status == CommissionEntryStatus.provisioned)
      .fold(0, (sum, entry) => sum + entry.commissionAmount);

  double get payableTotal => entries
      .where(
        (entry) =>
            entry.status == CommissionEntryStatus.approved ||
            entry.status == CommissionEntryStatus.paid,
      )
      .fold(0, (sum, entry) => sum + entry.commissionAmount);

  double get reversalTotal => entries
      .where((entry) => entry.isReversal)
      .fold(0, (sum, entry) => sum + entry.commissionAmount);

  CommissionStatementState copyWith({
    CommissionStatementStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    DateTime? from,
    DateTime? to,
    String? sellerId,
    CommissionEntryStatus? statusFilter,
    bool clearStatusFilter = false,
    List<CommissionEntry>? entries,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return CommissionStatementState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      from: from ?? this.from,
      to: to ?? this.to,
      sellerId: sellerId ?? this.sellerId,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      entries: entries ?? this.entries,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
