import '../value_objects/buyer_collaboration_source_type.dart';
import '../value_objects/buyer_collaboration_status.dart';
import 'buyer_collaboration_item.dart';

/// A seller/buyer collaboration over one selection/orçamento/pedido em
/// rascunho (TASK-211) — the aggregate root; comments live in a separate
/// [BuyerCollaborationComment] list fetched alongside it, never embedded, so
/// the history can grow without limit.
final class BuyerCollaborationSession {
  const BuyerCollaborationSession({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    required this.customerId,
    required this.sourceType,
    required this.sourceId,
    required this.priceListId,
    required this.status,
    required this.items,
    required this.showPrices,
    required this.currentTotal,
    this.convertedOrderId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActivityAt,
    required this.expiresAt,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String sellerId;
  final String customerId;
  final BuyerCollaborationSourceType sourceType;
  final String sourceId;
  final String priceListId;
  final BuyerCollaborationStatus status;
  final List<BuyerCollaborationItem> items;
  final bool showPrices;
  final double currentTotal;
  final String? convertedOrderId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActivityAt;
  final DateTime expiresAt;

  /// Lazily-computed status, mirroring the server's own
  /// `effectiveStatus` (`buyer-collaboration-shared.ts`): a session already
  /// past [expiresAt] reads as `expired` in the UI even before the
  /// scheduled `expireBuyerCollaborationSessions` job persists it, so a
  /// stale screen never offers an action the backend would reject anyway.
  BuyerCollaborationStatus effectiveStatus(DateTime now) {
    if (status.isTerminal) return status;
    return now.isAfter(expiresAt) ? BuyerCollaborationStatus.expired : status;
  }

  bool get isSharedWithBuyer => status != BuyerCollaborationStatus.sellerDraft;
}
