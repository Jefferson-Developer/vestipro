enum SampleHolderType { warehouse, salesRep, showroom, customer }

enum SampleItemStatus {
  available,
  checkedOut,
  consigned,
  damaged,
  lost,
  sold,
  returned,
}

enum SampleMovementType {
  outbound,
  transfer,
  checkIn,
  checkOut,
  returnToWarehouse,
  writeOff,
  convertToSale,
}

final class SampleKit {
  const SampleKit({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.collectionId,
    required this.name,
    required this.responsibleUserId,
    required this.holderType,
    required this.holderId,
    required this.itemIds,
    required this.updatedAt,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String collectionId;
  final String name;
  final String responsibleUserId;
  final SampleHolderType holderType;
  final String holderId;
  final List<String> itemIds;
  final DateTime updatedAt;
}

final class SampleItem {
  const SampleItem({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.productId,
    required this.variantId,
    required this.sampleWarehouseId,
    required this.status,
    required this.holderType,
    required this.holderId,
    required this.responsibleUserId,
    required this.physicalCondition,
    required this.replacementValueCents,
    this.currentKitId,
    this.customerId,
    this.visitId,
    this.lastMovementId,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String productId;
  final String variantId;
  final String sampleWarehouseId;
  final SampleItemStatus status;
  final SampleHolderType holderType;
  final String holderId;
  final String responsibleUserId;
  final String physicalCondition;
  final int replacementValueCents;
  final String? currentKitId;
  final String? customerId;
  final String? visitId;
  final String? lastMovementId;

  bool get isOpenResponsibility =>
      status == SampleItemStatus.available ||
      status == SampleItemStatus.checkedOut ||
      status == SampleItemStatus.consigned ||
      status == SampleItemStatus.damaged;

  SampleItem copyWith({
    SampleItemStatus? status,
    SampleHolderType? holderType,
    String? holderId,
    String? responsibleUserId,
    String? physicalCondition,
    String? customerId,
    String? visitId,
    String? lastMovementId,
  }) {
    return SampleItem(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      productId: productId,
      variantId: variantId,
      sampleWarehouseId: sampleWarehouseId,
      status: status ?? this.status,
      holderType: holderType ?? this.holderType,
      holderId: holderId ?? this.holderId,
      responsibleUserId: responsibleUserId ?? this.responsibleUserId,
      physicalCondition: physicalCondition ?? this.physicalCondition,
      replacementValueCents: replacementValueCents,
      currentKitId: currentKitId,
      customerId: customerId ?? this.customerId,
      visitId: visitId ?? this.visitId,
      lastMovementId: lastMovementId ?? this.lastMovementId,
    );
  }
}

final class ConsignmentAgreement {
  const ConsignmentAgreement({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.sampleItemIds,
    required this.startsAt,
    required this.dueAt,
    required this.allowSaleConversion,
    required this.requiresSignature,
    required this.signed,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String customerId;
  final List<String> sampleItemIds;
  final DateTime startsAt;
  final DateTime dueAt;
  final bool allowSaleConversion;
  final bool requiresSignature;
  final bool signed;

  bool get isAccepted => !requiresSignature || signed;
}

final class SampleEvidence {
  const SampleEvidence({
    this.photoUrls = const <String>[],
    this.notes,
    this.signatureUrl,
    this.visitId,
  });

  final List<String> photoUrls;
  final String? notes;
  final String? signatureUrl;
  final String? visitId;

  bool get hasProof =>
      photoUrls.isNotEmpty ||
      (notes != null && notes!.trim().isNotEmpty) ||
      (signatureUrl != null && signatureUrl!.trim().isNotEmpty);
}

final class SampleMovementRequest {
  const SampleMovementRequest({
    required this.type,
    required this.actorUserId,
    required this.destinationType,
    required this.destinationId,
    required this.reason,
    required this.evidence,
    this.customerId,
    this.visitId,
    this.managerApproved = false,
    this.saleConversionAuthorized = false,
    this.priceRevalidated = false,
    this.financialImpactTracked = false,
  });

  final SampleMovementType type;
  final String actorUserId;
  final SampleHolderType destinationType;
  final String destinationId;
  final String reason;
  final SampleEvidence evidence;
  final String? customerId;
  final String? visitId;
  final bool managerApproved;
  final bool saleConversionAuthorized;
  final bool priceRevalidated;
  final bool financialImpactTracked;
}

final class SampleMovementDecision {
  const SampleMovementDecision._({
    required this.allowed,
    required this.message,
    this.updatedItem,
  });

  factory SampleMovementDecision.allowed(SampleItem item) {
    return SampleMovementDecision._(
      allowed: true,
      message: 'Movimentacao de amostra autorizada.',
      updatedItem: item,
    );
  }

  factory SampleMovementDecision.denied(String message) {
    return SampleMovementDecision._(allowed: false, message: message);
  }

  final bool allowed;
  final String message;
  final SampleItem? updatedItem;
}

final class SampleMovementPolicy {
  const SampleMovementPolicy({
    required this.requiresEvidenceForLossOrDamage,
    required this.writeOffApprovalThresholdCents,
  });

  final bool requiresEvidenceForLossOrDamage;
  final int writeOffApprovalThresholdCents;
}

final class SampleMovementPolicyEngine {
  const SampleMovementPolicyEngine(this.policy);

  final SampleMovementPolicy policy;

  SampleMovementDecision decide({
    required SampleItem item,
    required SampleMovementRequest request,
    required bool actorIsManager,
    required bool actorOwnsSample,
  }) {
    if (!actorIsManager && !actorOwnsSample) {
      return SampleMovementDecision.denied(
        'Representante so pode movimentar mostruarios sob sua responsabilidade.',
      );
    }

    if (request.reason.trim().isEmpty) {
      return SampleMovementDecision.denied(
        'Motivo da movimentacao de amostra e obrigatorio.',
      );
    }

    if (request.type == SampleMovementType.writeOff) {
      final needsApproval =
          item.replacementValueCents >= policy.writeOffApprovalThresholdCents;
      if (policy.requiresEvidenceForLossOrDamage &&
          !request.evidence.hasProof) {
        return SampleMovementDecision.denied(
          'Baixa por perda ou avaria exige evidencia.',
        );
      }
      if (needsApproval && !request.managerApproved) {
        return SampleMovementDecision.denied(
          'Baixa por valor relevante exige aprovacao gerencial.',
        );
      }
      return SampleMovementDecision.allowed(
        item.copyWith(
          status: SampleItemStatus.lost,
          physicalCondition: request.reason,
          lastMovementId: '${item.id}-${request.type.name}',
        ),
      );
    }

    if (request.type == SampleMovementType.convertToSale) {
      if (!request.saleConversionAuthorized ||
          !request.priceRevalidated ||
          !request.financialImpactTracked) {
        return SampleMovementDecision.denied(
          'Venda de amostra exige politica autorizada, preco revalidado e impacto financeiro rastreado.',
        );
      }
      return SampleMovementDecision.allowed(
        item.copyWith(
          status: SampleItemStatus.sold,
          customerId: request.customerId,
          visitId: request.visitId,
          lastMovementId: '${item.id}-${request.type.name}',
        ),
      );
    }

    final nextStatus = switch (request.type) {
      SampleMovementType.outbound ||
      SampleMovementType.checkOut => SampleItemStatus.checkedOut,
      SampleMovementType.transfer => item.status,
      SampleMovementType.checkIn ||
      SampleMovementType.returnToWarehouse => SampleItemStatus.returned,
      SampleMovementType.writeOff => SampleItemStatus.lost,
      SampleMovementType.convertToSale => SampleItemStatus.sold,
    };

    return SampleMovementDecision.allowed(
      item.copyWith(
        status: nextStatus,
        holderType: request.destinationType,
        holderId: request.destinationId,
        responsibleUserId: request.destinationType == SampleHolderType.salesRep
            ? request.destinationId
            : item.responsibleUserId,
        customerId: request.customerId,
        visitId: request.visitId,
        lastMovementId: '${item.id}-${request.type.name}',
      ),
    );
  }
}

final class DemonstrationStockSnapshot {
  const DemonstrationStockSnapshot({
    required this.variantId,
    required this.sellableQuantity,
    required this.sampleQuantity,
    required this.consignedQuantity,
  });

  final String variantId;
  final int sellableQuantity;
  final int sampleQuantity;
  final int consignedQuantity;

  int get demonstrationQuantity => sampleQuantity + consignedQuantity;
}

final class DemonstrationStockCalculator {
  const DemonstrationStockCalculator();

  DemonstrationStockSnapshot compose({
    required String variantId,
    required int sellablePhysicalQuantity,
    required int sellableReservedQuantity,
    required int sellableBlockedQuantity,
    required Iterable<SampleItem> samples,
  }) {
    final sellable =
        sellablePhysicalQuantity -
        sellableReservedQuantity -
        sellableBlockedQuantity;
    var sampleQuantity = 0;
    var consignedQuantity = 0;
    for (final sample in samples.where(
      (sample) => sample.variantId == variantId,
    )) {
      if (!sample.isOpenResponsibility) {
        continue;
      }
      if (sample.status == SampleItemStatus.consigned) {
        consignedQuantity++;
      } else {
        sampleQuantity++;
      }
    }
    return DemonstrationStockSnapshot(
      variantId: variantId,
      sellableQuantity: sellable < 0 ? 0 : sellable,
      sampleQuantity: sampleQuantity,
      consignedQuantity: consignedQuantity,
    );
  }
}
