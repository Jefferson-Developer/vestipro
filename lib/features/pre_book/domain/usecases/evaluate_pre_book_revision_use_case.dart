import '../../../orders/domain/value_objects/order_status.dart';
import '../entities/pre_book_program.dart';

final class EvaluatePreBookRevisionUseCase {
  const EvaluatePreBookRevisionUseCase();

  PreBookRevisionDecision call({
    required PreBookProgram program,
    required PreBookOrderDraft original,
    required PreBookOrderDraft revised,
  }) {
    if (original.order.status != OrderStatus.approved) {
      return const PreBookRevisionDecision(
        requiresApproval: false,
        reasons: <String>[],
      );
    }

    final reasons = <String>[];
    final originalQuantityByVariant = <String, int>{
      for (final line in original.lines)
        line.item.variantId: line.item.quantity,
    };
    for (final line in revised.lines) {
      final previousQuantity = originalQuantityByVariant[line.item.variantId];
      if (previousQuantity != line.item.quantity &&
          program
              .commitmentRules
              .requiresApprovalOnQuantityChangeAfterApproval) {
        reasons.add('Quantidade alterada apos aprovacao.');
        break;
      }
    }

    final originalWindowByVariant = <String, String>{
      for (final line in original.lines)
        line.item.variantId: line.deliveryWindowId,
    };
    for (final line in revised.lines) {
      final previousWindow = originalWindowByVariant[line.item.variantId];
      if (previousWindow != line.deliveryWindowId &&
          program
              .commitmentRules
              .requiresApprovalOnDeliveryWindowChangeAfterApproval) {
        reasons.add('Data ou janela de entrega alterada apos aprovacao.');
        break;
      }
    }

    return PreBookRevisionDecision(
      requiresApproval: reasons.isNotEmpty,
      reasons: reasons,
    );
  }
}
