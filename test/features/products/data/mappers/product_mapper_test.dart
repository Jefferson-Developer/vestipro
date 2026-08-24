import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/products/data/dtos/product_custom_field_definition_dto.dart';
import 'package:vestipro/features/products/data/dtos/product_dto.dart';
import 'package:vestipro/features/products/data/mappers/product_mapper.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductMapper', () {
    const mapper = ProductMapper();
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 3);

    ProductDto buildFullDto({
      String status = 'active',
      String syncStatus = 'synced',
    }) {
      return ProductDto(
        id: 'product-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        sku: 'CAMISA-001',
        reference: 'REF-001',
        name: 'Camisa Essential',
        shortDescription: 'Camisa basica',
        fullDescription: 'Camisa basica de algodao pima',
        brand: 'Malwee',
        collectionId: 'collection-1',
        seasonId: 'season-1',
        line: 'Premium',
        categoryId: 'category-1',
        subcategoryId: 'subcategory-1',
        gender: 'masculine',
        targetAudience: 'adult',
        fabric: 'algodao',
        composition: '100% algodao pima',
        supplierId: 'supplier-1',
        ncm: '61051000',
        ean: '4006381333931',
        tags: const <String>['lancamento', 'basico'],
        status: status,
        launchDate: DateTime.utc(2026, 2, 1),
        seoTitle: 'Camisa Essential | Malwee',
        seoDescription: 'Camisa basica de algodao pima para o verao.',
        seoSlug: 'camisa-essential',
        photoUrls: const <String>['https://cdn.example.com/foto1.jpg'],
        videoUrls: const <String>['https://cdn.example.com/video1.mp4'],
        customFieldValues: const <ProductCustomFieldValueDto>[
          ProductCustomFieldValueDto(
            fieldDefinitionId: 'field-1',
            value: 'algodao-organico',
          ),
        ],
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-2',
        version: 3,
        syncStatus: syncStatus,
      );
    }

    ProductDto buildMinimalDto() {
      return ProductDto(
        id: 'product-2',
        organizationId: 'org-1',
        sku: 'CAMISA-002',
        reference: 'REF-002',
        name: 'Camisa Minima',
        status: 'draft',
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: 'pending',
      );
    }

    test('toEntity maps every field of a fully filled product', () {
      final entity = mapper.toEntity(buildFullDto());

      expect(entity.id, 'product-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.companyId, 'company-1');
      expect(entity.sku, Sku.parse('CAMISA-001'));
      expect(entity.reference, 'REF-001');
      expect(entity.name, 'Camisa Essential');
      expect(entity.brand, 'Malwee');
      expect(entity.gender, ProductGender.masculine);
      expect(entity.targetAudience, TargetAudience.adult);
      expect(entity.ean, Ean.parse('4006381333931'));
      expect(entity.tags, <String>['lancamento', 'basico']);
      expect(entity.status, ProductStatus.active);
      expect(entity.launchDate, DateTime.utc(2026, 2, 1));
      expect(entity.seoTitle, 'Camisa Essential | Malwee');
      expect(
        entity.seoDescription,
        'Camisa basica de algodao pima para o verao.',
      );
      expect(entity.seoSlug, 'camisa-essential');
      expect(entity.photoUrls, <String>['https://cdn.example.com/foto1.jpg']);
      expect(entity.videoUrls, <String>['https://cdn.example.com/video1.mp4']);
      expect(entity.customFieldValues.single.fieldDefinitionId, 'field-1');
      expect(entity.customFieldValues.single.value, 'algodao-organico');
      expect(entity.version, 3);
      expect(entity.syncStatus, ProductSyncStatus.synced);
    });

    test(
      'toEntity maps a minimal product with null fields and empty lists',
      () {
        final entity = mapper.toEntity(buildMinimalDto());

        expect(entity.companyId, isNull);
        expect(entity.shortDescription, isNull);
        expect(entity.fullDescription, isNull);
        expect(entity.brand, isNull);
        expect(entity.gender, isNull);
        expect(entity.targetAudience, isNull);
        expect(entity.ean, isNull);
        expect(entity.launchDate, isNull);
        expect(entity.seoTitle, isNull);
        expect(entity.seoDescription, isNull);
        expect(entity.seoSlug, isNull);
        expect(entity.tags, isEmpty);
        expect(entity.photoUrls, isEmpty);
        expect(entity.videoUrls, isEmpty);
        expect(entity.customFieldValues, isEmpty);
        expect(entity.status, ProductStatus.draft);
        expect(entity.syncStatus, ProductSyncStatus.pending);
      },
    );

    test('toDto is the inverse of toEntity for a fully filled product', () {
      final dto = buildFullDto();
      final roundTripped = mapper.toDto(mapper.toEntity(dto));

      expect(roundTripped.id, dto.id);
      expect(roundTripped.organizationId, dto.organizationId);
      expect(roundTripped.companyId, dto.companyId);
      expect(roundTripped.sku, dto.sku);
      expect(roundTripped.reference, dto.reference);
      expect(roundTripped.name, dto.name);
      expect(roundTripped.gender, dto.gender);
      expect(roundTripped.targetAudience, dto.targetAudience);
      expect(roundTripped.ean, dto.ean);
      expect(roundTripped.tags, dto.tags);
      expect(roundTripped.status, dto.status);
      expect(roundTripped.launchDate, dto.launchDate);
      expect(roundTripped.seoTitle, dto.seoTitle);
      expect(roundTripped.seoDescription, dto.seoDescription);
      expect(roundTripped.seoSlug, dto.seoSlug);
      expect(roundTripped.photoUrls, dto.photoUrls);
      expect(roundTripped.videoUrls, dto.videoUrls);
      expect(
        roundTripped.customFieldValues.single.fieldDefinitionId,
        dto.customFieldValues.single.fieldDefinitionId,
      );
      expect(roundTripped.version, dto.version);
      expect(roundTripped.syncStatus, dto.syncStatus);
    });

    test('toDto is the inverse of toEntity for a minimal product', () {
      final dto = buildMinimalDto();
      final roundTripped = mapper.toDto(mapper.toEntity(dto));

      expect(roundTripped.companyId, isNull);
      expect(roundTripped.ean, isNull);
      expect(roundTripped.seoTitle, isNull);
      expect(roundTripped.seoDescription, isNull);
      expect(roundTripped.seoSlug, isNull);
      expect(roundTripped.tags, isEmpty);
      expect(roundTripped.customFieldValues, isEmpty);
      expect(roundTripped.status, 'draft');
      expect(roundTripped.syncStatus, 'pending');
    });

    test('toEntity throws for an unknown status, gender or sync status', () {
      expect(
        () => mapper.toEntity(buildFullDto(status: 'archived')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => mapper.toEntity(buildFullDto(syncStatus: 'remote_only')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('definition mappers round-trip an organization custom field', () {
      const dto = ProductCustomFieldDefinitionDto(
        id: 'field-1',
        organizationId: 'org-1',
        key: 'composicao_extra',
        label: 'Composicao extra',
        type: 'list',
        isRequired: true,
        options: <String>['algodao', 'poliester'],
      );

      final entity = mapper.definitionToEntity(dto);

      expect(entity.id, 'field-1');
      expect(entity.type, ProductCustomFieldType.list);
      expect(entity.isRequired, isTrue);
      expect(entity.options, <String>['algodao', 'poliester']);

      final roundTripped = mapper.definitionToDto(entity);
      expect(roundTripped.type, dto.type);
      expect(roundTripped.options, dto.options);
    });
  });
}
