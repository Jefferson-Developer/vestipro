import 'package:vestipro/features/products/products.dart';

Product buildTestProduct({
  String id = 'product-1',
  String organizationId = 'org-1',
  String? companyId = 'company-1',
  String sku = 'CAMISA-001',
  String reference = 'REF-001',
  String name = 'Camisa Basica',
  String? brand = 'VestiPro',
  String? ean = '4006381333931',
  List<String> tags = const <String>['lancamento'],
  List<String> colorIds = const <String>[],
  String? sizeGridTemplateId,
  DateTime? deletedAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    sku: Sku.parse(sku),
    reference: reference,
    name: name,
    brand: brand,
    ean: ean == null ? null : Ean.parse(ean),
    tags: tags,
    colorIds: colorIds,
    sizeGridTemplateId: sizeGridTemplateId,
    status: ProductStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    deletedAt: deletedAt,
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}
