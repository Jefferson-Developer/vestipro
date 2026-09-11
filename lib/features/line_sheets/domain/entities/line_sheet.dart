import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/entities/size_grid_template.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';

enum LineSheetStatus { draft, published, archived }

enum LineSheetAccessProfile { seller, buyer, salesManager, catalogManager }

final class LineSheetAccessPolicy {
  const LineSheetAccessPolicy({
    required this.visibleProfiles,
    required this.showPrices,
    required this.showStock,
    this.allowedCustomerIds = const <String>{},
  });

  final Set<LineSheetAccessProfile> visibleProfiles;
  final bool showPrices;
  final bool showStock;
  final Set<String> allowedCustomerIds;

  bool allows({required LineSheetAccessProfile profile, String? customerId}) {
    if (!visibleProfiles.contains(profile)) return false;
    return allowedCustomerIds.isEmpty ||
        (customerId != null && allowedCustomerIds.contains(customerId));
  }
}

final class LineSheet {
  const LineSheet({
    required this.id,
    required this.organizationId,
    this.companyId,
    required this.collectionId,
    this.campaignId,
    required this.title,
    required this.version,
    required this.status,
    required this.accessPolicy,
    required this.productEntries,
    required this.publishedAt,
    required this.updatedAt,
  });

  final String id;
  final String organizationId;
  final String? companyId;
  final String collectionId;
  final String? campaignId;
  final String title;
  final int version;
  final LineSheetStatus status;
  final LineSheetAccessPolicy accessPolicy;
  final List<LineSheetProductEntry> productEntries;
  final DateTime? publishedAt;
  final DateTime updatedAt;

  bool get isPublished => status == LineSheetStatus.published;

  LineSheet publish({required DateTime now}) {
    return LineSheet(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      collectionId: collectionId,
      campaignId: campaignId,
      title: title,
      version: isPublished ? version + 1 : version,
      status: LineSheetStatus.published,
      accessPolicy: accessPolicy,
      productEntries: productEntries,
      publishedAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );
  }
}

final class LineSheetProductEntry {
  const LineSheetProductEntry({
    required this.product,
    required this.editorialOrder,
    this.highlight = false,
    this.tags = const <String>[],
    this.unitPrice,
    this.stockUpdatedAt,
    required this.colors,
    required this.sizes,
    required this.variants,
    required this.availabilityByVariantId,
  });

  final Product product;
  final int editorialOrder;
  final bool highlight;
  final List<String> tags;
  final double? unitPrice;
  final DateTime? stockUpdatedAt;
  final List<ProductColor> colors;
  final List<SizeGridSize> sizes;
  final List<ProductVariant> variants;
  final Map<String, VariantAvailability> availabilityByVariantId;

  List<SizeGridSize> get orderedSizes => sizes.sortedByCommercialOrder();

  ProductVariant? variantForCell({
    required String colorId,
    required String sizeId,
  }) {
    for (final variant in variants) {
      if (variant.colorId == colorId && variant.sizeId == sizeId) {
        return variant;
      }
    }
    return null;
  }

  bool get hasAvailableVariants => availabilityByVariantId.values.any(
    (availability) =>
        availability.status != VariantAvailabilityStatus.unavailable,
  );
}

final class LineSheetView {
  const LineSheetView({
    required this.lineSheet,
    required this.profile,
    this.customerId,
  });

  final LineSheet lineSheet;
  final LineSheetAccessProfile profile;
  final String? customerId;

  bool get canViewPrices => lineSheet.accessPolicy.showPrices;
  bool get canViewStock => lineSheet.accessPolicy.showStock;
}
