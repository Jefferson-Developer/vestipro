import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/showroom_samples/showroom_samples.dart';

void main() {
  final now = DateTime(2026, 9, 12);

  SampleItem sample({
    String id = 'sample-1',
    String responsibleUserId = 'rep-1',
    SampleItemStatus status = SampleItemStatus.checkedOut,
    int replacementValueCents = 10000,
  }) {
    return SampleItem(
      id: id,
      organizationId: 'org-1',
      companyId: 'company-1',
      productId: 'product-1',
      variantId: 'variant-1',
      sampleWarehouseId: 'sample-wh',
      status: status,
      holderType: SampleHolderType.salesRep,
      holderId: responsibleUserId,
      responsibleUserId: responsibleUserId,
      physicalCondition: 'Novo',
      replacementValueCents: replacementValueCents,
    );
  }

  test('moves sample between warehouse, rep, showroom and customer', () {
    const engine = SampleMovementPolicyEngine(
      SampleMovementPolicy(
        requiresEvidenceForLossOrDamage: true,
        writeOffApprovalThresholdCents: 5000,
      ),
    );

    final moved = engine.decide(
      item: sample(),
      request: SampleMovementRequest(
        type: SampleMovementType.transfer,
        actorUserId: 'rep-1',
        destinationType: SampleHolderType.showroom,
        destinationId: 'showroom-1',
        reason: 'Troca de ponto de exposicao',
        evidence: const SampleEvidence(visitId: 'visit-1'),
        visitId: 'visit-1',
      ),
      actorIsManager: false,
      actorOwnsSample: true,
    );

    expect(moved.allowed, isTrue);
    expect(moved.updatedItem!.holderType, SampleHolderType.showroom);
    expect(moved.updatedItem!.holderId, 'showroom-1');
    expect(moved.updatedItem!.visitId, 'visit-1');
  });

  test('keeps demonstration stock separated from sellable stock', () {
    const calculator = DemonstrationStockCalculator();

    final snapshot = calculator.compose(
      variantId: 'variant-1',
      sellablePhysicalQuantity: 20,
      sellableReservedQuantity: 4,
      sellableBlockedQuantity: 1,
      samples: [
        sample(status: SampleItemStatus.checkedOut),
        sample(id: 'sample-2', status: SampleItemStatus.consigned),
        sample(id: 'sample-3', status: SampleItemStatus.sold),
      ],
    );

    expect(snapshot.sellableQuantity, 15);
    expect(snapshot.demonstrationQuantity, 2);
    expect(snapshot.sellableQuantity, isNot(snapshot.demonstrationQuantity));
  });

  test(
    'converts sample to sale only with policy, price and financial trail',
    () {
      const engine = SampleMovementPolicyEngine(
        SampleMovementPolicy(
          requiresEvidenceForLossOrDamage: true,
          writeOffApprovalThresholdCents: 5000,
        ),
      );

      final denied = engine.decide(
        item: sample(status: SampleItemStatus.consigned),
        request: const SampleMovementRequest(
          type: SampleMovementType.convertToSale,
          actorUserId: 'rep-1',
          destinationType: SampleHolderType.customer,
          destinationId: 'customer-1',
          reason: 'Cliente comprou a peca consignada',
          evidence: SampleEvidence(signatureUrl: 'sign.png'),
          saleConversionAuthorized: true,
          priceRevalidated: false,
          financialImpactTracked: true,
        ),
        actorIsManager: false,
        actorOwnsSample: true,
      );
      expect(denied.allowed, isFalse);

      final allowed = engine.decide(
        item: sample(status: SampleItemStatus.consigned),
        request: const SampleMovementRequest(
          type: SampleMovementType.convertToSale,
          actorUserId: 'rep-1',
          destinationType: SampleHolderType.customer,
          destinationId: 'customer-1',
          customerId: 'customer-1',
          reason: 'Cliente comprou a peca consignada',
          evidence: SampleEvidence(signatureUrl: 'sign.png'),
          saleConversionAuthorized: true,
          priceRevalidated: true,
          financialImpactTracked: true,
        ),
        actorIsManager: false,
        actorOwnsSample: true,
      );

      expect(allowed.allowed, isTrue);
      expect(allowed.updatedItem!.status, SampleItemStatus.sold);
      expect(allowed.updatedItem!.customerId, 'customer-1');
    },
  );

  test('enforces RBAC by owner rep or manager scope', () {
    const engine = SampleMovementPolicyEngine(
      SampleMovementPolicy(
        requiresEvidenceForLossOrDamage: true,
        writeOffApprovalThresholdCents: 5000,
      ),
    );

    final denied = engine.decide(
      item: sample(responsibleUserId: 'rep-1'),
      request: const SampleMovementRequest(
        type: SampleMovementType.checkIn,
        actorUserId: 'rep-2',
        destinationType: SampleHolderType.warehouse,
        destinationId: 'sample-wh',
        reason: 'Conferencia',
        evidence: SampleEvidence(),
      ),
      actorIsManager: false,
      actorOwnsSample: false,
    );

    expect(denied.allowed, isFalse);

    final manager = engine.decide(
      item: sample(responsibleUserId: 'rep-1'),
      request: const SampleMovementRequest(
        type: SampleMovementType.checkIn,
        actorUserId: 'manager-1',
        destinationType: SampleHolderType.warehouse,
        destinationId: 'sample-wh',
        reason: 'Auditoria',
        evidence: SampleEvidence(),
      ),
      actorIsManager: true,
      actorOwnsSample: false,
    );

    expect(manager.allowed, isTrue);
  });

  test('requires evidence and approval for loss or damage write-off', () {
    const engine = SampleMovementPolicyEngine(
      SampleMovementPolicy(
        requiresEvidenceForLossOrDamage: true,
        writeOffApprovalThresholdCents: 5000,
      ),
    );

    final withoutEvidence = engine.decide(
      item: sample(replacementValueCents: 8000),
      request: const SampleMovementRequest(
        type: SampleMovementType.writeOff,
        actorUserId: 'rep-1',
        destinationType: SampleHolderType.salesRep,
        destinationId: 'rep-1',
        reason: 'Avaria no provador',
        evidence: SampleEvidence(),
        managerApproved: true,
      ),
      actorIsManager: false,
      actorOwnsSample: true,
    );
    expect(withoutEvidence.allowed, isFalse);

    final withoutApproval = engine.decide(
      item: sample(replacementValueCents: 8000),
      request: const SampleMovementRequest(
        type: SampleMovementType.writeOff,
        actorUserId: 'rep-1',
        destinationType: SampleHolderType.salesRep,
        destinationId: 'rep-1',
        reason: 'Avaria no provador',
        evidence: SampleEvidence(photoUrls: ['damage.jpg']),
      ),
      actorIsManager: false,
      actorOwnsSample: true,
    );
    expect(withoutApproval.allowed, isFalse);

    final allowed = engine.decide(
      item: sample(replacementValueCents: 8000),
      request: const SampleMovementRequest(
        type: SampleMovementType.writeOff,
        actorUserId: 'rep-1',
        destinationType: SampleHolderType.salesRep,
        destinationId: 'rep-1',
        reason: 'Avaria no provador',
        evidence: SampleEvidence(photoUrls: ['damage.jpg']),
        managerApproved: true,
      ),
      actorIsManager: false,
      actorOwnsSample: true,
    );

    expect(allowed.allowed, isTrue);
    expect(allowed.updatedItem!.status, SampleItemStatus.lost);
  });

  test('consignment agreement needs acceptance when signature is required', () {
    final agreement = ConsignmentAgreement(
      id: 'cons-1',
      organizationId: 'org-1',
      companyId: 'company-1',
      customerId: 'customer-1',
      sampleItemIds: const ['sample-1'],
      startsAt: now,
      dueAt: now.add(const Duration(days: 30)),
      allowSaleConversion: true,
      requiresSignature: true,
      signed: false,
    );

    expect(agreement.isAccepted, isFalse);
  });
}
