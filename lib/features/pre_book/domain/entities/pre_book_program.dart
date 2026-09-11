import '../../../inventory/domain/entities/future_stock_entry.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../../../orders/domain/value_objects/order_status.dart';

const String preBookOrderType = 'pre_book';

enum PreBookProgramStatus { draft, open, closed, cancelled }

enum PreBookAudienceProfile { seller, salesManager, buyer, keyAccount }

enum PreBookAvailabilityStatus {
  forecast,
  allocated,
  firmReserved,
  unavailable,
}

enum PreBookPricingPolicyType { launchPrice, priceList, campaignOverride }

enum PreBookProductionRisk { low, attention, high }

final class PreBookAudiencePolicy {
  const PreBookAudiencePolicy({
    required this.profiles,
    this.customerIds = const <String>{},
  });

  final Set<PreBookAudienceProfile> profiles;
  final Set<String> customerIds;

  bool allows({required PreBookAudienceProfile profile, String? customerId}) {
    if (!profiles.contains(profile)) return false;
    return customerIds.isEmpty ||
        (customerId != null && customerIds.contains(customerId));
  }
}

final class PreBookDeliveryWindow {
  const PreBookDeliveryWindow({
    required this.id,
    required this.label,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String label;
  final DateTime startsAt;
  final DateTime endsAt;

  bool contains(DateTime promisedDate) {
    final value = promisedDate.toUtc();
    return !value.isBefore(startsAt.toUtc()) && !value.isAfter(endsAt.toUtc());
  }
}

final class PreBookCommitmentRules {
  const PreBookCommitmentRules({
    this.requiresApprovalAfterWindow = true,
    this.requiresApprovalOnQuantityChangeAfterApproval = true,
    this.requiresApprovalOnDeliveryWindowChangeAfterApproval = true,
    this.requiresApprovalAboveVolume,
    this.requiresApprovalAboveDiscountPercent,
    this.minimumCommitmentPieces = 0,
  });

  final bool requiresApprovalAfterWindow;
  final bool requiresApprovalOnQuantityChangeAfterApproval;
  final bool requiresApprovalOnDeliveryWindowChangeAfterApproval;
  final int? requiresApprovalAboveVolume;
  final double? requiresApprovalAboveDiscountPercent;
  final int minimumCommitmentPieces;
}

final class PreBookPricingPolicy {
  const PreBookPricingPolicy({
    required this.type,
    this.priceListId,
    this.campaignId,
    this.discountPercent = 0,
  });

  final PreBookPricingPolicyType type;
  final String? priceListId;
  final String? campaignId;
  final double discountPercent;
}

final class PreBookProgram {
  const PreBookProgram({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.collectionId,
    required this.name,
    required this.salesWindowStart,
    required this.salesWindowEnd,
    required this.deliveryWindows,
    required this.status,
    required this.audiencePolicy,
    required this.targetPieces,
    required this.cancellationRules,
    required this.pricingPolicy,
    required this.commitmentRules,
    required this.updatedAt,
  });

  final String id;
  final String organizationId;
  final String? companyId;
  final String collectionId;
  final String name;
  final DateTime salesWindowStart;
  final DateTime salesWindowEnd;
  final List<PreBookDeliveryWindow> deliveryWindows;
  final PreBookProgramStatus status;
  final PreBookAudiencePolicy audiencePolicy;
  final int targetPieces;
  final String cancellationRules;
  final PreBookPricingPolicy pricingPolicy;
  final PreBookCommitmentRules commitmentRules;
  final DateTime updatedAt;

  bool isSalesWindowOpen(DateTime now) {
    final value = now.toUtc();
    return status == PreBookProgramStatus.open &&
        !value.isBefore(salesWindowStart.toUtc()) &&
        !value.isAfter(salesWindowEnd.toUtc());
  }

  PreBookDeliveryWindow? deliveryWindowById(String id) {
    for (final window in deliveryWindows) {
      if (window.id == id) return window;
    }
    return null;
  }

  PreBookDeliveryWindow? deliveryWindowForDate(DateTime promisedDate) {
    for (final window in deliveryWindows) {
      if (window.contains(promisedDate)) return window;
    }
    return null;
  }
}

final class PreBookVariantAvailability {
  const PreBookVariantAvailability({
    required this.variantId,
    required this.productId,
    required this.deliveryWindowId,
    required this.status,
    required this.futureQuantity,
    this.allocatedQuantity = 0,
    this.reservedQuantity = 0,
    this.expectedDate,
  });

  final String variantId;
  final String productId;
  final String deliveryWindowId;
  final PreBookAvailabilityStatus status;
  final int futureQuantity;
  final int allocatedQuantity;
  final int reservedQuantity;
  final DateTime? expectedDate;

  int get availableToPromise {
    if (status == PreBookAvailabilityStatus.unavailable) return 0;
    final available = futureQuantity - allocatedQuantity - reservedQuantity;
    return available < 0 ? 0 : available;
  }

  bool canPromise(int quantity) =>
      quantity > 0 && availableToPromise >= quantity;

  static PreBookVariantAvailability fromFutureStock({
    required FutureStockEntry entry,
    required PreBookDeliveryWindow deliveryWindow,
    int allocatedQuantity = 0,
    int reservedQuantity = 0,
    PreBookAvailabilityStatus status = PreBookAvailabilityStatus.forecast,
  }) {
    return PreBookVariantAvailability(
      variantId: entry.variantId,
      productId: entry.productId,
      deliveryWindowId: deliveryWindow.id,
      status: status,
      futureQuantity: entry.quantity,
      allocatedQuantity: allocatedQuantity,
      reservedQuantity: reservedQuantity,
      expectedDate: entry.expectedDate,
    );
  }
}

final class PreBookOrderLine {
  const PreBookOrderLine({
    required this.item,
    required this.deliveryWindowId,
    required this.promisedDeliveryDate,
    required this.availabilityStatus,
  });

  final OrderItem item;
  final String deliveryWindowId;
  final DateTime promisedDeliveryDate;
  final PreBookAvailabilityStatus availabilityStatus;
}

final class PreBookOrderDraft {
  const PreBookOrderDraft({
    required this.programId,
    required this.order,
    required this.lines,
  });

  final String programId;
  final Order order;
  final List<PreBookOrderLine> lines;

  int get totalPieces =>
      lines.fold<int>(0, (sum, line) => sum + line.item.quantity);

  double get totalAmount =>
      lines.fold<double>(0, (sum, line) => sum + line.item.subtotal);

  bool get isPreBookOrder => order.orderType == preBookOrderType;

  Map<String, Object?> commitmentSnapshot() => <String, Object?>{
    'program_id': programId,
    'collection_id': order.collectionId,
    'order_type': order.orderType,
    'delivery_windows': lines
        .map(
          (line) => <String, Object?>{
            'item_id': line.item.id,
            'variant_id': line.item.variantId,
            'delivery_window_id': line.deliveryWindowId,
            'promised_delivery_date': line.promisedDeliveryDate
                .toUtc()
                .toIso8601String(),
            'availability_status': line.availabilityStatus.name,
          },
        )
        .toList(growable: false),
  };
}

final class PreBookCaptureMetrics {
  const PreBookCaptureMetrics({
    required this.program,
    required this.reservedPieces,
    required this.soldPieces,
    required this.cancelledPieces,
    required this.deliveryRisk,
  });

  final PreBookProgram program;
  final int reservedPieces;
  final int soldPieces;
  final int cancelledPieces;
  final PreBookProductionRisk deliveryRisk;

  int get capturedPieces => reservedPieces + soldPieces;

  int get targetGap {
    final gap = program.targetPieces - capturedPieces;
    return gap < 0 ? 0 : gap;
  }

  double get targetProgress {
    if (program.targetPieces <= 0) return 1;
    final progress = capturedPieces / program.targetPieces;
    return progress > 1 ? 1 : progress;
  }
}

final class PreBookRevisionDecision {
  const PreBookRevisionDecision({
    required this.requiresApproval,
    required this.reasons,
  });

  final bool requiresApproval;
  final List<String> reasons;
}

extension PreBookOrderX on Order {
  bool get isPreBook => orderType == preBookOrderType;

  bool get isApprovedForPreBookChange => status == OrderStatus.approved;
}
