import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../../../orders/domain/value_objects/order_status.dart';
import '../entities/pre_book_program.dart';

final class PreBookOrderItemInput {
  const PreBookOrderItemInput({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.deliveryWindowId,
  });

  final String id;
  final String variantId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String deliveryWindowId;
}

final class PreBookOrderCreationResult {
  const PreBookOrderCreationResult({
    required this.draft,
    required this.requiresApproval,
    required this.approvalReasons,
  });

  final PreBookOrderDraft draft;
  final bool requiresApproval;
  final List<String> approvalReasons;
}

final class CreatePreBookOrderUseCase {
  const CreatePreBookOrderUseCase();

  PreBookOrderCreationResult call({
    required Order baseDraft,
    required PreBookProgram program,
    required List<PreBookOrderItemInput> items,
    required Map<String, PreBookVariantAvailability> availabilityByVariantId,
    required PreBookAudienceProfile profile,
    required DateTime now,
    String? customerId,
    double orderDiscountPercent = 0,
    bool exceptionalPermission = false,
  }) {
    final fieldErrors = <String>[];
    if (baseDraft.organizationId != program.organizationId) {
      fieldErrors.add(
        'Programa e pedido pertencem a organizations diferentes.',
      );
    }
    if (program.companyId != null && baseDraft.companyId != program.companyId) {
      fieldErrors.add('Programa nao pertence a empresa do pedido.');
    }
    if (!program.audiencePolicy.allows(
      profile: profile,
      customerId: customerId,
    )) {
      fieldErrors.add('Cliente ou perfil nao elegivel para este pre-book.');
    }
    if (items.isEmpty) fieldErrors.add('Inclua ao menos um item de pre-book.');
    if (items.any((item) => item.quantity <= 0)) {
      fieldErrors.add('Quantidade de pre-book deve ser maior que zero.');
    }
    if (!program.isSalesWindowOpen(now) &&
        !(exceptionalPermission &&
            program.commitmentRules.requiresApprovalAfterWindow)) {
      fieldErrors.add(
        'Janela comercial de pre-book encerrada ou indisponivel.',
      );
    }

    final lines = <PreBookOrderLine>[];
    for (final input in items) {
      final window = program.deliveryWindowById(input.deliveryWindowId);
      if (window == null) {
        fieldErrors.add('Janela de entrega invalida para ${input.variantId}.');
        continue;
      }
      final availability = availabilityByVariantId[input.variantId];
      if (availability == null ||
          availability.deliveryWindowId != input.deliveryWindowId ||
          availability.status == PreBookAvailabilityStatus.unavailable ||
          !availability.canPromise(input.quantity)) {
        fieldErrors.add(
          'Estoque futuro insuficiente para ${input.variantId}; pronta entrega nao pode ser consumida.',
        );
        continue;
      }
      final promisedDate = availability.expectedDate ?? window.startsAt;
      if (!window.contains(promisedDate)) {
        fieldErrors.add(
          'Data prometida fora da janela aprovada para ${input.variantId}.',
        );
        continue;
      }
      final subtotal = input.quantity * input.unitPrice;
      lines.add(
        PreBookOrderLine(
          item: OrderItem(
            id: input.id,
            variantId: input.variantId,
            productId: input.productId,
            quantity: input.quantity,
            unitPrice: input.unitPrice,
            subtotal: subtotal,
          ),
          deliveryWindowId: input.deliveryWindowId,
          promisedDeliveryDate: promisedDate,
          availabilityStatus: availability.status,
        ),
      );
    }

    if (fieldErrors.isNotEmpty) {
      throw PreBookOrderValidationException(fieldErrors);
    }

    final approvalReasons = <String>[];
    final totalPieces = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final approvalAboveVolume =
        program.commitmentRules.requiresApprovalAboveVolume;
    if (approvalAboveVolume != null && totalPieces > approvalAboveVolume) {
      approvalReasons.add('Volume acima da alçada configurada.');
    }
    final approvalAboveDiscount =
        program.commitmentRules.requiresApprovalAboveDiscountPercent;
    if (approvalAboveDiscount != null &&
        orderDiscountPercent > approvalAboveDiscount) {
      approvalReasons.add('Desconto acima da política de pre-book.');
    }
    if (!program.isSalesWindowOpen(now) && exceptionalPermission) {
      approvalReasons.add('Submissao excepcional fora da janela comercial.');
    }
    if (totalPieces < program.commitmentRules.minimumCommitmentPieces) {
      approvalReasons.add('Volume abaixo do compromisso minimo do programa.');
    }

    final order = baseDraft.copyWith(
      collectionId: program.collectionId,
      orderType: preBookOrderType,
      items: lines.map((line) => line.item).toList(growable: false),
      status: approvalReasons.isEmpty
          ? baseDraft.status
          : OrderStatus.underReview,
      updatedAt: now.toUtc(),
    );

    return PreBookOrderCreationResult(
      draft: PreBookOrderDraft(
        programId: program.id,
        order: order,
        lines: lines,
      ),
      requiresApproval: approvalReasons.isNotEmpty,
      approvalReasons: approvalReasons,
    );
  }
}

final class PreBookOrderValidationException implements Exception {
  const PreBookOrderValidationException(this.messages);

  final List<String> messages;

  @override
  String toString() => messages.join(' ');
}
