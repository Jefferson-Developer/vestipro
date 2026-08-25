import '../value_objects/ean.dart';
import '../value_objects/hex_color.dart';
import '../value_objects/product_color_status.dart';
import '../value_objects/product_sync_status.dart';

/// Reusable organization-scoped color palette entry (TASK-070).
///
/// Products only keep references to these ids, so equivalent colors are
/// suggested before creation instead of being recreated per product.
final class ProductColor {
  const ProductColor({
    required this.id,
    required this.organizationId,
    required this.code,
    required this.name,
    required this.hex,
    this.mainImageUrl,
    this.additionalImageUrls = const <String>[],
    this.eans = const <Ean>[],
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String organizationId;
  final String code;
  final String name;
  final HexColor hex;
  final String? mainImageUrl;
  final List<String> additionalImageUrls;
  final List<Ean> eans;
  final ProductColorStatus status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final int version;
  final ProductSyncStatus syncStatus;

  bool get isAvailable =>
      status == ProductColorStatus.available && deletedAt == null;

  ProductColor copyWith({
    String? code,
    String? name,
    HexColor? hex,
    String? mainImageUrl,
    List<String>? additionalImageUrls,
    List<Ean>? eans,
    ProductColorStatus? status,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
    ProductSyncStatus? syncStatus,
  }) {
    return ProductColor(
      id: id,
      organizationId: organizationId,
      code: code ?? this.code,
      name: name ?? this.name,
      hex: hex ?? this.hex,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      additionalImageUrls: additionalImageUrls ?? this.additionalImageUrls,
      eans: eans ?? this.eans,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
