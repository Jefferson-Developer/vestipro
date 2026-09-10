import '../value_objects/post_sale_event_type.dart';

/// One immutable milestone on a pedido's pós-venda timeline (TASK-201,
/// EPIC-30) — despachado, em trânsito, entregue, problema reportado, em
/// resolução ou resolvido (registrado manualmente por vendedor/suporte via
/// `RegisterPostSaleEventUseCase`), ou devolução/troca solicitada/decidida
/// (registrado automaticamente pelas Cloud Functions de TASK-199/TASK-200,
/// nunca duplicando aquela modelagem).
///
/// Exclusively written by `registerPostSaleEvent`/`createReturnRequest`/
/// `resolveReturnRequest`/`createExchangeRequest`/`resolveExchangeRequest`
/// (Cloud Functions) — the UI never mutates one directly (no Firestore
/// write from a widget, `AGENTS.md`); this entity is only ever read back
/// through [PostSaleEventRepository.watchByOrder]. Never edited once
/// written (`tasks.md`: "histórico não é editado, apenas complementado com
/// novos eventos") — only ever created, never updated.
final class PostSaleEvent {
  const PostSaleEvent({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    required this.type,
    this.description,
    required this.source,
    this.sourceRequestId,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.notifiedSeller,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final PostSaleEventType type;
  final String? description;
  final PostSaleEventSource source;

  /// The `returnRequestId`/`exchangeRequestId` this event was auto-appended
  /// from, when [source] is [PostSaleEventSource.system]; always `null` for
  /// a [PostSaleEventSource.manual] event.
  final String? sourceRequestId;
  final String createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final bool notifiedSeller;

  /// Whether this milestone is a "problema reportado" — the one type the
  /// timeline UI highlights (`tasks.md`: "evento de problema em destaque").
  bool get isProblem => type == PostSaleEventType.problemReported;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostSaleEvent &&
          other.id == id &&
          other.organizationId == organizationId &&
          other.companyId == companyId &&
          other.orderId == orderId &&
          other.orderNumber == orderNumber &&
          other.customerId == customerId &&
          other.sellerId == sellerId &&
          other.type == type &&
          other.description == description &&
          other.source == source &&
          other.sourceRequestId == sourceRequestId &&
          other.createdBy == createdBy &&
          other.createdByName == createdByName &&
          other.createdAt == createdAt &&
          other.notifiedSeller == notifiedSeller);

  @override
  int get hashCode => Object.hash(
    Object.hash(
      id,
      organizationId,
      companyId,
      orderId,
      orderNumber,
      customerId,
      sellerId,
      type,
      description,
    ),
    source,
    sourceRequestId,
    createdBy,
    createdByName,
    createdAt,
    notifiedSeller,
  );
}
