import '../../../organizations/organizations.dart';
import '../../../pricing/pricing.dart';

/// Resolved defaults a new `Order` draft (TASK-096) is pre-filled with, once
/// a customer is selected — the "empresa/unidade/tabela de preço padrão
/// conforme regras já vigentes no cadastro do cliente" `tasks.md` seção 9
/// describes.
///
/// Holds the full [Branch]/[PriceList]/[PaymentTerm] entities (not just
/// their ids) so the "novo pedido" screen can show a human-readable summary
/// of what was pre-filled right after a customer is picked, without a
/// second round trip — [ResolveOrderDraftDefaultsUseCase] already has these
/// entities in hand by the time it resolves this value. Only the id of each
/// is ever persisted on the `Order` itself.
final class OrderDraftDefaults {
  const OrderDraftDefaults({
    required this.branch,
    required this.priceList,
    required this.paymentTerm,
  });

  final Branch branch;
  final PriceList priceList;
  final PaymentTerm paymentTerm;
}
