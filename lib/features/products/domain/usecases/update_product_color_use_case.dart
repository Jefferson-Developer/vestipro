import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_color.dart';
import '../repositories/product_color_repository.dart';
import '../services/product_color_similarity_service.dart';
import '../value_objects/ean.dart';
import '../value_objects/hex_color.dart';
import '../value_objects/product_color_status.dart';
import '../value_objects/product_sync_status.dart';
import 'product_use_case_helpers.dart';

@injectable
final class UpdateProductColorUseCase {
  const UpdateProductColorUseCase(this._repository, this._similarityService);

  final ProductColorRepository _repository;
  final ProductColorSimilarityService _similarityService;

  Future<AppResult<ProductColor>> call({
    required String organizationId,
    required String id,
    required String code,
    required String name,
    required String hex,
    String? mainImageUrl,
    List<String> additionalImageUrls = const <String>[],
    List<String> eans = const <String>[],
    required String updatedBy,
    ProductColorStatus? status,
    bool confirmedSimilarColor = false,
  }) async {
    final fieldErrors = <String, String>{};
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedCode = code.trim();
    final trimmedName = name.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedCode.isEmpty) fieldErrors['code'] = 'Informe o código da cor.';
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Informe o nome da cor.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    HexColor? parsedHex;
    try {
      parsedHex = HexColor.parse(hex);
    } on ValidationException catch (exception) {
      fieldErrors.addAll(exception.fieldErrors);
    }

    final parsedEans = <Ean>[];
    for (final raw in eans) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      try {
        final ean = Ean.parse(trimmed);
        final existsResult = await _repository.eanExists(
          organizationId: trimmedOrganizationId,
          ean: ean,
          excludingColorId: trimmedId,
        );
        if (existsResult is AppFailure<bool>) {
          return AppFailure<ProductColor>(existsResult.failure);
        }
        if ((existsResult as AppSuccess<bool>).value) {
          fieldErrors['eans'] = 'EAN já cadastrado nesta organização.';
        }
        parsedEans.add(ean);
      } on ValidationException catch (exception) {
        fieldErrors['eans'] = exception.fieldErrors['ean'] ?? exception.message;
      }
    }

    if (fieldErrors.isNotEmpty || parsedHex == null) {
      return AppFailure<ProductColor>(
        ValidationFailure(
          'Invalid product color payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_color_payload',
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<ProductColor>) return currentResult;
    final current = (currentResult as AppSuccess<ProductColor>).value;

    final listResult = await _repository.listByOrganization(
      trimmedOrganizationId,
    );
    if (listResult is AppFailure<List<ProductColor>>) {
      return AppFailure<ProductColor>(listResult.failure);
    }
    final similar = _similarityService.findSimilar(
      name: trimmedName,
      hex: parsedHex,
      existingColors: (listResult as AppSuccess<List<ProductColor>>).value,
      excludingColorId: trimmedId,
    );
    if (similar.isNotEmpty && !confirmedSimilarColor) {
      return AppFailure<ProductColor>(
        ConflictFailure(
          'Similar color already exists in this organization.',
          code: 'product_color_similarity_confirmation_required',
          cause: similar.first.color.id,
        ),
      );
    }

    return _repository.update(
      color: current.copyWith(
        code: trimmedCode,
        name: trimmedName,
        hex: parsedHex,
        mainImageUrl: normalizeProductOptional(mainImageUrl),
        additionalImageUrls: _normalizeUrls(additionalImageUrls),
        eans: parsedEans,
        status: status,
        updatedAt: DateTime.now().toUtc(),
        updatedBy: trimmedUpdatedBy,
        version: current.version + 1,
        syncStatus: ProductSyncStatus.pending,
      ),
    );
  }
}

List<String> _normalizeUrls(List<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toList(growable: false);
