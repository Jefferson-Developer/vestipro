import 'package:injectable/injectable.dart' hide Order;

import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/value_objects/customer_status.dart';
import '../../../pricing/domain/entities/payment_term.dart';
import '../../../pricing/domain/entities/price_list.dart';
import '../entities/order.dart';
import '../entities/order_pricing_summary.dart';
import '../entities/order_submission_context.dart';
import '../entities/order_submission_issue.dart';

/// Impede que um pedido inconsistente seja enviado (EPIC-13, TASK-100):
/// cliente ativo, tabela de preço vigente, quantidade disponível/coerente,
/// condição de pagamento válida e desconto dentro da política do vendedor.
///
/// This is a **client-side, UX-only** guard — `tasks.md`'s own rule for this
/// task is explicit: the exact same checks (or equivalent) must be
/// re-executed server-side on submission (TASK-101's `submitOrder` Cloud
/// Function); nothing here ever substitutes for that. Every [OrderSubmissionIssue]
/// message is written to be action-oriented and never leaks a technical
/// detail, matching that same rule ("mensagens de erro nunca expõem
/// detalhes técnicos").
///
/// Discount/permission validation is deliberately not re-implemented here:
/// [OrderPricingSummary.blocked]/[OrderPricingSummary.approvalRequired]
/// already come from the server-side pricing engine
/// (`calculatePricing`, TASK-088), which already factors in the seller's
/// own discount policy — duplicating that logic client-side would risk it
/// drifting out of sync with the one definitive source, violating this
/// codebase's "pricing definitivo server-side" rule (`AGENTS.md`). A
/// `blocked` discount is a hard blocker here; an `approvalRequired` one is
/// only ever a non-blocking warning, matching TASK-100's "falta de permissão
/// do vendedor... não bloqueia sozinha... gera fluxo de aprovação" rule.
@lazySingleton
final class OrderSubmissionValidator {
  const OrderSubmissionValidator();

  /// Every pendência/aviso found for [order] right now, given the
  /// best-effort [context] and [pricingSummary] the caller resolved. Never
  /// throws — a missing/unresolved [context] field is treated exactly like
  /// TASK-100 requires: a blocking-but-actionable pendência asking the
  /// seller to try again, since submission cannot be trusted to be correct
  /// without it.
  List<OrderSubmissionIssue> validate({
    required Order order,
    required OrderSubmissionContext context,
    OrderPricingSummary? pricingSummary,
    Map<String, String> productNamesById = const <String, String>{},
    DateTime? now,
  }) {
    final resolvedNow = (now ?? DateTime.now()).toUtc();
    return List<OrderSubmissionIssue>.unmodifiable(<OrderSubmissionIssue>[
      ..._validateItemsPresence(order),
      ..._validateCustomer(context.customer),
      ..._validatePriceList(context.priceList, resolvedNow),
      ..._validatePaymentTerm(context.paymentTerm, order.priceListId),
      ..._validateItemsAvailability(order, context, productNamesById),
      ..._validatePricing(pricingSummary),
    ]);
  }

  List<OrderSubmissionIssue> _validateItemsPresence(Order order) {
    if (order.items.isNotEmpty) return const <OrderSubmissionIssue>[];
    return const <OrderSubmissionIssue>[
      OrderSubmissionIssue(
        type: OrderSubmissionIssueType.itemsEmpty,
        severity: OrderSubmissionIssueSeverity.blocking,
        message: 'Adicione ao menos um produto para enviar o pedido.',
        target: OrderSubmissionIssueTarget.items,
      ),
    ];
  }

  List<OrderSubmissionIssue> _validateCustomer(Customer? customer) {
    if (customer == null) {
      return const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.customerNotConfirmed,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'Não foi possível confirmar os dados do cliente. Tente '
              'novamente.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ];
    }
    return switch (customer.status) {
      CustomerStatus.active => const <OrderSubmissionIssue>[],
      CustomerStatus.inactive => const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.customerInactive,
          severity: OrderSubmissionIssueSeverity.blocking,
          message: 'Este cliente está inativo. Reative-o para continuar.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ],
      CustomerStatus.blocked => const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.customerBlocked,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'Este cliente está bloqueado. Regularize a situação para '
              'continuar.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ],
      CustomerStatus.prospect => const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.customerInactive,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'Este cliente ainda não está ativo. Confirme o cadastro para '
              'continuar.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ],
    };
  }

  List<OrderSubmissionIssue> _validatePriceList(
    PriceList? priceList,
    DateTime now,
  ) {
    if (priceList == null) {
      return const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.priceListNotConfirmed,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'Não foi possível confirmar a tabela de preço deste pedido. '
              'Tente novamente.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ];
    }
    if (!priceList.isApplicableAt(now)) {
      return const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.priceListExpired,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'A tabela de preço deste pedido venceu. Selecione uma tabela '
              'vigente para continuar.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ];
    }
    return const <OrderSubmissionIssue>[];
  }

  List<OrderSubmissionIssue> _validatePaymentTerm(
    PaymentTerm? paymentTerm,
    String priceListId,
  ) {
    if (paymentTerm == null) {
      return const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.paymentTermNotConfirmed,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'Não foi possível confirmar a condição de pagamento deste '
              'pedido. Tente novamente.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ];
    }
    if (!paymentTerm.isActive) {
      return const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.paymentTermInactive,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'Esta condição de pagamento não está mais disponível. Escolha '
              'outra para continuar.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ];
    }
    if (!paymentTerm.isCompatibleWithPriceList(priceListId)) {
      return const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.paymentTermIncompatibleWithPriceList,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'Esta condição de pagamento não é válida para a tabela de '
              'preço selecionada. Escolha outra para continuar.',
          target: OrderSubmissionIssueTarget.orderSummary,
        ),
      ];
    }
    return const <OrderSubmissionIssue>[];
  }

  /// Item-level quantity/availability check. A [OrderItem.variantId] with no
  /// entry in [context]'s availability map is skipped entirely — the same
  /// "never blocking on this lookup" precedent every other best-effort
  /// resolution in this feature already follows (see
  /// `OrderDraftState.productsById`'s own docs), since it usually just means
  /// the lookup has not resolved yet (offline, brand-new variant).
  List<OrderSubmissionIssue> _validateItemsAvailability(
    Order order,
    OrderSubmissionContext context,
    Map<String, String> productNamesById,
  ) {
    final issues = <OrderSubmissionIssue>[];
    for (final item in order.items) {
      final availability = context.availabilityByVariantId[item.variantId];
      if (availability == null) continue;
      final productName = productNamesById[item.productId] ?? item.productId;

      if (!availability.acceptsQuantity) {
        issues.add(
          OrderSubmissionIssue(
            type: OrderSubmissionIssueType.itemUnavailable,
            severity: OrderSubmissionIssueSeverity.blocking,
            message:
                '$productName não está mais disponível. Remova o item para '
                'continuar.',
            target: OrderSubmissionIssueTarget.items,
            productId: item.productId,
            variantId: item.variantId,
          ),
        );
        continue;
      }

      final availableQuantity = availability.availableQuantity;
      if (availableQuantity != null && item.quantity > availableQuantity) {
        issues.add(
          OrderSubmissionIssue(
            type: OrderSubmissionIssueType.itemQuantityExceedsAvailability,
            severity: OrderSubmissionIssueSeverity.blocking,
            message:
                'A quantidade de $productName (${item.quantity}) é maior '
                'que a disponível ($availableQuantity). Ajuste a '
                'quantidade para continuar.',
            target: OrderSubmissionIssueTarget.items,
            productId: item.productId,
            variantId: item.variantId,
          ),
        );
      }
    }
    return issues;
  }

  List<OrderSubmissionIssue> _validatePricing(
    OrderPricingSummary? pricingSummary,
  ) {
    if (pricingSummary == null) return const <OrderSubmissionIssue>[];
    if (pricingSummary.blocked) {
      return const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.discountBlocked,
          severity: OrderSubmissionIssueSeverity.blocking,
          message:
              'Um desconto aplicado está fora do limite permitido para o '
              'seu perfil. Ajuste ou remova o desconto para continuar.',
          target: OrderSubmissionIssueTarget.pricingSummary,
        ),
      ];
    }
    if (pricingSummary.approvalRequired) {
      return const <OrderSubmissionIssue>[
        OrderSubmissionIssue(
          type: OrderSubmissionIssueType.discountRequiresApproval,
          severity: OrderSubmissionIssueSeverity.warning,
          message:
              'Este pedido tem desconto acima do seu limite e será enviado '
              'para aprovação antes de ser confirmado.',
          target: OrderSubmissionIssueTarget.pricingSummary,
        ),
      ];
    }
    return const <OrderSubmissionIssue>[];
  }
}
