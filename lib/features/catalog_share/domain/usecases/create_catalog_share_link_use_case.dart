import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/catalog_share_item.dart';
import '../entities/issued_catalog_share.dart';
import '../repositories/catalog_share_repository.dart';
import '../value_objects/catalog_share_scope.dart';

/// Creates a new catalog share (TASK-081). Validates the payload
/// client-side (organizationId present, at least one item, exactly one item
/// when [scope] is [CatalogShareScope.product], collection identity present
/// when [scope] is [CatalogShareScope.collection]) purely to fail fast with
/// a field-level message — `createCatalogShareLink` re-validates every one
/// of these independently and is the only decision that actually matters
/// (`AGENTS.md`).
@injectable
final class CreateCatalogShareLinkUseCase {
  const CreateCatalogShareLinkUseCase(this._repository);

  final CatalogShareRepository _repository;

  Future<AppResult<IssuedCatalogShare>> call({
    required String organizationId,
    required CatalogShareScope scope,
    required List<CatalogShareItem> items,
    String? collectionId,
    String? collectionName,
    int? expiresInDays,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (items.isEmpty) {
      fieldErrors['items'] = 'Selecione ao menos um produto para compartilhar.';
    }
    if (scope == CatalogShareScope.product && items.length > 1) {
      fieldErrors['items'] =
          'Compartilhamento de produto único aceita apenas 1 item.';
    }
    if (scope == CatalogShareScope.collection &&
        (collectionId == null || collectionId.trim().isEmpty)) {
      fieldErrors['collectionId'] =
          'Coleção é obrigatória para este tipo de compartilhamento.';
    }

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<IssuedCatalogShare>>.value(
        AppFailure<IssuedCatalogShare>(
          ValidationFailure(
            'Invalid catalog share payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_create_catalog_share_payload',
          ),
        ),
      );
    }

    return _repository.create(
      organizationId: trimmedOrganizationId,
      scope: scope,
      items: items,
      collectionId: collectionId?.trim(),
      collectionName: collectionName?.trim(),
      expiresInDays: expiresInDays,
    );
  }
}
