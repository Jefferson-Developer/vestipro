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
final class CreateProductColorUseCase {
  const CreateProductColorUseCase(this._repository, this._similarityService);

  final ProductColorRepository _repository;
  final ProductColorSimilarityService _similarityService;

  Future<AppResult<ProductColor>> call({
    required String id,
    required String organizationId,
    required String code,
    required String name,
    required String hex,
    String? mainImageUrl,
    List<String> additionalImageUrls = const <String>[],
    List<String> eans = const <String>[],
    required String createdBy,
    bool confirmedSimilarColor = false,
  }) async {
    final parsed = await _parsePayload(
      id: id,
      organizationId: organizationId,
      code: code,
      name: name,
      hex: hex,
      userId: createdBy,
      eans: eans,
      excludingColorId: null,
    );
    if (parsed is AppFailure<_ParsedColorPayload>) {
      return AppFailure<ProductColor>(parsed.failure);
    }
    final payload = (parsed as AppSuccess<_ParsedColorPayload>).value;

    final existingResult = await _repository.listByOrganization(
      payload.organizationId,
    );
    if (existingResult is AppFailure<List<ProductColor>>) {
      return AppFailure<ProductColor>(existingResult.failure);
    }
    final similar = _similarityService.findSimilar(
      name: payload.name,
      hex: payload.hex,
      existingColors: (existingResult as AppSuccess<List<ProductColor>>).value,
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

    final now = DateTime.now().toUtc();
    return _repository.create(
      color: ProductColor(
        id: payload.id,
        organizationId: payload.organizationId,
        code: payload.code,
        name: payload.name,
        hex: payload.hex,
        mainImageUrl: normalizeProductOptional(mainImageUrl),
        additionalImageUrls: _normalizeUrls(additionalImageUrls),
        eans: payload.eans,
        status: ProductColorStatus.available,
        createdAt: now,
        createdBy: payload.userId,
        updatedAt: now,
        updatedBy: payload.userId,
        version: 1,
        syncStatus: ProductSyncStatus.pending,
      ),
    );
  }

  Future<AppResult<_ParsedColorPayload>> _parsePayload({
    required String id,
    required String organizationId,
    required String code,
    required String name,
    required String hex,
    required String userId,
    required List<String> eans,
    required String? excludingColorId,
  }) async {
    final fieldErrors = <String, String>{};
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCode = code.trim();
    final trimmedName = name.trim();
    final trimmedUserId = userId.trim();

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCode.isEmpty) fieldErrors['code'] = 'Informe o código da cor.';
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Informe o nome da cor.';
    if (trimmedUserId.isEmpty) fieldErrors['userId'] = 'UserId is required.';

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
          excludingColorId: excludingColorId,
        );
        if (existsResult is AppFailure<bool>) {
          return AppFailure<_ParsedColorPayload>(existsResult.failure);
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
      return AppFailure<_ParsedColorPayload>(
        ValidationFailure(
          'Invalid product color payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_color_payload',
        ),
      );
    }
    return AppSuccess<_ParsedColorPayload>(
      _ParsedColorPayload(
        id: trimmedId,
        organizationId: trimmedOrganizationId,
        code: trimmedCode,
        name: trimmedName,
        hex: parsedHex,
        eans: parsedEans,
        userId: trimmedUserId,
      ),
    );
  }
}

List<String> _normalizeUrls(List<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toList(growable: false);

final class _ParsedColorPayload {
  const _ParsedColorPayload({
    required this.id,
    required this.organizationId,
    required this.code,
    required this.name,
    required this.hex,
    required this.eans,
    required this.userId,
  });

  final String id;
  final String organizationId;
  final String code;
  final String name;
  final HexColor hex;
  final List<Ean> eans;
  final String userId;
}
